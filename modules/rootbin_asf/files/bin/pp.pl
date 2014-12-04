#!/usr/local/bin/perl -w

=head1 NAME

pp.pl - a tinderbox frontend

=head1 SYNOPSIS

    TODO

=head1 OPTIONS

  On the tinderbox:

    --class CLASS     act only on CLASS (from pp.conf) or ,-separated list
    --all             act on all classes

    --add             add everything for CLASSES
    --build           build everything for CLASSES
    --delete          pkg_delete -af
    --rescan          update ports metadata

  On the clients:

    --jail            allow --update without $PACKAGESITE. (tb jail != jail)
    --update          delete all packages, then install new ones

  Common options:

    --verbose         print commands executed
    --version         print $Revision: 893262 $
    --help            print this message

=cut

### core
use strict;
use warnings FATAL => 'all';
use Carp;

### CPAN
use Data::Dumper ();
use Getopt::Long ();
use Pod::Usage ();

### constants
use constant EXIT_SUCCESS   => 0;
use constant EXIT_FAILED_INVALID_ARGS_OR_ENV => 1;

### other constants
use constant PROGNAME => $0;

### signal handlers
local $SIG{__DIE__}  = \&Carp::confess;
local $SIG{__WARN__} = \&Carp::cluck;

### version
our $VERSION = do { my @r = (q$Revision: 893262 $ =~ /\d+/g); sprintf "%d." . "%02d" x $#r, @r };

### globals
# cmdline options (standard) with defaults
my $Help      = 0;
my $Version   = 0;
my $Debug     = 0;
my $Verbose   = 0;
my $NoExec    = 0;

# cmdline options (custom) with defaults
my $Class   = "";

my $Add     = 0;
my $Build   = 0;
my $Clean   = 0;
my $Delete  = 0;
my $Jail    = 0;
my $Rescan  = 0;
my $Update  = 0;
my $Parallel= 0; #badly broken

my $All     = 0;

# internals
my $PORTSDIR = $ENV{PORTSDIR} ? $ENV{PORTSDIR} : $ENV{PORTSDIR} = '/usr/ports';

### Utility Functions
sub error   { print STDERR "ERROR: $_[0]"                              }
sub debug   { print STDERR "DEBUG: $_[0]"          if $Debug           }
sub verbose { print STDOUT "VERBOSE($_[0]): $_[1]" if $Verbose > $_[0] }

sub execute {

    my $cmd;
    if (@_ == 2) {
        $cmd = "cd $_[0] ; $_[1]";
    }
    else {
        $cmd = $_[0];
    }

    # intentionally stdout
    verbose(0, "$cmd\n");
    unless (system($cmd) == 0) {
        error("Err: $?\n");
        return 0;
    }
    else {
        return 1;
    }
}

### main
sub getopts_wrapper {

    my $rv =
        Getopt::Long::GetOptions(
            "debug|d"      => \$Debug,   # unused
            "verbose=i"    => \$Verbose,
            "help|h"       => \$Help,
            "version|V"    => \$Version,
            "noexec|n"     => \$NoExec,  # unused

            "class=s"      => \$Class,

            "add"          => \$Add,
            "build"        => \$Build,
            "clean"        => \$Clean,   # unused
            "delete"       => \$Delete,
            "jail"         => \$Jail,
            "rescan"       => \$Rescan,
            "update"       => \$Update,

            "all"          => \$All,
        );

    die "You must run this from a root shell (sudo su -) to get PACKAGESITE" if !$ENV{PACKAGESITE} && $Update && !$Jail;


    Pod::Usage::pod2usage(-verbose => 1) unless $rv;

    unless ($Help || valid_args()) {
        $rv = 0;
        Pod::Usage::pod2usage(-verbose => 1);
    }

    return $rv ? 1 : 0;
}

sub valid_args {

    my $errors = 0;

    ## NoExec implies Verbosity level 1
    $Verbose = 1 if $NoExec;

    return $errors > 0 ? 0 : 1;
}

sub port_2_pkg {
  my ($port) = @_;

  my $pkg = $port;

  my $pyver = "py27";

  $pkg =~ s!.*/!!;

  $pkg .= "-$pyver"         if $pkg =~ /svnmailer/;
  $pkg .= '-static'         if $pkg =~ /bash/;
  $pkg =~ s/3$//            if $pkg =~ /ncftp3/;
  $pkg =~ s/ruby-//         if $pkg =~ /cruisecontrol/;
  $pkg =~ s/13//            if $pkg =~ /swig/;
  $pkg =~ s/py-/$pyver-/    if $pkg =~ /py-/;
  $pkg =~ s/ruby-/ruby18-/  if $pkg =~ /^ruby-sqlite/;
  $pkg =~ s/ruby-/ruby18-/  if $pkg =~ /ruby-gems/;
  $pkg =~ s/19//            if $pkg =~ /ruby19/;
  $pkg =~ s/Archiv/Archive/ if $pkg =~ /pear-PHP_Archiv/;
  $pkg =~ s/mod/ap22-mod/   if $pkg =~ /^mod_perl2/;
  $pkg =~ s/c/C/            if $pkg =~ /^p5-chart/;
  $pkg =~ s/2//		    if $pkg =~ /cyrus-sasl2/;

  return $pkg;
}

sub task_add {
    my %args = @_;

    my $ports = $args{ports};

    fork and return if $Parallel;
    foreach my $port (@$ports) {
      print "====> $port\n";
      execute("/space/scripts/tc addPort -b $args{build} -d $port");
    }
    exit if $Parallel;

    return;
}

sub task_build {
    my %args = @_;

    my $Port=`pwd`;
    if ($Port =~ m!/usr/ports/!) {
      $Port =~ s,/usr/ports/,,;
    }
    else {
      $Port = '';
    }

    execute("mdconfig -d -u 4")           unless $Parallel;
    execute("mdmfs -s 12g md4 /space/md") unless $Parallel;

    execute("/space/scripts/tc tinderbuild -nullfs -plistcheck -onceonly -noduds -b $args{build} $Port"
           . ( $Parallel ? " &" : ""));

    execute("umount /space/md")           unless $Parallel;

    return;
}

sub task_delete  { 
    my %args = @_;

    execute("pkg_delete -af"); 

    return;
}

sub task_update {
    my %args = @_;

    my $ports = $args{ports};

    task_delete(%args); # TODO better options?

    foreach my $port (@$ports) {
    	my $pkg = port_2_pkg($port);
        execute("pkg_add -r $pkg");
    }

    return;
}

sub task_rescan {
    my %args = @_;

    execute("/space/scripts/tc rescanPorts -b $args{build}");

    return;
}

sub _pkgs {

    my $c = `cat /root/bin/pp.conf`;

    eval $c;
}

sub work {

    my $rv = EXIT_SUCCESS;

    my %all = _pkgs();
    if ($Update) {
        my $pkgsite = $ENV{PACKAGESITE};
        exit unless $pkgsite && $pkgsite ne '';
        $pkgsite =~ s!/Latest/!!;
        $pkgsite =~ s!.*/!!;
        $Class = $pkgsite;
        print STDERR "Class=$Class\n";
    }

    my $classes =  $All ? [ grep { !/base/ } keys %all]
                        : [split /,/, $Class];

    if ($Build and $Parallel) {
        execute("mdconfig -d -u 4");
        execute("mdmfs -s 12g md4 /space/md");
    }

    foreach my $class (@$classes) {
        $class =~ s/9\.\d+-RELENG-?//;
        my $build = "9.1-RELENG-$class";

        print "========> $class: $build\n";

        my $ports = $all{$class};

        if ($class eq 'svn') {
         ## subversion is installed in /usr/local/subversion-install outside of ports on eris and harmonia
         push @$ports, grep { !m!devel/subversion! } @{$all{base}};
        }
        elsif ($class eq 's-bz') {
         ## bugzilla is installed outside of ports
         push @$ports, grep { !m!devel/bugzilla! } @{$all{base}};
        }
        elsif ($class =~ /smtp/) {
          ## no postfix on hermes
          push @$ports, grep { !m!mail/postfix! } @{$all{base}};
        }
        else {
         push @$ports, @{$all{base}};
        }

        task_add(ports   => $ports,  build => $build) if $Add;
        task_build(                  build => $build) if $Build;
        task_clean()                                  if $Clean; ## XXX: TODO
        task_delete()                                 if $Delete;
        task_rescan(                 build => $build) if $Rescan;
        task_update(ports => $ports, build => $build) if $Update;
    }

    if ($Parallel) {
        $? and $rv = $? >> 8 while wait() != -1;
        execute("umount /space/md") if $Build;
    }

    return $rv;
}

sub main {

    getopts_wrapper() or return EXIT_FAILED_INVALID_ARGS_OR_ENV;

    if ($Help) {
        Pod::Usage::pod2usage(-verbose => 1);
        return EXIT_SUCCESS;
    }

    if ($Version) {
        print PROGNAME . " - v$VERSION\n\n";
        return EXIT_SUCCESS;
    }

    return work();
}

MAIN: {
  exit main();
}
