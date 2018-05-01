#/etc/puppet/modules/sudoers/manifests/install/ubuntu/ubuntu_1804.pp

class sudoers::install::ubuntu::ubuntu_1804 (
) {

  file {'/etc/sudoers':
    content => template('sudoers/ubuntu_1804_sudoers.erb');
  }
}
