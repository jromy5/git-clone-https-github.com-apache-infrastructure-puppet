#/etc/puppet/modules/buildbot_slave/manifests/rvm.pp

include rvm

# the buildvot slave rvm class
class buildbot_slave::rvm ( ) {

  ############################################################
  #                         Symlink Ruby                     #
  ############################################################
  # stolen from whimsy_server module

  # define ruby symlinks 
  define buildbot_slave::ruby::symlink ($binary = $title, $ruby = '') {
    $version = split($ruby, '-')
    file { "/usr/local/bin/${binary}${version[1]}" :
      ensure => link,
      target => "/usr/local/rvm/wrappers/${ruby}/${binary}",
    }
  }

  # define rvn symlinking
  define buildbot_slave::rvm::symlink ($ruby = $title) {
    $binaries = [erb, gem, irb, rake, rdoc, ri, ruby, testrb]
    buildbot_slave::ruby::symlink { $binaries: ruby => $ruby}
  }

  $rubies = keys(hiera_hash('rvm::system_rubies'))
  buildbot_slave::rvm::symlink { $rubies: }

}
