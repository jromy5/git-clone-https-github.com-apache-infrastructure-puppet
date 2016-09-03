#/etc/puppet/modules/buildbot_slave/manifests/cpan.pp

include cpan

# jenkins class for the build slaves.
class buildbot_slave::cpan (
  
  $modules,

) {

  require stdlib
  require buildbot_slave

  define buildbot_slave::install_modules ($module = $title) {
    cpan { $module :
      ensure    => present,
    }
  }

  buildbot_slave::install_modules   { $modules: }


}
