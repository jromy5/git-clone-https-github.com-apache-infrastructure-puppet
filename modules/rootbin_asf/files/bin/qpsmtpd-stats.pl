#! /usr/bin/perl -nl
#
use warnings FATAL => 'all';
use strict;

use constant BASE_DIR => "/opt/qpsmtpd";
use Getopt::Long;

# Usage: qpsmtpd-stats.pl [--write] /path/to/logs/qpsmtpd_error
#
# This script generates statistics for Apache::Qpsmtpd based on the error
# log output.  It's useful for a nightly cronjob, I suppose like this:
#
# 55 23 * * * /root/bin/qpsmtpd-stats.pl /var/log/www/qpsmtpd_error
#
# The --write option is used when recording per-ip stats to BASE_DIR.
# Don't use that unless you know what you're doing.
#

our $write;
BEGIN { GetOptions("write", \$write); }


our (%ip, %conn, $ccount, $transactions, %trans, %plugins);
our ($spf_forgery, $spf_error, $spf_probable,
     $deny_soft, $conn_error, $conn_timeouts);
our (%sorbs, %spamhaus, %unresolvable);

/ line / || /core_output_filter/ and ++$conn_error;
/connection timed out/ and ++$conn_timeouts;
/denysoft mail from (\S+)/
    and ++$deny_soft and ++$unresolvable{$1};

/^(\d+)/ or next;
my $pid = $1;

if (/Connection from \[([.\d]+)\]/) {
    delete $ip{$pid};
    $conn{$1}++;
    ++$ccount;
    next;
}
if (/(\S+) (\S+) plugin:/) {
    my $time = $1;
    my $plugin = $2;
    if ($plugin eq "mail_logger") {
      ++$transactions;
      /ip: \[(\S+)\]/ and $ip{$pid} = $1 and $trans{$1}++;
    }
    elsif (exists $ip{$pid}) {
      $plugins{$plugin}++;
      my $path = join "/", (BASE_DIR, split /[.]/, $ip{$pid});
      if ($write and -f $path) {
        open my $fh, ">>", $path;
        print $fh "$time $plugin";
      }
      if ($plugin eq "dnsbl") {
        /sorbs/ && ++$sorbs{$ip{$pid}}
            or /spamhaus/ && ++$spamhaus{$ip{$pid}};
      }
      elsif ($plugin eq "sender_permitted_from") {
        /SPF forgery/ && ++$spf_forgery
            or /SPF error/ && ++$spf_error
               or /SPF probable/ && ++$spf_probable;
      }
    }
}

sub blocked {
    my ($ip) = (@_,$_);
    $sorbs{$ip} or $spamhaus{$ip};
}

sub sum {
    my $n = 0;
    $n += $_ for @_;
    return $n;
}

END {
    no warnings "uninitialized";

    open my $maillog, "<", "/var/log/maillog" or die "Can't open maillog :$!";
    my ($queued, @scores, %rules);
    while (<$maillog>) {
        /Queued/ and ++$queued;
        if (/spamd: result: . (-?\d+) - ([A-Z0-9_,]+)?/) {
            if ($1 >= 0) {
                $scores[$1]++;
            }
            else {
                $scores[0]++;
            }
	    if ($2) {
	        $rules{$_}++ for split /,/, $2;
	    }
        }
    }
    $scores[21] += 0; # extend score array to at least 21
    $scores[$_] = 0 for grep !defined $scores[$_], 0..$#scores;

    print "General statistics...";
    print sprintf "%40s %10d", "Unique IPs", scalar keys %conn;
    print sprintf "%40s %10d", "Total connections", $ccount;
    print sprintf "%40s %10d", "Total transactions", $transactions;
    my $rejects = sum values %plugins;
    print sprintf "%40s %10d (%2d%%)", "Total plugin hits", $rejects,
        int(100 * $rejects / $transactions);
    print sprintf "%40s %10d", "SPF Errors", $spf_error;
    print sprintf "%40s %10d", "SPF Forgeries", $spf_forgery;
    print sprintf "%40s %10d", "SPF Probable Forgeries", $spf_probable;
    print sprintf "%40s %10d", "Soft Denials", $deny_soft;
    print sprintf "%40s %10d", "Connection Errors", $conn_error;
    print sprintf "%40s %10d", "Connection TimeOuts", $conn_timeouts;
    print sprintf "%40s %10.2f%%", "Overall Effectiveness", 100 * (1 - $queued/$transactions);

    print "Rejections by plugin...";
    print sprintf "%40s %10d (%2d%%)", $_, $plugins{$_},
        int(100 * $plugins{$_} / $transactions)
            for sort {$plugins{$b} <=> $plugins{$a}} keys %plugins;

    print "DNSBL Breakdown...";
    print sprintf "%40s %10d (%6d unique)", sorbs =>
        sum(values %sorbs), scalar keys %sorbs;
    print sprintf "%40s %10d (%6d unique)", spamhaus =>
        sum(values %spamhaus),  scalar keys %spamhaus;

    print "Spamassassin Breakdown...";
    print sprintf "%40s %10d", "Total checked" => sum(@scores);
    print sprintf "%40s %10d (%2d%%)", "Total passed" => $queued, 
      int ($queued * 100 / sum(@scores));
    print "Distribution of Spamassassin Scores...";
    print sprintf "%40s %10d", "-0", $scores[0];
    print sprintf "%40s %10d", $_, $scores[$_] for 1..9;
    print sprintf "%40s %10d", "10-20", sum(@scores[10..20]);
    print sprintf "%40s %10d", "21-", sum(@scores[21..$#scores]);
    print "Top 10 Spamassassin Rules...";
    print sprintf "%40s %10d", $_, $rules{$_} for +(sort{$rules{$b}<=>$rules{$a}} keys %rules)[0..9];
    print "Top 10 Unresolvable From-Addresses...";
    print sprintf "%40s %10d", $_, $unresolvable{$_} for +(sort{$unresolvable{$b}<=>$unresolvable{$a}} keys %unresolvable)[0..9];
    print "Top 1% transactions..." . (" " x 30) . "[*] - DNSBL listing";
    my @x = sort { $trans{$b} <=> $trans{$a} } keys %trans;
    print sprintf "%40s %10d%s", $_, $trans{$_}, blocked() ? "*" : ""
        for @x[0..@x/100];

}
