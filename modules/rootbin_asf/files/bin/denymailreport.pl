#!/usr/local/bin/perl -w
#
# Reports on spam caught by DENYMAIL patch to qmail
#

use strict;

my $logfile = "/var/log/denymaillog";
my $maillog = "/var/log/maillog.0.gz";

my @date = localtime(time-(60*60*24));
my $yr = 1900 + $date[5];
my $mo = 1 + $date[4];
   $mo = "0$mo" if (length($mo) == 1);
my $da = 1 + $date[3];
   $da = "0$da" if (length($da) == 1);
my $datestr = "$yr-$mo-$da";

my (%tempbaddns,
    %permbaddns,
    %badmailfrom,
    %gateway,
    %spam,
    %blackholed,
    %unknown);

# -- Accumulate info about denied mail

open (MLOG, "zgrep REJECT $maillog |") ||
    die("DENYMAILREPORT: can't parse $maillog ($!)!");
while (<MLOG>) {
    my @fields = split(/\s+/, $_, 8);
    my $type = $fields[6];
    my $report = $fields[7];

    if ($type eq "HARDDNS_MAIL_FROM") {
        $permbaddns{"$report"}++;
    }
    elsif ($type eq "SOFTDNS_MAIL_FROM") {
        $tempbaddns{"$report"}++;
    }
    elsif ($type eq "BLACKHOLED") {
        $blackholed{"$report"}++;
    }
    elsif ($type eq "BAD_MAIL_FROM") {
        $badmailfrom{"$report"}++;
    }
    elsif ($type eq "JUNK_THRESHOLD") {
        $spam{"$report"}++;
    }
    elsif ($type eq "GATEWAY") {
        $gateway{"$report"}++;
    }
    else {
        $unknown{"$_"}++;
    }
}
close(MLOG);

# -- Log denied mail info to separate logfile

my $entry;
open (MLOG, ">$logfile") ||
    die("DENYMAILREPORT: can't write to $logfile ($!)!");

#print MLOG "\nDeliveries which failed permanently due to ",
#           "bad DNS in their 'From' header:\n\n";
#foreach $entry (sort keys(%permbaddns)) {
#    print MLOG "$permbaddns{$entry}\t$entry";
#}

print MLOG "\n\nDeliveries which failed temporarily due to ",
           "DNS timeouts on the lookup:\n\n";
foreach $entry (sort keys(%tempbaddns)) {
    print MLOG "$tempbaddns{$entry}\t$entry";
}

print MLOG "\n\nDeliveries which failed due to being listed ",
           "in tcp.smtp:\n\n";
foreach $entry (sort keys(%blackholed)) {
    print MLOG "$blackholed{$entry}\t$entry";
}

print MLOG "\n\nDeliveries which failed because they were ",
           "listed in qmail's 'badmailfrom' file:\n\n";
foreach $entry (sort keys(%badmailfrom)) {
    print MLOG "$badmailfrom{$entry}\t$entry";
}

print MLOG "\n\nMail which exceeded the 'badheaders' spam ",
           "thresholds.\n\n";
foreach $entry (sort keys(%spam)) {
    print MLOG "$spam{$entry}\t$entry";
}

print MLOG "\n\nAttempted relays:\n\n";
foreach $entry (sort keys(%gateway)) {
    print MLOG "$gateway{$entry}\t$entry";
}

print MLOG "\n\nUnknown:\n\n";
foreach $entry (sort keys(%unknown)) {
    print MLOG "$unknown{$entry}\t$entry";
}

close(MLOG);

# -- Print out a summary

my $c;
print "DENYMAILREPORT [see $logfile for details]\n\n";

$c = keys(%permbaddns);
print "Deliveries which failed permanently due ",
      "to bad DNS in their 'From' header: $c\n";

$c = keys(%tempbaddns);
print "Deliveries which failed temporarily due to DNS ",
      "timeouts on the lookup: $c\n";

$c = keys(%blackholed);
print "Deliveries which failed due to being listed ",
      "in tcp.smtp: $c\n";

$c = keys(%badmailfrom);
print "Deliveries which failed because they were listed ",
      "in qmail's 'badmailfrom' file: $c\n";

$c = keys(%spam);
print "Mail which exceeded the 'badheaders' spam ",
      "thresholds: $c\n";

$c = keys(%gateway);
print "Attempted relays: $c\n";

$c = keys(%unknown);
print "Unknown: $c\n";

