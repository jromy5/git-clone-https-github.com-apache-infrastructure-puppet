class sudoers::install::ubuntu::1404 ( 
) { 

  file {'/etc/sudoers':
    content => template('/usr/local/etc/puppet/modules/sudoers/templates/ubuntu_1404_sudoers.erb');
  }
}
