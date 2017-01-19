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

	/usr/bin/time -o "$TMP/time" -f "%e" $comm $size &> /dev/null; #oryfinally %U instead %e
	time="$(cat "$TMP/time" 2> /dev/null)";
	echo $name $size $time |\
	awk '{printf "| %-12s | %16s | %8s s | %19.2f |\n", $1, $2, $3, $2/$3;}' \
	 | tee /dev/tty \
     | awk '{print $2","$4","$6","$9}' >> results.log

     sqlite3 log.db  "insert into log (name,size,time,git) values ('$name',$size,$time,'$GIT');"

}

cd "$(dirname "${BASH_SOURCE[0]}")";

trap onExit SIGINT SIGTERM EXIT;

TMP="$(mktemp -d)";
POW=$1;
GIT=`git rev-parse HEAD`;

g++ -o "$TMP/cpp" 'inc/inc.cpp';
gcc -o "$TMP/c"   'inc/inc.c';
mcs -out:"$TMP/cs.exe" inc/inc.cs
javac 'inc/inc.java' -d .;
mysql -u root inc < inc/def.sql;
f95 -o "$TMP/f" inc/inc.f95
fpc -Op inc/inc.p -o"$TMP/p" -Tlinux &>/dev/null

echo '+--------------+------------------+------------+---------------------+';
echo '|     File     |       Size       |    Time    |        Speed        |';
echo '+--------------+------------------+------------+---------------------+';
#test    inc.m.sh    $[ 20000000*POW]    bash    inc/inc.m.sh; # long time of setup about 5 sec
#test    inc.bash    $[    20598*POW]    bash    inc/inc.bash;
#test    inc.sql.sh  $[    40713*POW]    bash    inc/inc.sql.sh;
#test    inc.wl      $[   178362*POW]    MathematicaScript -script inc/inc.wl;
#test    inc.cs      $[   500126*POW]    mono    "$TMP/cs.exe";
#test    inc.js      $[   763305*POW]    node    inc/inc.js;
#test    inc.python  $[  1441468*POW]    python  inc/inc.python;
#test    inc.rb      $[  2484535*POW]    ruby    inc/inc.rb;
#test    inc.perl    $[  2215594*POW]    perl    inc/inc.perl;
test    inc.r       $[   139211*POW]    Rscript inc/inc.r;
#test    inc.php     $[ 10476892*POW]    php     inc/inc.php;
#test    inc.f95     $[ 30079457*POW]    "/$TMP/f";
#test    inc.cpp     $[ 36443924*POW]    "$TMP/cpp";
#test    inc.c       $[ 37093252*POW]    "$TMP/c";
#test    inc.p       $[ 43815805*POW]    "$TMP/p";
#test    inc.java    $[255411892*POW]    java inc;
echo '+--------------+------------------+------------+---------------------+';

