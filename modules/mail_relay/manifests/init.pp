#/etc/puppet/modules/mail_relay/manifests/init.pp

class mail_relay (

  $mail_ldap_servers = '',
  $packages          = ['postfix-ldap'],
  $mynetworks         = '', # defined in common.eyaml

) {

  package { $packages:
    ensure => present,
  }

  file {
    '/etc/postfix/ldap-mail-forward-lookup.cf':
      content => template('mail_relay/ldap-mail-forward-lookup.cf.erb'),
      mode    => '0644',
      notify  => Service['postfix'],
  }

  file {
    '/etc/postfix/mynetworks':
      ensure  => file,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => $mynetworks,
      notify  => Service['postfix'];
    }
}
