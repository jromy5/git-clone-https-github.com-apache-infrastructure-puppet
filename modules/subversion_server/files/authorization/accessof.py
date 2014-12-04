#!/usr/bin/env python

from __future__ import print_function

try:
    import configparser
except ImportError:
    import ConfigParser as configparser

import glob
import sys

if len(sys.argv[1:]) == 0:
    raise Exception("Usage: $0 foo\n"
                    "Prints all stanzas that mention 'foo'\n"
                    "Ex.  $0 @committers,  $0 ea")

OPTION = sys.argv[1]
for f in glob.glob("*template"):
    parser = configparser.SafeConfigParser()
    parser.read(f)
    for section in parser.sections():
        if parser.has_option(section, OPTION):
            print('%s: %s: %s' % (f, section, parser.get(section, OPTION)))
