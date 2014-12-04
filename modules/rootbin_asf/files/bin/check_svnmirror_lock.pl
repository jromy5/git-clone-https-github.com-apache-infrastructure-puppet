#!/usr/bin/perl -T

use warnings;
use strict;

$ENV{PATH}="/usr/local/svn-install/current/bin:/bin:/usr/bin";

#
# check_svnmirror_lock.pl  - look for stale lock and if so, remove it and sync
#

use Getopt::Long;

my %master;
my %slave;
my $lockfile;

my $delay = 100;  # time delay used to detect whether or not the lock is stale
my $slack = 0;    # acceptable differential between master & slave revisions
my $user = "asf-sync-process";

$| = 1;

GetOptions( "master=s" => \$master{url},
	    "slave=s"  => \$slave{url},
            "lock=s"   => \$lockfile,
            "slack=i"  => \$slack );

die "Usage: $0 --master=<url> --slave=<url> --lock=<path>\n"
  unless $master{url} && $slave{url};

for (\%master, \%slave) {
    $_->{url} =~ m{^(https?://[\w/.-]+)$} or die "bad url: $_->{url}";
    $_->{url} = $1;
    $_->{revision} = get_revision_number($_->{url});
}

exit 0 if $slave{revision} + $slack >= $master{revision};

my $lock = check_lock($slave{url});
print <<EOT and print_logs(\%master, \%slave), exit sync($slave{url}) unless $lock;
Master and mirror out of sync!
No stale lock detected.
Master url: $master{url}
Master revision: $master{revision}
Slave url: $slave{url}
Slave revision: $slave{revision}
Syncing ...

EOT

sleep $delay;

exit 0 if $slave{revision} < get_revision_number($slave{url})
  or check_sync_running($slave{url})
  or $lock ne check_lock($slave{url});

chomp $lock;

clear_lock($slave{url})
  or die "Mirror $slave{url} is stale, but can't clear lock $lock: $?";

print <<EOT and print_logs(\%master, \%slave), exit sync($slave{url});
Master and mirror out of sync!
Stale lock $lock cleared.
Master url: $master{url}
Master revision: $master{revision}
Slave url: $slave{url}
Slave revision: $slave{revision}
Syncing ...

EOT

sub get_revision_number {
  my $url = shift;
  print "Contacting $url\n" if -t STDOUT;
  my $svn_info = `svn info --username=$user $url 2>&1`;
  $svn_info =~ /^Revision: (\d+)$/m
    or exit 1; # silently die because one of the hosts may be offline
  return $1;
}

sub check_lock {
  my $url = shift;
  return `svn propget --strict svn:sync-lock --revprop -r 0 --username=$user $url`;
}

sub clear_lock {
  my $url = shift;
  return `svn propdel svn:sync-lock --revprop -r 0 --username=$user $url`;
}

sub sync {
  my $url = shift;
  system "/root/bin/setlock.pl $lockfile svnsync sync --disable-locking --source-username=$user --sync-username=$user $url";
}

sub check_sync_running {
  my $url = shift;
  return `ps auxwww | grep "svnsync sync --source-username=$user --sync-username=$user $url" | grep -v grep`;
}

sub print_logs {
  my ($master, $slave) = @_;
  my $srev = $$slave{revision} + 1;
  system "svn log -r$$master{revision}:$srev --username=$user $$master{url}";
}
