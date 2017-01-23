##/etc/puppet/modules/buildbot_slave/manifests/init.pp

class buildbot_slave::github (

  $github_rsa     = '',
  $github_rsa_pub = '',

) {

  file {

     "/home/${username}/.ssh/id_rsa_github":
      require => File["/home/${username}/.ssh"],
      path    => "/home/${username}/.ssh/id_rsa_github",
      owner   => $username,
      group   => $groupname,
      mode    => '0600',
      content => template('buildbot_slave/ssh/id_rsa_github.erb');

    "/home/${username}/.ssh/id_rsa_github.pub":
      require => File["/home/${username}/.ssh"],
      path    => "/home/${username}/.ssh/id_rsa_github.pub",
      owner   => $username,
      group   => $groupname,
      mode    => '0644',
      content => template('buildbot_slave/ssh/id_rsa_github.pub.erb');

  }

}
 
