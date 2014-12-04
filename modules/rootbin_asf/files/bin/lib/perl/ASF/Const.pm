package ASF::Const;

## core
use strict;
use warnings FATAL => 'all';
use Carp;

## custom

## exit codes
use constant EXIT_SUCCESS                    => 0;
use constant EXIT_FAILED_INVALID_ARGS_OR_ENV => 1;
use constant EXIT_FAILED                     => -1;

use constant DEBUGGING => defined $ENV{ASFDEBUG} && $ENV{ASFDEBUG} == 1 ? 1 : 0;

# XXX: don't cheat
our $GCCVERSION = $ENV{_GCCVERSION};
our $OSAASFH     = $ENV{_OSAASFH};
our $OSVERSION  = $ENV{_OSVERSION};
our $OSNAME     = $ENV{_OSNAME};

our $tmpl_config = {
                    EVAL_PERL    => 1,
                    ABSOLUTE     => 1,
                    RELATIVE     => 1,
                   };

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
