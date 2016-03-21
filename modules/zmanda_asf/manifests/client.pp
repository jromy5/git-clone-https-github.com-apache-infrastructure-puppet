#/etc/puppet/modules/zmanda/manifests/install.pp

class zmanda_asf::client (
  $zmanda_client_version  = "3.3.9-1",
  $s3_prefix              = "s3://asf-private/packages",
){

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
    'libuuid-perl',
    'libarchive-zip-perl',
    'libcrypt-ssleay-perl',
    'libclass-methodmaker-perl',
    'libdata-dump-perl',
    'libsoap-lite-perl',
  ]

  if ! defined(Package['awscli']) {
    package { 'awscli':
      ensure    => 'present',
      provider  => 'pip',
      require   => Package['pip'],
    }
  }

  if $::lsbdistcodename == 'trusty' {
    exec { '/usr/bin/dpkg --add-architecture i386':
      unless => '/bin/grep -q i386 /var/lib/dpkg/arch',
      before => Package[$zmandapkgs],
      notify => Exec['apt_update'],
    }
    package { $zmandapkgs:
      ensure  => 'installed',
      require => Exec['/usr/bin/dpkg --add-architecture i386'],
    }

    # exec { 's3copy':

    # is zmanda client installed?
    # /usr/bin/dpkg-query -W amanda-enterprise-backup-client (1 or 0)

    # insert s3 copy code for ubuntu installer here
    # insert ubuntu zmanda client install code here
  }

  # exec { 'copy from s3fs':
    # # command => '/bin/mount /mnt/asf-private',
    # unless  => '/bin/grep -qs asf-private /etc/mtab',
    # require => S3fs::Mount['asf-private'],
  # } -> File['/tmp/amanda-enterprise-3.3.6-linux.run']

  # file { '/tmp/amanda-enterprise-3.3.6-linux.run':
    # mode   => '0755',
    # owner  => 'root',
    # group  => 'root',
    # source => '/mnt/asf-private/packages/amanda-enterprise-3.3.6-linux.run',
    # before => Exec['install zmanda'],
  # }
# 
  # exec { 'install zmanda':
    # command => '/tmp/amanda-enterprise-3.3.6-linux.run --mode unattended',
    # unless  => '/usr/bin/test -f /var/lib/amanda/amanda-release',
    # require => File['/tmp/amanda-enterprise-3.3.6-linux.run'],
  # }
# 
  # file { '/etc/zmanda/zmanda_license':
    # mode    => '0664',
    # owner   => 'root',
    # group   => 'root',
    # source  => '/mnt/asf-private/licenses/zmanda_license',
    # require => Exec['install zmanda'],
  # }
# 
  # file { '/opt/zmanda/amanda/apache2/conf/ssl.conf':
    # mode    => '0644',
    # owner   => 'root',
    # group   => 'root',
    # source  => 'puppet:///modules/zmanda_asf/ssl.conf',
    # require => File['/etc/zmanda/zmanda_license']
  # }
}
