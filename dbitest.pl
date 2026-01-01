#!/usr/bin/perl
#use strict;
use warnings;

use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=test.db","","", {
  sqlite_open_flags => SQLITE_OPEN_READONLY,
  AutoCommit => 1,
  RaiseError => 1,
  sqlite_see_if_its_a_number => 1,
});

open FILE, "<dictrules3.txt";
my $sth = $dbh->prepare("BEGIN");
$sth->execute();

while(<FILE>) {
	print $_;
	chomp;
	$sth = $dbh->prepare("INSERT OR IGNORE INTO tbl2 (password, pid, status) VALUES (?1, ?2, ?3)");
	$sth->execute($_, 1, 2);
}
$sth = $dbh->prepare("END");
$sth->execute();

close FILE;
#
exit();
#
my $sth = $dbh->prepare("SELECT * FROM tbl2 WHERE 1");
$sth->execute();

while(my $dat = $sth->fetchrow_hashref()) {
	print "$dat->{'password'}\t$dat->{'pid'}\t$dat->{'status'}\t$dat->{'ts'}\n";
}
