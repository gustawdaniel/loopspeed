#! /bin/bash

show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [-f file] [FILE]...
Do stuff with FILE and write the result to standard output. With no FILE
or when FILE is -, read standard input.

    -h          display this help and exit
    -a          all programs enable, enable this only if you have
                licence on Mathematica and Matlab.
    -t          time based mode of calculations. You assign number
                of seconds for each program. Programs goes equally.
    -l          line badsed mode of calculations. You assign number
                of lines executed by loop. Good mode for debug.
    -f file     load numbers of seconds (-t) or loops (-l) from file,
                default config/list.txt
EOF
}

function onExit {
	[ ! -z "$TMP" ] && \
	[   -d "$TMP" ] && \
	rm -Rf "$TMP";
	rm -f inc.class;
	exit;
}

function test {
	name="$1";
	size="$2";
	comm="${@:3}"

    [ $size -le 0 ] && return;

    time=`bash util/timing.sh $comm $size`
	echo $name,$size,$time,$GIT	\
	    | tee -a log/results.log \
	    | awk -F ',' '{printf "| %-12s | %15s | %12.6f s | %19.2f |\n", $1, $2, $3, $2/$3;}'

     sqlite3 log/log.db  "insert into log (name,size,time,git) values ('$name',$size,$time,'$GIT');"
}

function compile {
    g++ -O1 -o "$TMP/cpp" 'inc/inc.cpp';
    gcc -O1 -o "$TMP/c"   'inc/inc.c';
    mcs -out:"$TMP/cs.exe" inc/inc.cs
    javac 'inc/inc.java' -d .;
    mysql -u root < inc/def.sql;
    f95 -O1 -o "$TMP/f" inc/inc.f95
    fpc -O2 inc/inc.p -o"$TMP/p" -Tlinux &>/dev/null
}

# number of loops for given languages in dependence from $timeMode
function calculate {

    if [[ "$timeMode" -eq "1"  ]]; then
#        echo $1 ${a[$1]} ${b[$1]} $POW "\n";
        echo $1 ${a[$1]} ${b[$1]} $POW | awk '{ printf "%s %.0f\n", $1, ($4-$3)/$2 }';
    else # linemode for debug
        echo $1 $[1*POW];
    fi
}

function testbundle {
#    TP=;

    #echo "size = $line";
    [ "$allPrograms" -eq "1" ] && test    $(calculate inc.m.sh    )    bash    inc/inc.m.sh; # long time of setup about 5 sec
    test    $(calculate inc.bash    )    bash    inc/inc.bash;
    test    $(calculate inc.sql.sh  )    bash    inc/inc.sql.sh;
    [ "$allPrograms" -eq "1" ] && test    $(calculate inc.wl      )    MathematicaScript -script inc/inc.wl;
    test    $(calculate inc.r       )    Rscript inc/inc.r;
    test    $(calculate inc.cs      )    mono    "$TMP/cs.exe";
    test    $(calculate inc.js      )    node    inc/inc.js;
    test    $(calculate inc.python  )    python  inc/inc.python;
    test    $(calculate inc.rb      )    ruby    inc/inc.rb;
    test    $(calculate inc.pl      )    perl    inc/inc.pl;
    test    $(calculate inc.php     )    php     inc/inc.php;
    test    $(calculate inc.f95     )    "/$TMP/f";
    test    $(calculate inc.cpp     )    "$TMP/cpp";
    test    $(calculate inc.c       )    "$TMP/c";
    test    $(calculate inc.p       )    "$TMP/p";
    test    $(calculate inc.java    )    java inc;
}

function loadParams {
source <(sqlite3 log/log.db "select name, a from result" |
         awk -F '|' '{printf("a[%s]=%s;\n",$1,$2);}')

source <(sqlite3 log/log.db "select name, b from result" |
         awk -F '|' '{printf("b[%s]=%s;\n",$1,$2);}')
}

cd "$(dirname "${BASH_SOURCE[0]}")";
trap onExit SIGINT SIGTERM EXIT;

TMP="$(mktemp -d)";
GIT=`git rev-parse HEAD`;
declare -A a
declare -A b
allPrograms=0; # if all programs should be tested? Default: no, because licence is not free.
configFile='config/list.txt';
timeMode=1;
fileMode=0;

while getopts hatlf opt; do
    case $opt in
        h)
            show_help
            exit 0
            ;;
        a)  allPrograms=$((allPrograms+1))
            ;;
        t)  timeMode=1;
            ;;
        l)  timeMode=0;
            ;;
        f)  configFile=${2:-${configFile}}; fileMode=1;
            ;;
        *)
            show_help >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.

POW=${1:-4};

# Everything that's left in "$@" is a non-option.  In our case, a FILE to process.
#printf 'a=<%d>\nt=<%s>\nf=<%s>\nfm=<%s>\n' "$allPrograms" "$timeMode" "$configFile" "$fileMode"
#printf '<%s>\n' "$@"
#echo $POW;

loadParams;
compile

echo '+--------------+-----------------+----------------+---------------------+';
echo '|     File     |      Size       |      Time      |        Speed        |';
echo '+--------------+-----------------+----------------+---------------------+';

if [[ "$fileMode" -eq "1" ]]; then
   while IFS='' read -r POW || [[ -n "$POW" ]]; do
      testbundle;
   done < ${1:-${configFile}}
else
  testbundle;
fi

echo '+--------------+-----------------+----------------+---------------------+';
