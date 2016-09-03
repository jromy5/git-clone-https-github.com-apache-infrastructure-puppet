#/etc/puppet/modules/build_slaves/manifests/jenkins.pp

include cpan

# jenkins class for the build slaves.
class buildbot_slave::cpan (
  
  $modules = ['Archive::Zip', 'LWP::UserAgent', 'LWP::Protocol', 'XML::Parser', 'LWP::Protocol::https'],

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
