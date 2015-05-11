#/etc/puppet/modules/tomcat_asf/manifests/init.pp

class tomcat_asf (
) {

  $tcinstance = hiera_hash('tomcat::instance',{})
  create_resources(tomcat::instance, $tcinstance)

  $tcservice = hiera_hash('tomcat::service',{})
  create_resources(tomcat::service, $tcservice)

  $tcwar = hiera_hash('tomcat::war', {})
  create_resources(tomcat::war, $tcwar)

  $tcconfig = hiera_hash('tomcat::config',{})
  create_resources(tomcat::config, $tcconfig)
}
