#!/usr/bin/perl -T
#
use warnings FATAL => "all";
use strict;

$ENV{PATH}="/usr/bin";

use Getopt::Long;
GetOptions("alog=s" => \(my $alog),
           "slog=s" => \(my $slog));

die "Usage: $0 --alog=<access logfile> --slog=<svn logfile>"
    unless $alog and $slog;

open my $svn_log, "<", $slog or die "can't open svn log [$slog]: $!";

my $duration = 1000;
my $threshold = 5;
my $abuse_threshold_ban = 500000;
my $abuse_threshold_warn = 200000;
my $abuse_log_filename = "/var/log/svn-abuse.log";

my %h;
my @d;
my $total_ops;
while (<$svn_log>) {
    /(\d+) \S+$/ or next;
    $h{$_} = $1 if $1 > $duration;
    $d[log($1+1)]++;
    $total_ops++;
}

open my $access_log, "<", $alog or die "can't open access log [$alog]: $!";
my %hits;
my $total_hits = 0;
while (<$access_log>) {
    /^\S+ (\S+)/ or next;
    $hits{$1}++;
    $total_hits++;
}

my @sorted_ips;
@sorted_ips = sort {$hits{$b}<=>$hits{$a}} keys %hits;

print "top 10 ip addresses\ntotal hits = $total_hits\n\n";
printf "%16s %8d %6.4s %%  %s", $_, $hits{$_}, $hits{$_} * 100 / $total_hits, `dig +short -x $_ | /usr/bin/xargs` || "\n",
  for +@sorted_ips[0..9];

my $index;
my $ip;
my $count;
my $timestamp = localtime();
open my $abuse_log, ">>", $abuse_log_filename or die "can't open abuse log [$abuse_log_filename]";
$index = 0;
$ip = $sorted_ips[$index];
$count = $hits{$ip};
while ($count > 200000) {
  if ($count > 500000) {
    print $abuse_log "$timestamp $ip $count BAN\n";
  } else {
    print $abuse_log "$timestamp $ip $count WARN\n";
  }
  $index++;
  $ip = $sorted_ips[$index];
  $count = $hits{$ip};
}

print "\nlogarithmic distribution of duration of svn ops\ntotal ops = $total_ops\n\n";

print "   seconds        number   percent\n";
for (grep defined $d[$_], 0..$#d) {
    printf("%6d-%-6d %10d %6.4s %%\n", int(exp($_)-1), int(exp($_+1)-2),
                                    $d[$_], $d[$_] * 100 / $total_ops);
}

print "\n";

if (keys %h) {
    print "svn ops taking over $duration seconds to complete,\n";
    print "in chronological order.\n\n";
    my @intervals;

    for (sort keys %h) {

	# [27/Apr/2006:00:00:10 -0700] 82.70.225.147 - update 
	# '/spamassassin/trunk' 0 4b4:44506bfa:6

        m!^\[\d+/\w+/\d+:(\d+):(\d+):\d+ [+-]\d+\] (\S+) \S+ (\S+ \S+(?: \S+)*) (\d+) (\S+)$!
            or die "svn operation pattern match failed for $_";

        my ($hour, $min, $ip, $op, $et, $fid) = ($1, $2, $3, $4, $5, $6); 
	my $start = sprintf "%02d:%02d", $hour, $min;

	my $end_min = $min + int($et / 60);
	my $end_hour = $hour;
	++$end_hour, $end_min -= 60 while $end_min >= 60;
        my $end = sprintf "%02d:%02d", $end_hour, $end_min;

        my $access_line = `grep $fid $alog`
             or warn "can't find access record for $_" and next;

	# svn.apache.org 84.151.105.21 - - [28/Apr/2006:20:50:50 -0700]
        # "PROPFIND /repos/asf/!svn/bln/398077 HTTP/1.1" 207 262 "-" 
        # "JavaSVN 0.9.3 (http://tmate.org/svn/)" 5a35:4452e29a:2d 80

	$access_line =~ /"[^"]+" \d+ (\d+) .+ (\d+)$/
            or die "can't match access pattern: $access_line";

        my $bw = int ($1 / ($et * 1024));
        my $port = $2;

	print "[$start - $end] $ip $op ($bw KB/s) $port\n";
        tr/:/./ for $start, $end;
        push @intervals, [$start, $end];
    }
    print "\ntimeline with over $threshold concurrent expensive ops\n\n";
    compute_overlaps(@intervals);
}

sub compute_overlaps
{
    for my $hour (map {sprintf "%02d", $_} 0..23) {
	for my $min (map {sprintf "%02d", $_*5} 0..11) {
	    my $jobs = running("$hour.$min", @_);
	    print "$hour:$min " . ("x" x $jobs) . " $jobs\n"
		if $jobs > $threshold;
        }
    }
}

sub running
{
    my $time = shift;
    my $r = 0;
    for (@_) {
	++$r if $time >= $_->[0] and $time <= $_->[1];
    }
    return $r;
}
