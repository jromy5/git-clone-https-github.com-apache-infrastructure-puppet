#/etc/puppet/modules/postfix_asf/manifests/init.pp

class postfix_asf (
  $sender_access = '',
) {

  exec { 'refresh_sender_access' :
    command     => '/usr/sbin/postmap /etc/postfix/sender_access && /usr/sbin/postfix reload',
    refreshonly => true,
  }

  file {
    '/etc/postfix/sender_access':
      ensure  => file,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template('postfix_asf/sender_access.erb'),
      notify  => Exec['refresh_sender_access'];
  }

}
