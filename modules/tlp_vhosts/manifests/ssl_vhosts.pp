
class tlp_vhosts::ssl_vhosts inherits tlp_vhosts {


    apache::vhost { 'tlp-ssl':
        priority => '99',
        vhost_name => '*',
        servername => 'www.apache.org',
        port => '443',
        ssl => true,
        virtual_docroot => '/var/www/%1.0.apache.org',
        docroot => '/var/www',
        directories => [
            { path => '/var/www',
              options => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'],
              allow_override => ['All'],
              addhandlers => [{ handler => 'cgi-script', extensions => ['.cgi']}],
            },
        ],
        serveraliases => ['*.apache.org'],
        custom_fragment => '
        VirtualScriptAlias /var/www/%1.0.apache.org/cgi-bin
        UseCanonicalName Off
        Use CatchAll
        ',
    }
#
#    apache::vhost { 'incubator':
#        vhost_name => '*',
#        servername => 'www.apache.org',
#        port => '80',
#        virtual_docroot => '/var/www/%1.0.apache.org',
#        docroot => '/var/www',
#        directories => [
#            { path => '/var/www',
#              options => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'],
#              allow_override => ['All'],
#              addhandlers => [{ handler => 'cgi-script', extensions => ['.cgi']}],
#            },
#        ],
#        serveraliases => ['*.incubator.apache.org', '*.incubator.*.apache.org'],
#        custom_fragment => '
#        VirtualScriptAlias /var/www/%1.0.apache.org/cgi-bin
#        UseCanonicalName Off
#        Use CatchAll
#        ',
#    }
#
#    apache::vhost { 'aoo':
#        port => 443,
#        servername => 'www.openoffice.org',
#        serveraliases => ['ooo-site.apache.org', '*.openoffice.org', 'openoffice.org'],
#        docroot => '/var/www/ooo-site.apache.org/content',
#        custom_fragment => '
#        Use OpenOffice http
#        ',
#    }

    apache::vhost { 'uima-ssl':
        port => 443,
        ssl => true,
        servername => 'uima.apache.org',
        serveraliases => ['uima.*.apache.org'],
        docroot => '/var/www/uima.apache.org/pubsub',
        directories => [
            {
                path => '/var/www/uima.apache.org/pubsub',
                options => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'],
                addhandlers => [{ handler => 'cgi-script', extensions => ['.cgi']}],
            },
        ],
    }

    apache::vhost { 'tomee-ssl':
        port => 443,
        ssl => true,
        servername => 'tomee.apache.org',
        serveraliases => ['tomee.*.apache.org', 'openejb.apache.org', 'openejb.*.apache.org'],
        docroot => '/var/www/tomee.apache.org/content',
        rewrites => [ { rewrite_rule => ['^/favicon.ico /var/www/tomee.apache.org/content/favicon.ico'] } ],
        scriptalias => '/cgi-bin/ /x1/www/tomee.apache.org/cgi-bin/',
    }

    apache::vhost { 'spamassassin-ssl':
        port => 443,
        ssl => true,
        servername => 'spamassassin.apache.org',
        serveraliases => ['spamassassin.*.apache.org'],
        docroot => '/var/www/spamassassin.apache.org',
        directories => [
            {
                path => '/var/www/spamassassin.apache.org',
                options => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'],
                addhandlers => [{ handler => 'cgi-script', extensions => ['.cgi']}],
            },
        ],
        rewrites => [
            { rewrite_rule => ['^/favicon.ico /var/www/spamassassin.apache.org/images/favicon.ico'], }
        ],
    }

    apache::vhost { 'xml-ssl':
        port => 443,
        ssl => true,
        servername => 'xml.apache.org',
        serveraliases => ['xml.*.apache.org'],
        docroot=> '/var/www/xml.apache.org',
        redirect_status => ['permanent'],
        redirect_source => ['/websrc/', '/from-cvs/'],
        redirect_dest => ['https://cvs.apache.org/', 'https://cvs.apache.org/snapshots/'],
        custom_fragment => '
        # prevent some loops that robots get stuck in
        <Location /xalan/samples/applet>
            deny from all
        </Location>
        <LocationMatch /xerces-c/faq-other.html/.*>
            deny from all
        </LocationMatch>
        ',
    }

