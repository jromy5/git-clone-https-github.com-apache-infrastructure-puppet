#! /usr/bin/perl

use strict ;
use warnings ;

my $GEOIP_UPDATE = '/usr/local/bin/geoipupdate' ;
my $GEOIP_DIR = '/usr/local/share/GeoIP' ;
my $GEOIP_DAT = "$GEOIP_DIR/GeoIP.dat" ;
my $LOGIN = 'apmirror' ;
my $GROUP = 'apmirror' ;
my $S_UID = 4 ;
my $S_GID = 5 ;
my $S_MOD = 2 ;

my $prog = substr $0, rindex ( $0, '/' ) + 1 ;
my $Usage = <<USAGE ;
Usage: $prog [-v] [-q] [-d] [-f] args
option v : be verbose
option q : be quiet
option d : show debug info
option f : action ; otherwise dry-run
USAGE
sub Usage { die "$_[0]$Usage" ; }
sub Error { die "$prog: $_[0]\n" ; }
sub Warn  { warn "$prog: $_[0]\n" ; }

# usage: &GetOptions(ARG,ARG,..) defines $opt_ID as 1 or user spec'ed value
# usage: &GetOptions(\%opt,ARG,ARG,..) defines $opt{ID} as 1 or user value
# ARG = 'ID' | 'ID=SPC' | 'ID:SPC' for no-arg, required-arg or optional-arg
# ID  = perl identifier
# SPC = i|f|s for integer, fixedpoint real or string argument

use Getopt::Long ;
Getopt::Long::config ( 'no_ignore_case' ) ;
my %opt = () ; Usage '' unless GetOptions
  ( \%opt, qw(v q d f) ) ;
Usage("Arg count\n") unless @ARGV == 0 ;

$opt{v} ||= $opt{d} ;

Error "must run as root (not as uid $<)" if $< != 0 and $opt{f} ;

my $TAG = $opt{f} ? 'TRYING' : 'WOULD' ;

my $uid = getpwnam $LOGIN ;
my $gid = getgrnam $GROUP ;

# sanity checks

Error "missing dest dir $GEOIP_DIR" unless -d $GEOIP_DIR ;
my ( $UID, $GID, $MOD ) = ( stat $GEOIP_DIR ) [ $S_UID, $S_GID, $S_MOD ] ;

Error "can't find uid for $LOGIN" unless defined $uid ;
Error "can't find gid for $GROUP" unless defined $gid ;

if ( $opt{d} )
  { printf "found uid $LOGIN -> %s ; gid $GROUP -> %s\n", $uid, $gid ;
    printf "found $GEOIP_DIR/ : uid=%s gid=%s mode=%o\n", $UID, $GID, $MOD ;
  }

# set gid, mode for $GEOIP_DIR

unless ( $gid == $GID )
  { printf "$TAG chown $UID $gid $GEOIP_DIR/\n" if $opt{v} ;
    if ( $opt{f} )
      { chown $UID, $gid, $GEOIP_DIR or
	  Error "can't chown $UID $gid $GEOIP_DIR ($!)" ;
      }
  }

unless ( $MOD & 020 )
  { my $mod = $MOD | 020 ;
    printf "$TAG chmod %o $GEOIP_DIR/\n", $mod if $opt{v} ;
    if ( $opt{f} )
      { chmod $mod, $GEOIP_DIR or
	  Error sprintf "can't chmod %o %s ($!)", $mod, $GEOIP_DIR ;
      }
  }

# set uid, mode for $GEOIP_DAT

( $UID, $GID, $MOD ) = ( stat $GEOIP_DAT ) [ $S_UID, $S_GID, $S_MOD ] ;

if ( -f $GEOIP_DAT )
  { printf "found $GEOIP_DAT : uid=%s gid=%s mode=%o\n", $UID, $GID, $MOD
      if $opt{d} ;
    if ( $uid != $UID )
      { printf "$TAG chown $uid $gid $GEOIP_DAT\n" if $opt{v} ;
        if ( $opt{f} )
          { chown $uid, $gid, $GEOIP_DAT or
	      Error "can't chown $uid $gid $GEOIP_DAT ($!)" ;
	  }
      }
  }

# run $GEOIP_UPDATE as $LOGIN

my @CMD = ( '/usr/bin/su', $LOGIN, '-c', $GEOIP_UPDATE ) ;
my $CMD = sprintf "[%s]", join ' ', @CMD ;
printf "$TAG $CMD\n" if $opt{v} ;
if ( $opt{f} )
  { system ( @CMD ) == 0 or Error "failed $CMD ($?)" ; }

print "THIS IS A DRY-RUN\n" unless $opt{q} or $opt{f} ;
