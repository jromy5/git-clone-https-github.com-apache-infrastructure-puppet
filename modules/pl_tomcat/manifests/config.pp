class pl_tomcat::config {
  $tcconfig = hiera_hash('tomcat::config',{})
  create_resources(tomcat::config, $tcconfig)
}
