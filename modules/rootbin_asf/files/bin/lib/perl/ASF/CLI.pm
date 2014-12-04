package ASF::CLI;

## core
use strict;
use warnings FATAL => 'all';
use Carp;

## mp2

## libapreq2

## dist
use Getopt::Long ();
use Pod::Usage ();

## cpan

## custom
use ASF::Const ();
use ASF::Util ();

## version
our $VERSION = q$Revision$;

## constants

## globals
our $Force = 0;
our $Help = 0;
our $Version = 0;

our $PROGNAME = $0;

sub run {
    my $class = shift;

    local $SIG{__WARN__} = \&Carp::cluck;
    local $SIG{__DIE__}  = \&Carp::confess;

    getopts() or return ASF::Const::EXIT_FAILED_INVALID_ARGS_OR_ENV;

    if ($Help) {
        Pod::Usage::pod2usage(-verbose => 1);
        return ASF::Const::EXIT_SUCCESS;
    }

    if ($Version) {
        print $PROGNAME . " - v" . $::VERSION . "\n\n";
        return ASF::Const::EXIT_SUCCESS;
    }

    unless (valid_args()) {
        Pod::Usage::pod2usage(-verbose => 1);
        return ASF::Const::EXIT_FAILED_INVALID_ARGS_OR_ENV;
    }

    return ::work();
}

sub getopts {

    {
      no strict 'refs';
      my $func = "main::skip_getopts";
      return 1 if defined *$func && &$func();
    }

    my $custom_opts = ::getopts();

    my $rv =
        Getopt::Long::GetOptions(
                                 "debug"      => \$ASF::Util::Debug,
                                 "no-execute" => sub { $ASF::Util::Execute = 0 },
                                 "verbose=i"  => \$ASF::Util::Verbose,
                                 "help"       => \$Help,
                                 "version"    => \$Version,
                                 "force"      => \$Force,

                                 %$custom_opts,
                                );

    Pod::Usage::pod2usage(-verbose => 1) unless $rv;

    return $rv ? 1 : 0;
}

sub valid_args {

    {
      no strict 'refs';
      my $func = "main::skip_validate_args";
      return 1 if defined *$func && &$func();
    }

    my $errors = 0;

    ## --no-execute implies --verbose=1 unless verbose is set higher already
    $ASF::Util::Verbose ||= 1 unless $ASF::Util::Execute;

    $errors += ::valid_args();

    return $errors > 0 ? 0 : 1;
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
