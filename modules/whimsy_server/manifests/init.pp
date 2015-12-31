#/etc/puppet/modules/whimsy_server/manifests/init.pp


class whimsy_server (

) {

  vcsrepo { '/srv/whimsy':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/apache/whimsy.git'
  }

}
