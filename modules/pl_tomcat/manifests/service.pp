class pl_tomcat::service {
  $tcservice = hiera_hash('tomcat::service',{})
  create_resources(tomcat::service, $tcservice)
}