    apache::vhost { 'ws-ssl':
        port => 443,
        ssl => true,
        servername => 'ws.apache.org',
        serveraliases => ['ws.*.apache.org'],
        docroot => '/var/www/ws.apache.org',
        redirect_status => ['permanent'],
        redirect_source => ['/xml-rpc'],
        redirect_dest => ['https://ws.apache.org/xmlrpc'],
    }

    apache::vhost { 'xalan-ssl':
        port => 443,
        ssl => true,
        servername => 'xalan.apache.org',
        serveraliases => ['xalan.*.apache.org'],
        docroot => '/var/www/xalan.apache.org',
        custom_fragment =>'
        <Location /xalan/samples/applet>
            deny from all
        </Location>
        ',
    }

    apache::vhost { 'xerces-ssl':
        port => 443,
        ssl => true,
        servername => 'xerces.apache.org',
        serveraliases => 'xerces.*.apache.org',
        docroot => '/var/www/xerces.apache.org',
        custom_fragment => '
        <LocationMatch /xerces-c/faq-other.html/.*>
            deny from all
        </LocationMatch>
        ',
    }

    apache::vhost { 'perl-ssl':
        port => 443,
        ssl => true,
        servername => 'perl.apache.org',
        serveraliases => ['apache.perl.org', 'perl-new.apache.org', 'perl.*.apache.org'],
        docroot => '/var/www/perl.apache.org',
        setenv => ['SWISH_BINARY_PATH /usr/bin/swish-e'],
        directories => [
                { path => '/var/www/perl.apache.org',
                  options => ['+ExecCGI'],
                },
        ],
        redirect_status => ['permanent'],
        redirect_source => ['/from-cvs/', '/guide', '/src/mod_perl.html', '/src/apache-modlist.html', '/src/cgi_to_mod_perl.html',
                            '/src/mod_perl_traps.html', '/dist/mod_perl.html', '/dist/apache-modlist.html', '/dist/cgi_to_mod_perl.html',
                            '/dist/mod_perl_traps.html', '/faq/mod_perl_cgi.html', '/mod_perl_cvs.html', '/faq/index.html', '/tuning/index.html',
                            '/faq/mod_perl_api.html', '/features/tmpl-cmp.html', '/perl_myth.html', '/perl_myth.pod', '/faq/mjtg-news.txt',
                            '/faq/mod_perl_api.pod', '/faq/mod_perl_cgi.pod', '/faq/mod_perl_faq.html', '/faq/mod_perl_faq.pod',
                            '/faq/mod_perl_faq.tar.gz', '/distributions.html', '/tidbits.html', '/products.html', '/isp.html', '/sites.html',
                            '/stories/index.html', '/stories/ColbyChem.html', '/stories/France-Presse.html', '/stories/adultad.html',
                            '/stories/bsat.html', '/stories/idl-net.html', '/stories/imdb.html', '/stories/lind-waldock.html',
                            '/stories/presto.html', '/stories/seds-org.html', '/stories/singlesheaven.html', '/stories/tgix.html',
                            '/stories/uber-alles.html', '/stories/webby.html', '/stories/winamillion.html', '/stories/wmboerse.html',
                            '/win32_binaries.html', '/win32_binaries.pod', '/win32_compile.html', '/win32_compile.pod', '/win32_multithread.html',
                            '/win32_multithread.pod', '/email-etiquette.html', '/jobs.html', '/netcraft/index.html', '/logos/index.html',
                            '/Embperl/', '/perl/Embperl/', '/embperl.html', '/asp', '/CREDITS.html', '/contribute/cvs_howto.html', '/bench.txt',
                            '/email-etiquette.pod', '/embperl.html', '/faqs.html'],
        redirect_dest => ['https://cvs.apache.org/snapshots/', 'https://perl.apache.org/docs/1.0/guide', 'https://perl.apache.org/docs/index.html',
                        'https://perl.apache.org/products/apache-modules.html', 'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/docs/index.html',
                        'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/products/apache-modules.html', 'https://perl.apache.org/docs/index.html',
                        'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/contribute/svn_howto.html',
                        'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/docs/index.html',
                        'https://perl.apache.org/docs/tutorials/tmpl/comparison/comparison.html', 'https://perl.apache.org/docs/general/perl_myth.html',
                        'https://perl.apache.org/docs/general/perl_myth.pod.orig', 'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/docs/index.html',
                        'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/docs/index.html',
                        'https://perl.apache.org/docs/index.html', 'https://perl.apache.org/download/index.html', 'https://perl.apache.org/docs/offsite/articles.html',
                        'https://perl.apache.org/products/index.html', 'https://perl.apache.org/help/isps.html', 'https://perl.apache.org/outstanding/sites.html',
                        'https://perl.apache.org/outstanding/success_stories/index.html', 'https://perl.apache.org/outstanding/success_stories/colbychem.html',
                        'https://perl.apache.org/outstanding/success_stories/www.afp-direct.com.html', 'https://perl.apache.org/outstanding/success_stories/adultad.html',
                        'https://perl.apache.org/outstanding/success_stories/bsat.html', 'https://perl.apache.org/outstanding/success_stories/idl-net.html',
                        'https://perl.apache.org/outstanding/success_stories/imdb.com.html', 'https://perl.apache.org/outstanding/success_stories/www.lind-waldock.com.html',
                        'https://perl.apache.org/outstanding/success_stories/presto.html', 'https://perl.apache.org/outstanding/success_stories/seds.org.html',
                        'https://perl.apache.org/outstanding/success_stories/singlesheaven.com.html', 'https://perl.apache.org/outstanding/success_stories/tgix.html',
                        'https://perl.apache.org/outstanding/success_stories/openscape.org.html', 'https://perl.apache.org/outstanding/success_stories/imdb.com.html',
                        'https://perl.apache.org/outstanding/success_stories/winamillion.msn.com.html', 'https://perl.apache.org/outstanding/success_stories/wmboerse.html',
                        'https://perl.apache.org/docs/1.0/os/win32/index.html', 'https://perl.apache.org/docs/1.0/os/win32/index.html',
                        'https://perl.apache.org/docs/1.0/os/win32/index.html', 'https://perl.apache.org/docs/1.0/os/win32/index.html',
                        'https://perl.apache.org/docs/1.0/os/win32/multithread.html', 'https://perl.apache.org/docs/1.0/win32/multithread.pod.orig',
                        'https://perl.apache.org/maillist/email-etiquette.html', 'https://perl.apache.org/jobs/jobs.html', 'https://perl.apache.org/outstanding/stats/netcraft.html',
                        'https://perl.apache.org/about/link/linktous.html', 'https://perl.apache.org/embperl/', 'https://perl.apache.org/embperl/', 'https://perl.apache.org/embperl/',
                        'https://www.apache-asp.org/', 'https://perl.apache.org/about/contributors/people.html', 'https://perl.apache.org/contribute/svn_howto.html',
                        'https://www.chamas.com/bench/', 'https://perl.apache.org/maillist/email-etiquette.pod.orig', 'https://perl.apache.org/embperl/',
                        'https://perl.apache.org/docs/offsite/index.html'],
        custom_fragment => '
            XBithack Full
            <IfDefine !MINOTAUR>
                ProxyPass /search https://140.211.11.10/search
                ProxyPreserveHost on
            </IfDefine>
        ',
    }

