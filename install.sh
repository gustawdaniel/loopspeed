#!/usr/bin/env bash

if command -v paru >/dev/null 2>&1; then
  paru -S --needed --noconfirm \
    php python jdk-openjdk gcc mono gcc-fortran fpc r ruby \
    sqlite bc git mariadb-clients curl \
    perl-text-csv perl-dbi perl-dbd-sqlite
fi

mkdir -p log

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

if [ ! -d "shunit2-2.1.6" ]; then
  curl -L "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/shunit2/shunit2-2.1.6.tgz" | tar zx
fi
