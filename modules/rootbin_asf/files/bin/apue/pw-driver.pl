#!/usr/bin/perl
#
# pty driver for ASF passwords:

# % make
# % cd ..
# % AVAILID=foo apue/pty -d apue/pw-driver.pl -- ./asf-do.pl --terminal ...
#
#  Keep in mind that sudo will allow you to login without a passwd
#  once you've logged in successfully within the last few minutes.
#  So if you just run the above with a quick "sudo true" you
#  can immediately run a normal asf-do.pl without using pty (or the
#  --terminal option) again.
#
#  The real killer application of this script is to run it in a screen
#  session:
#  % TERM=ansi apue/pty -d apue/pw-driver.pl screen
#
#  Then you no longer need to run asf-do.pl from pty, among other advantages.
#  SOME COMMON SENSE ADVICE: DO NOT RUN UNTRUSTED PROGRAMS, ANYWHERE, IF YOU
#  USE THIS WITH SCREEN!

use strict;
use warnings FATAL => 'all';
use feature qw/state/;

use POSIX qw/ttyname/;
use Term::ReadKey;
use IO::Select;
BEGIN { 
    eval { use IO::Socket::UNIX; };
    warn "Can't use IO::Socket::UNIX: $@" if $@;
}

open my $term, "+<", ttyname fileno STDERR
    or do { kill INT => getppid; exit 255 };
select STDERR;
$| = 1;

my $BUFSIZE = 4096;
my $NSM = ''; # include this in regexps to make them not match themselves, e.g., for 'pty -d $0 -- $SHELL -c "cat $0"'

if (`hostname` =~ /\Q.apache.org\E$/) {
    print $term "Don't run $0 from apache.org hosts!\n";
    kill INT => getppid;
    exit 255;
}

$SIG{TERM} = sub { ReadMode restore => $term; exit 255 };

my $SOCKET = "$ENV{HOME}/.pty-agent/socket";
my $user = $ENV{AVAILID} || $ENV{USER};
getpw("OPIE"); getpw("LDAP"); # initialize state
ReadMode raw => $term;

my $PREFIX_RE = qr/(?:[\w.-]+:\s+)?/;

my ($sawopie, $sawsvn) = ('', 0);

my %secret;
sub getpw {
    my ($type, $force) = @_;
    if (defined($IO::Socket::UNIX::VERSION) and -S $SOCKET) {
        state $socket = IO::Socket::UNIX->new(
          Domain => AF_UNIX,
          Type => SOCK_STREAM,
          Peer => $SOCKET,
        ) or warn "Can't open socket: $!";
        goto NO_SOCKET unless $socket;
        if ($force) {
            my $newvalue = prompt($type);
            $socket->print("SET $type $newvalue\n");
        }
        $socket->print("GET $type\n");
        my $reply = $socket->getline;
        chomp $reply;
        return $reply;
    }
    else {
      NO_SOCKET:
        $secret{$type} = prompt($type)    if $force or not $secret{$type};
        return $secret{$type};
    }
}

sub prompt {
    my $type = shift;
    # block these to avoid leaving $tty in a non-echo state
    local $SIG{INT} = local $SIG{QUIT} = local $SIG{TSTP} = "IGNORE";
    ReadMode noecho => $term;
    print $term "\n$type Password (^D aborts): ";
    no warnings 'uninitialized';
    chomp(my $passwd = ReadLine 0, $term);
    print $term "\n";
    ReadMode raw => $term;
    kill INT => getppid                          unless defined $passwd;
    ReadMode restore => $term                    unless defined $passwd;
    print $term "Operation aborted\n" and exit 1 unless defined $passwd;
    return $passwd;
}

my $s     = IO::Select->new(\*STDIN, $term);
my $ss    = IO::Select->new(\*STDIN);
my $clear = `clear`;
my $toggle= 0;

