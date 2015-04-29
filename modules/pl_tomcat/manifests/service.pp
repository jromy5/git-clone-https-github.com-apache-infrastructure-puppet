#/etc/puppet/modules/pl_tomcat/manifests/service.pp

class pl_tomcat::service {
  $tcservice = hiera_hash('tomcat::service',{})
  create_resources(tomcat::service, $tcservice)
}
