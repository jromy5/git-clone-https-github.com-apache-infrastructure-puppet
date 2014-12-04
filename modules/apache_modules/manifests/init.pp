class apache_modules (
  $dev_package = [],
) {

    package { "${dev_package}":
      ensure => latest,
    }
}
