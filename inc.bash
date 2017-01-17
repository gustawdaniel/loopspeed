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
	awk '{printf "| %-12s | %16s | %8s s | %19.2f |\n", $1, $2, $3, $2/$3;}'
}

cd "$(dirname "${BASH_SOURCE[0]}")";

trap onExit SIGINT SIGTERM EXIT;

TMP="$(mktemp -d)";
POW=5;

g++ -o "$TMP/cpp" 'inc/inc.cpp';
gcc -o "$TMP/c"   'inc/inc.c';
mcs -out:"$TMP/cs.exe" inc/inc.cs
javac 'inc/inc.java' -d .;
mysql -u root inc < inc/def.sql;
f95 -o "$TMP/f" inc/inc.f95

echo '+--------------+------------------+------------+---------------------+';
echo '|     File     |       Size       |    Time    |        Speed        |';
echo '+--------------+------------------+------------+---------------------+';

test    inc.m.sh    $[         1*POW]    bash    inc/inc.m.sh;
test    inc.bash    $[    200000*POW]    bash    inc/inc.bash;
test    inc.sql.sh  $[    400000*POW]    bash    inc/inc.sql.sh;
test    inc.wl      $[   2000000*POW]    MathematicaScript -script inc/inc.wl;
test    inc.cs      $[   5000000*POW]    mono    "$TMP/cs.exe";
test    inc.js      $[  12000000*POW]    node    inc/inc.js;
test    inc.bash    $[  25000000*POW]    Rscript inc/inc.r;
test    inc.rb      $[  25000000*POW]    ruby    inc/inc.rb;
test    inc.perl    $[  25000000*POW]    perl    inc/inc.perl;
test    inc.python  $[  25000000*POW]    python  inc/inc.python;
test    inc.php     $[ 100000000*POW]    php     inc/inc.php;
test    inc.f95     $[ 300000000*POW]    "/$TMP/f";
test    inc.cpp     $[ 400000000*POW]    "$TMP/cpp";
test    inc.c       $[ 400000000*POW]    "$TMP/c";
test    inc.java    $[2000000000*POW]    java inc;
echo '+--------------+------------------+------------+---------------------+';

