#!/usr/bin/perl
#
# script which can be used in post-commit hook to check if a commit contains private directories
#
use strict;
use warnings;

my $file = '/x1/svn/asf-authorization';
my $svn_look = '/usr/bin/svnlook';
my $dir = undef;

sub parse_auth_file {
        my $auth_hash;
        open (AUTH_FILE, $file);

        # parse the auth file and store the perms in a hash
        while (my $line = <AUTH_FILE>) {
                if ($line =~ /^\[(\/.*)\]$/) {
                        $dir = $1;
                } elsif (defined $dir && $line =~ /(.+)=(.*)/) {
                        #$auth_hash->{$dir}->{$1} = $2;
                        my $var_hash;

                        my $key = $1;
                        my $value = $2;

                        #strip of blanks
                        $key =~ s/ //g;
                        $value =~ s/ //g;
                        if (exists $auth_hash->{$dir}) {
                                $var_hash = $auth_hash->{$dir};
                        }
                        $var_hash->{$key} = $value;
                        $auth_hash->{$dir} = $var_hash;
                }
        }
        close AUTH_FILE;
        return $auth_hash;
}

sub changed_dirs($$) {
        my $repos = shift;
        my $rev = shift;
        my @dirs = `$svn_look dirs-changed --revision $rev $repos`;

        return @dirs;
}

sub check_private {
        my $num_args = $#ARGV + 1;
        die "Usage: $0 repos_path revision\n" if ($num_args != 2);

        my @dirs = &changed_dirs($ARGV[0],$ARGV[1]);
        my $auth_hash =  &parse_auth_file;
        my $private = 0;

        # loop over the changed directories
        foreach my $dir (@dirs) {
                my $n_dir = '/' . $dir;
                while (!exists $auth_hash->{$n_dir}) {
                        $n_dir = $1 if $n_dir =~ /(.+)\/.*$/;
                }
                my $perm = $auth_hash->{$n_dir}->{'*'};
                if (defined $perm && $perm eq '') {
                        $private = 1;
                }
        }
        if ($private == 1) {
                print "Commit contains private directories!\n";
        } else {
                print "Commit contains no private directories\n";
        }
        exit $private;
}

&check_private;