    apache::vhost { 'jspwiki-ssl':
        port => 443,
        ssl => true,
        servername => 'jspwiki.apache.org',
        docroot => '/var/www/jspwiki.apache.org/content',
        redirect_status => ['permanent'],
        redirect_source => ['/doc', '/wiki'],
        redirect_dest => ['https://jspwiki-doc.apache.org', 'https://jspwiki-wiki.apache.org'],
    }

    apache::vhost { 'gump-ssl':
        port => 443,
        ssl => true,
        servername => 'gump.apache.org',
        serveraliases => ['gump.*.apache.org'],
        docroot => '/var/www/gump.apache.org',
        custom_fragment => '
            #
            # Start the expires heading
            #
            ExpiresActive On

            #
            # If the responses dont already contain expiration headers
            # make sure to set them, so that we dont get hit back
            # with resources of this type since they are not going
            # to change that frequently anyway
            #
            ExpiresByType text/css "access plus 1 day"
            ExpiresByType text/javascript "access plus 1 day"
            ExpiresByType image/gif "access plus 1 day"
            ExpiresByType image/jpeg "access plus 1 day"
            ExpiresByType image/png "access plus 1 day"

            # *** This httpd install does not contain mod_deflate ***
            # Enable response deflation in those browsers that support it
            # and for those resources that are no already compressed
            # (since it would result in expansion rather than compression)
            # Also, make sure that proxies understand that this response
            # varies with the user agent so they dont cache results of
            # one browser for another one
            #
            #<Location />
            #  SetOutputFilter deflate
            #  BrowserMatch ^Mozilla/4         gzip-only-text/html
            #  BrowserMatch ^Mozilla/4\.0[678] no-gzip
            #  BrowserMatch \bMSIE             !no-gzip !gzip-only-text/html
            #  SetEnvIfNoCase Request_URI     .(?:gif|jpe?g|png)$ no-gzip dont-vary
            #  Header append Vary User-Agent env=!dont-vary
            #</Location>

            RewriteEngine On
            RewriteOptions inherit
        ',
    }

