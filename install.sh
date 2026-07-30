#!/usr/bin/env bash


paru -S --needed --noconfirm \
  php python jdk-openjdk gcc mono gcc-fortran fpc r ruby \
  sqlite bc git mariadb-clients curl \
  perl-text-csv perl-dbi perl-dbd-sqlite

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
"create table IF NOT EXISTS result (
    name varchar(255),
    a real,
    b real,
    ea real,
    eb real
);"

curl -L "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/shunit2/shunit2-2.1.6.tgz" | tar zx
