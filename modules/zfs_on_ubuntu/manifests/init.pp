#/etc/puppet/modules/zfs_on_ubuntu/manifests/init.pp

class zfs_on_ubuntu {

  $packages = ['zfs-dkms', 'ubuntu-zfs']

  apt::ppa { 'ppa:zfs-native/stable':
  }

  package { $packages:
    ensure   => installed,
    require  => apt::ppa['ppa:zfs-native/stable'],
  }
}
