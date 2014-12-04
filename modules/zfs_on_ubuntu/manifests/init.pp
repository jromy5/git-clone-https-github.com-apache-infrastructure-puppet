#/etc/puppet/modules/zfs_on_ubuntu/manifests/init.pp

class zfs_on_ubuntu {

  apt::ppa { 'ppa:zfs-native/stable':
  }
}
