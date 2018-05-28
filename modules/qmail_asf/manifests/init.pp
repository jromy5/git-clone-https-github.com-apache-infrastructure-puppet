##/etc/puppet/modules/qmail_asf/manifests/init.pp

class qmail_asf (

  $username                      = 'apmail',
  $user_present                  = 'present',
  $groupname                     = 'apmail',
  $group_present                 = 'present',
  $groups                        = [],
  $shell                         = '/bin/bash',

  # override below in yaml
  $parent_dir,
  $ezmlm_version = '',

  # override below in eyaml
  $stats_url = '',
  $mm_auth = '',

  $required_packages = ['qmail', 'dot-forward', 'daemontools', 'ucspi-tcp', 'rbldnsd', 'djbdns',
                          'dnscache-run', 'dnsmasq', 'clamav', 'clamav-freshclam', 'qpsmtpd'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  # qmail specific

  $apmail_home        = "${parent_dir}/${username}"
  $bin_dir            = "${apmail_home}/bin"
  $lib_dir            = "${apmail_home}/lib"
  $lists_dir          = "${apmail_home}/lists"
  $logs2_dir          = "${apmail_home}/logs2"
  $json_dir           = "${apmail_home}/json"
  $svn_dot_dir        = "${apmail_home}/.subversion2"
  $mailqsize_port     = '8083'

  # ezmlm specific

  # $tarball            = "${ezmlm_version}.tar.gz"
  $tarball            = "ezmlm-idx-${ezmlm_version}.tar.gz"
  $download_dir       = '/tmp'
  $downloaded_tarball = "${download_dir}/${tarball}"
  # $download_url       = "https://github.com/gmcdonald/ezmlm-idx/archive/${tarball}"
  $download_url       = "https://untroubled.org/ezmlm/archive/7.2.2/ezmlm-idx-7.2.2.tar.gz"
  $install_dir        = "${parent_dir}/ezmlm-idx-${ezmlm_version}"


  # TODO: this dir does not exist yet
  $control_dir = '/var/qmail/control'

  user {
    $username:
      ensure     => $user_present,
      name       => $username,
      home       => $apmail_home,
      shell      => $shell,
      groups     => $groups,
      managehome => true,
      require    => Group[$groupname],
      system     => true,
  }

  group {
    $groupname:
      ensure => $group_present,
      name   => $groupname,
  }

  # download ezmlm
  exec {
    'download-ezmlm':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }

  file { $downloaded_tarball:
    ensure  => file,
    require => Exec['download-ezmlm'],
  }

# extract the download and move it
  exec {
    'extract-ezmlm':
      command => "/bin/tar -xvzf ${tarball} && mv ezmlm-idx-${ezmlm_version} ${parent_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/INSTALL",
      timeout => 1200,
      require => [File[$downloaded_tarball],File[$parent_dir]],
  }

  # various files or dirs needed

  file {

  # directories

    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $bin_dir:
      ensure  => directory,
      recurse => true,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      source  => 'puppet:///modules/qmail_asf/apmail/bin',
      require => User[$username];
    $lib_dir:
      ensure  => directory,
      recurse => true,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      source  => 'puppet:///modules/qmail_asf/apmail/lib',
      require => User[$username];
    $lists_dir:
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    $logs2_dir:
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    $json_dir:
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    "${json_dir}/output":
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    $svn_dot_dir:
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    $install_dir:
      ensure  => directory,
      recurse => true,
      owner   => root,
      group   => root,
      mode    => '0755',
      source  => 'puppet:///modules/qmail_asf/ezmlm/conf',
      require => [User[$username] , Exec[extract-ezmlm]];

  # template files

  # common.conf - global variables other scripts should use.

    "${bin_dir}/common.conf":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/common.conf.erb'),
      mode    => '0644';

  # Other template files needed for other reasons, perhaps they contain
  # passwords or tokens and other stuff

    "${bin_dir}/infod.py":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/infod.py.erb'),
      mode    => '0755';

    "${bin_dir}/makelist-apache.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/makelist-apache.sh.erb'),
      mode    => '0755';

    "${bin_dir}/massmove-apache.pl":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/massmove-apache.pl.erb'),
      mode    => '0755';

    "${bin_dir}/move-allowed-poster":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/move-allowed-poster.erb'),
      mode    => '0755';

  # symlinks

    "/home/${username}":
      ensure => link,
      target => $apmail_home;

  }

}
