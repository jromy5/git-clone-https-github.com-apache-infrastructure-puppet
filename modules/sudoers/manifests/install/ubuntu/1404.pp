class sudoers::install::ubuntu::1404 ( 
) { 

  file {'/etc/sudoers':
    content => template('sudoers/ubuntu_1404_sudoers.erb');
  }
}
