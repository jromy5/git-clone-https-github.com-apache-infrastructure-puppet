package ASF::Cmd;

## core
use strict;
use warnings FATAL => 'all';
use Carp;

## mp2

## libapreq2

## dist

## cpan

## custom

## version
our $VERSION = q$Revision$;

our $MKDIR_P = "/bin/mkdir -p";
our $FETCH   = "/usr/bin/fetch";
our $TAR     = "/usr/bin/tar";
our $CP_R    = "/bin/cp -R";
our $RM_RF   = "/bin/rm -rf";
our $MAKE    = "/usr/bin/make";
our $GMAKE   = "/usr/local/bin/gmake";
our $SED_I   = "/usr/bin/sed -i ''";
our $SYSCTL  = "/sbin/sysctl";
our $BZIP2   = "/usr/bin/bzip2";
our $PS      = "/bin/ps";
our $TAIL    = "/usr/bin/tail";

our $MYSQLDUMP = "/usr/local/bin/mysqldump";
our $TARSNAP = "/usr/local/bin/tarsnap";

1;

__END__

=head1 SYNOPSIS

=head1 COPYRIGHT

  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
