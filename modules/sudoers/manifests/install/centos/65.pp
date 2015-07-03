#/etc/puppet/modules/sudoers/install/centos/65.pp

class sudoers::install::centos::65 (
) {

  file {'/etc/sudoers':
    content => template('sudoers/centos_65_sudoers.erb');
  }
}
