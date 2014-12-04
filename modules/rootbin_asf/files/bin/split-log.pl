#!/usr/bin/perl
#
# Filter used to split the output of asf-do.pl
# into individual logfiles.
#

use lib 'lib/perl';
use strict;
use warnings FATAL => 'all';
use File::Path 'rmtree';
use ASF::Manage::Util;
use Getopt::Std;

getopts a => \ my %opts;

my $prefix_len = 2 + ASF::Manage::Util::maxhostlen;

rmtree "logs" unless $opts{a} or $ENV{APPEND};
mkdir "logs";

my %fh;

while (<>) {
    my ($prefix, $content) = unpack "a$prefix_len a*", $_;
    if ($prefix =~ /^([\w.-]+): +$/) {
        my $host = $1;
        my $fh = $fh{$host} ||= do {
            open my $fh, ">>", "logs/$host"
                or die "Can't open $host logs: $!\n";
            $fh;
        };
        print $fh $content;
    }
}
