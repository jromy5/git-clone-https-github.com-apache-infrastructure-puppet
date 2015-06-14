#/etc/puppet/modules/ulimit/manifests/init.pp

class ulimit_asf {

  include ulimit

  $rule = hiera_hash('ulimit::rule',{})
  create_resources(ulimit::rule, $rule)
}
