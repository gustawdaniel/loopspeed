#!/usr/bin/perl -w
use warnings FATAL => 'all';
use DBI;
use strict;
#https://mailliststock.wordpress.com/2007/03/01/sqlite-examples-with-bash-perl-and-python/
my $db = DBI->connect("dbi:SQLite:log/log.db", "", "",{RaiseError => 1, AutoCommit => 1});

my $git='d1f050302c28aa8a837ec5453323df30cad9766e';
my $filename =  $ARGV[0] || 'log/results.log';

open( my $fh => $filename) || die "Cannot open $filename: $!";

while(my $line = <$fh>) {
        my @row = split(",",$line);
        $db->do("INSERT INTO log (name,size,time,git) values ('".$row[0]."',$row[1],$row[2],'$git');");
}
close($fh);

