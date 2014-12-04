package ASF::Util;

## core
use strict;
use warnings FATAL => 'all';
use Carp;
use LWP::UserAgent;
use HTML::Parser;

## mp2

## libapreq2

## dist

## cpan

## custom
use ASF::Const ();
use ASF::Cmd ();
use ASF::IO ();

## version
our $VERSION = q$Revision$;

## constants

## globals
our $Debug = 0;
our $Verbose = 0;
our $Execute = 1;

sub error   { print STDERR "ERROR: $_[0]"                              }
sub debug   { print STDERR "DEBUG: $_[0]"          if $Debug           }
sub verbose { print STDOUT "VERBOSE($_[0]): $_[1]" if $Verbose > $_[0] }

sub sed {
    my $regexes = shift;
    my $file    = shift;

    my $replacements = join "' -e '", @$regexes;

    execute("$ASF::Cmd::SED_I -e '$replacements' $file");
}

my $cwd = "";
sub execute {

    my ($dir, $cmd, $args);
    if (@_ == 1) {
        ($cmd) = @_;
    }
    elsif (@_ == 2) {
        if (ref $_[1] eq 'HASH') {
            ($cmd, $args) = @_;
        }
        else {
            ($dir, $cmd) = @_;
        }
    }
    elsif (@_ == 3) {
        ($dir, $cmd, $args) = @_;
    }
    else {
        # ; invalid call
    }

    if ($dir && $dir ne '') {
        $cwd = $dir;
        print STDOUT "cd $dir\n" unless $args->{silent} && $args->{slient} == 1;
    }

    print STDOUT "$cmd\n" unless $args->{silent} && $args->{silent} == 1;

    if ($Execute) {
        unless ((system($cmd) == 0)) {
            error("$?\n");
            return 0;
        }
        else {
            return 1;
        }
    }
    else {
        return 1;
    }
}

sub lprint {
    my ($total, $str) = @_;

    my $length = length $str;
    my $diff   = $total - $length;

    return $str . (' ' x $diff);
}

sub generate_systems {
    my $ua = LWP::UserAgent->new;
    my ($idt, $idr, $idd, @tables) = (0, 0, 0);
    my ($in_tr, $in_td, $in_th);

    my $start = sub {
        $in_tr = 1, return if $_[0] eq "tr";
        $in_td = 1, return if $_[0] eq "td";
        $in_th = 1, return if $_[0] eq "th";
    };

    my $end = sub {
        ++$idd
            if $in_th or $in_td;
        $idd = 0, ++$idr, $in_tr = 0, $in_th = 0, $in_td = 0, return
            if $_[0] eq "tr";
        $idr = 0, ++$idt, return
            if $_[0] eq "table";
    };

    my $text = sub {
        $tables[$idt][$idr][$idd] = lc shift if $in_td or $in_th;
    };

    my $parser = HTML::Parser->new(
        api_version => 3,
        start_h     => [ $start, "tagname" ],
        end_h       => [ $end,   "tagname" ],
        text_h      => [ $text,  "dtext"   ],
    );

    my $response = $ua->get("http://www.apache.org/dev/machines.html");
    die $response->status_line, "\n" unless $response->is_success;
    $parser->empty_element_tags(1);
    $parser->parse($response->decoded_content);
    $parser->eof;
    # last 4 tables are for hardware, deprecated hosts, ssh keys and ssl keys
    pop @tables;
    pop @tables;
    pop @tables;
    my $deprecated = pop @tables;
    pop @tables;
    push @tables, $deprecated;

    print "#!/usr/bin/perl\n{\n";
    for my $t (@tables) {
        my $i = 0;
        my %h = map {$_ => $i++} @{$t->[0]};
        $i = 0;
        while (++$i < @$t) {
            my $row = $t->[$i];
            print "  '$row->[$h{name}]' => { os => '$row->[$h{os}]', ";
            print "dc => '$row->[$h{location}]', ";
            chomp $row->[$h{class}];
            $row->[$h{class}] =~ tr/,/ /;
            print " classes => [qw($row->[$h{class}])] },\n";
        }
    }
    print "}\n";

    return ASF::Const::EXIT_SUCCESS;
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
