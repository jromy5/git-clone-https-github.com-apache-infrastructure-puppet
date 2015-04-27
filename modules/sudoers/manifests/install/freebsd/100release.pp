class sudoers::install::freebsd::100release (
) {
  file {'/etc/sudoers':
    content => template('sudoers/freebsd_100release_sudoers.erb');
  }
}
