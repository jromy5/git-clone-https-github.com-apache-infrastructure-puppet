#!/usr/bin/python
#
# Generate svn authorization files from the input configs.
#
# This script is run periodically via cron.
#
# For testing, it is helpful to create a directory structure like:
#   ### fill this out
#

import sys
import os.path
import md5
import re

import ldap
import ldap.syncrepl
import ldap.controls.libldap

LDAP_URL = 'ldaps://ldap-us-ro.apache.org'

AUTHZ_DIR = '/x1/svn/authorization'
TEMPLATE_SUBDIR = 'templates'

PUBLIC_AUTHZ = 'asf-authorization'
PUBLIC_TEMPLATE = 'asf-authorization-template'

PRIVATE_AUTHZ = 'pit-authorization'
PRIVATE_TEMPLATE = 'pit-authorization-template'

LDAP_RE = re.compile(r'^([-\w]+)={ldap:cn=([^,]*),([^;}]*)(?:;attr=(.*))?}')
REUSE_RE = re.compile(r'reuse:(asf|pit)-authorization:(.*)}')
UID_RE = re.compile(r'^uid=([^,]*),.*')


def main(authz_dir=AUTHZ_DIR):

  # Disable cert check. The self-signed cert throws off python-ldap.
  ### global option, not per connection? ugh.
  ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)

  # Easy to front-load client handle creation. It will lazy connect.
  client = ldap.initialize(LDAP_URL)

  pub_t, priv_t = load_templates(os.path.join(authz_dir, TEMPLATE_SUBDIR))
  pub_z, priv_z = get_authz_files(authz_dir)

  # Determine if the authz files need regenerating.
  gen_pub = False
  gen_priv = False
  if True: ### check for template changes. TODO: cache md5sum.
    # One of the templates changed, so we'll rebuild both.
    ### maybe optimize for individual rebuilds in the future
    gen_pub = True
    gen_priv = True
  else:
    # The two sets of cached CSNs should be the same, so any change "should"
    # trigger on pub_z. We likely will never execute the second half.
    # Regardless, if we see an LDAP change, BOTH files need rebuilding.
    gen_pub = pub_z.have_CSNs_changed(client) \
              or priv_z.have_CSNs_changed(client)
    gen_priv = gen_pub

  reuse = {'asf': pub_t, 'pit': priv_t}
  if gen_pub:
    pub_z.generate(client, pub_t, reuse)
  if gen_priv:
    priv_z.generate(client, priv_t, reuse)


def load_templates(dirpath):
  pub = Template(os.path.join(dirpath, PUBLIC_TEMPLATE))
  priv = Template(os.path.join(dirpath, PRIVATE_TEMPLATE))
  return pub, priv


def get_authz_files(dirpath):
  pub = AuthzFile(os.path.join(dirpath, PUBLIC_AUTHZ))
  priv = AuthzFile(os.path.join(dirpath, PRIVATE_AUTHZ))
  return pub, priv


class Template(object):
  def __init__(self, fname):
    contents = open(fname).read()
    self.md5 = md5.md5(contents).hexdigest()
    self.lines = contents.splitlines()
    ### pre-parse

  def find_group(self, group):
    ### pre-parse the file to avoid the linear search. maybe. network time
    ### for LDAP likely outweighs this.
    lead = group + '={ldap:'
    for line in self.lines:
      if line.startswith(lead):
        return line
    raise Exception('referenced group not found: ' + group)


