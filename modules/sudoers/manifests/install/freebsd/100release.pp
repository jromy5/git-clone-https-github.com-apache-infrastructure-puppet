class sudoers::install::freebsd::100release ( 
) { 

  file {'/etc/sudoers':
    content => template('/usr/local/etc/puppet/modules/sudoers/templates/freebsd_100release_sudoers.erb');
  }
}
