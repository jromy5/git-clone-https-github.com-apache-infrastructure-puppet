#!/usr/bin/perl

# sender-demunger:  wrapper around commands which does
#                   SRS and BATV demunging of the SENDER env var

# Usage: sender-demunger <command> <args>

# Note: if you pass no command-line arguments to this script, tests are run.

for ($ENV{SENDER}) {

    if (/^SRS[01][=+-]/i) {

        my $fqdn = qr/[^=+\@.]+ (?: \. [^=+\@.]+ )+/x;   # full domain name

        s/^SRS[01][=+-]
          .+?     [=+]                                   # stuff we can skip
          ($fqdn)  =  ([^\@]+)                           # capture address
          \@ .+ $                                        # rest of SENDER
         /$2\@$1/xi

             or do {
                 my $LOG;
                 open $LOG, ">>/var/log/sender-demunger/srs"
                     and print $LOG "$_\n";
             };
    }

    if (/^prvs=/) {

        s/^prvs= [0-9a-f]{9,10} =                        # hash in front
          (?=[^\@])                                      # ensure non-empty user
         //xi

             or s!^prvs= ([^\@]+)                        # capture the user
                  (?: /[0-9a-f]{10} | =[0-9a-f]{9,10} ) \@  # hash in back
                 !$1\@!xi

                     or do {
                         my $LOG;
                         open $LOG, ">>/var/log/sender-demunger/prvs"
                             and print $LOG "$_\n";
                     };
    }
}

exec {$ARGV[0]} @ARGV or exit $! if @ARGV;

while (<DATA>) {
    (local $ENV{SENDER}, my $expected) = split;

    my $output =  qx{$0 /usr/bin/perl -e 'print \$ENV{SENDER}'};

    die <<"" unless $output eq $expected;
Parse of $ENV{SENDER} (line $.) failed:
  expected <$expected>
  but saw  <$output>

}

#  Licensed to the Apache Software Foundation (ASF) under one or more
#  contributor license agreements.  See the NOTICE file distributed with
#  this work for additional information regarding copyright ownership.
#  The ASF licenses this file to You under the Apache License, Version 2.0
#  (the "License"); you may not use this file except in compliance with
#  the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

__DATA__
srs0=lhndoj=xq=example.com=darrell@example.net                        darrell@example.com
SRS0=078+09af+ee3=849=example.net=ghurkin@example.com                 ghurkin@example.net
SRS1+foo.com=6721eec4c=779=example.org=ghurkin@example.com            ghurkin@example.org
SRS0-b51+e3c67f+64ed=757=example.com=gremlin+foo.bar=quux@example.org gremlin+foo.bar=quux@example.com
SRS0++vm+te+62+example.name=prvs=matt.foo=bar=123456789@example.net   matt.foo=bar@example.name
prvs=swgithen=9829761d2@example.edu                                   swgithen@example.edu
prvs=10433b4100=christian@example.com                                 christian@example.com
prvs=andrew/060798222b@example.com                                    andrew@example.com
prvs=deadbeef0=john.thumb@example.com                                 john.thumb@example.com
prvs=hellothere=0266c69606@example.com                                hellothere@example.com
