package ASF::Manage::Util;

## core
use strict;
use warnings FATAL => 'all';
use Carp;

## mp2

## libapreq2

## dist
use Fcntl ();
use File::Basename ();
use File::Temp ();
use IO::Select ();
use IO::Socket::INET ();
use POSIX qw( :termios_h );
use Time::HiRes ();

## cpan

## custom
use ASF::Util ();
use ASF::Const ();

## version
our $VERSION = q$Revision$;

## constants
use constant PORT_SSH => 22;
use constant EXIT_INT => 99;

## globals
our $LOCK;

my $sudoersf = '/usr/local/etc/sudoers';
my $sudoerss = '/opt/sfw/etc/sudoers';
my $sudoersl = '/etc/sudoers';

my $_dirs = "/boot /etc /usr/local/etc /root/bin";
my %cmds = (
            update => "sudo svn up --force $_dirs",
            delta  => "sudo svn diff $_dirs",
            sync   => "for d in $_dirs; do cd \$d; sudo svn ci -m 'sync'; done",
            pkgs   => '. /etc/profile; sudo perl /root/bin/pp.pl --update',
            sudoersf => "sudoscp:../../../sudoers/sudoers:$sudoersf",
            sudoerss => "sudoscp:../../../sudoers/sudoers:$sudoerss",
            sudoersl => "sudoscp:../../../sudoers/sudoers:$sudoersl",
           );

sub w (@) { print STDERR join('', @_, "\n") }

# sort hostnames such that app10 goes after app9, etc.
sub csrt ($$) {
    my ($x, $y) = @_;

    my ($xw, $xn, $xe) = $x =~ /^(\D+)(\d+)(.*)/;
    my ($yw, $yn, $ye) = $y =~ /^(\D+)(\d+)(.*)/;
    return defined($xw) && defined($yw) && defined($xn) && defined($yn) ?
        ($xe cmp $ye) || ($xw cmp $yw) || ($xn <=> $yn) :
        ($x cmp $y);
}

my $sys_h;

sub systems {
    return $sys_h if $sys_h;

    my $d = File::Basename::dirname($0);
    $sys_h = do "$d/.systems";
    die $@ if $@;

    for my $v (values %$sys_h) {
        $v->{dc} =~ tr/!//d;
        local $_ = $v->{os};
        /^[89]\.\d-\w+/ and $v->{os} = "freebsd" and next;
        /\du\d/      and $v->{os} = "solaris" and next;
        /\blts\b/    and $v->{os} = "ubuntu"  and next;
        /freebsd/    and $v->{os} = "freebsd" and next;
        /windows/    and $v->{os} = "windows" and next;
        /ubuntu/     and $v->{os} = "ubuntu"  and next;
        /debian/     and $v->{os} = "debian"  and next;
        /fedora/     and $v->{os} = "fedora"  and next;
        /sunos/      and $v->{os} = "solaris" and next;
        /^10\.\d$/   and $v->{os} = "mac"     and next;
        /centos/     and $v->{os} = "centos"  and next;
    }

    return $sys_h;
}

sub classes {

    my $systems = systems();
    my %c = map { $_ => 1 } map { @{$_->{classes}} } values %$systems;

    return [keys %c];
}

sub dcs {

    my $s = systems();

    my %d = map { $s->{$_}->{dc} => 1 } keys %$s;
    return [keys %d];
}

sub oses {

    my $s = systems();

    my %o = map { $s->{$_}->{os} => 1 } keys %$s;
    return [keys %o];
}

sub host2classes {
    my $s = shift;

    my $systems = systems();
    my $host = $systems->{$s};

    return {map { $_ => 1 } @{$host->{classes}}};
}

my $domain = ".apache.org";
sub host2fqdn { "$_[0]$domain" }

my $mhl;
sub maxhostlen {
    return $mhl if $mhl;

    my $systems = systems();
    my $len = 0;
    for (keys %$systems) {
        $len = length if length > $len;
    }
    return $mhl = $len + length $domain;
}

