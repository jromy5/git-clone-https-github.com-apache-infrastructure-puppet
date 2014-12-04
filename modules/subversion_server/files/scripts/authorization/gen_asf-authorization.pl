#!/usr/bin/perl

# Run from svn hook on asf-authorization-template and builds authz on a commit. 

# Run from cron, watches the OUs in the template and rebuilds authz on a change.
# This is expected to be on line one of the asf-authorization file.
# If it is not or the CSN is different, then the asf-autorization file is rebuilt. 
#
# Sample info line:
#   csn=20090605170902.347261Z#000000#000#000000,csn=20090605170902.347261Z#000000#000#000000+
#   ou=groups,dc=apache,dc=org:ou=pmc,ou=committees,ou=groups,dc=apache,dc=org

use warnings;
use strict;
use File::Copy;
use POSIX 'strftime';
use Net::LDAP;
use Net::LDAP::Control::SyncRequest;
use Net::LDAP::Constant qw(
  LDAP_SYNC_REFRESH_ONLY
  LDAP_SYNC_REFRESH_AND_PERSIST
  LDAP_SUCCESS );

my $LDAPHOST  = "ldaps://127.0.0.1";
my $debug         = 1;
my ( $cookie, $ldap, %watchlist );

$ldap = Net::LDAP->new("$LDAPHOST");
$ldap->bind;

die "Bad usage" if @ARGV*@ARGV - 3*@ARGV + 2;
my ($MODE, $DIR) = @ARGV;
$DIR ||= "/x1/svn/config/authorization";
die "Usage: (ldap_change|template_commit) [DIR]"
    unless $MODE =~ m/^ldap_change$|^template_commit$/
       and -d $DIR;

rebuild_if_needed(
  "$DIR/asf-authorization-template",
  "$DIR/asf-authorization");
rebuild_if_needed(
  "$DIR/pit-authorization-template",
  "$DIR/pit-authorization");

sub rebuild_if_needed {
    my ($AUTHZTEMPLATE, $AUTHZ_FILE) = @_;
    rebuild($AUTHZTEMPLATE, $AUTHZ_FILE), return if $MODE eq 'template_commit';
    if ( -e $AUTHZ_FILE ) {
        (%watchlist) = getCSNandOUlistFromAUTHZ($AUTHZ_FILE);
        if ($debug) {
            print "Main: Watch list from getCSNandOUlistFromAUTHZ:\n";
            while ( ( my $k, my $v ) = each %watchlist ) {
                print "\t$k => $v\n";
            }
        }
        if ( !( $watchlist{"empty"} ) ) {
            print "Main: Watch list was good\n" if ($debug);
            ( my $different ) = compareCSNs(%watchlist);
            if ( $different eq "true" ) {
                print "main: Found at least one changed CSN, rebuilding authz.\n"
                  if ($debug);
                rebuild($AUTHZTEMPLATE, $AUTHZ_FILE);
            }
            else {
                print "Main: No change in CSN. Nothing to do. Exiting.\n"
                  if ($debug);
                return;
            }
        }
        else {
            print "Main: Watch list was missing or invalid. Rebuilding authz.\n"
              if ($debug);
            rebuild($AUTHZTEMPLATE, $AUTHZ_FILE);
        }
    }
    else {
        rebuild($AUTHZTEMPLATE, $AUTHZ_FILE);
    }
}

#end-main--------------------------------------------------------------------------

sub rebuild {
    my ($AUTHZTEMPLATE, $AUTHZ_FILE) = @_;
    my @newauthzfile;
    open( TEMPLATE, $AUTHZTEMPLATE )
      or die "Couldn't open $AUTHZTEMPLATE for reading: $!\n";
    my @dirtyOUwatchlist;
    push( @newauthzfile, "#placeholder" );
    while (<TEMPLATE>) {
        if ($_ !~ m/^#/ && $_ =~ m/{reuse:((?:asf|pit)-authorization):(\w[\w\d-]*?)}/ ) {
            my (@lines) = `/usr/bin/grep '^$2 *= *' $DIR/$1-template`;
            die "Uh-oh: found '@lines', expected one line; at '$_'" unless @lines == 1;
            $_ = $lines[0];
        }
        if ($_ !~ m/^#/ && $_ =~ m/{ldap:(cn=.+)}/ ) {
            chomp;
            my @groupdn = split( /,/, $1 );
            my $groupname = shift(@groupdn);
            my ( $groupbase, $membersline );
            $groupbase = join( ',', @groupdn );
            $groupname =~ s/^cn=//;
            push( @dirtyOUwatchlist, "$groupbase" );
            ( my @memberlist ) = getMembers( $groupname, $groupbase );

            # Fix up for -pmc
            if ( $groupdn[0] eq "ou=pmc" ) {
                $groupname .= "-pmc";
            }
            push( @newauthzfile, "$groupname=" );
            foreach my $member (@memberlist) {

                # shorten the full dn down to just the uid value.
                # This only happens on non posix groups.
                if ( $member =~ m/uid=(\w[\w-]+),/ ) {
                    $member = $1;
            }
                $membersline .= $member . ",";
            }
            if ($membersline) { 
                $membersline =~ s/,$//;
                push( @newauthzfile, "$membersline\n" );
            }
            else {
                    print "rebuild: $groupname, $groupbase had no members or did not exist\n" if ($debug);
                    push( @newauthzfile, "\n" );  # newline for empty group
            }
        }
        else {
            push( @newauthzfile, "$_" );
        }
    }

    #clean up our OU Watchlist/CSN and write out the new asf-authz.

    ( my $cleanWatchList ) = makeWL(@dirtyOUwatchlist);

    $newauthzfile[0] = "$cleanWatchList\n";
    #TODO add sanity check before rotating. Such as, "is the new file empty?"
    my $AUTHZ_TMP="$AUTHZ_FILE.$$";
    open( NEWAUTHZ, ">$AUTHZ_TMP" ) or die "Couldn't open $AUTHZ_TMP for writing: $!\n";
    foreach (@newauthzfile) {
        print NEWAUTHZ $_;
    }
    close NEWAUTHZ;
    print "rotate: Rotating files.\n" if ($debug);
    my $authz_archivefile = "$AUTHZ_FILE.old"; 
    my $authz_archivezip = "$authz_archivefile";
    copy($AUTHZ_FILE,$authz_archivefile);
    rename $AUTHZ_TMP,$AUTHZ_FILE;
    system "gzip -f $authz_archivezip";
}

