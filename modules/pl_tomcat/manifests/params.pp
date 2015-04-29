#/etc/puppet/modules/pl_tomcat/manifest/params.pp

class pl_tomcat::params {
  $tcparams = hiera_hash('tomcat::params',{})
  create_resources(tomcat::params, $tcparams)
}
