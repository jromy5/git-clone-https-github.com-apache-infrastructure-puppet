#/etc/puppet/modules/httpd_modules/maanifests/init.pp

class httpd_modules (
  $dev_package = [],
) {

    require apache

    package { $dev_package:
      ensure => latest,
    }
}
