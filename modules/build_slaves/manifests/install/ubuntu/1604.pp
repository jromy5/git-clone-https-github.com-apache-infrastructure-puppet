#/etc/puppet/modules/build_slaves/manifests/install/ubuntu/1604.pp

class build_slaves::install::ubuntu::1604 (

$jenkins_pids_max = $build_slaves::UserTasksMax

) {

  file { 'pids.max':
    ensure  => present,
    path    => '/sys/fs/cgroup/pids/user.slice/user-910.slice/pids.max',
    mode    => '0644',
    content => $jenkins_pids_max,
    require => [User[$build_slaves::username]];
  }
}
