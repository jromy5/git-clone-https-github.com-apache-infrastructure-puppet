#!/usr/bin/env perl

# Script to retrieve httpd server-status
# and parse the html page.
# Output is tab separated.
# This version works with httpd 2.4(.3).

use strict;

use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

# We use plain socket communication
# to not rely on installed LWP or curl.
use IO::Socket::INET;

my $VERSION = '1.0';

# Default communication parameters
# All can be overwritten on the commandline,
# see the usage.
my $DEFAULT_SERVER = 'localhost';
my $DEFAULT_PORT = 80;
my $DEFAULT_URI = '/server-status';
my $DEFAULT_TIMEOUT = 10;
my $DEFAULT_AGENT = "HTTP ServerStatus Poller $VERSION";
# Only used with -r and -d
my $DEFAULT_INTERVAL = 10;

# The list of parameters we parse out of
# the server-status html page.
my @HTTP_STATS = (
    'C_GENERATION',
    'M_GENERATION',
    'UPTIME',
    'ACCESSES',
    'TRAFFIC',
    'CPU_USR',
    'CPU_SYS',
    'CPU_USR_CHILD',
    'CPU_SYS_CHILD',
    'CPU_PCT',
    'REQUEST_RATE',
    'TRAFFIC_RATE',
    'AVG_SIZE',
    'BUSY_COUNT',
    'IDLE_COUNT',
    'ACCEPTING_WORKER_COUNT',
    'NONACCEPTING_WORKER_COUNT',
    'TOTAL_CONNS',
    'BUSY_THREADS',
    'IDLE_THREADS',
    'ASYNC_WRITE_CONNS',
    'ASYNC_KA_CONNS',
    'ASYNC_CLOSE_CONNS',
    'VERSION',
    'RESTART');

# These ones represent counters which
# can optionally be presented as deltas
# or rates per second.
my $HTTP_COUNTERS = {
    'ACCESSES' => 1,
    'TRAFFIC' => 1,
    'CPU_USR' => 1,
    'CPU_SYS' => 1,
    'CPU_USR_CHILD' => 1,
    'CPU_SYS_CHILD' => 1,
};

# Used to scale all sizes to KB
my $UNITS = {'KB' => 1, 'kB' => 1, 'MB' => 1024, 'GB' => 1024*1024, 'TB' => 1024*1024*1024};

sub HELP_MESSAGE {
    printf "Usage: $0 [-d|-r] [-s address] [-p port] {-u uri] [-t timeout] [-h host] [-a agent] [interval [count]]\n";
    printf "       -d:         print deltas for counters\n";
    printf "       -r:         print change rates (deltas divided by delta time) for counters\n";
    printf "       -s address: use address to connect to the web server\n";
    printf "                   Default: $DEFAULT_SERVER\n";
    printf "       -p port:    use port to connect to the web server\n";
    printf "                   Default: $DEFAULT_PORT\n";
    printf "       -u uri:     use uri to retrieve the web server status\n";
    printf "                   Default: $DEFAULT_URI\n";
    printf "       -t timeout: set socket timeout\n";
    printf "                   Default: $DEFAULT_TIMEOUT\n";
    printf "       -h host:    name used in Host header\n";
    printf "                   Default: address\n";
    printf "       -a agent:   user agent string send to server\n";
    printf "                   Default: $DEFAULT_AGENT\n";
    printf "       interval:   Sampling interval in seconds (only one sample if missing)\n";
    printf "       count:      Sample count (unlimited if missing)\n";
    exit(1);
}

sub VERSION_MESSAGE {
    printf "$0 Version $VERSION\n";
}

sub log_error {
    my $msg = shift;
    my $ts = scalar localtime;
    print STDERR "ERROR: $ts $msg\n";
}

sub check_number {
    my $number = shift;
    my $name = shift;
    if ($number !~ /^\d+$/) {
        log_error("Parameter '$name' must be a number, value '$number' is invalid - aborting");
        exit(10);
    }
}

sub check_uri {
    my $uri = shift;
    my $name = shift;
    if ($uri !~ /^\//) {
        log_error("Parameter '$name' must be a uri beginning with a slash '/', value '$uri' is invalid - aborting");
        exit(10);
    }
}

# Scale size in KB
sub size_in_kb {
    my $size = shift;
    my $unit = shift;
    if (exists($UNITS->{$unit})) {
        return $size * $UNITS->{$unit};
     } else {
        log_error("Unknown size unit '$unit'");
    }
    return -1;
}

my %opts;
getopts('drs:p:u:t:h:a:', \%opts) or HELP_MESSAGE();

# Our config set. Start with defaults.
my $config = {
    server => $DEFAULT_SERVER,
    port => $DEFAULT_PORT,
    uri => $DEFAULT_URI,
    timeout => $DEFAULT_TIMEOUT,
    host => $DEFAULT_SERVER,
    agent => $DEFAULT_AGENT,
};

