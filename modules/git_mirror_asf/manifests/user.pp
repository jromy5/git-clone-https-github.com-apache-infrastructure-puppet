# dfdsfsd

class git_mirror_asf::user (
  $username = 'git',
  $groupname = 'git',
  $ssh_key_contents = '',
) {

  group { $groupname:
    ensure => present,
    system => true,
  }

  -> user { $username:
    ensure     => present,
    groups     => [$groupname],
    home       => "/home/${username}",
    managehome => true,
    shell      => '/bin/bash',
    require    => Group[$groupname],
  }

  -> file {
    "/home/${username}/.ssh":
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      mode    => '0700',
      require => User[$username];
    "/home/${username}/.ssh/id_rsa":
      ensure  => present,
      owner   => $username,
      group   => $groupname,
      mode    => '0600',
      content => $ssh_key_contents,
      require => File["/home/${username}/.ssh"];
  }

}