    apache::vhost { 'apache.org-ssl':
        port => 443,
        ssl => true,
        servername => 'www.apache.org',
        serveraliases => ['apache.org', 'apachegroup.org', 'www.apachegroup.org', 'www.*.apache.org'],
        docroot => '/var/www/www.apache.org/content',
        redirect_status => ['permanent'],
        redirect_source => [
            '/docs/vif.info',
            '/docs/directives.html',
            '/docs/API.html',
            '/docs/FAQ.html',
            '/manual-index.cgi/docs',
            '/bugdb.cgi/',
            '/bugdb.cgi',
            '/Conference1998',
            '/java',
            '/perl',
            '/docs/manual',
            '/docs',
            '/httpd',
            '/httpd/',
            '/httpd.html',
            '/index/full',
            '/info/css-security',
            '/websrc/',
            '/from-cvs/',
            '/travel/application'
        ],
        redirect_dest => [
            'https://httpd.apache.org/docs/misc/vif-info',
            'https://httpd.apache.org/docs/mod/directives.html',
            'https://httpd.apache.org/docs/misc/API.html',
            'https://httpd.apache.org/docs/misc/FAQ.html',
            'https://www.apache.org/search.html',
            'https://bugs.apache.org/index/',
            'https://bugs.apache.org/',
            'https://www.apachecon.com',
            'https://archive.apache.org/dist/java/',
            'https://perl.apache.org',
            'https://httpd.apache.org/docs',
            'https://httpd.apache.org/docs',
            'https://httpd.apache.org',
            'https://httpd.apache.org/',
            'https://httpd.apache.org/',
            'https://www.apache.org',
            'https://httpd.apache.org/info/css-security',
            'https://cvs.apache.org/',
            'https://cvs.apache.org/snapshots/',
            'https://tac-apply.apache.org'
        ],
        redirectmatch_status => ['permanent'],
        redirectmatch_regexp => ['^/LICENSE.*', '/flyers(.*)'],
        redirectmatch_dest => ['https://www.apache.org/licenses/', 'https://www.apache.org/foundation/contributing.html'],
        custom_fragment => '
            RewriteEngine on
            RewriteOptions inherit
            RewriteRule /docs/mod_(.*)$ https://httpd.apache.org/docs/mod/mod_$1 [R=permanent]

            # Grab referals from www.apache.com and explain where
            # they landed.
            RewriteCond %{HTTP_REFERER} ^https://([^/]*\.)?apache\.com/
            RewriteRule ^/dist/.* https://www.apache.org/info/referer-dotcom.html [R,L]

            # odd ddos coming from aouu.com
            RewriteCond %{HTTP_REFERER} aouu.com
            RewriteRule ^ - [F,L]

            <IfModule mod_expires.c>
                ExpiresActive On
                ExpiresDefault A3600
            </IfModule>
        ',

    }