class AuthzFile(object):
  def __init__(self, fname):
    self.fname = fname
    self.exists = os.path.exists(fname)
    self.cache = None
    if self.exists:
      # The first line of the authz file has the cached data.
      line = open(fname).readline().strip()
      if line.startswith('#csn'):
        self.cache = parse_OU_CSN(line)
      else:
        self.exists = False

  def have_CSNs_changed(self, client):
    if not self.cache:
      # There was no cache, so we're definitely out of date
      return True
    for ou, csn in self.cache.items():
      current_csn = get_CSN(client, ou)
      if current_csn != csn:
        return True
    return False

  def generate(self, client, template, reuse):
    new_z = [ '# placeholder for CSN cache',
              ]
    ous = set()  # Track the OUs that we pull data from, and need a CSN for.
    for line in template.lines:
      if line.startswith('#') or '={' not in line:
        new_z.append(line)
      elif '={reuse' in line:
        # Extract which file we will reuse from, and the group to define.
        ### dumb, as we have the group at the start of this line. redundant.
        which, group = REUSE_RE.search(line).groups()
        reuse_line = reuse[which].find_group(group)
        new_z.append(self._group_from_LDAP(client, reuse_line, ous))
      elif '={ldap' in line:
        new_z.append(self._group_from_LDAP(client, line, ous))
      else:
        ### wtf is ={ doing on the line, if not reuse/ldap?
        new_z.append(line)

    # Cache CSNs for each OU that we saw in this file.
    new_z[0] = gen_cache(client, ous)

    # Write to an intermediate file, then do an atomic move into place.
    ### TODO: throw an alert if the new file is "too different" from the old
    tmp = '%s.%d' % (self.fname, os.getpid())
    open(tmp, 'w').write('\n'.join(new_z) + '\n')
    os.rename(tmp, self.fname)

  def _group_from_LDAP(self, client, line, ous):
    m = LDAP_RE.match(line)
    # Extract the four match groups we need. attr may be None.
    group, cn, dn, attr = m.groups()
    # Note that we're holding client-side data for this DN (OU)
    ous.add(dn)
    # Fetch/format the line to define this group from LDAP
    members = get_members(client, cn, dn, attr)
    return group + '=' + ','.join(members)


def gen_cache(client, ous):
  ous = sorted(ous)
  csns = [ ]
  for ou in ous:
    csns.append(get_CSN(client, ou))
  return '#' + ','.join(csns) + '+' + ':'.join(ous)


def parse_OU_CSN(cache_line):
  'Parse cached OU->CSN mapping from the authz file, when it was last written.'

  # skip the leading '#', then cleave the two halves
  csn_str, ou_str = cache_line[1:].split('+')
  csns = csn_str.split(',')
  ous = ou_str.split(':')
  assert len(csns) == len(ous)
  return dict(zip(ous, csns))


def get_CSN(client, ou):
  #print 'OU:', ou
  # We want a Client Synchronization Token
  sync_ctrl = ldap.syncrepl.SyncRequestControl()
  # We don't need any results (so, limit to one). We want the above token.
  page_ctrl = ldap.controls.libldap.SimplePagedResultsControl(size=1, cookie='')

  # Start the query, with the above controls.
  msgid = client.search_ext(ou, ldap.SCOPE_SUBTREE,
                            attrlist=['*'],
                            serverctrls=[sync_ctrl, page_ctrl],
                            )
  # Wait for the result, and get the SyncDoneControl response
  rtype, data, _msgid, ctrls = client.result3(msgid)

  # Ensure we actually got a response. For the correct message.
  assert rtype == ldap.RES_SEARCH_RESULT
  assert msgid == _msgid

  # Should be a SyncDoneControl
  assert len(ctrls) == 1
  assert isinstance(ctrls[0], ldap.syncrepl.SyncDoneControl)
  cookie = ctrls[0].cookie

  # An example of the cookie:
  #   "rid=000,sid=005,csn=20120802221241.953472Z#000000#000#000000;..."
  csn = cookie[cookie.index('csn='):]
  #print 'CSN:', csn
  return csn


def get_members(client, cn, dn, attr):
  if attr:
    attrlist = [ attr ]
  else:
    attrlist = None
  results = client.search_s(dn, scope=ldap.SCOPE_ONELEVEL,
                            filterstr='(cn=%s)' % (cn,),
                            attrlist=attrlist)
  # Should be a single result.
  assert len(results) == 1
  _, data = results[0]
  if attr is None:
    if 'memberUid' in data:
      members = data['memberUid']
    elif 'member' in data:
      members = data['member']
  else:
    members = data[attr]

  # Sometimes the result items look like: uid=FOO,ou=people,...
  # Trim to just the uid values.
  if members[0].startswith('uid='):
    return [ UID_RE.match(m).group(1) for m in members ]
  return members


if __name__ == '__main__':
  # USAGE: gen.py [DIR]
  if len(sys.argv) > 1:
    main(sys.argv[1])
  else:
    main()
