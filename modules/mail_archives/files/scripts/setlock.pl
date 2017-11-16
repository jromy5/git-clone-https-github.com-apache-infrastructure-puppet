#!/usr/bin/perl

#  setlock.pl
#  takes no options
#  Usage:  setlock.pl /path/to/lockfile $command @args

=head1 NOTICE TO MAINTAINERS

Change C<puppet:modules/mail_archives/files/scripts/setlock.pl> and not this file directly.

=cut

use strict;
use warnings FATAL => 'all';
use Fcntl ":flock";

my ($lockfile, $command, @args) = @ARGV;

die "Usage: $0 /path/to/lockfile command args"
    unless $lockfile and $command;

open my $fh, "+>>", $lockfile or die "Can't open lockfile $lockfile: $!";
flock $fh, LOCK_EX or die "Can't get exclusive lock on $lockfile: $!";
exit system $command, @args;

