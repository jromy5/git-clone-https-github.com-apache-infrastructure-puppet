#/etc/puppet/modules/mail_relay/manifests/init.pp

class mail_relay (

  $mail_ldap_servers     = '',  

) {

  file {
    '/etc/postfix/ldap-mail-forward-lookup.cf':
      source  => template('mail_rely/ldap-mail-forward-lookup.cf.erb'),
      mode    => '0644',
      notify  => 'postfix',
      require => Class['postfix::server'];
  }
}
