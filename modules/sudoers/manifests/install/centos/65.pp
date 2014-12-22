class sudoers::install::centos::6x ( 
) { 

  file {'/etc/sudoers':
    content => template('sudoers/centos_6x_sudoers.erb');
  }
}
