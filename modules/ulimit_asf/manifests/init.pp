class ulimit_asf {
  $rule = hiera_hash('ulimit::rule',{})
  create_resources(ulimit::rule, $rule)
}