    apache::vhost { 'httpd-ssl':
        port => 443,
        ssl => true,
        servername => 'httpd.apache.org',
        serveraliases => ['httpd.*.apache.org'],
        docroot => '/var/www/httpd.apache.org/content',
        directories => [
            { path => '/var/www/httpd.apache.org/content',
              options => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'],
              addhandlers => [{ handler => 'cgi-script', extensions => ['.cgi']}],
            },
        ],
        custom_fragment => '
        AddLanguage da .da
        AddDefaultCharset off
        
        <Directory /var/www/httpd.apache.org/content/docs/1.3>
            SSILegacyExprParser on
            <Files ~ "\.html">
                SetOutputFilter INCLUDES
            </Files>
        </Directory>
        
        # virtualize the language sub"directories"
        AliasMatch ^(/docs/(?:2\.[0-6]|trunk))(?:/(?:da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn))?(/.*)?$ \
        /var/www/httpd.apache.org/content$1$2
        
        # Add an alias, so that /docs/current/ -> /docs/2.4/
        # and virtualize the language sub"directories"
        AliasMatch ^(/docs)/current(?:/(?:da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn))?(/.*)?$ \
            /var/www/httpd.apache.org/content$1/2.4$2
        
        <DirectoryMatch "/var/www/httpd.apache.org/content/docs/(2\.[0-6]|trunk)">
            Options -Multiviews
            <Files *.html>
                SetHandler type-map
            </Files>
            # .tr is text/troff in mime.types!
            <Files *.html.tr.utf8>
                ForceType "text/html; charset=utf-8"
            </Files>
            
            # Tell mod_negotiation which language to prefer
            SetEnvIf Request_URI   ^/docs/(?:2\.[0-6]|trunk|current)/(da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn)/ \
                prefer-language=$1
            
            # Deal with language switching (/docs/2.0/de/en/... -> /docs/2.0/en/...)
            RedirectMatch 301 ^(/docs/(?:2\.[0-6]|trunk|current))(?:/(da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn)){2,}(/.*)?$ \
                $1/$2$3
        </DirectoryMatch>
        
        # virtualize the language sub"directories"
        AliasMatch ^(/mod_ftp)(?:/(?:da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn))?(/.*)?$ \
            /var/www/httpd.apache.org/content$1$2
        
        <DirectoryMatch "/var/www/httpd.apache.org/content/mod_ftp/[\w.]+">
            Options -Multiviews
            <FilesMatch "^[^.]+\.html$">
                SetHandler type-map
            </FilesMatch>
            #  .tr is text/troff in mime.types!
            <Files *.html.tr.utf8>
                ForceType "text/html; charset=utf-8"
            </Files>
            
            # Tell mod_negotiation which language to prefer
            SetEnvIf Request_URI   ^/mod_ftp/(da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn)/ \
                prefer-language=$1
            
            # Deal with language switching (/mod_ftp/de/en/... -> /mod_ftp/en/...)
            RedirectMatch 301 ^(/mod_ftp)(?:/(da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn)){2,}(/.*)?$ \
                $1/$2$3
            
            # Now fail-over for all not-founds from /mod_ftp/... into /docs/trunk/...
            # since we point to httpd doc pages for reference.
            RewriteEngine On
            RewriteBase /mod_ftp
            RewriteOptions inherit
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^(.+) https://httpd.apache.org/docs/trunk/$1 [R=301,L]
        </DirectoryMatch>
        
        # virtualize the language sub"directories"
        AliasMatch ^(/mod_fcgid)(?:/(?:da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn))?(/.*)?$ \
            /var/www/httpd.apache.org/content$1$2
        
        <DirectoryMatch "/var/www/httpd.apache.org/content/mod_fcgid/[\w.]+">
            Options -Multiviews
            <FilesMatch "^[^.]+\.html$">
                SetHandler type-map
            </FilesMatch>
            #  .tr is text/troff in mime.types!
            <Files *.html.tr.utf8>
                ForceType "text/html; charset=utf-8"
            </Files>
            
            # Tell mod_negotiation which language to prefer
            SetEnvIf Request_URI   ^/mod_fcgid/(da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn)/ \
                prefer-language=$1
            
            # Deal with language switching (/mod_fcgid/de/en/... -> /mod_fcgid/en/...)
            RedirectMatch 301 ^(/mod_fcgid)(?:/(da|de|en|es|fr|ja|ko|pt-br|ru|tr|zh-cn)){2,}(/.*)?$ \
                $1/$2$3
            
            # Now fail-over for all not-founds from /mod_fcgid/... into /docs/trunk/...
            # since we point to httpd doc pages for reference.
            RewriteEngine On
            RewriteBase /mod_fcgid
            RewriteOptions inherit
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^(.+) https://httpd.apache.org/docs/trunk/$1 [R=301,L]
        </DirectoryMatch>
        
        RewriteEngine On
        RewriteOptions inherit
        
        # If it isnt a specific version or asking for trunk, give it current
        RewriteCond $1 !^(1|2|trunk|index|current)
        RewriteRule ^/docs/(.+) /docs/current/$1 [R=301,L]
        
        # Convert docs-2.x -> docs/2.x
        RewriteRule ^/docs-2\.(.)/(.*) /docs/2.$1/$2 [R=301,L]
        ',
    }


