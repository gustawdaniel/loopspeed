#!/usr/bin/env bash

echo "\n\n\nBASH START\n\n\n"

# no prompt password mysql installation
#http://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt

apt-get update -y

echo "mysql-server mysql-server/root_password password ''" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password ''" | debconf-set-selections
apt-get install -y mysql-server

apt-get install -y sqlite3 g++ mono-mcs openjdk-9-jdk-headless gfortran fp-compiler r-base nodejs-legacy ruby php

apt-get install -y bc


cpan install DBI DBD::SQLite Text::CSV_XS

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


echo "\n\n\nBASH END\n\n\n"