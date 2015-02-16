class maven_central_mirror_asf::install {

  $maven_central_mirror_pkgs = [
                                'awscli'
  ]

  if $::lsbdistcodename == 'trusty' {

    package { $maven_central_mirror_pkgs:
      ensure  => 'installed',
    }
  }

  s3fs::mount { 'asf-maven-central-mirror':
    bucket      => 'asf-maven-central-mirror',
    mount_point => '/mnt/asf-maven-central-mirror',
    ensure      => defined,
    before      => Exec['mount s3fs'],
  }

  exec { "mount s3fs":
    command => "/bin/mount /mnt/asf-maven-central-mirror",
    unless  => "/bin/grep -qs asf-maven-central-mirror /etc/mtab",
    require => S3fs::Mount['asf-maven-central-mirror']
  } 

}
