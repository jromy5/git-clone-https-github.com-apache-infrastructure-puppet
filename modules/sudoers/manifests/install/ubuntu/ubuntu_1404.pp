#/etc/puppet/modules/sudoers/manifests/install/ubuntu/ubuntu_1404.pp

class sudoers::install::ubuntu::ubuntu_1404 (
) {

  file {'/etc/sudoers':
    content => template('sudoers/ubuntu_1404_sudoers.erb');
  }
}
