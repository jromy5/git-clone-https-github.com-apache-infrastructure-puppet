class httpd_modules (
  $dev_package = [],
) {

    package { "${dev_package}":
      ensure => latest,
    }
}
