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

for(sort keys %$asfdefs , keys %$pitdefs) {
    print "$_ not used anywhere\n" unless m!-pmc$! || defined $groupused{$_};
}

# Check for TLPs without -pmc references (affects people.apache.org site generation)
for(sort keys %$asfdefs) {
	next if m!-site$! || $_ eq 'committers';
	print "$_-pmc missing from ASF auth\n" unless $$asfdefs{$_} eq 'LIST' || defined $$pitrefs{"$_-pmc"};
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
        s/ +$//;# trim
        next if m!^#! || m!^\[! || m!^\s*$! || m!^(\*|\w[-\w]+) = ?(r|rw)?$!;
        # committers={ldap:cn=committers,ou=groups,dc=apache,dc=org}
        if (m!^([^=]+)={ldap:cn=([^,]+),!) {
            my ($group, $cn)=($1,$2);
            my $error=0;
            if ($group =~ m!-pmc$!) {
                $error=1 unless $group eq "$cn-pmc";
                $error=1 unless m!,ou=pmc,ou=committees,!;
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
        # @ace = rw
        if (m!^@(\w[-\w]*)\s*=\s*(r|rw)\s*$!) {
            my $groupref=$1;
            my $error=0;
            $error=1, print "Group $groupref not defined\n" unless 
                defined $groups{$groupref} or defined $refs{$groupref};
            $groupused{$groupref}++;
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
        print "??: $_";
    }
    close IN;
    return \%refs, \%groups;
}