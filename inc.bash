#! /bin/bash

function onExit
{
	[ ! -z "$TMP" ] && \
	[   -d "$TMP" ] && \
	rm -Rf "$TMP";
	rm -f inc.class;
	exit;
}

function test
{
	name="$1";
	size="$2";
	comm="${@:3}"

#	/usr/bin/time -o "$TMP/time" -f "%e" $comm $size &> /dev/null; #oryfinally %U instead %e
#	time="$(cat "$TMP/time" 2> /dev/null)";
    time=`bash util/timing.sh $comm $size`
	echo $name,$size,$time,$GIT	\
	    | tee -a log/results.log \
	    | awk -F ',' '{printf "| %-12s | %15s | %12.6f s | %19.2f |\n", $1, $2, $3, $2/$3;}'
#
#	 | tee /dev/tty \
#     | awk '{print $2","$4","$6","$9}' >> log/results.log

     sqlite3 log/log.db  "insert into log (name,size,time,git) values ('$name',$size,$time,'$GIT');"

}

cd "$(dirname "${BASH_SOURCE[0]}")";

trap onExit SIGINT SIGTERM EXIT;

TMP="$(mktemp -d)";
POW=${1:-50};
GIT=`git rev-parse HEAD`;

g++ -O1 -o "$TMP/cpp" 'inc/inc.cpp';
gcc -o "$TMP/c"   'inc/inc.c';
mcs -out:"$TMP/cs.exe" inc/inc.cs
javac 'inc/inc.java' -d .;
mysql -u root < inc/def.sql;
f95 -o "$TMP/f" inc/inc.f95
fpc -O2 inc/inc.p -o"$TMP/p" -Tlinux &>/dev/null

echo '+--------------+-----------------+----------------+---------------------+';
echo '|     File     |      Size       |      Time      |        Speed        |';
echo '+--------------+-----------------+----------------+---------------------+';
while IFS='' read -r POW || [[ -n "$POW" ]]; do

#echo "size = $line";
#test    inc.m.sh    $[ 20000000*POW]    bash    inc/inc.m.sh; # long time of setup about 5 sec
#test    inc.bash    $[1*POW]    bash    inc/inc.bash;
#test    inc.sql.sh  $[1*POW]    bash    inc/inc.sql.sh;
#test    inc.wl      $[1*POW]    MathematicaScript -script inc/inc.wl;
#test    inc.cs      $[1*POW]    mono    "$TMP/cs.exe";
#test    inc.js      $[1*POW]    node    inc/inc.js;
#test    inc.python  $[1*POW]    python  inc/inc.python;
#test    inc.rb      $[1*POW]    ruby    inc/inc.rb;
#test    inc.perl    $[1*POW]    perl    inc/inc.perl;
#test    inc.r       $[1*POW]    Rscript inc/inc.r;
test    inc.php     $[1*POW]    php     inc/inc.php;
test    inc.f95     $[1*POW]    "/$TMP/f";
test    inc.cpp     $[1*POW]    "$TMP/cpp";
test    inc.c       $[1*POW]    "$TMP/c";
test    inc.p       $[1*POW]    "$TMP/p";
test    inc.java    $[1*POW]    java inc;

done < ${1:-config/list.txt}

echo '+--------------+-----------------+----------------+---------------------+';