# Overwrite commandline set config
if ($opts{'s'}) {
    $config->{server} = $opts{'s'};
    $config->{host} = $opts{'s'};
}
if ($opts{'p'}) {
    $config->{port} = $opts{'p'};
    check_number($config->{port}, 'port');
}
if ($opts{'u'}) {
    $config->{uri} = $opts{'u'};
    check_uri($config->{uri}, 'uri');
}
if ($opts{'t'}) {
    $config->{timeout} = $opts{'t'};
    check_number($config->{timeout}, 'timeout');
}
if ($opts{'h'}) {
    $config->{host} = $opts{'h'};
}
if ($opts{'a'}) {
    $config->{agent} = $opts{'a'};
}

# Check for delta or rate mode
my $delta = $opts{'d'};
my $rate = $opts{'r'};

# Only one of them allowed
if ($delta && $rate) {
    HELP_MESSAGE();
}

# Get optional interval from commandline
my $interval = 0;
if ($#ARGV >= 0) {
    $interval = $ARGV[0];
    check_number($interval, 'interval');
    shift;
}

# Get optional count from commandline
my $count = 0;
if ($#ARGV >= 0) {
    $count = $ARGV[0];
    check_number($count, 'count');
    shift;
}

# Connect to web server, send server-status
# request, read status line and return
# the socket for consuming the rest.
sub retrieve {

    my $config = shift;
    my $socket;
    $socket = IO::Socket::INET->new(
        PeerAddr => "$config->{server}:$config->{port}",
        Timeout => $config->{timeout});
    if (!$socket->connected()) {
        log_error("Could not connect socket to host $config->{server} port $config->{port}");
    }
    # Basic HTTP
    $socket->print("GET $config->{uri} HTTP/1.0\n");
    $socket->print("Host: $config->{host}\n");
    $socket->print("User-Agent: $config->{agent}\n");
    $socket->print("\n");
    my $status = $socket->getline();
    $status =~ s/\r\n$//;
    if ($status =~ /^HTTP\/\d\.\d\s+(\d+)(\s+(.*))?$/) {
        if ($1 ne '200') {
            log_error("HTTP error '$1': $3");
            $socket->close();
        }
    } else {
        log_error("Wrong status line: '$status'");
        $socket->close();
    }
    return $socket;
}

