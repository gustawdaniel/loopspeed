#!/usr/bin/env bash

sudo apt-get install sqlite3 g++ mono-mcs openjdk-9-jdk-headless mysql-server gfortran fp-compiler r-base nodejs-legacy ruby php

sudo cpan install DBI DBD::SQLite

#sudo mysql -u root -e \
#"DROP USER 'root'@'localhost';
#CREATE USER 'root'@'%' IDENTIFIED BY '';
#GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
#FLUSH PRIVILEGES;";

sqlite3 log/log.db \
"create table IF NOT EXISTS log (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    size UNSIGNED INTEGER,
    time DECIMAL(8,2),
    git CHAR(41)
);"
