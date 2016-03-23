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
    'libcurl3-gnutls',
    'libcurl3',
    'libglib2.0-0',
    'lib32z1',
    'lib32ncurses5',
    'lib32bz2-1.0',
    'gettext',
    'xinetd',
    'libcroco3',
    'libunistring0',
    'libasprintf-dev',
    'libgettextpo-dev',
    'update-inetd',
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
      content => $keycontent,
      owner   => 'amandabackup',
      mode    => '0640',
      require => Exec['install client'],
    }
  }
}