sub getMembers {
    my $gid  = shift;
    my $base = shift;
    my ( @members, @entries, $attr, @attrs );
    print "getMembers: Looking for $gid, $base\n" if ($debug);

    # Look for memberUid for posix groups and member for groupOfNames
    # No group should ever have both?

    my $request = $ldap->search(
        filter => "(cn=$gid)",
        base   => "$base",
        scope  => 'one',
        attrs  => [ 'memberUid', 'member' ]
    );
    $request->code && die $request->error;
    @entries = $request->entries;
    foreach my $entry (@entries) {
        @attrs = $entry->attributes();
        foreach $attr (@attrs) {
            @members = $entry->get_value($attr);
        }
    }
    return @members;
}

sub getCSNandOUlistFromAUTHZ {

  # Use the first line of the old authz file to see what OUs we need to watch
  # and what the CSN ID for each of those OUs was at the time of last writing.

    my $AUTHZ_FILE = shift;
    my %wl;
    open( AUTHZCURRENT, "<$AUTHZ_FILE" )
      or die "Couldn't open $AUTHZ_FILE for reading: $!\n";
    my $stampedline = <AUTHZCURRENT>;
    print "getCSNandOUlistFromAUTHZ: Read first line from authz, $stampedline\n"
      if ($debug);
    $stampedline =~ s/^\#//;
    if ( $stampedline =~ m/^csn.*/ ) {
        chomp $stampedline;
        ( my $oldcsns, my $oldous ) = split( '\+', $stampedline );
        my @CSNs = split( ',', $oldcsns );
        my @OUs  = split( ':', $oldous );
        @wl{@OUs} = @CSNs;
    }
    else {

        # Let main know we did not get a good hint from the old authz
        # Main will assume it's a fresh start and make a new one
        # As long as we have a template, we know what we need to do.

        print "getCSNandOUlistFromAUTHZ: CSN line was bad/empty: $stampedline\n"
          if ($debug);
        $wl{"empty"} = "badline";
	close AUTHZCURRENT;
        return %wl;
    }
    close AUTHZCURRENT;
    if ($debug) {
        print "getCSNandOUlistFromAUTHZ: Watch list from authz:\n";
        while ( ( my $k, my $v ) = each %wl ) {
            print "\t$k => $v\n";
        }
    }
        close AUTHZCURRENT;
    return %wl;
}

sub compareCSNs {
    my (%wl) = @_;
    my %newcsns;
    my $needrebuild = "false";
    if ($debug) {
        print "compareCSNs: Working with these values:\n";
        while ( ( my $k, my $v ) = each %wl ) {
            print "\t$k => $v\n";
        }
    }

    while ( ( my $ou, my $oldcsn ) = each(%wl) ) {
        ( $newcsns{$ou} ) = getCSN($ou);
        print "compareCSNs: old $oldcsn, new $newcsns{$ou}\n" if ($debug);
        if ( $oldcsn ne $newcsns{$ou} ) {
            $needrebuild = "true";
        }
    }

    #return ( $needrebuild, %newcsns );
    return $needrebuild;
}

sub getCSN {
    my $ou = shift;
    my $req =
      Net::LDAP::Control::SyncRequest->new( mode => LDAP_SYNC_REFRESH_ONLY );
    my $mesg = $ldap->search(
        base     => $ou,
        scope    => 'sub',
        control  => [$req],
        callback => \&searchCallback,
        filter   => "(objectClass=*)",
        attrs    => ['*']
    );
    print "getCSN: Cookie is $cookie\n" if ($debug);
    #( my $newris, my $newsid, my $newcsn ) = split( ',', $cookie );
    $cookie =~ m/.+(csn=.+)$/;
    my $newcsn = $1;
    print "getCSN: New CSN is $newcsn\n" if ($debug);
    $mesg->code && die $mesg->error;
    return $newcsn;

}

sub searchCallback {
    my $message  = shift;
    my $entry    = shift;
    my @controls = $message->control;
    if ( $controls[0]->isa('Net::LDAP::Control::SyncDone') ) {
        $cookie = $controls[0]->cookie;
    }
}

sub makeWL {
    my @ouwatchlist = @_;
    @ouwatchlist = sort @ouwatchlist;
    my $prev = 'nonesuch';
    @ouwatchlist = grep( $_ ne $prev && ( ($prev) = $_ ), @ouwatchlist );
    my @newcsns;
    foreach my $ou (@ouwatchlist) {
        push( @newcsns, getCSN($ou) );
    }
    my $wl = "#";
    $wl .= join( ',', @newcsns );
    $wl .= "+";
    $wl .= join( ':', @ouwatchlist );
    return $wl;
}
