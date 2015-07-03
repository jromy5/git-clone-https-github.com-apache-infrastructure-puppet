#/etc/puppet/modules/asf999/manifests/create_user.pp

class asf999::create_user (

  $groups      = [],
  $keycontent  = '',
  $password    = '',
  $shell       = '/bin/bash', #provide a default, JIC.
  $sshdkeysdir = '/etc/ssh/ssh_keys',

) {
  user { 'asf999':
    ensure   => present,
    name     => 'asf999',
    comment  => 'Emergency local access account for the Infrastructure team',
    groups   => $groups,
    home     => '/home/asf999',
    password => $password,
    shell    => $shell,
    uid      => '999',
  }

  file {"${sshdkeysdir}/asf999.pub":
    content => $keycontent,
    owner   => 'asf999',
    mode    => '0640',
    require => User['asf999'],
  }
}
