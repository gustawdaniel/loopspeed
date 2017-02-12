#!/usr/bin/env bash

apt-get update -y
apt-get install -y g++ mono-mcs openjdk-9-jdk-headless gfortran fp-compiler r-base nodejs-legacy ruby php
apt-get install -y sqlite3 bc git mysql-client
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