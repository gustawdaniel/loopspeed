#!/usr/bin/perl -w

use v5.10;
use strict;
use warnings;
use autodie;

use Text::CSV_XS;
use DBI;

my $dbh = DBI->connect(
    "dbi:SQLite:log/log.db", "", "",
    {
        RaiseError => 1, AutoCommit => 0
    }
);

$dbh->do("DELETE FROM result");

#$dbh->do(<<'SQL');
#CREATE TABLE test (
#    name        VARCHAR,
#    num1        INT,
#    num2        INT,
#    thing       VARCHAR,
#    num3        INT,
#    stuff       VARCHAR
#)
#SQL

# Using bind parameters avoids having to recompile the statement every time
my $sth = $dbh->prepare(<<'SQL');
INSERT INTO result
       (name, a,     b,     ea,    eb)
VALUES (?,    ?,     ?,     ?,     ?)
SQL

my $csv = Text::CSV_XS->new or die;
open my $fh, "<", "config/parameters.csv";
while(my $row = $csv->getline($fh)) {
    $sth->execute(@$row);
}
$csv->eof;
close $fh;

$sth->finish;
$dbh->commit;