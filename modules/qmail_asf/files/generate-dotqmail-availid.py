#!/usr/bin/env python

#import getpass
import ldap
import logging
import os
import sys
import smtplib
from email.mime.text import MIMEText

"""
generate/update .qmail files based on LDAP

If run with no arguments, will update all committers.

If run with arguments, arguments can be a list of uids or a dash.  A
dash indicates that a mail message should be read from stdin and the uid
will be extracted from the X-ASF-AVAILID header.
"""

LDAP_URI = 'ldaps://ldap-us-ro.apache.org'
COMMITTERS_OU = 'ou=people,dc=apache,dc=org'
SEARCH_ATTRS = "uid mail asf-banned loginShell".split()

NOTICE = """Dear %s,
your ASF forwarding address details have now changed from

%s

to

%s.

Please contact root@apache.org ASAP, by replying to this email,
if you did not initiate this change.

Thanks,

Apache Infrastructure Team
"""

logging.getLogger().setLevel(logging.WARN)

def update(attrs):
    uid = attrs['uid'][0]

    if 'mail' not in attrs:
        if 'asf-banned' not in attrs \
           and '/usr/bin/false' not in attrs['loginShell']:
            logging.warn('%s has no mail attr', uid)
        return

    # Filter out addresses that could be paths (/) or commands (|)
    addrs = sorted(set(filter(lambda x: not x[:1] in '/|', attrs['mail'])))
    fname = '/home/apmail/.qmail-%s' % uid

    update_fname = True

    if os.path.isfile(fname):
        oldaddrs = open(fname, 'r').read().splitlines()
        if oldaddrs == addrs:
            update_fname = False
# Don't create or send the email (update to r975717)
#         if update_fname and set(oldaddrs) != set(['%s@locus.apache.org' % uid]):
#             # account creation uses the @locus address, until first run
#             # of this script
#             notice = MIMEText(NOTICE % (uid, ", ".join(oldaddrs),
#                                         ", ".join(addrs)))
#             notice['Subject'] = "[NOTICE] Apache Forwarding Address Changed"
#             notice['From'] = "apmail@apache.org"
#             notice['To'] = ", ".join(oldaddrs)
#             notice['Reply-To'] = "root@apache.org"
# 
#             s = smtplib.SMTP('localhost', 2025)
#             #s.sendmail("apmail@apache.org", oldaddrs, notice.as_string())
#             s.quit()

    if update_fname:
        fnamet = '%s.t' % fname
        open(fnamet, 'w').write("".join(map(lambda x: x+"\n", addrs)))
        os.rename(fnamet, fname)

    if not os.path.exists(fname + '-default'):
        with open(fname + '-default', 'w') as file:
            file.write("%s@apache.org\n" % uid)

    if not os.path.exists(fname + '-owner'):
        if os.path.islink(fname + '-owner'):
            os.unlink(fname + '-owner')
        os.symlink(fname + '-default', fname + '-owner')

def main():
    lh = ldap.initialize(LDAP_URI)

    if len(sys.argv) <= 1:

        # no arguments: update all committers
        for dn, attrs in lh.search_s(COMMITTERS_OU, ldap.SCOPE_SUBTREE,
                                     '(objectClass=asf-committer)',
                                     SEARCH_ATTRS):
            logging.debug('analyzing dn=%s: uid=%s, mail=%r',
                          dn, attrs.get('uid'), attrs.get('mail'))
            update(attrs)

    else:

        # update .qmail files for the specified uids
        for uid in sys.argv[1:]:
            if uid == '-':
                # dash argument: parse email to determine committer to update
                from email.parser import Parser
                email = Parser().parsestr(sys.stdin.read())
                uid = email['X-ASF-AVAILID']

                if not uid:
                    logging.error('mail missing X-ASF-AVAILID header')
                    continue

            result = lh.search_s(COMMITTERS_OU, ldap.SCOPE_SUBTREE, 
                                    '(uid=%s)' % uid, SEARCH_ATTRS)

            if result:
                dn, attrs = result[0]
                update(attrs)
            else:
              logging.error('user %s not in LDAP', repr(uid))

if __name__ == '__main__':
    main()
