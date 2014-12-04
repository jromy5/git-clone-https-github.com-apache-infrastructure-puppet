package RC::IO;

## core
use strict;
use warnings FATAL => 'all';
use Carp;

## mp2

## libapreq2

## dist
use File::Find ();

## cpan

## custom

## version
our $VERSION = q$Revision$;

## constants

## globals

sub dread {
    my $f = shift;
    my %args = @_;

    my @lines;
    if (open my $fh, '<', $f) {
      @lines = <$fh>; 
      close $fh or die "Can't close [$f] b/c [$!]";
    }
    else {
      die "Can't open [$f] b/c [$!]" unless $args{nofail};
    }

    return \@lines;
}

sub dappend {
    my ($f, $str) = @_;

    open my $fh, '>>', $f or die "Can't open [$f] b/c [$!]";
    print $fh $$str;
    close $fh or die "Can't close [$f] b/c [$!]";

    return;
}

sub scan {
  my ($dir, $regex) = @_;

  my @files = ();
  File::Find::find sub {
    return unless /$regex/;
    push @files, $File::Find::name;
  }, $dir;

  return \@files;
}

1;

__END__

=head1 SYNOPSIS

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
