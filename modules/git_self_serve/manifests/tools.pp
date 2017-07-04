# class git self serve for tools.
class git_self_serve::tools (

  $hipchattoken,

) {

  include ldapclient

  file {
    '/var/www/git-setup/':
      ensure => directory,
      mode   => '0755',
      owner  => 'www-data',
      group  => 'www-data';
    '/var/www/git-setup/index.html':
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/git_self_serve/index.html';
    '/var/www/git-setup/ss.lua':
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => template('git_self_serve/ss.lua.erb');
    '/var/www/git-setup/js':
      ensure => directory,
      mode   => '0755',
      owner  => 'www-data',
      group  => 'www-data';
    '/var/www/git-setup/js/ss.js':
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/git_self_serve/ss.js';
  }

}
