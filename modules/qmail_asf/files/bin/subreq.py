#!/usr/bin/env python

import glob
import json
import logging
import os
import tempfile
import subprocess
import string
import sys

# include common path variables
execfile("common.conf")

from collections import namedtuple
Entry = namedtuple('Entry', 'listkey availid listaddr')

PROGNAME = os.path.basename(sys.argv[0])
logging.getLogger().name = sys.argv[0]

SVN_CONFIG_DIR = 'APMAIL_HOME/.subversion2'

BASEDIR = 'APMAIL_HOME/lists'

class Hooks:
    @staticmethod
    def welcome(entry):
        listkey, availid = entry.listkey, entry.availid
        if 'security' not in listkey and 'trademarks' not in listkey:
            return # DECLINED
        try:
            stdin = tempfile.SpooledTemporaryFile()
            if op == 'sub':
                stdin.write('Welcome %s@!\n'
                            '\n'
                            'You are now subscribed to the privately-archived %s@ mailing list!\n'
                            % (availid, listkey))
            else:
                stdin.write('Welcome %s@!\n'
                            '\n'
                            'You are now unsubscribed from the privately-archived %s@ mailing list!\n'
                            % (availid, listkey))
            stdin.flush()
            stdin.seek(0)
            subprocess.check_call(['mail', '-s', "Welcome %s@!" % availid,
                                   entry.listaddr],
                                  stdin=stdin)
        except Exception as e:
            logging.warn('%s: %s', type(e).__name__, e)

HOOKS = [
  # Hook functions should never raise; if they have a problem, they should
  # log it.  They should return None.
  Hooks.welcome,
]

class Skip(Exception):
    pass

def key2dir(listkey):
    # special processing for empire-db
    if listkey.startswith('empire-db-'):
        base  = 'empire-db'
    else:
        base = listkey.split('-', 1)[0]
    tail = listkey[len(base)+1:]
    dirs = [
        'apache.org/%s' % listkey,
        ['%s.apache.org/%s', '%s.com/%s'][base == 'apachecon'] % (base, tail),
    ]
    dirs = ['%s/%s' % (BASEDIR, d) for d in dirs]
    dirs = filter(os.path.isdir, dirs)
    dirs = filter(lambda d: d[-1] != '/', dirs) # 'community'
    if len(dirs) != 1:
        raise Skip("Wrong number of dirs found for %r: %r" % (listkey, dirs))
    return dirs[0]

def process_entry(fn, op):
    j = json.load(open(fn))
    if j['version'] not in [2,3]:
        raise Skip("Unknown format %r" % j['version'])

    availid = j['availid']
    addr = j['addr']
    listkey = j['listkey']

    # not sure whether leading hyphens are okay, so forbid them
    assert addr[0] in string.letters + string.digits + '_'

    listdir = key2dir(listkey)
    assert os.path.isabs(listdir)
    mop = '+=' if op != 'unsub' else '-='
    logging.info("%s@ %s %s", listkey, mop, availid)
    subprocess.check_call([
        'ezmlm-' + op,
        '-n',
        listdir, '.',
        addr, 'via:%s' % PROGNAME,
    ])
    listaddr = open(os.path.join(listdir, 'outlocal')).read().rstrip() + "@" + \
               open(os.path.join(listdir, 'outhost')).read().rstrip()
    return Entry(listkey=listkey, availid=availid, listaddr=listaddr)

def run_hooks(entry, hooks):
    for hook in hooks:
        try:
            hook(entry)
        except Exception as e:
            # Violation of hook API.
            logging.error("Hook raised an exception: "
                          "hook=(%s, %r), exception=(%s, %s)",
                          getattr(hook, 'func_name'), hook,
                          type(e).__name__, e)

def main(op):
    os.chdir('APMAIL_HOME/' + op + 'req')
    success = set()
    for fn in sys.argv[1:] or glob.glob('*.json'):
        try:
            entry = process_entry(fn, op)
        except Skip as skip:
            logging.warn('Skipped %r: %s' % (fn, skip.message))
        else:
            subprocess.check_call(['svn', 'rm', '--quiet', '--', fn])
            success.add(entry)
    for entry in success:
        run_hooks(entry, HOOKS)
    mop = '+=' if op != 'unsub' else '-='
    subprocess.check_call([
        'svn', 'commit', '--quiet', '--config-dir', SVN_CONFIG_DIR,
        '-m', 'Process requests:\n' + '\n'.join(sorted(
                 '%s@ %s %s' % (entry.listkey, mop, entry.availid)
                 for entry in success)),
    ])

if __name__ == '__main__':
    main('sub')
    main('unsub')
