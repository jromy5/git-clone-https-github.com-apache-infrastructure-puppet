
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
        serveraliases => '*.apache.org',
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
        ssl => true,
        ssl_cert => '/etc/ssl/certs/wildcard.apache.org.crt',
        ssl_chain => '/etc/ssl/certs/wildcard.apache.org.chain',
        ssl_key => '/etc/ssl/private/wildcard.apache.org.key',
        virtual_docroot => '/var/www/%1.0.apache.org',
        docroot => '/var/www',
        override => ['FileInfo'],
        serveraliases => '*.apache.org',
        custom_fragment => '
        VirtualScriptAlias /var/www/%1.0.apache.org/cgi-bin
        UseCanonicalName Off
        Use CatchAll
        ',
    }

}
