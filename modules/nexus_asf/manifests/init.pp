# class: nexus
# prepare the base system for a nexus install
#
class nexus_asf {

  user { 'nexus':
    home       => '/home/nexus',
    managehome => true,
    before     => File['/x1/nexus-work'],
  }

  file { '/x1/nexus-work':
    ensure => directory,
    owner  => 'nexus',
    group  => 'nexus',
  }

  file { '/etc/init.d/nexus':
    ensure => present,
    mode   => '0755',
    source => 'puppet:///modules/nexus_asf/init.d/nexus',
  }

  service { 'nexus':
    ensure => running,
    enable => true,
  }

}