sub can_connect {
    my ($timeout, @hosts) = @_;

    my @handles;

    # note: DNS lookups are done serially before the timeout
    foreach my $host (@hosts) {
        my $sock = IO::Socket::INET->new(
                                         PeerAddr => $host,
                                         PeerPort => PORT_SSH,
                                         Proto    => 'tcp',
                                         Blocking => 0,
                                        );
        push @handles, [ $host, $sock ] if defined $sock;
    }
    return unless @handles;

    my %ready;
    my $select = IO::Select->new(map { $_->[1] } @handles);
    my %fileno_to_host = map { ($_->[1]->fileno(), $_->[0]) } @handles;
    my $t0 = Time::HiRes::time();
    my $wait = $timeout || 1;
    while ($select->count() > 0 && $wait > 0) {
        $wait = $timeout - (Time::HiRes::time() - $t0);
        my ($read, $write, $except) = IO::Select::select($select, $select, $select, $wait > 0 ? $wait : 0);
        foreach my $h (@$read, @$write) {
            $select->remove($h);
            $ready{$fileno_to_host{$h->fileno()}} = 1 if $h->connected();
        }
    }

    return keys %ready;
}

sub pexec_core {
    my %args = @_;

    my $t0 = Time::HiRes::time();

    my $ocmd = $args{cmd};
    my $idx;
    my $termios = POSIX::Termios->new;
    $termios->getattr(fileno STDIN) unless $args{stdin};

    my %pids = map {
        my $cmd = $ocmd;
        $cmd =~ s/%h%/$_/g;

        doit(
             where      => $_,
             timeout    => $args{timeout},
             serial     => $args{serial},
             verbose    => $args{verbose},
             unbuffered => $args{unbuffered},
             commands   => [$cmd],
             idx        => ++$idx,
             terminal   => $args{terminal},
            )
    } @{$args{hosts}};

    my @failed;
    if ($args{serial}) {
        @failed = values %pids;
        %pids = ();
    }

    my $total = my $procs = keys %pids;
    if ($procs) {
        while ((my $pid = wait()) != -1) {
            $procs--, push @failed, $pids{$pid} if $?;
            delete $pids{$pid};
        }
    }
    $termios->setattr(fileno STDIN, &POSIX::TCSANOW) unless $args{stdin};

    if ($args{serial}) {
        $total = @{$args{hosts}};
        $procs = $total - @failed;
    }
    w sprintf(
        "$0: %d host%s completed (%d total) in %.1f sec.",
        $procs, $procs == 1 ? '' : 's', $total, Time::HiRes::time() - $t0
        );
    w "HOSTS FAILED: @failed" if @failed;
    return !@failed;
}

sub pexec {
    my %args = @_;

    my $exec = join ' ', map { exists $cmds{$_} ? $cmds{$_} : $_ } @{$args{args}};
    my $quiet = $args{quiet} ? "-q" : "";
    my $term = $args{terminal} ? "-t" : "";
    my $pty = $args{terminal} ? "apue/pty -ie -t $args{timeout} --" : "";
    my $stdin = $args{stdin} ? "<$args{stdin}" : "";

    my ($cmd, $cmd2);
    if ($exec =~ /^sudoscp:/) {
        my ($j, $from, $to) = split /:/, $exec;
        my $t = "/tmp/rwsdo.tmp";
        $cmd = "scp -Brp $quiet $from $args{user}\@%h%:$t";
        $cmd2 = qq{$pty ssh -A $term $quiet $args{ssh_opt} $args{user}\@%h% "sudo sh -c 'cat $t > $to'; rm -f $t"}
    }
    elsif ($exec =~ /^scp:/) {
        my ($j, $from, $to) = split /:/, $exec;
        $cmd = "scp -Brp $quiet $from $args{user}\@%h%:$to";
    }
    elsif ($exec =~ /^scpr:/) {
        my ($j, $to, $from) = split /:/, $exec;
        $cmd = "scp -Brp $quiet $args{user}\@%h%:$from /tmp/%h%";
    }
    elsif ($exec =~ /^rsync:/) {
        my ($j, $from, $to) = split /:/, $exec;
        $cmd = "rsync -az --delete $quiet $from $args{user}\@%h%:$to";
    }
    else {
        $cmd = "$pty ssh -A $term $quiet $stdin $args{ssh_opt} $args{user}\@%h% '$exec'";
    }

    my $rv = pexec_core(%args, cmd => $cmd);
    $rv = pexec_core(%args, cmd => $cmd2) if $exec =~ /^sudoscp:/ and $rv;

    return $rv;
}

