#!/usr/bin/perl

use strict;
use warnings;

$ENV{PATH} = "/usr/bin:/bin:/usr/local/bin";

sub get_remote_concurrency {
    my $cur = `pgrep qmail-remote | wc -l`;
    $cur=~ s/\s+//g;
    return $cur;
}

my $max = `cat /var/qmail/control/concurrencyremote`;
chomp $max;

my $cur = get_remote_concurrency() or exit 1;
exit 0 if $cur + 10 < $max;

sleep 60;

my $cur2 = get_remote_concurrency() or exit 1;
exit 0 if $cur2 + 10 < $max;

system 'date +"%a, %Y-%m-%d %H:%M:%S %Z"';

print <<EOT;

Qmail remote concurrency is too close to $max!
It is $cur2, and was $cur a sleep(60) ago.
qmail-remote is wedged with a deadlock on tcpto
so bring down qmail-send and start over.

I'll bring qmail-send down for you now.

# svc -t /var/service/qmail-send
EOT

exec("svc", "-t", "/var/service/qmail-send");
