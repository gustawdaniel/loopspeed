#!/usr/bin/env bash

sqlite3 log/log.db \
"create table IF NOT EXISTS log (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    size UNSIGNED INTEGER,
    time DECIMAL(8,2),
    git CHAR(41)
);"

#http://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable
#https://www.gnu.org/software/bash/manual/bashref.html#Shell-Parameter-Expansion
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "POW = " $line;
    bash inc.bash $line
done < ${1:-config/list.txt}

