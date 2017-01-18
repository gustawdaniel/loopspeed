#!/bin/bash
sqlite3 log.db  "create table IF NOT EXISTS log (id INTEGER PRIMARY KEY,f VARCHAR(255),l VARCHAR(255));"
sqlite3 log.db  "insert into log (f,l) values ('john','smith');"
sqlite3 log.db  "select * from log";
