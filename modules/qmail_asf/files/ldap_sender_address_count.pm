# USAGE: require ldap_sender_address_count > 0 and ...

use Net::LDAP;

my $LDAP_SERVER="ldap1-us-west.apache.org";
my $LDAP_CAFILE="/usr/local/etc/openldap/clients/us/cacerts/cacert.pem";
my $LDAP_BASE="ou=people,dc=apache,dc=org";

my $ldap = Net::LDAP->new(
    "ldaps://$LDAP_SERVER",
    onerror => 'die',
#   verify  => 'require', # XXX !!! fscking perl idiocy that this stopped working
    cafile  => $LDAP_CAFILE,
) or die "Can't connect to ldaps://$LDAP_SERVER; $!\n";

$ldap->bind;

my $response = $ldap->search(
    base  => $LDAP_BASE,
    attrs => ['uid'],
    scope => 'one',
    filter=> "(|(mail=$ENV{SENDER})(asf-altEmail=$ENV{SENDER}))",
);

$response->count || "0e0"; # must always return a true value for require
