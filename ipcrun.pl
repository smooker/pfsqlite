#!/usr/bin/perl

#use strict;
use warnings;
use IPC::Run qw( start pump finish timeout run );;
use Data::Dumper;
use feature 'say';
use Symbol 'gensym'; # vivify a separate handle for STDERR
use DBI;
use Proc::ProcessTable;
use Time::HiRes qw(usleep nanosleep);

my $dbh = DBI->connect("dbi:SQLite:dbname=test.db","","", {
#  sqlite_open_flags => SQLITE_OPEN_READONLY,
  AutoCommit => 1,
  RaiseError => 1,
  sqlite_see_if_its_a_number => 1,
});

my %pids;        #PIDs

my %stdouts;     #stdout
my %stdins;      #stdin
my %stderrs;     #stderr
my %fhs;	 	 #file handlers
my %h;			 #handles

my @passwords;
my %passtested;

#sub AUTOLOAD {
#        print "AUTOLOAD fired\n";
#}

sub getPidState {
	my $pid = shift;
	my $pt = Proc::ProcessTable->new();
	my $kid;
	for my $p (@{ $pt->table } ) {
		if ( $p->ppid == $$ ) {
			if ($p->pid == $pid) {
#				print "Z:".$p->state."\n";
				return $p->state;
			}
		}
	}
	return 'undef';
}

sub stall_timer {
	print "STALL TIMER FIRED\n";
}

sub oneProc {
	my $i = shift;

	my @cmd;
	push @cmd, "./pop3test.pl";
#	push @cmd, "./echo.sh";
#	push @cmd, $i;
	push @cmd, pop(@passwords);

	#open $stdouts{$i}, '+<', "/tmp/out_$i.txt" or die "open failed: $!";
	#print "opened filehandle $stdouts{$i} with descriptor ".fileno($stdouts{$i})."\n";
	#$pids{$i} = open3(my $stdin = gensym, ['&', $stdouts{$i}], my $stderr = gensym, @cmd);
#	$pids{$i} = start \@cmd, \$stdins{$i}, \$stdins{$i}, \$stderrs{$i}, timeout( 10 );
	$h{$i} = start \@cmd, \$stdins{$i}, \$stdouts{$i}, \$stderrs{$i},
		   timeout( 50, name => 'process timer' ),
		   $stall_timer = timeout( 55, name => 'stall_timer' ),
		   debug => 0;

#    $stdins{$i} .= "some input\n";
	pump $h{$i} until $stdouts{$i} =~ /alive/g;	#wait for child to spread

	$pids{$i} = $h{$i}->{KIDS}[0]{PID};

	warn $stderrs{$i} if $stderrs{$i};
	print $stdouts{$i};
}

sub finishPid {
	my $id = shift;
	print "Finishig ID:$id\n";
	#finish $h{$id};
	close $stdouts{$id};
}

sub getDefunctPids {
	my @result;
	foreach my $cp (values %pids) {
		my ($key) = grep{ $pids{$_} eq $cp } keys %pids;
		if ( getPidState($cp) eq 'defunct' ) {
			push @result, $pids{$key};	
		}
	}
	return @result;
}

sub spreadPids {
    #
	for (my $i=0;$i<10;$i++) {
		oneProc($i);
	}
#	foreach my $ch (values %h) {
#		print $ch->{KIDS}[0]{PID}."\n";
#	}
	#print Dumper($h{0});
	while(1) {
		my @arr = getDefunctPids(); 
		foreach my $cp (@arr) {
			# $key id proc number starting from 0 to 9 in this case
			my ($key) = grep{ $pids{$_} eq $cp } keys %pids;
			#print "PID:".$cp." KEY:"."$key\n";
			if (getPidState($cp) eq 'defunct') {
				print "PID:".$cp." KEY:$key has passed away. Will feed another work later\n";
				finishPid($key);
				oneProc($key);
				#here will create replacement process or what ?
			}
		}
		print "arr size:".scalar @arr."\n";
		last if scalar @arr > 9;
		usleep(100000);
	}

	print "REAP children\n";
    my @arr = getDefunctPids();
	foreach my $cp (@arr) {
		# $key id proc number starting from 0 to 9 in this case
		my ($key) = grep{ $pids{$_} eq $cp } keys %pids;
		finish $h{$key};
		print "finished $key\n";	
	}
}

my $sth = $dbh->prepare("SELECT * FROM tbl2 WHERE 1");
$sth->execute();

while(my $dat = $sth->fetchrow_hashref()) {
#        print "$dat->{'password'}\t$dat->{'pid'}\t$dat->{'status'}\t$dat->{'ts'}\n";
	chomp $dat->{'id'};
	my $pass = $dat->{'id'};
	push @passwords, $pass;
}

#foreach my $key (keys %passtested) {
#        print $key."\t".$passtested{$key}."\n";
#}

#exit();

spreadPids();

print "END"."\n";
