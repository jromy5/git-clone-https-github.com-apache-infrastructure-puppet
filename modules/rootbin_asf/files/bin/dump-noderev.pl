#!/usr/local/bin/perl

use warnings;
use strict;

$ENV{uc $_} ||= lc $_ for qw/svn svnlook svnadmin/;

sub open_pack_or_rev_file {
  my ($FS, $REVISION, $OFFSET) = @_;
  my $shard = int ($REVISION / 1000);
  my $remainder = $REVISION % 1000;

  if (-e "$FS/revs/$shard/$REVISION") {
    return  "$FS/revs/$shard/$REVISION", $OFFSET;
  } elsif (-e "$FS/revs/$REVISION") {
    return  "$FS/revs/$REVISION", $OFFSET;
  } elsif (-e "$FS/revs/$shard.pack") {
    my $lineno = $remainder+1;
    my $rev_offset = `cat $FS/revs/$shard.pack/manifest | sed -ne ${lineno}p`;
    return  "$FS/revs/$shard.pack/pack", $rev_offset + $OFFSET;
  }
}

sub main {
  my ($REPOS, $FSPATH, $REV) = @_;
  my $FS = "$REPOS/db";
  $REV =~ s/^r*// if defined $REV;

  die "USAGE: $0 /path/to/repos /path/in/repos [revnum]" if @_ != 2 and @_ != 3;

  die "Non-numeric revision number: $REV" if defined $REV and $REV !~ /^\d+$/;
  die "Unknown repos format: $REPOS/format" if `cat $REPOS/format` !~ /^[35]$/;
  die "Not FSFS: $FS/fs-type" if `cat $FS/fs-type` ne "fsfs\n";
  die "Unknown FSFS format: $FS/format" if `head -n1 $FS/format` !~ /^[12346]$/;

  my ($revision, $offset) = do {
    my $REV_ARG = defined($REV) ? "-r$REV" : "";
    # silence "broken pipe" error
    my $line = `$ENV{SVNLOOK} tree --full-paths --show-ids $REV_ARG $REPOS $FSPATH 2>&1 | head -n1`; 
    my ($noderev_id) = $line =~ /\S* <(.*)>$/;
    my ($node_id, $copy_id, $txn_id) = split /\./, $noderev_id;
    die if $txn_id =~ /\./;
    $txn_id =~ m#^r(\d+)/(\d+)$#;
  };

  my ($file, $file_offset) = open_pack_or_rev_file $FS, $revision, $offset;

  # Magic number 1024; assumes node-revs will be shorter than that.
  system("<$file xxd -p -s $file_offset -l 1024 | xxd -p -r | sed -e '/^\$/q'") == 0
    or die;
}

main @ARGV;


__END__

=head1 NAME

dump-noderev.pl - dump a node-revision from a FSFS-backed Subversion repository

=head1 SYNOPSIS

    % $0 /srv/repos/recipes /trunk
    % $0 /srv/repos/recipes /trunk r42

=head1 OPTIONS

None.

=head1 SEE ALSO

https://svn.apache.org/repos/asf/subversion/trunk/tools/dev/

=head1 COPYRIGHT

Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to You under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

