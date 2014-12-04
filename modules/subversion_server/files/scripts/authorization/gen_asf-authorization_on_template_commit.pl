#!/usr/bin/perl
use warnings;
use strict;

my $realscript = $0;
$realscript =~ s#[^/]*$#./gen_asf-authorization.pl#;
exec $realscript, "template_commit", @ARGV
