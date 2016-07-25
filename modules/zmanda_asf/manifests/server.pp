#/etc/puppet/modules/zmanda/manifests/install.pp

class zmanda_asf::server (
  $amandauser             = 'amandabackup',
  $backupserver           = 'bai.apache.org',
  $keycontent             = '', # amanadauser ssh public key
  $s3_prefix              = 's3://asf-private',
  $sshdkeysdir            = '/etc/ssh/ssh_keys',
  $zmanda_lic             = 'zmanda_license',
  $zmanda_pkg             = 'amanda-enterprise-3.3.9-linux.run',
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
      command => "/usr/local/bin/aws s3 cp ${s3_prefix}/packages/${zmanda_pkg} /root",
      unless  => '/usr/bin/dpkg-query -W amanda-enterprise-backup-server',
      require => Class['Awscli'],
    } -> Exec['install zmanda']

    exec { 'install zmanda':
      command => "/bin/chmod +x /root/${zmanda_pkg} && /root/${zmanda_pkg} --mode unattended",
      unless  => '/usr/bin/dpkg-query -W amanda-enterprise-backup-server',
    }

    exec { 's3copy license':
      command => "/usr/local/bin/aws s3 cp ${s3_prefix}/licenses/${zmanda_lic} /etc/zmanda/zmanda_license",
      require => Exec['install zmanda'],
    }

  }

  file { '/opt/zmanda/amanda/apache2/conf/ssl.conf':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/zmanda_asf/ssl.conf',
    require => Exec['install zmanda'],
  }

  file { '/var/lib/amanda/.ssh/id_rsa_amdump':
    mode    =>  '0600',
    owner   =>  'amandabackup',
    group   =>  'disk',
    content =>  hiera('zmanda_asf::amdump_private_key'),
    require => Exec['install zmanda'],
  }

  file { '/var/lib/amanda/.ssh/id_rsa_amrecover':
    mode    =>  '0600',
    owner   =>  'amandabackup',
    group   =>  'disk',
    content =>  hiera('zmanda_asf::amrecover_private_key'),
    require => Exec['install zmanda'],
  }

  file { '/var/lib/amanda/.ssh/id_rsa_amdump.pub':
    mode    =>  '0600',
    owner   =>  'amandabackup',
    group   =>  'disk',
    content =>  hiera('zmanda_asf::amdump_public_key'),
    require => Exec['install zmanda'],
  }

  file { '/var/lib/amanda/.ssh/id_rsa_amrecover.pub':
    mode    =>  '0600',
    owner   =>  'amandabackup',
    group   =>  'disk',
    content =>  hiera('zmanda_asf::amrecover_public_key'),
    require => Exec['install zmanda'],
  }

}
