#!/usr/bin/perl

use NetSNMP::agent (':all');
use NetSNMP::ASN qw(ASN_OCTET_STR ASN_INTEGER);

sub zpool_handler {
  my ($handler, $registration_info, $request_info, $requests) = @_;
  my $request;
  for($request = $requests; $request; $request = $request->next()) {
    my ($good, $bad, $lgood, $lbad) = zpool();
    my $oid = $request->getOID();
    if ($request_info->getMode() == MODE_GET) {
      if ($oid == new NetSNMP::OID(".1.3.6.1.4.1.1024.1")) {
        $request->setValue(ASN_INTEGER, $good);
      }
      if ($oid == new NetSNMP::OID(".1.3.6.1.4.1.1024.2")) {
        $request->setValue(ASN_INTEGER, $bad);
      }
      if ($oid == new NetSNMP::OID(".1.3.6.1.4.1.1024.3")) {
        $request->setValue(ASN_INTEGER, $lgood);
      }
      if ($oid == new NetSNMP::OID(".1.3.6.1.4.1.1024.4")) {
        $request->setValue(ASN_INTEGER, $lbad);
      }
   } elsif ($request_info->getMode() == MODE_GETNEXT) {
      if ($oid == new NetSNMP::OID(".1.3.6.1.4.1.1024.1")) {
        $request->setOID(".1.3.6.1.4.1.1024.2");
        $request->setValue(ASN_INTEGER, $bad);
      }
      elsif ($oid == new NetSNMP::OID(".1.3.6.1.4.1.1024.2")) {
        $request->setOID(".1.3.6.1.4.1.1024.3");
        $request->setValue(ASN_INTEGER, $lgood);
      }
      elsif ($oid == new NetSNMP::OID(".1.3.6.1.4.1.1024.3")) {
        $request->setOID(".1.3.6.1.4.1.1024.4");
        $request->setValue(ASN_INTEGER, $lbad);
      }
      elsif ($oid < new NetSNMP::OID(".1.3.6.1.4.1.1024.1")) {
        $request->setOID(".1.3.6.1.4.1.1024.1");
        $request->setValue(ASN_INTEGER, $good);
      }
    }
  }
}

sub zpool {
    my $zstatus = qx(sudo zpool status);
    my $zlist = qx(sudo zpool list -H);
    my $zsbad= scalar grep (/[a-z0-9][a-z0-9]+\s{1,8}(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED)/ ,split(/\n/, $zstatus));
    my $zsgood = scalar grep (/[a-z0-9][a-z0-9]+\s{1,5}(ONLINE|READY|AVAIL)/ ,split(/\n/, $zstatus));
    my $zlbad= scalar grep (/[a-z0-9][a-z0-9]+\s{1,8}(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED)/ ,split(/\n/, $zlist));
    my $zlgood = scalar grep (/[a-z0-9][a-z0-9]+\s{1,5}(ONLINE|READY|AVAIL)/ ,split(/\n/, $zlist));
    return ($zsgood, $zsbad, $zlgood, $zlbad)
}

my $agent = new NetSNMP::agent();
$agent->register("zpool_status", ".1.3.6.1.4.1.1024",
                 \&zpool_handler);