while (my @readable = $s->can_read) {
    for my $r (@readable) {
        if (!sysread $r, $_, $BUFSIZE) {
            ReadMode restore => $term;
            exit;
        }

        if ($r == \*STDIN) {

            print;

            if (index($_, $clear) >= 0) {
                while ($ss->can_read(0.1)) {
                    if (!sysread $r, $_, $BUFSIZE) {
                        ReadMode restore => $term;
                        exit;
                    }
                    print;
                }
                next;
            }
            elsif (/\btoggle ${NSM}pw-driver\s*(on|off)?/) {
                if ($1) {
                    $toggle = $1 eq "off" ? 1 : 0;
                }
                else {
                    $toggle = $toggle == 1 ? 0 : 1;
                }
            }
            elsif ($toggle) {

            }
            elsif (/(otp-md5 [0-9]+ [a-z]{2}[0-9]+)/) {
                my $opiepasswd = getpw("OPIE", $sawopie eq $1);
                my $cmd = $sawopie = $1;
                open my $c, "| $cmd 2>/dev/null"
                    or do {
                        kill INT => getppid;
                        print $term "Can't popen $cmd: $!\n";
                        ReadMode restore => $term;
                        exit 2;
                    };
                print $c "$opiepasswd\n";
                close $c or do {
                    print $term "$cmd failed: $?\n";
                };
                $opiepasswd = undef;
            }
            elsif (/^${PREFIX_RE}Username:${NSM} /m) {
                $sawsvn |= 1;
                syswrite STDOUT, "$user\n";
            }
            # The next two blocks automate the response to 'ssh -t minotaur.apache.org sudo passwd $AVAILID'.
            elsif (/^\QNew LDAP Password ${NSM}for $user (^D aborts):/) {
                chomp(my $newpw = `pwgen -sy 16`);
                warn("pwgen failed ($?): $!"), continue if $?;
                $secret{"LDAP"} = $newpw;
                syswrite STDOUT, "$newpw\n";
            }
            elsif (/^\QRepeat New LDAP Password ${NSM}for $user (^D aborts):/m) {
                syswrite STDOUT, "$secret{LDAP}\n";
            }
            # svn, modify_group_members.pl
            elsif (/^(${PREFIX_RE})Password ${NSM}for '(\w+)'(?: \(\^D aborts\))?:/m) {
                my $prompted = $2;
                if ($prompted eq $user) {
                    my $ldappasswd = getpw("LDAP", ($sawsvn & 3) == 3);
                    syswrite STDOUT, "$ldappasswd\n";
                    $ldappasswd = undef;
                    $sawsvn |= 2;
                }
                else {
                    syswrite STDOUT, "\n";
                    $sawsvn &=~2;
                }
                $sawsvn &=~1;
            }
            # curl
            elsif (/^(${PREFIX_RE})Enter host password ${NSM}for user '(\w+)':/m) {
                if ($2 eq $user) {
                    my $ldappasswd = getpw("LDAP", ($sawsvn & 3) == 3);
                    syswrite STDOUT, "$ldappasswd\n";
                    $ldappasswd = undef;
                    $sawsvn |= 2;
                }
                else {
		    syswrite STDOUT, "\n";
                    $sawsvn &=~2;
                }
                # TODO: how to detect "wrong password" errors?
            }
            elsif (m!\(yes/${NSM}no\)\?!g or /'yes' or ${NSM}'no'/) {
                syswrite STDOUT, "no\n";
            }
            elsif (/^$PREFIX_RE - Fingerprint:${NSM} 15:1D:8A:D1:E1:BA:C2:14:66:BC:28:36:BA:80:B5:FC:F8:72:F3:7C/im) {
                syswrite STDOUT, "p\n";
            }
            elsif (/^$PREFIX_RE\Q(R)eject, accept (t)emporarily ${NSM}or accept (p)ermanently?\E/m) {
                syswrite STDOUT, "r\n";
            }
            elsif (/^($PREFIX_RE)\Q$user/m) {
            }
            elsif (/^($PREFIX_RE)Authentication ${NSM}realm:/m) {
            }
            elsif (/^($PREFIX_RE)\S/m) {
            }
        }
        else {
            syswrite STDOUT, $_;
        }
    }
}

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

