#!/usr/bin/env perl

# Check asf- and pit- authorization-template for errors:
# - references to @groupname must relate to an existing group name
# - references to reuse:[asf|pit]-authorization must be present in the related file
# - ldap:cn=name must agree with group name

use strict;

my %groupused=(); # is the group used?

my ($pitrefs, $asfdefs)=process_file('asf');
my ($asfrefs, $pitdefs)=process_file('pit');

for(sort keys %$asfrefs) {
    print "$_ referenced by pit but not defined in asf\n" unless defined $asfdefs->{$_};
}

for(sort keys %$pitrefs) {
    print "$_ referenced by asf but not defined in pit\n" unless defined $pitdefs->{$_};
}

my @unusedlist=();
my @unusedldap=();
for(sort keys %$asfdefs) {
	next if  defined $groupused{$_};
	if ($asfdefs->{$_} eq 'LIST') {
        push @unusedlist,$_;
	} else {
        next if  m!-pmc$!;
        push @unusedldap,$_;
	}
}
for(sort keys %$pitdefs) {
    next if defined $groupused{$_};
    if ($pitdefs->{$_} eq 'LIST') {
        push @unusedlist,$_;
    } else {
        next if  m!-pmc$!;
        push @unusedldap,$_;
    }
}
if (scalar @unusedlist) {
    print "The following local lists don't appear to be used in the asf or pit auth files: ",join(' ', @unusedlist),"\n";
}

if (scalar @unusedldap) {
    print "The following LDAP groups don't appear to be used in the asf or pit auth files:\n",join(' ', @unusedldap),"\n";
}

print "Completed scans\n";

sub process_file{
    my $name=shift;
    my $file="${name}-authorization-template";
    print "Scanning $file\n";
    my %groups=();
    my %refs=();
    open IN,"<$file" or die "Cannot open $file $!";
    while(<IN>) {
    	last if m!^\[groups\]!;
    }
    die "Could not find [groups] marker in $name" if eof;
    while(<IN>) {
        last if m!^\[/\]!;
        s/ +$//;# trim
        next if m!^#! || m!^\s*$!; # comment or empty
        next if m!^\[!; # directory header
        # committers={ldap:cn=committers,ou=groups,dc=apache,dc=org}
        # ace-pmc={ldap:cn=ace,ou=project,ou=groups,dc=apache,dc=org;attr=owner}
        if (m!^([^=]+)={ldap:cn=([^,]+),!) {
            my ($group, $cn)=($1,$2);
            my $error=0;
            if ($group =~ m!-pmc$!) {
                $error=1 unless $group eq "$cn-pmc";
                $error=1 unless m!cn=$cn,ou=project,ou=groups,dc=apache,dc=org;attr=owner!
                    or m!,ou=pmc,ou=committees,!; # drop this last checke when tac&security are moved
            } elsif ($group =~ m!-ppmc$!) {
                $error=1 unless m!cn=$cn,ou=project,ou=groups,dc=apache,dc=org;attr=owner!;
            } else {
                $error=1 unless $group eq $cn;                                
            }
            $error=1, print "$group already defined\n" if defined $groups{$group};
            $groups{$group}='LDAP';
            next unless $error;
        }
        # abdera-pmc={reuse:pit-authorization:abdera-pmc}
        if (m!^([^=]+)={reuse:(asf|pit)-authorization:([^}]+)!) {
            my ($group, $type, $alias)=($1,$2,$3);
            my $error=($group ne $alias); # names must agree
            $error=1 if $type eq $name; # Must refer to other file
            $error=1, print "$group already defined\n" if $refs{$group}++;
            next unless $error;
        }
        # aurora=jfarrell,benh,...
        if (m!^(\w[^=]*)=(\w[-\w]*(,\w[-\w]*)*)?$!) {
            my $group=$1;
            #print;
            my $error=0;
            $error=1, print "$group already defined\n" if defined $groups{$group};
            $groups{$group}='LIST';
            next unless $error;
        }
        print "??: Line: $. $_";
    }
    die "Could not find [/] marker in $name" if eof;
    while(<IN>) {
        s/ +$//;# trim
        next if m!^#! || m!^\s*$!; # comment or empty
        next if m!^\[!; # directory header
        next if m!^\* *= *r?$!; # * = r?
        # @ace = rw
        if (m!^@(\w[-\w]*)\s*=\s*(r|rw)\s*$!) {
            my $groupref=$1;
            my $error=0;
            $error=1, print "Group $groupref not defined\n" unless 
                defined $groups{$groupref} or defined $refs{$groupref};
            $groupused{$groupref}++;
            next unless $error;
        }
        # user = rw
        if (m!^(\w[-\w]*)\s*=\s*(r|rw)?\s*$!) {
        	my $usr=$1;
            my $error=0;
            $error=1, print "User $usr is also defined as a group\n" if 
                defined $groups{$usr} or defined $refs{$usr};
            next unless $error;
        }
        print "??: Line: $. $_";
    }
    close IN;
    return \%refs, \%groups;
}
