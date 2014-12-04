#!/usr/bin/perl -w

use lib "lib/perl";

use ASF ();
use ASF::CLI ();
use ASF::Manage::Util ();
use ASF::Util ();

## dist
use File::Temp ();
use Time::HiRes ();

our $Class      = "";
our $Dc         = "";
our $Exclude    = "";
our $Host       = "";
our $Os         = "";
our $Quiet      = 0;
our $Serial     = 0;
our $Timeout    = 5;
our $Unbuffered = 0;
our $Zones      = 0;
our $Systems    = 0;
our $Clone      = 0;
our $Terminal   = 0;
our $Vm         = 0;
our $List       = 0;

exit ASF::CLI->run();

sub work {
    return ASF::Util::generate_systems if $Systems;

    my $stdin;
    if ($Clone) {
        my $hup;
        my ($fh, $filename) = File::Temp::tempfile("asf-do-XXXX", SUFFIX=>".tmp", TMPDIR => 1);
        $SIG{HUP} = $SIG{INT} = sub { unlink $filename; exit 255; };
        print $fh $stdin while sysread STDIN, $stdin, 4096;
        close $fh;
        $stdin = $filename;
    }

    $Exclude = [split/,/, $Exclude] if $Exclude ne "";
    $Host    = [split/,/, $Host]    if $Host    ne "";

    my $arg_str = join ' ', @ARGV;

    my $user = $ENV{AVAILID} || $ENV{USER};
    my $ssh_opt = "-o NumberOfPasswordPrompts=0 -o ConnectTimeout=$Timeout";
    $ASF::Manage::Util::LOCK = File::Temp::tempfile() unless $Unbuffered;

    my $systems = ASF::Manage::Util::systems();
    my @hosts = keys %$systems;
    @hosts = ASF::Manage::Util::filter_hosts(
                                             \@hosts,
                                             class   => $Class,
                                             host    => $Host,
                                             os      => $Os,
                                             dc      => $Dc,
                                             exclude => $Exclude,
                                             zones   => $Zones,
                                             vm      => $Vm,
                                            );
    if ($List) {
        print "$_\n" for @hosts;
        return ASF::Const::EXIT_SUCCESS;
    }

    @hosts = ASF::Manage::Util::can_connect($Timeout,  map { ASF::Manage::Util::host2fqdn($_) } @hosts);

    if (@hosts == 0) {
        unlink $stdin if $Clone;
        die "no hosts are available";
    }

    my $t0 = Time::HiRes::time();
    if (exists $ASF::Manage::Util::tasks{$arg_str}) {
        my $pkg = $ASF::Manage::Util::tasks{$arg_str};
        my $f = $pkg;
        $f =~ s!::!/!g;
        eval {
            require "$f.pm";
            $pkg->run(\@hosts);
        };
        unlink $stdin if $Clone;
        ASF::Util::error($@) if $@;
    }
    else {
        my $rv = ASF::Manage::Util::pexec(
                                 args       => \@ARGV,
                                 hosts      => \@hosts,
                                 quiet      => $Quiet,
                                 timeout    => $Timeout,
                                 serial     => $Serial,
                                 verbose    => $ASF::Util::Verbose,
                                 unbuffered => $Unbuffered,
                                 ssh_opt    => $ssh_opt,
                                 user       => $user,
                                 stdin      => $stdin,
                                 terminal   => $Terminal,
        );
        unlink $stdin if $Clone;
        $rv or return ASF::Const::EXIT_FAILED;
    }

    return ASF::Const::EXIT_SUCCESS;
}

sub getopts {
    {
     "quiet"      => \$Quiet,
     "serial"     => \$Serial,
     "timeout=i"  => \$Timeout,
     "unbuffered" => \$Unbuffered,
     "systems"    => \$Systems,
     "class=s"    => \$Class,
     "dc=s"       => \$Dc,
     "exclude=s"  => \$Exclude,
     "host=s"     => \$Host,
     "os=s"       => \$Os,
     "zones"      => \$Zones,
     "clone-stdin"=> \$Clone,
     "terminal"   => \$Terminal,
     "vm"         => \$Vm,
     "list"       => \$List,
    };
}

sub valid_args { 0 }

__END__

=head1 NAME

asf-do.pl - utility for running a common command across multiple ASF hosts

=head1 SYNOPSIS

    % cd /path/to/infra-trunk/machines/root/bin
    % cd apue; make; cd ..

    # get w from all hosts including zones

    % ./asf-do.pl --zones --vm w

    # run svn update as root on several core dirs,
    # caching sudo creds for next cmd:

    % apue/pty -d apue/pw-driver.pl -- ./asf-do.pl --quiet --terminal \
      --unbuffered --serial --os freebsd update

    # update the ports collection on all freebsd hosts but zones and new-mino

    % USE_STDERR=1 apue/pty -d ./split-log.pl ./asf-do.pl --terminal --os freebsd --exclude new-minotaur pkgs

    # run a local perl script as root on all ubuntu hosts

    % ./asf-do.pl <script.pl --quiet --terminal --clone-stdin --os ubuntu sudo perl

    # flush sudo creds cache

    % ./asf-do.pl --zones --vm sudo -k

=head1 OPTIONS

=head2 --quiet

Causes ssh to run with the -q flag set to quiet its operation.

=head2 --serial

Causes the commands to be run consecutively instead of concurrently.
You want this flag if you are trying to obtain password creds using
C<apue/pty -d apue/pw-driver.pl -- ./asf-do.pl --terminal ...>.

=head2 --timeout C<i>

Sets the timeout for determining whether we can connect to a host or not.
Defaults to 5.

=head2 --unbuffered

By default asf-do.pl will store the output of each host and write it all
to stdout only upon completion of the command, after first taking a write
lock to ensure the results aren't interleaved with those of another host.

If you don't want this behavior (and you don't when you're trying to obtain
password creds using C<apue/pty -d apue/pw-driver.pl -- ./asf-do.pl --terminal ...>),
set this flag and writes will happen immediately.

=head2 --systems

Write the generated .systems config file to stdout after parsing
http://www.apache.org/dev/machines.html.  You'll want to replace
.systems with this output whenever that url's content changes.

=head2 --class C<s>

Choose a class of hosts, taken from .systems. This operates as a filter.

=head2 --dc C<s>

Choose a datacenter, taken from .systems.  This operates as a filter.

=head2 --exclude C<s>

A comma-separated list of hosts to exclude.

=head2 --host C<s>

A comma-separated list of hosts.

=head2 --os C<s>

The Operating System type, interpreted from .systems.  This operates as a filter
when combined with other options.

=head2 --zones

Zones are filtered out by default.  If you wish to keep them, add this option.

=head2 --vm

Virtual Machines are filtered out by default. To keep them add this option.

=head2 --clone-stdin

Makes a copy of stdin, to be passed along to each connection.  Not compatible
with C<apue/pty -d apue/pw-driver.pl -- ./asf-do.pl --terminal ...>.

Best to avoid using this option if you are running screen under
C<apue/pty -d apue/pw-driver.pl screen>.

=head2 --terminal

Pass -t to ssh to open a terminal on connect.

=head2 --list

List the hosts in a given (remaining) argument spec.

=head1 SEE ALSO

split-log.pl, which takes output from asf-do.pl and splits it into individual
logfiles.

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
