#! /usr/bin/perl -w


# Script written by Henk Penning

use strict ;
use warnings ;

my $PID_FILE = '/var/run/rsyncd.pid' ;
my $LLL = '/var/log/rsync/rsync' ;

my $prog = substr($0,rindex($0,'/')+1) ;
my $Usage = <<USAGE ;
Usage: $prog [-v] [-q] [-d] [-l] args
option l : search $LLL.*.bz2
option v : be verbose
option q : be quiet
option d : show debug info
USAGE
sub Usage { die "$_[0]$Usage" ; }
sub Error { die "$prog: $_[0]\n" ; }
sub Warn  { warn "$prog: $_[0]\n" ; }

# usage: &GetOptions(ARG,ARG,..) defines $opt_ID as 1 or user spec'ed value
# usage: &GetOptions(\%opt,ARG,ARG,..) defines $opt{ID} as 1 or user value
# ARG = 'ID' | 'ID=SPC' | 'ID:SPC' for no-arg, required-arg or optional-arg
# ID  = perl identifier
# SPC = i|f|s for integer, fixedpoint real or string argument

use Getopt::Long ; Getopt::Long::config('no_ignore_case') ;
my %opt = () ; Usage('') unless GetOptions(\%opt,'v','q','d','l') ;
Usage("Arg count\n") unless @ARGV >= 0 ;

$opt{l} = 1 ;

my $PS  = '/bin/ps -ax' ;
my %PID ;
my %tab ;
my $dpid = 0 ;

if ( open PID, $PID_FILE )
  { $dpid = <PID> ; chop $dpid ; close PID ; }

my @LOG = ( $LLL ) ;

if ( $opt{l} )
  { unshift @LOG, map { "/bin/bzcat $_|" ; } reverse sort <$LLL.*.bz2> ; }

# printf "[%s]", join ',', @LOG ; exit ;

open PS, "$PS|" or Error "can't popen $PS ($!)" ;

while ( <PS> )
  { next unless /rsync.*--daemon/ ;
#   my ( $user, $pid ) = ( split ' ' ) [ 0, 1 ] ;
#   $PID { $pid } ++ if $user eq 'nobody' ;
    my $pid = ( split ' ' ) [ 0 ] ;
    $PID { $pid } ++ ;
  }

# 2004/02/19 23:53:33 [99275] rsync on apache-dist from ftp.kaist.ac.kr (143.248.234.110)

for my $LOG ( @LOG )
  { printf "processing %s ...\n",  $LOG ;
    open LOG, $LOG or Error "can't open $LOG ($!)" ;

    while ( <LOG> )
      { my @rec = split ' ' ;
        next if @rec < 4 ;
        if ( $rec [ 3 ] eq 'rsync' and $rec [ 4 ] eq 'on' )
          { my $pid = $rec [ 2 ] ;
            $pid = substr $pid, 1, -1 ;
# printf "%s %s\n", $pid, $rec [ 7 ] ;
            if ( $PID { $pid } )
              { $tab { $pid } = join ' ', @rec [ 0, 1, 7, 8 ] ; }
          }
      }
    close LOG ;
  }

sub by_date
  { my $x = $tab { $a } || 0 ;
    my $y = $tab { $b } || 0 ;
    $x cmp $y ;
  }

my %ips = () ;
my $seen = 0 ;

for my $pid ( sort by_date keys %PID )
  { my $site = $tab { $pid }
      || ( $pid == $dpid ? "THE DAEMON ($PID_FILE)" : 'not found' ) ;
    printf "%5s %s\n", $pid, $site ;
    my $ip ;
    if ( $site =~ /\((.*)\)/ )
      { my $ip = $1 ;
#       printf "%s\n", $ip ;
        push @{ $ips { $ip } }, $pid ;
      }
    $seen ++ ;
  }

my @kill = () ;

for my $ip ( sort keys %ips )
  { my $cnt = scalar @{ $ips { $ip } } ;
    if ( $cnt > 1 )
      { printf "busy %d times : %-15s pids : %s\n"
          , $cnt, $ip, join ' ', @{ $ips { $ip } } ;
        push @kill, @{ $ips { $ip } } ;
        pop @kill ;
      }
  }
printf "busy : %d\n", $seen ;
printf "%d doubles\n", scalar grep { @$_ > 1 } values %ips ;
printf "Kill:\n" ;
if (@kill)
  {
    printf "%s\n", join ' ', @kill if @kill ;
  } else {
    printf "\n" ;
  }
  
