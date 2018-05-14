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

  # override below in eyaml
  $stats_url = '',

){

  # qmail specific

  $apmail_home    = "${parent_dir}/${username}"
  $bin_dir        = "${apmail_home}/bin"
  $lib_dir        = "${apmail_home}/lib"
  $lists_dir      = "${apmail_home}/lists"
  $logs2_dir      = "${apmail_home}/logs2"
  $json_dir       = "${apmail_home}/json"
  $svn_dot_dir    = "${apmail_home}/.subversion2"
  $mailqsize_port = '8083'

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

  # various files or dirs needed

  file {

  # directories

    $bin_dir:
      ensure  => directory,
      recurse => true,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    $lib_dir:
      ensure  => directory,
      recurse => true,
      owner   => $username,
      group   => $username,
      mode    => '0755',
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

  # template files

    "${bin_dir}/generate-podlings-list.py":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/generate-podlings-list.py.erb'),
      mode    => '0755';

    "${bin_dir}/generate-qmail-pmcs.py":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/generate-qmail-pmcs.py.erb'),
      mode    => '0755';

    "${bin_dir}/selfserve-make-lists.py":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/selfserve-make-lists.py.erb'),
      mode    => '0755';

    "${bin_dir}/allow-email-in-all-tlp-private-lists.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/allow-email-in-all-tlp-private-lists.sh.erb'),
      mode    => '0755';

    "${bin_dir}/autoresponse-apache.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/autoresponse-apache.sh.erb'),
      mode    => '0755';

    "${bin_dir}/autoresponse-apachecon.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/autoresponse-apachecon.sh.erb'),
      mode    => '0755';

    "${bin_dir}/autoresponse-human-response.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/autoresponse-human-response.sh.erb'),
      mode    => '0755';

    "${bin_dir}/autoresponse-ooobz.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/autoresponse-ooobz.sh.erb'),
      mode    => '0755';

    "${bin_dir}/autoresponse.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/autoresponse.sh.erb'),
      mode    => '0755';

    "${bin_dir}/backup-listinfo.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/backup-listinfo.sh.erb'),
      mode    => '0755';

    "${json_dir}/parselog.py":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/parselog.py.erb'),
      mode    => '0755';

    "${logs2_dir}/rotate-logs2.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/rotate-logs2.sh.erb'),
      mode    => '0755';

  # symlinks

    "/home/${username}":
      ensure => link,
      target => $apmail_home;

  }

}
