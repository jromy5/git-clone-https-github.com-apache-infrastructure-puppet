
class tlp_vhosts::config inherits tlp_vhosts {


    apache::mod { 'macro': }

    apache::custom_config { 'tlp_macro':
        ensure => present,
        source => 'puppet:///modules/tlp_vhosts/tlp_macro',
    }
 
    apache::mod { 'rewrite': }

    apache::vhost { 'tlp':
        vhost_name => '*',
        servername => 'www.apache.org',
        port => '80',
        virtual_docroot => '/var/www/%1.0.apache.org',
        docroot => '/var/www',
        override => ['FileInfo'],
        serveraliases => ['*.apache.org'],
        custom_fragment => '
        VirtualScriptAlias /var/www/%1.0.apache.org/cgi-bin
        UseCanonicalName Off
        Use CatchAll
        ',
    }

    apache::vhost { 'tlp-ssl':
        vhost_name => '*',
        servername => 'www.apache.org',
        port => '443',
        ssl => true,    # ssl cert, chain, key defined in apache class, as that is the main ssl stuff used
        virtual_docroot => '/var/www/%1.0.apache.org',
        docroot => '/var/www',
        override => ['FileInfo'],
        serveraliases => ['*.apache.org'],
        custom_fragment => '
        VirtualScriptAlias /var/www/%1.0.apache.org/cgi-bin
        UseCanonicalName Off
        Use CatchAll
        ',
    }

    apache::mod { 'expires': }

    apache::vhost { 'apache.org':
        port => 80,
        servername => 'www.apache.org',
        serveraliases => ['apache.org', 'apachegroup.org', 'www.apachegroup.org', 'www.*.apache.org'],
        docroot => '/var/www/www.apache.org',
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
            'http://httpd.apache.org/docs/misc/vif-info',
            'http://httpd.apache.org/docs/mod/directives.html',
            'http://httpd.apache.org/docs/misc/API.html',
            'http://httpd.apache.org/docs/misc/FAQ.html',
            'http://www.apache.org/search.html',
            'http://bugs.apache.org/index/',
            'http://bugs.apache.org/',
            'http://www.apachecon.com',
            'http://archive.apache.org/dist/java/',
            'http://perl.apache.org',
            'http://httpd.apache.org/docs',
            'http://httpd.apache.org/docs',
            'http://httpd.apache.org',
            'http://httpd.apache.org/',
            'http://httpd.apache.org/',
            'http://www.apache.org',
            'http://httpd.apache.org/info/css-security',
            'http://cvs.apache.org/',
            'http://cvs.apache.org/snapshots/',
            'http://tac-apply.apache.org'
        ],
        redirectmatch_status => ['permanent'],
        redirectmatch_regexp => ['^/LICENSE.*', '/flyers(.*)'],
        redirectmatch_dest => ['http://www.apache.org/licenses/', 'http://www.apache.org/foundation/contributing.html'],
        custom_fragment => '
            RewriteEngine on
            RewriteOptions inherit
            RewriteRule /docs/mod_(.*)$ http://httpd.apache.org/docs/mod/mod_$1 [R=permanent]

            # Grab referals from www.apache.com and explain where
            # they landed.
            RewriteCond %{HTTP_REFERER} ^http://([^/]*\.)?apache\.com/
            RewriteRule ^/dist/.* http://www.apache.org/info/referer-dotcom.html [R,L]

            # odd ddos coming from aouu.com
            RewriteCond %{HTTP_REFERER} aouu.com
            RewriteRule ^ - [F,L]

            <IfModule mod_expires.c>
                ExpiresActive On
                ExpiresDefault A3600
            </IfModule>
        ',

    }

    apache::mod { 'include': }

    apache::vhost { 'httpd':
        port => 80,
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
        
        <Directory /x1/www/httpd.apache.org/content/docs/1.3>
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
            RewriteRule ^(.+) http://httpd.apache.org/docs/trunk/$1 [R=301,L]
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
            RewriteRule ^(.+) http://httpd.apache.org/docs/trunk/$1 [R=301,L]
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

    apache::vhost { 'httpd-ssl':
        servername => 'httpd.apache.org',
        serveraliases => ['httpd.*.apache.org'],
        port => '443',
        ssl => true,    # ssl cert, chain, key defined in apache class, as that is the main ssl stuff used
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
        
        <Directory /x1/www/httpd.apache.org/content/docs/1.3>
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

}