sub reader {
    my ($fh, $unbuffered) = @_;
    if ($unbuffered) {
        my $s = IO::Select->new($fh);
        $_ = "";
        while (sysread $fh, $_, 4096, length) {
            last unless $s->can_read(0);
        }
        return length;
    }
    else {
        return defined($_ = <$fh>);
    }
}

sub doit {
    my %args = @_;

    my $pid = $args{serial} ? 0 : fork();
    local $_;

    if ($pid) {
        # parent
        return $pid, $args{where};
    }
    elsif ($pid == 0) {
        # child
        my @status;
        foreach my $cmd (@{$args{commands}}) {
            w "[$$] $args{where}: $cmd" if $args{verbose};

            my @out;
            open my $fh, "$cmd 2>&1 |"
                or die "can't popen $cmd: $!";

            while (reader($fh, $args{unbuffered})) {
                for (split /(?<=\n)/) {
                    s/\r?\n$//;
                    $_ .= "\r\n" if  $args{terminal};
                    $_ .= "\n"   if !$args{terminal};
                    if ($args{unbuffered}) {
                        my $string = ASF::Util::lprint(2 + maxhostlen, "$args{where}:") . $_;
                        my $n = 0;
                        do {
                            my $b = syswrite STDOUT, substr($string, $n);
                            die "syswrite failed: $!" unless $b;
                            $n += $b;
                        } while ($n < length $string);
                    }
                    else {
                        push @out, ASF::Util::lprint(2 + maxhostlen, "$args{where}:"), $_;
                    }
                }
            }
            if (!close $fh) {
                push @status, $? if $?;
            }
            if (@out) {
                flock($LOCK, &Fcntl::LOCK_EX) or ASF::Util::error("couldn't flock: $!\n");
                print @out;
                flock($LOCK, &Fcntl::LOCK_UN) or ASF::Util::error("couldn't un-flock: $!\n");
            }
        }

        return @status ? ($args{idx}, $args{where}) : () if $args{serial};
        exit @status ? ASF::Const::EXIT_FAILED : ASF::Const::EXIT_SUCCESS;
    }
    else {
        warn "fork() failed: $!\n";
        return;
    }
}

sub filter_hosts {
    my $hosts = shift;
    my %args = @_;

    my $systems = systems();

    my @h = @$hosts;
    @h = grep { my $c = ASF::Manage::Util::host2classes($_); $c->{$args{class}} } @h if $args{class} ne '';
    @h = grep { $systems->{$_}->{dc} =~ /$args{dc}/ } @h if $args{dc} ne '';
    @h = grep { $systems->{$_}->{os} =~ /$args{os}/ } @h if $args{os} ne '';
    @h = grep { my $x = $_; grep { $_ eq $x } @{$args{host}} } @h if $args{host} ne '';
    @h = grep { my $x = $_; !grep $x eq $_, @{$args{exclude}} } @h if $args{exclude};

    # gotta ask for zones
    @h = grep { my $c = join '%', keys %{ASF::Manage::Util::host2classes($_)}; $c !~ /zone/ && !/zone/ } @h
        unless $args{zones} or $args{host};
    # ditto for vm
    @h = grep { my $c = join '%', keys %{ASF::Manage::Util::host2classes($_)}; $c !~ /\bvm/ && !/\bvm/ } @h
        unless $args{vm} or $args{host};

    return @h;
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
