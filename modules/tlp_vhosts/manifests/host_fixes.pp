
class tlp_vhosts::host_fixes inherits tlp_vhosts {

    apache::vhost { 'cloudstack':
        port => 80,
        servername => 'www.cloudstack.org',
        serveraliases => ['cloudstack.org', 'cloudstack.com', 'www.cloudstack.com'],
        docroot => '/var/www/cloudstack.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://cloudstack.apache.org']
    }

    apache::vhost { 'cloudstack-docs':
        port => 80,
        servername => 'docs.cloudstack.org',
        docroot => '/var/www/cloudstack.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://cloudstack.apache.org/docs/'],
    }

    apache::vhost { 'deltaspike':
        port => 80,
        servername => 'www.deltaspkie.org',
        serveraliases => ['deltaspkie.org'],
        docroot => '/var/www/delatspkie.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://deltaspike.apache.org'],
    }

    apache::vhost { 'www-jspwiki':
        port => 80,
        servername => 'www.jspwiki.org',
        serveraliases => ['jspwiki.org'],
        docroot => '/var/www/jspwiki.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://jspwiki.apache.org/'],
    }

    apache::vhost { 'libcloud':
        port => 80,
        servername => 'www.libcloud.org',
        serveraliases => ['libcloud.org', 'www.libcloud.net', 'libcloud.net', 'www.libcloud.com', 'libcloud.com'],
        docroot => '/var/www/libcloud.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://libcloud.apache.org/'],
    }

    apache::vhost { 'odftoolkit':
        port => 80,
        servername => 'www.odftoolkit.org',
        serveraliases => ['odftoolkit.org', 'www.odf-toolkit.com', 'odf-toolkit.com', 'www.odf-toolkit.net', 'odf-toolkit.net',
                            'www.odf-toolkit.org', 'odf-toolkit.org', 'www.odfcoalition.com', 'odfcoalition.com',
                            'www.odfcoalition.net',  'odfcoalition.net', 'www.odfcoalition.org', 'odfcoalition.org',
                            'www.odftoolkit.com', 'odftoolkit.com', 'www.odftoolkit.net', 'odftoolkit.net'],
        docroot => '/var/www/incubator.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://incubator.apache.org/odftoolkit/'],
    }

    apache::vhost { 'spamassassin-redirect':
        port => 80,
        servername => 'ServerName www.spamassassin.org',
        serveraliases => ['spamassassin.org', 'au.spamassassin.org', 'au2.spamassassin.org',
                            'eu.spamassassin.org', 'eu2.spamassassin.org', 'eu3.spamassassin.org',
                            'ie.spamassassin.org', 'news.spamassassin.org', 'uk.spamassassin.org',
                            'us.spamassassin.org', 'useast.spamassassin.org', 'uswest.spamassassin.org',
                            'www.au.spamassassin.org', 'www.au2.spamassassin.org', 'www.eu.spamassassin.org',
                            'www.eu2.spamassassin.org', 'www.eu3.spamassassin.org',   'www.ie.spamassassin.org',
                            'www.uk.spamassassin.org', 'www.us.spamassassin.org', 'www.useast.spamassassin.org',
                            'www.uswest.spamassassin.org'],
        docroot => '/var/www/spamassassin.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://spamassassin.apache.org/'],
    }

    apache::vhost { 'wiki-spamassassin':
        port => 80,
        servername => 'wiki.spamassassin.org',
        docroot => '/var/www/spamassassin.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/w/', '/'],
        redirect_dest => [' http://wiki.apache.org/spamassassin/', 'http://wiki.apache.org/spamassassin/'], 
    }

    apache::vhost { 'subversion':
        port => 80,
        servername => 'ServerName www.subversion.org',
        docroot => '/var/www/subversion.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirectmatch_regexp => ['^'],
        redirectmatch_dest => ['http://subversion.apache.org/'],
    }

    apache::vhost { 'svn.collab':
        port => 80,
        servername => 'svn.collab.net',
        docroot => '/var/www/subversion.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirectmatch_regexp => ['^'],
        redirectmatch_dest => ['https://subversion.apache.org/source-code'],
    }

    apache::vhost { 'webservices':
        port => 80,
        servername => 'webservices.apache.org',
        serveraliases => 'webservices.*.apache.org',
        docroot => '/var/www/ws.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://ws.apache.org/'],
    }

    apache::vhost { 'ofbiz':
        port => 80,
        servername => 'www.ofbiz.org',
        serveraliases => ['ofbiz.org'],
        docroot => '/var/www/ofbiz.apache.org', # apache puppet module requires a docroot defined
        rewrites => [
            {
                comment => 'bigfiles.ofbiz.org',
                rewrite_cond => ['${lowercase:%{HTTP_HOST}} ^bigfiles(?:\.\w+)?\.ofbiz\.org$'],
                rewrite_rule => ['(.*) http://ofbiz-bigfiles.apache.org/ [L]'],
            },
        ],
    }

    apache::vhost { 'myfaces':
        port => 80,
        servername => 'www.myfaces.org',
        serveraliases => ['myfaces.org'],
        docroot => '/var/www/myfaces.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://myfaces.apache.org'],
    }

    apache::vhost { 'httpcomponents':
        port => 80,
        servername => 'httpcomponents.apache.org',
        serveraliases => ['httpcomponents.*.apache.org'],
        docroot => '/var/www/hc.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://hc.apache.org/'],
    }

    apache::vhost { 'wicket':
        port => 80,
        servername => 'wicketframework.org',
        serveraliases => ['wicket-framework.org'],
        docroot => '/var/www/wicket.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://wicket.apache.org/'], 
    }

    apache::vhost { 'quetz':
        port => 80,
        servername => 'quetzalcoatl.apache.org',
        serveraliases => ['python.apache.org'],
        docroot => '/var/www/quetz.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://quetz.apache.org/'],
    }

    apache::vhost { 'jackrabbit':
        port => 80,
        servername => 'jackrabbit.apache.org',
        serveraliases => ['jackrabbit.*.apache.org'],
        docroot => '/var/www/jackrabbit.apache.org', # apache puppet module requires a docroot defined
        rewrites => [ { rewrite_rule => ['^/favicon.ico /var/www/jackrabbit.apache.org/favicon.ico'] } ],
    }

    apache::vhost { 'jclouds':
        port => 80,
        servername => 'www.jclouds.org',
        serveraliases => ['www.jclouds.net', 'www.jclouds.com', 'jclouds.org', 'jclouds.net', 'jclouds.com'],
        docroot => '/var/www/jclouds.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['http://jclouds.apache.org/'],
    }

}
