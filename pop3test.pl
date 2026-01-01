#!/usr/bin/perl
use strict;
use warnings;
use Net::POP3;

use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=test.db","","", {
#  sqlite_open_flags => SQLITE_OPEN_READONLY,
  AutoCommit => 1,
  RaiseError => 1,
  sqlite_see_if_its_a_number => 1,
});


my $id=$ARGV[0];
print "id:$id\n";
my $sth = $dbh->prepare("SELECT * FROM tbl2 WHERE id=?");
$sth->execute($id);

my $pass;
my $mail;
while(my $dat = $sth->fetchrow_hashref()) {
	$pass = $dat->{'password'};
	$mail = $dat->{'mail'}
}

	if (!$pass) {
		die "NO PASSWORD\n";
	}
	if (!$mail) {
		die "NO MAIL\n";
	}
	print "alive...\n";

	my $pop = Net::POP3->new('pop3.abv.bg', SSL => 1, Timeout => 60, Debug => 1);
	if ($pop->login($mail, $pass)) {
	  print "PASS:$pass\n";
#	  my $msgnums = $pop->list; # hashref of msgnum => size
#	  foreach my $msgnum (keys %$msgnums) {
#		my $msg = $pop->get($msgnum);
#		print @$msg;
#	    $pop->delete($msgnum);
#	  }
	 $pop->quit;
	 print "PASS FOUND\n";
	 my $sth2 = $dbh->prepare("UPDATE tbl2 SET status=255, lu_ts=datetime() WHERE id=?");
	 $sth2->execute($id);

	 exit();
	}
	print "NOTPASS\n";
	my $sth2 = $dbh->prepare("UPDATE tbl2 SET status=status+1 WHERE id=?");
	$sth2->execute($id);
	$pop->quit;
	sleep(1);
