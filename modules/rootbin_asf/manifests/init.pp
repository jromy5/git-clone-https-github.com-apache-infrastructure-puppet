#/etc/puppet/modules/rootbin_asf/manifests/init.pp

class rootbin_asf {

  $group = $::asfosname ? {
    /^ubuntu$/  => 'root',
    /^centos$/  => 'root',
    /^freebsd$/ => 'wheel',
    default     => 'root',
  }

  file {
    '/root/bin':
      ensure  => present,
      recurse => true,
      source  => 'puppet:///modules/rootbin_asf/bin',
      owner   => 'root',
      group   => $group,
      mode    => '0775',
  }
}