sub server_status {

    my $config = shift;
    my $data = shift;
    # Connect to web server and get result
    my $socket = retrieve($config);
    my $key;

    # Remember time stamp
    $data->{'secs'} = time();
    $data->{'ts'} = scalar localtime($data->{'secs'});

    # Parse server-status output

    #<dl><dt>Server Version: Apache/2.4.3 (Unix) OpenSSL/1.0.0g</dt>
    #<dt>Restart Time: Tuesday, 04-Dec-2012 20:08:08 UTC</dt>
    #<dt>Parent Server Config. Generation: 1</dt>
    #<dt>Parent Server MPM Generation: 0</dt>
    #<dt>Server uptime:  2 hours 58 minutes 2 seconds</dt>
    #<dt>Total accesses: 1352055 - Total Traffic: 129.5 GB</dt>
    #<dt>CPU Usage: u1399.36 s1507.3 cu0 cs0 - 27.2% CPU load</dt>
    #<dt>127 requests/sec - 12.4 MB/second - 100.5 kB/request</dt>
    #<dt>30 requests currently being processed, 226 idle workers</dt>
    #<tr><th>total</th><th>accepting</th><th>busy</th><th>idle</th><th>writing</th><th>keep-alive</th><th>closing</th></tr>
    #<tr><td>46553</td><td>89</td><td>yes</td><td>9</td><td>119</td><td>10</td><td>38</td><td>32</td></tr>
    #<tr><td>46554</td><td>302</td><td>yes</td><td>21</td><td>107</td><td>39</td><td>123</td><td>118</td></tr>
    #<tr><td>Sum</td><td>391</td><td>&nbsp;</td><td>30</td><td>226</td><td>49</td><td>161</td><td>150</td></tr>

    while (<$socket>) {
        $data->{'found'} = 1;
        if ($_ =~ /^<dl><dt>Server Version: Apache\/([^\s]+)/) {
            $data->{'VERSION'} = $1;
        } elsif ($_ =~ /^<dt>Restart Time: [^\s]+ ([^<]+)</) {
            $data->{'RESTART'} = $1;
        } elsif ($_ =~ /^<dt>Parent Server Config. Generation: (\d+)/) {
            $data->{'C_GENERATION'} = $1;
        } elsif ($_ =~ /^<dt>Parent Server MPM Generation: (\d+)/) {
            $data->{'M_GENERATION'} = $1;
        } elsif ($_ =~ /^<dt>Server uptime:(\s+(\d+) days?)?(\s+(\d+) hours?)?(\s+(\d+) minutes?)?(\s+(\d+) seconds?)?/) {
            $data->{'UPTIME'} = $2 * 86400 + $4 * 3600 + $6 * 60 + $8;
        } elsif ($_ =~ /^<dt>Total accesses: (\d+) - Total Traffic: ([\d\.]+) ([^<]+)</) {
            $data->{'ACCESSES'} = $1;
            $data->{'TRAFFIC'} = size_in_kb($2, $3);
        } elsif ($_ =~ /^<dt>CPU Usage: u([\d\.]+) s([\d\.]+) cu([\d\.]+) cs([\d\.]+) - ([\d\.]+)% CPU load/) {
            $data->{'CPU_USR'} = $1;
            $data->{'CPU_SYS'} = $2;
            $data->{'CPU_USR_CHILD'} = $3;
            $data->{'CPU_SYS_CHILD'} = $4;
            $data->{'CPU_PCT'} = $5;
        } elsif ($_ =~ /^<dt>(\d+) requests\/sec - ([\d\.]+) ([^\/]+)\/second - ([\d\.]+) ([^\/]+)\/request/) {
            $data->{'REQUEST_RATE'} = $1;
            $data->{'TRAFFIC_RATE'} = size_in_kb($2, $3);
            $data->{'AVG_SIZE'} = size_in_kb($4, $5);
        } elsif ($_ =~ /^<dt>(\d+) requests currently being processed, (\d+) idle workers/) {
            $data->{'BUSY_COUNT'} = $1;
            $data->{'IDLE_COUNT'} = $2;
        } elsif ($_ =~ /^<tr><td>\d+<\/td><td>\d+<\/td><td>(yes|no)/) {
            if ($1 eq 'yes') {
                $data->{'ACCEPTING_WORKER_COUNT'}++;
            } else {
                $data->{'NONACCEPTING_WORKER_COUNT'}++;
            }
        } elsif ($_ =~ /^<tr><td>Sum<\/td><td>(\d+)<\/td><td>\&nbsp;<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)<\/td><td>(\d+)</) {
            $data->{'TOTAL_CONNS'} = $1;
            $data->{'BUSY_THREADS'} = $2;
            $data->{'IDLE_THREADS'} = $3;
            $data->{'ASYNC_WRITE_CONNS'} = $4;
            $data->{'ASYNC_KA_CONNS'} = $5;
            $data->{'ASYNC_CLOSE_CONNS'} = $6;
        }
    }

    $socket->close();

}

# Output statistics
sub print_http_stats {
    my $data = shift;
    my $previous = shift;
    my $delta = shift;
    my $rate = shift;
    my %save;
    if (!$data->{'found'}) {
        return;
    }
    if ($delta) {
        for my $key (keys %{$HTTP_COUNTERS}) {
            $save{$key} = $data->{$key};
            $data->{$key} = $data->{$key} - $previous->{$key};
            if ($data->{$key} != int($data->{$key})) {
                $data->{$key} = sprintf("%.3f", $data->{$key});
            }
        }
    } elsif ($rate) {
        my $quot = $data->{secs} - $previous->{secs};
        for my $key (keys %{$HTTP_COUNTERS}) {
            $save{$key} = $data->{$key};
            if ($quot > 0) {
                $data->{$key} = sprintf("%.3f", ($data->{$key} - $previous->{$key}) / $quot);
            } else {
                $data->{$key} = '-';
            }
        }
    }
    printf $data->{'ts'};
    for (my $i = 0; $i <= $#HTTP_STATS; $i++) {
        printf "\t%s", $data->{$HTTP_STATS[$i]};
    }
    printf "\n";
    if ($delta || $rate) {
        for my $key (keys %{$HTTP_COUNTERS}) {
            $data->{$key} = $save{$key};
        }
    }
}

# XXX We could also print a repeated header every
# N samples
my $HEADER = '#Time                       ' . "\t" . join("\t", @HTTP_STATS) . "\n";
print $HEADER;

my $data = {};
my $previous_data;

server_status($config, $data);
if (!$delta && !$rate) {
    print_http_stats($data, $previous_data, 0, 0);
    $count--;
# If delta or rate handling are active
# we need to ensure at least one other
# iteration to be able to calculate deltas or rates
} elsif (!$interval) {
    $interval = $DEFAULT_INTERVAL;
    $count = 1;
} elsif (!$count) {
    $count = 1;
}

if ($interval > 0) {
    while($count <0 || $count > 0) {
        sleep($interval);
        $previous_data = $data;
        $data = {};
        server_status($config, $data);
        print_http_stats($data, $previous_data, $delta, $rate);
        $count--;
    }
}
