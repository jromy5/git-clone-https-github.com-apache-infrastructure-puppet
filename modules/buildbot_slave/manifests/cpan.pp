#/etc/puppet/modules/buildbot_slave/manifests/cpan.pp

include cpan

# buildbot cpan  class for the build slaves.
class buildbot_slave::cpan (

  $cpan_modules,

) {

  require stdlib
  require buildbot_slave

  #define cpan modules
  define buildbot_slave::install_modules ($module = $title) {
    cpan { $module :
      ensure    => present,
    }
  }

  buildbot_slave::install_modules   { $cpan_modules: }


}
