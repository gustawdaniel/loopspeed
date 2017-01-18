#!/usr/bin/perl -w
use DBI;
use strict;
#https://mailliststock.wordpress.com/2007/03/01/sqlite-examples-with-bash-perl-and-python/
my $db = DBI->connect("dbi:SQLite:log.db", "", "",
{RaiseError => 1, AutoCommit => 1});

my $git='fd7f0d3acd0cd14af4e7d9d51713dc0875e65ae0';
#my $filename = $ARGV{0};

print $ARGV[0];

#open( my $fh => $filename) || die "Cannot open $filename: $!";
#my %gene_count;
#
#while(my $line = <$fh>) {
#        my @row = split(",",$line);
##        $gene_count{ $row[] } = ++;
#}
#close($fh);



#$db->do("CREATE TABLE n (id INTEGER PRIMARY KEY, f TEXT, l TEXT)");
#$db->do("INSERT INTO n VALUES (NULL, 'john', 'smith')");
#my $all = $db->selectall_arrayref("SELECT * FROM n");

#foreach my $row (@$all) {
#my ($id, $first, $last) = @$row;
#print "$id|$first|$lastn";
#}

#  sqlite3 log.db  "insert into log (name,size,time,git) values ('$name',$size,$time,'$GIT');"
# results.log

