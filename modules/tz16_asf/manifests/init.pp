# force set timezone to UTC on ubuntu 1604

class tz16_asf {

  file {'/etc/localtime':
    ensure => link,
    target => '/usr/share/zoneinfo/Etc/UTC',
    notify => Exec['set_tz16'],
  }

  exec {'set_tz16':
    command => '/usr/sbin/dpkg-reconfigure --frontend noninteractive tzdata',
  }

}
