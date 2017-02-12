#!/usr/bin/env bash


apt-get update -y
apt-get install -y php python default-jdk g++ mono-mcs gfortran fp-compiler r-base nodejs-legacy ruby

apt-get install -y sqlite3 bc git mysql-client curl
apt-get install -y libtext-csv-perl libdbi-perl libdbd-sqlite3-perl
#cpan install DBI DBD::SQLite Text::CSV_XS

sqlite3 log/log.db \
"create table IF NOT EXISTS log (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    size UNSIGNED INTEGER,
    time DECIMAL(12,6),
    git CHAR(41)
);"

sqlite3 log/log.db \
"create table result (
    name varchar(255),
    a real,
    b real,
    ea real,
    eb real
);"

curl -L "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/shunit2/shunit2-2.1.6.tgz" | tar zx
