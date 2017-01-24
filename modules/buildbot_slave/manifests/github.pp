##/etc/puppet/modules/buildbot_slave/manifests/init.pp

class buildbot_slave::github (

  $github_rsa     = '',
  $github_rsa_pub = '',

)  {

  require buildbot_slave

  file {

     "/home/${buildbot_slaves::username}/.ssh/id_rsa_github":
      require => File["/home/${buildbot_slaves::username}/.ssh"],
      path    => "/home/${buildbot_slaves::username}/.ssh/id_rsa_github",
      owner   => $buildbot_slaves::username,
      group   => $buildbot_slaves::groupname,
      mode    => '0600',
      content => template('buildbot_slave/ssh/id_rsa_github.erb');

    "/home/${buildbot_slaves::username}/.ssh/id_rsa_github.pub":
      require => File["/home/${buildbot_slaves::username}/.ssh"],
      path    => "/home/${buildbot_slaves::username}/.ssh/id_rsa_github.pub",
      owner   => $buildbot_slaves::username,
      group   => $buildbot_slaves::groupname,
      mode    => '0644',
      content => template('buildbot_slave/ssh/id_rsa_github.pub.erb');

  }

}
 
