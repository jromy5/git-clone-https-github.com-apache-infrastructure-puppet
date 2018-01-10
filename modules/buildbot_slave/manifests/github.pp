##/etc/puppet/modules/buildbot_slave/manifests/init.pp

class buildbot_slave::github (

  $github_rsa     = '',
  $github_rsa_pub = '',

)  {

  require buildbot_slave

  file {

  "/home/${buildbot_slave::username}/.ssh/id_rsa_github":
    require => File["/home/${buildbot_slave::username}/.ssh"],
    path    => "/home/${buildbot_slave::username}/.ssh/id_rsa_github",
    owner   => $buildbot_slave::username,
    group   => $buildbot_slave::groupname,
    mode    => '0600',
    content => template('buildbot_slave/ssh/id_rsa_github.erb');

  "/home/${buildbot_slave::username}/.ssh/id_rsa_github.pub":
    require => File["/home/${buildbot_slave::username}/.ssh"],
    path    => "/home/${buildbot_slave::username}/.ssh/id_rsa_github.pub",
    owner   => $buildbot_slave::username,
    group   => $buildbot_slave::groupname,
    mode    => '0644',
    content => template('buildbot_slave/ssh/id_rsa_github.pub.erb');
  }

}

