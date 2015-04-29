#/etc/puppet/modules/pl_tomcat/manifests/init.pp

class pl_tomcat::instance {
  $tcinstance = hiera_hash('tomcat::instance',{})
  create_resources(tomcat::instance, $tcinstance)
}
