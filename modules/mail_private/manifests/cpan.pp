#/etc/puppet/modules/mail_private/manifests/cpan.pp

include cpan

# mail_private cpan class.
class mail_private::cpan (

  $cpan_modules,

) {

  require stdlib
  require mail_private

  #define cpan modules
  define mail_private::install_modules ($module = $title) {
    cpan { $module :
      ensure    => present,
    }
  }

  mail_private::install_modules { $cpan_modules: }

}
