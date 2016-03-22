#/etc/puppet/modules/zmanda/manifests/install.pp

class zmanda_asf::client (
  $amandauser             = 'amandabackup',
  $backupserver           = 'bai.apache.org',
  $keycontent             = '', # amanadauser ssh public key
  $s3_prefix              = 's3://asf-private/packages',
  $sshdkeysdir            = '/etc/ssh/ssh_keys',
  $zmanda_client_version  = '3.3.9-1',
  $zmanda_pkg             = 'amanda-enterprise-backup-client_3.3.9-1Ubuntu1404_amd64.tar',
){

  include awscli

  awscli::profile { 'default':
    aws_access_key_id     => hiera('s3fs::aws_access_key_id'),
    aws_secret_access_key => hiera('s3fs::aws_secret_access_key'),
  }

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
    'gettext',
    'libcroco3',
    'libunistring0',
    'libasprintf-dev',
    'libgettextpo-dev',
  ]

  if $::lsbdistcodename == 'trusty' {

    exec { '/usr/bin/dpkg --add-architecture i386':
      command => '/usr/bin/dpkg --add-architecture i386 && apt-get update',
      unless  => '/bin/grep -q i386 /var/lib/dpkg/arch',
      before  => Package[$zmandapkgs],
    }

    package { $zmandapkgs:
      ensure  => 'installed',
      require => Exec['/usr/bin/dpkg --add-architecture i386'],
      before  => Exec['s3copy']
    }

    exec { 's3copy':
      command => "/usr/local/bin/aws s3 cp ${s3_prefix}/${zmanda_pkg} /root",
      unless  => '/usr/bin/dpkg-query -W amanda-enterprise-backup-client',
      require => Class['Awscli'],
    } -> Exec['untar zmanda']

    exec { 'untar zmanda':
      command => "/bin/tar -xf /root/${zmanda_pkg} -C /root",
      unless  => '/usr/bin/dpkg-query -W amanda-enterprise-backup-client',
    } -> Exec['install client']

    exec { 'install client':
      command => "/usr/bin/dpkg --force-confold -i /root/amanda-enterprise-backup-client_3.3.9-1Ubuntu1404_amd64/amanda-enterprise-backup-client_3.3.9-1Ubuntu1404_amd64.deb",
      unless  => '/usr/bin/dpkg-query -W amanda-enterprise-backup-client',
    } -> Exec['install extensions']

    exec { 'install extensions':
      command => "/usr/bin/dpkg --force-confold -i /root/amanda-enterprise-backup-client_3.3.9-1Ubuntu1404_amd64/amanda-enterprise-extensions-client_3.3.9-1Ubuntu1404_amd64.deb",
      unless  => '/usr/bin/dpkg-query -W amanda-enterprise-extensions-client',
    } -> File['update amandahosts']

    file {'update amandahosts':
      path    => '/var/lib/amanda/.amandahosts',
      ensure  => present,
      content => "${backupserver} amandabackup amdump",
      owner   => 'amandabackup',
      group   => 'disk',
      mode    => '0600',
    }

    file {"${sshdkeysdir}/amandabackup.pub":
      content => hiera('zmanda_asf::amdump_public_key'),
      owner   => 'amandabackup',
      mode    => '0640',
    }
  }
}
