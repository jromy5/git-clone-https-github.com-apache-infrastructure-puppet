#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
This is the ES library for PicoAPI.
It stores the elasticsearch handler and config options.
"""


# Main imports
import cgi
import re
#import aaa
import elasticsearch

class AimAPIDatabase(object):
    def __init__(self, config):
        self.config = config
        self.dbname = config['elasticsearch']['dbname']
        self.ES = elasticsearch.Elasticsearch([{
                'host': config['elasticsearch']['host'],
                'port': int(config['elasticsearch']['port']),
                'use_ssl': config['elasticsearch']['ssl'],
                'verify_certs': False,
                'url_prefix': config['elasticsearch']['uri'] if 'uri' in config['elasticsearch'] else '',
                'http_auth': config['elasticsearch']['auth'] if 'auth' in config['elasticsearch'] else None
            }],
                max_retries=5,
                retry_on_timeout=True
            )
