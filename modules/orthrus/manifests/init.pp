#/etc/puppet/modules/orthrus/manifests/init.pp

class orthrus {

  case $asfosname {
    ubuntu: {

      package { 'orthrus':
        ensure  => present,
        require => apt::source['asf_internal'],
      }

      exec { 'setuid-ortpasswd':
        command => '/bin/chmod u+s /usr/local/bin/ortpasswd',
        unless  => '/usr/bin/test -u /usr/local/bin/ortpasswd',
        onlyif  => '/usr/bin/test -f /usr/local/bin/ortpasswd',
        require => Package['orthrus'],
      }

    }
    centos: {

      package { 'orthrus':
        ensure  => present,
        require => Yumrepo['asf_internal'],
      }

      exec { 'setuid-ortpasswd':
        command => '/bin/chmod u+s /usr/bin/ortpasswd',
        unless  => '/usr/bin/test -u /usr/bin/ortpasswd',
        onlyif  => '/usr/bin/test -f /usr/bin/ortpasswd',
        require => Package['orthrus'],
      }

    }
    default: {
    }
  }
}
