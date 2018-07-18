#/etc/puppet/modules/zfs_on_ubuntu/manifests/init.pp

class zfs_on_ubuntu {

  $packages_pre = [
    "linux-headers-${::kernelrelease}",
  ]

  $packages_zfs = [
    'zfs-dkms',
    'ubuntu-zfs'
  ]

  apt::ppa { 'ppa:zfs-native/stable': }

  package { $packages_pre:
    ensure  => installed,
  }
  ~> package { $packages_zfs:
    ensure  => installed,
    require => Apt::Ppa['ppa:zfs-native/stable'],
  }
  ~> exec { 'modprobe zfs':
    command => '/sbin/modprobe zfs'
  }

}
