#!/usr/bin/env perl

# Decode mapping sizes in /proc/PID/maps.
# One could also use /proc/PID/smaps, but the
# data there is formatted multi-line.

use strict;

use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

my $VERSION = '1.0';

sub HELP_MESSAGE {
    printf "Usage: $0 [-p] [-s] PID\n";
    printf "       -p: ignore copy on write '---p' maps\n";
    printf "       -s: sort by map size descending\n";
    exit(1);
}

sub VERSION_MESSAGE {
    printf "$0 Version $VERSION\n";
}

my %opts;
getopts('hps', \%opts) or HELP_MESSAGE();

if ($opts{'h'}) {
    HELP_MESSAGE();
}

# Should we sort by map size?
my $sort = $opts{'s'};

# Should we ignore copy on write '---p' maps?
my $ignore = $opts{'p'};

# We need a PID
if ($#ARGV != 0) {
    HELP_MESSAGE();
}

my $pid = $ARGV[0];
# Data gets read from proc file system
my $procfile = "/proc/$pid/maps";

if (! -f $procfile) {
    printf "Process with PID $pid does not exist - Aborting!\n";
    exit(2);
}

if (! -r $procfile) {
    printf "Process maps file $procfile not readable - Aborting!\n";
    exit(3);
}

# Check whether the line is a copy on write '---p' map
sub ignore {
    my $map = shift;
    if ($map =~ /^[0-9a-fA-F]+-[0-9a-fA-F]+\s+---p\s+/) {
        return 1;
    }
    return 0;
}

# Calculate size as delta between the begin and end hex addresses
sub mapsize {
    my $map = shift;
    if ($map =~ /^([0-9a-fA-F]+)-([0-9a-fA-F]+)/) {
        return hex($2) - hex($1);
    }
    return 0;
}

# List of entries in read maps file
my @MAPS;

# Sort helper function using sizes and for
# equal size the addresses
sub bysize {
    if ($MAPS[$b]->{size} != $MAPS[$a]->{size}) {
        return $MAPS[$b]->{size} <=> $MAPS[$a]->{size};
    }
    return $MAPS[$a]->{data} cmp $MAPS[$b]->{data};
}

# Digest the maps file

# Total size of all map entries
my $total = 0;
my $i = 0;
open(IN, "<$procfile") or die "Could not open file $procfile for read: $!";
while(<IN>) {
    next if $ignore && ignore($_);
    $MAPS[$i] = ();
    $MAPS[$i]->{data} = $_;
    $MAPS[$i]->{size} = mapsize($_);
    $total += $MAPS[$i]->{size};
    $i++;
}
close(IN);

# Sort indexes if wanted
my @INDEXES = 0..$#MAPS;
if ($sort) {
    @INDEXES = sort bysize @INDEXES;
}

# Write output
printf("Total size: %d bytes\n", $total);
my $cum = 0;
for $i (@INDEXES) {
    $cum += $MAPS[$i]->{size};
    printf("%10d %6.2f%% %6.2f%% %s",
        $MAPS[$i]->{size},
        $total > 0 ? $MAPS[$i]->{size} / $total * 100 : -1,
        $total > 0 ? $cum / $total * 100 : -1,
        $MAPS[$i]->{data});
}
