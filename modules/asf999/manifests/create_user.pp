#/etc/puppet/modules/asf999/manifests/create_user.pp

class asf999::create_user (

  $groups     = [],
  $password   = '',
  $shell      = '/bin/bash', #provide a default, JIC.
  $sshkeys    = '',
  $sshrootdir = ::ssh

) {
    user { 'asf999': 
      name     => 'asf999',
      ensure   => present,
      comment  => 'Emergency local access account for the Infrastructure team',
      groups   => $groups, 
      home     => '/home/asf999',
      password => $password,
      uid      => '999',
  }

  file { '
 
ssh::server::config
}
