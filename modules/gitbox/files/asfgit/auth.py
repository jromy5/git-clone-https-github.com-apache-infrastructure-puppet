import ConfigParser
import os
import re

import ldap

import asfgit.cfg as cfg
import asfgit.log as log
import asfgit.util as util

GROUP_DN="cn=%(group)s,ou=groups,dc=apache,dc=org"
DN_RE=re.compile("uid=([^,]+),ou=people,dc=apache,dc=org")
SUBPROJECT_RE=re.compile("-.+$")


def authorized_committers(repo_name):
    writers = set()

    # Read the static file to get admin and bot names.
    parser = ConfigParser.SafeConfigParser()
    with open(cfg.auth_file) as handle:
        parser.readfp(handle)

    for admin in parser.get("groups", "gitadmins").split(","):
        writers.add(util.decode(admin.strip()))

    if parser.has_option("groups", repo_name):
        dn = parser.get("groups", repo_name).strip()
    else:
        # drop subproject name if present
        repo_name = SUBPROJECT_RE.sub("", repo_name)
        dn = GROUP_DN % {"group": repo_name}

    # Individually granted access
    if parser.has_option("individuals", repo_name):
        for person in parser.get("individuals", repo_name).split(","):
            writers.add(util.decode(person.strip()))

    # Add the committers listed in ldap for the project.
    lh = ldap.initialize("ldaps://ldap-lb-us.apache.org")
    attrs = ["memberUid", "member"]
    try:
        for dn, attrs in lh.search_s(dn, ldap.SCOPE_BASE, attrlist=attrs):
            for availid in attrs.get("memberUid", []):
                writers.add(availid)
            for dn in attrs.get("member", []):
                writers.add(DN_RE.match(dn).group(1))
    except:
        log.exception()

    # Add per-repository exceptions
    map(writers.add, cfg.extra_writers)

    return writers
