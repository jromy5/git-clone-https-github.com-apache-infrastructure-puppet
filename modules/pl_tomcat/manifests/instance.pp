class pl_tomcat::instance {
  $tcinstance = hiera_hash('tomcat::instance',{})
  create_resources(tomcat::instance, $tcinstance)
}
