#!/usr/bin/perl

use strict;

my $LIMIT_LOGIN_PLUS_NEWACOUNT = 200;
my $LIMIT_RATIO_LOGIN_PLUS_NEWACOUNT = 50;

# Process access log and output all IPs with:
#     #newacount+#login >= LIMIT_LOGIN_PLUS_NEWACOUNT and 
#     #newacount+#login >= LIMIT_RATIO_LOGIN_PLUS_NEWACOUNT / 100 * #wiki_requests

my %data;
my $data;

my ($pre, $request, $ref, $ua, $method, $ip, $ts, $wiki);
my $tmp;

while(<>) {
    next unless $_ =~ /^wiki/;

#wiki.apache.org 87.117.229.136 - - [09/Aug/2013:00:02:21 +0000] "GET /cassandra/MoinMoin?action=newaccount HTTP/1.1" 200 2377 "https://wiki.apache.org/cassandra/MoinMoin?action=login" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.112 Safari/535.1" - - 33009 4460334080 0 + 142647

    ($pre, $request, $tmp, $ref, $tmp, $ua) = split(/"/, $_);
    ($tmp, $ip, $tmp, $tmp, $ts) = split(/ /, $pre);
    ($method, $request, $tmp) = split(/ /, $request);
    ($tmp, $wiki) = split(/\//, $request);
    $ts =~ s/.//;
    if (!exists($data{$ip})) {
        $data{$ip} = {};
        $data{$ip}->{wiki}={};
        $data{$ip}->{ua}={};
        $data{$ip}->{begin}=$ts;
    }
    $data = $data{$ip};
    $data->{end} = $ts;
    $data->{total}++;
    if ($request =~ /action=newaccount/) {
        $data->{new}++;
    } elsif ($request =~ /action=login/) {
        $data->{login}++;
    } elsif ($ref =~ /action=newaccount/) {
        if ($method eq 'POST') {
            $data->{refnewpost}++;
        } else {
            $data->{refnew}++;
        }
    } elsif ($ref =~ /action=login/) {
        if ($method eq 'POST') {
            $data->{refloginpost}++;
        } else {
            $data->{reflogin}++;
        }
    } else {
        $data->{other}++;
    }
    $data->{wiki}->{$wiki}++;
    $data->{ua}->{$ua}++;
}
 
my $sum;
for $ip (keys %data) {
    $sum = $data{$ip}->{new} + $data{$ip}->{login};
    delete($data{$ip}) if $sum < $LIMIT_LOGIN_PLUS_NEWACOUNT ||
                          $sum < $LIMIT_RATIO_LOGIN_PLUS_NEWACOUNT * $data{$ip}->{total} / 100;
}

sub byabuse {
    return $data{$b}->{new}+$data{$b}->{login} <=> $data{$a}->{new}+$data{$a}->{login};
}

sub most_frequent {
    my $list = shift;
    my $max = 0;
    my $result;
    for my $k (keys %{$list}) {
        if ($list->{$k} > $max) {
            $max = $list->{$k};
            $result = $k;
        }
    }
    return $result;
}

my $ua_list;
my $wiki_list;

printf("#%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
       'IP', 'First', 'Last', 'Total', 'NewAccount', 'Login', 'POSTNewAccountReferer', 'POSTLoginReferer', 'NewAccountReferer', 'LoginReferer', 'Others',
       'NumWikis', 'TopWikiCount', 'TopWiki', 'NumUA', 'TopUACount', 'TopUA');
for $ip (sort byabuse keys %data) {
# IP #begin #end #total #newaccount #login #othersPOSTNewaccRef #othersPOSTLoginRef #othersNewaccRef #othersLoginRef #others #wikis #MostFrequentWiki #UAs #MostFrequentUA 
    $data = $data{$ip};
    $wiki_list = keys $data->{wiki};
    $ua_list = keys $data->{ua};
    $wiki = most_frequent($data->{wiki});
    $ua = most_frequent($data->{ua});
    printf("%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%d\t%s\n", 
           $ip, $data->{begin}, $data->{end},
           $data->{total}, $data->{new}, $data->{login},
           $data->{refnewpost}, $data->{refloginpost}, $data->{refnew}, $data->{reflogin}, $data->{other},
           $wiki_list, $data->{wiki}->{$wiki}, $wiki,
           $ua_list, $data->{ua}->{$ua}, $ua);
}
