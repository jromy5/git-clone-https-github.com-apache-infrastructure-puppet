#!/usr/bin/python

import sys
import re
import os.path

import ezt

DB_FNAME = 'dirty.db'
TEMPLATE_FNAME = 'pads.ezt'

RE_PADS = re.compile('^{"key":"pad:([^:"]*)')


def gen_page(pads, template_path):
  data = {
    'pads': sorted(pads),
    }

  print('Content-Type: text/html')
  print('')

  template = ezt.Template(template_path, base_format=ezt.FORMAT_HTML)
  template.generate(sys.stdout, data)


def get_pads(db_path):
  pads = set()
  for line in open(db_path).readlines():
    m = RE_PADS.match(line)
    if m:
      pads.add(m.group(1))
  return pads


if __name__ == '__main__':
  this_dir = os.path.dirname(__file__)
  db_path = os.path.join(this_dir, os.path.pardir, DB_FNAME)
  pads = get_pads(db_path)
  #print '\n'.join(sorted(pads))
  template_path = os.path.join(this_dir, TEMPLATE_FNAME)
  gen_page(pads, template_path)
