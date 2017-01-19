#!/usr/bin/env bash

#http://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable
#https://www.gnu.org/software/bash/manual/bashref.html#Shell-Parameter-Expansion
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "POW = " $line;
    bash inc.bash $line
done < ${1:-config/list.txt}

