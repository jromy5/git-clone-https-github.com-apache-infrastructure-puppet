class tomcat::instance {
  $tcinstance = hiera_hash('tomcat::instance',{})
  create_resources(tomcat::instance, $tcinstance)
}

class tomcat::config {
  $tcconfig = hiera_hash('tomcat::config',{})
  create_resources(tomcat::config, $tcconfig)
}

class tomcat::params {
  $tcparams = hiera_hash('tomcat::params',{})
  create_resources(tomcat::params, $tcparams)
}
