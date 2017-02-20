# deploy reviewboard

class reviews_asf  (
  $dbuser     = '',
  $dbpass     = '',
  $dbname     = '',
  $dbtype     = 'mysql',
  $dbhost     = '',
  $secret_key = '',
  $rbhome     = '/var/www/reviews.apache.org',
  $rbhost     = 'reviews.apache.org',
  $rbuser     = 'reviewboard',
  $rbgroup    = 'reviewboard',
) {

  user {
    $rbuser:
      ensure     => 'present',
      name       => $rbuser,
      home       => "/home/${rbuser}",
      managehome => true,
      system     => true,
      require    => Group[$rbgroup],
  }

  group {
    $rbgroup:
      name   => $rbgroup,
      system => true,
  }

  exec { 'rbsite-install':
    command => '/usr/local/bin/rbsite-install.sh',
    creates => "${rbhome}/.installed",
    onlyif  => "/usr/bin/test ! -f ${rbhome}/.installed",
    require => File['/usr/local/bin/rbsite-install.sh'],
  }

  file {
    '/usr/local/bin/rbsite-install.sh':
      ensure  => 'present',
      content => template('reviews_asf/rbsite-install.sh.erb'),
      mode    => '0750';
    "${rbhome}/conf/settings_local.py":
      ensure  => 'present',
      content => template('reviews_asf/settings_local.py.erb'),
      owner   => 'www-data',
      group   => 'www-data',
      mode    => '0640',
      require => Exec['rbsite-install'];
    "${rbhome}/data":
      ensure  => 'directory',
      owner   => 'www-data',
      group   => 'www-data',
      mode    => '0750',
      require => Exec['rbsite-install'];
    "${rbhome}/htdocs/media/ext":
      ensure  => 'directory',
      owner   => 'www-data',
      group   => 'www-data',
      mode    => '0750',
      require => Exec['rbsite-install'];
    "${rbhome}/htdocs/static/ext":
      ensure  => 'directory',
      owner   => 'www-data',
      group   => 'www-data',
      mode    => '0750',
      require => Exec['rbsite-install'];

  }
}
