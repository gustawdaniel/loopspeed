#!/usr/bin/env bash

#rm -f results.log

sqlite3 log.db \
"create table IF NOT EXISTS log (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    size UNSIGNED INTEGER,
    time DECIMAL(8,2),
    git CHAR(41)
);"

#i=1;
#max=$1;
#    j=$[1*$max];
#
##while [[ $i -le $max ]];
##do
##    j=$[1*$i];
#    echo "POW = " $j;
#    bash inc.bash $j;
##    i=$[i+1];
##done