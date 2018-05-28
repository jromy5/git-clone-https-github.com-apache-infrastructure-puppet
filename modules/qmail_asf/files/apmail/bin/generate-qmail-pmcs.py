#!/usr/bin/env python

"""
Process all current PMCs and generate the pmcs@apache.org mail alias

Also recreate any existing outhost files for any new PMCs detected.
"""

import glob
import logging
import os
import subprocess
import urllib
import json

execfile("common.conf")

URL = "https://whimsy.apache.org/public/committee-info.json"

LISTDIR = "APMAIL_HOME/lists'
TARGET = 'APMAIL_HOME/.qmail-pmcs'

logging.getLogger().setLevel(logging.INFO)

def main():
    pmcs = []
    cttees = json.load(urllib.urlopen(URL),'utf-8')['committees']
    for j in cttees:
        cttee = cttees[j]
        if cttee['pmc']:
            pmcs += [cttee['mail_list']]

    fd = open(TARGET+'.t', 'w')
    fd.write('| APMAIL_HOME/bin/ezmlm-filter-bcc pmcs@apache.org\n')
    for p in sorted(set(pmcs)):
        fd.write('private@%s.apache.org\n' % p)
    fd.flush()
    fd.close()
    # get the new PMCs
    diff = subprocess.check_output(['comm', '-13', TARGET, TARGET+'.t'])
    os.rename(TARGET+'.t', TARGET)

    for listname in diff.splitlines():
        tlp = listname.strip().split('@')[1].split('.')[0]
        assert listname == ('private@%s.apache.org' % tlp)
        logging.info("Setting outhost for *@%s.apache.org", tlp)
        for outhost in glob.glob('%s/%s.apache.org/*/outhost' % (LISTDIR, tlp)):
            open(outhost, 'w').write('%s.apache.org\n' % tlp)

if __name__ == '__main__':
    main()