    ## Host redirect fixes

    apache::vhost { 'cloudstack-ssl':
        port => 443,
        ssl => true,
        servername => 'www.cloudstack.org',
        serveraliases => ['cloudstack.org', 'cloudstack.com', 'www.cloudstack.com'],
        docroot => '/var/www/cloudstack.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://cloudstack.apache.org']
    }

    apache::vhost { 'cloudstack-docs-ssl':
        port => 443,
        ssl => true,
        servername => 'docs.cloudstack.org',
        docroot => '/var/www/cloudstack.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://cloudstack.apache.org/docs/'],
    }

    apache::vhost { 'deltaspike-ssl':
        port => 443,
        ssl => true,
        servername => 'www.deltaspkie.org',
        serveraliases => ['deltaspkie.org'],
        docroot => '/var/www/delatspkie.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://deltaspike.apache.org'],
    }

    apache::vhost { 'www-jspwiki-ssl':
        port => 443,
        ssl => true,
        servername => 'www.jspwiki.org',
        serveraliases => ['jspwiki.org'],
        docroot => '/var/www/jspwiki.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://jspwiki.apache.org/'],
    }

    apache::vhost { 'libcloud-ssl':
        port => 443,
        ssl => true,
        servername => 'www.libcloud.org',
        serveraliases => ['libcloud.org', 'www.libcloud.net', 'libcloud.net', 'www.libcloud.com', 'libcloud.com'],
        docroot => '/var/www/libcloud.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://libcloud.apache.org/'],
    }

    apache::vhost { 'odftoolkit-ssl':
        port => 443,
        ssl => true,
        servername => 'www.odftoolkit.org',
        serveraliases => ['odftoolkit.org', 'www.odf-toolkit.com', 'odf-toolkit.com', 'www.odf-toolkit.net', 'odf-toolkit.net',
                            'www.odf-toolkit.org', 'odf-toolkit.org', 'www.odfcoalition.com', 'odfcoalition.com',
                            'www.odfcoalition.net',  'odfcoalition.net', 'www.odfcoalition.org', 'odfcoalition.org',
                            'www.odftoolkit.com', 'odftoolkit.com', 'www.odftoolkit.net', 'odftoolkit.net'],
        docroot => '/var/www/incubator.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://incubator.apache.org/odftoolkit/'],
    }

    apache::vhost { 'spamassassin-redirect-ssl':
        port => 443,
        ssl => true,
        servername => 'www.spamassassin.org',
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
        redirect_dest => ['https://spamassassin.apache.org/'],
    }

    apache::vhost { 'wiki-spamassassin-ssl':
        port => 443,
        ssl => true,
        servername => 'wiki.spamassassin.org',
        docroot => '/var/www/spamassassin.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/w/', '/'],
        redirect_dest => [' https://wiki.apache.org/spamassassin/', 'https://wiki.apache.org/spamassassin/'], 
    }

    apache::vhost { 'subversion-ssl':
        port => 443,
        ssl => true,
        servername => 'www.subversion.org',
        docroot => '/var/www/subversion.apache.org', # apache puppet module requires a docroot defined
        redirectmatch_status => ['permanent'],
        redirectmatch_regexp => ['^'],
        redirectmatch_dest => ['https://subversion.apache.org/'],
    }

    apache::vhost { 'svn.collab-ssl':
        port => 443,
        ssl => true,
        servername => 'svn.collab.net',
        docroot => '/var/www/subversion.apache.org', # apache puppet module requires a docroot defined
        redirectmatch_status => ['permanent'],
        redirectmatch_regexp => ['^'],
        redirectmatch_dest => ['https://subversion.apache.org/source-code'],
    }

    apache::vhost { 'webservices-ssl':
        port => 443,
        ssl => true,
        servername => 'webservices.apache.org',
        serveraliases => 'webservices.*.apache.org',
        docroot => '/var/www/ws.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://ws.apache.org/'],
    }

    apache::vhost { 'ofbiz-ssl':
        port => 443,
        ssl => true,
        servername => 'www.ofbiz.org',
        serveraliases => ['ofbiz.org'],
        docroot => '/var/www/ofbiz.apache.org', # apache puppet module requires a docroot defined
        rewrites => [
            {
                comment => 'bigfiles.ofbiz.org',
                rewrite_cond => ['${lowercase:%{HTTP_HOST}} ^bigfiles(?:\.\w+)?\.ofbiz\.org$'],
                rewrite_rule => ['(.*) https://ofbiz-bigfiles.apache.org/ [L]'],
            },
        ],
    }

    apache::vhost { 'myfaces-ssl':
        port => 443,
        ssl => true,
        servername => 'www.myfaces.org',
        serveraliases => ['myfaces.org'],
        docroot => '/var/www/myfaces.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://myfaces.apache.org'],
    }

    apache::vhost { 'httpcomponents-ssl':
        port => 443,
        ssl => true,
        servername => 'httpcomponents.apache.org',
        serveraliases => ['httpcomponents.*.apache.org'],
        docroot => '/var/www/hc.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://hc.apache.org/'],
    }

    apache::vhost { 'wicket-ssl':
        port => 443,
        ssl => true,
        servername => 'wicketframework.org',
        serveraliases => ['wicket-framework.org'],
        docroot => '/var/www/wicket.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://wicket.apache.org/'], 
    }

    apache::vhost { 'quetz-ssl':
        port => 443,
        ssl => true,
        servername => 'quetzalcoatl.apache.org',
        serveraliases => ['python.apache.org'],
        docroot => '/var/www/quetz.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://quetz.apache.org/'],
    }

    apache::vhost { 'jackrabbit-ssl':
        port => 443,
        ssl => true,
        servername => 'jackrabbit.apache.org',
        serveraliases => ['jackrabbit.*.apache.org'],
        docroot => '/var/www/jackrabbit.apache.org', # apache puppet module requires a docroot defined
        rewrites => [ { rewrite_rule => ['^/favicon.ico /var/www/jackrabbit.apache.org/favicon.ico'] } ],
    }

    apache::vhost { 'jclouds-ssl':
        port => 443,
        ssl => true,
        servername => 'www.jclouds.org',
        serveraliases => ['www.jclouds.net', 'www.jclouds.com', 'jclouds.org', 'jclouds.net', 'jclouds.com'],
        docroot => '/var/www/jclouds.apache.org', # apache puppet module requires a docroot defined
        redirect_status => ['permanent'],
        redirect_source => ['/'],
        redirect_dest => ['https://jclouds.apache.org/'],
    }

}
