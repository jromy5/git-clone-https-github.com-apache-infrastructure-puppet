class httpd_modules (
  $dev_package = [],
) {

    require apache

    package { $dev_package:
      ensure => latest,
    }
}
