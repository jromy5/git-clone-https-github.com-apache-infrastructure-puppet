class zmanda_asf::install {

  $zmandapkgs = [
    'libc6:i386',
    'libncurses5:i386',
    'libstdc++6:i386',
    'bsd-mailx',
    'gcc-multilib',
    'gettext-base',
    'libffi6:i386',
    'libgcc1:i386',
    'libglib2.0-0:i386',
    'libpcre3:i386',
    'libreadline5:i386',
    'libselinux1:i386',
    'lsb-release',
    'lsscsi',
    'mt-st',
    'mtx',
    'xinetd',
    'zlib1g:i386',
    'libcurl3-gnutls',
    'libglib2.0-0',
    'libpcre3',
    'libidn11',
    'libssh2-1',
    'libcurl3',
    'libreadline6',
    'libssl-dev',
    'libxml-libxml-perl',
    'perl-doc',
  ]

  if $::lsbdistcodename == 'trusty' {
    exec { "apt-get update":
      command => "/usr/bin/apt-get update",
      before  => Exec['/usr/bin/dpkg --add-architecture i386'],
    }
    exec { '/usr/bin/dpkg --add-architecture i386':
      unless  => '/bin/grep -q i386 /var/lib/dpkg/arch',
      before  => Package[$zmandapkgs],
      require => Exec['apt-get update'],
    }
    package { $zmandapkgs:
      ensure  => 'installed',
      require => Exec['/usr/bin/dpkg --add-architecture i386'],
    }
  }

  s3fs::mount { 'asf-private':
    bucket      => 'asf-private',
    mount_point => '/mnt/asf-private',
    ensure      => defined,
    before      => Exec['mount s3fs'],
  }

  exec { "mount s3fs":
    command => "/bin/mount /mnt/asf-private",
    unless  => "/bin/grep -qs asf-private /etc/mtab",
    require => S3fs::Mount['asf-private'],
    before  => Exec['untar vmware'],
  } 

  exec { "untar vmware":
    creates => "/tmp/vmware-vsphere-cli-distrib/vmware-install.pl",
    command => "/bin/tar -C /tmp -xzf /mnt/asf-private/packages/VMware-vSphere-Perl-SDK-5.1.0-780721.x86_64.tar.gz",
    require => Exec['mount s3fs'],
    before  => Exec['install vmware'],
  } -> Exec["install vmware"]

  exec { "install vmware":
    cwd         => "/tmp/vmware-vsphere-cli-distrib",
    command     => "/usr/bin/yes | /tmp/vmware-vsphere-cli-distrib/vmware-install.pl -d",
    environment => ["PAGER=/bin/cat"],
    logoutput   => false,
    require     => Exec['untar vmware'],
    returns     => 1,
  } 

  exec { "install zmanda":
    command => "/mnt/asf-private/packages/amanda-enterprise-3.3.6-linux.run --mode unattended",
    unless  => "/usr/bin/test -f /opt/zmanda/amanda/uninstall",
    require => Exec['install vmware'],
  } 
  
  file { "/etc/zmanda/zmanda_license":
    mode    => 440,
    owner   => root,
    group   => root,
    source  => "/mnt/asf-private/licenses/zmanda_license",
    require => Exec['install zmanda'],
  } -> Exec["unmount s3fs"]

  exec { "unmount s3fs":
    command => "/bin/umount /mnt/asf-private",
  }

  file { "/opt/zmanda/amanda/apache2/conf/ssl.conf":
    mode    => 644,
    owner   => root,
    group   => root,
    source  => "puppet:///modules/zmanda_asf/ssl.conf",
    require => File['/etc/zmanda/zmanda_license']
  }
}
