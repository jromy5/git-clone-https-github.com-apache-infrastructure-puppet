class pl-tomcat::instance {
  $tcinstance = hiera_hash('tomcat::instance',{})
  create_resources(tomcat::instance, $tcinstance)
}

class pl-tomcat::config {
  $tcconfig = hiera_hash('tomcat::config',{})
  create_resources(tomcat::config, $tcconfig)
}

class pl-tomcat::params {
  $tcparams = hiera_hash('tomcat::params',{})
  create_resources(tomcat::params, $tcparams)
}

class pl-tomcat::service {
  $tcservice = hiera_hash('tomcat::service',{})
  create_resources(tomcat::service, $tcservice)
}
