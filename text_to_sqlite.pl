#!/usr/bin/perl -w
use DBI;
use strict;
#https://mailliststock.wordpress.com/2007/03/01/sqlite-examples-with-bash-perl-and-python/
my $db = DBI->connect("dbi:SQLite:log.db", "", "",
{RaiseError => 1, AutoCommit => 1});

my $git='d1f050302c28aa8a837ec5453323df30cad9766e';
#my $filename = 'results.log';
my $filename = $ARGV[0];

open( my $fh => $filename) || die "Cannot open $filename: $!";

while(my $line = <$fh>) {
        my @row = split(",",$line);
        $db->do("INSERT INTO log (name,size,time,git) values ('".$row[0]."',$row[1],$row[2],'$git');");
}
close($fh);



#$db->do("CREATE TABLE n (id INTEGER PRIMARY KEY, f TEXT, l TEXT)");
#my $all = $db->selectall_arrayref("SELECT * FROM n");

#foreach my $row (@$all) {
#my ($id, $first, $last) = @$row;
#print "$id|$first|$lastn";
#}

#  sqlite3 log.db  "insert into log (name,size,time,git) values ('$name',$size,$time,'$GIT');"
# results.log

