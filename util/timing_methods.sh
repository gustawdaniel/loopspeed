#!/usr/bin/env bash

#http://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable
#https://www.gnu.org/software/bash/manual/bashref.html#Shell-Parameter-Expansion


function onExit
{
	[ ! -z "$TMP" ] && \
	[   -d "$TMP" ] && \
	rm -Rf "$TMP";
	exit;
}

trap onExit SIGINT SIGTERM EXIT;


GIT=`git rev-parse HEAD`;
TMP="$(mktemp -d)";
i=0;

while IFS='' read -r line || [[ -n "$line" ]]; do

    i=$[i+1];

    t1=`bash util/timing.sh bash inc/inc.bash $line`
    /usr/bin/time -o "$TMP/time" -f "%e" bash inc/inc.bash $line &> /dev/null;
    t2="$(cat "$TMP/time" 2> /dev/null)";

    echo $i $line $t1 $t2 $GIT |\
	awk '{print $1, $2, $3, $4, $5}' \
	 | tee /dev/tty >> log/results_timing_methods.log

done < ${1:-config/list_timing_methods.txt}

