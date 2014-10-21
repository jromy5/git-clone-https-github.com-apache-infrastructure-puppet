#/etc/puppet/modules/pflogsumm/manifests/init.pp

class pflogsumm {
  $packages   => ['pflogsumm'],

){

  package { $packages: 
    ensure   =>  installed,
  }

  cron { 'create-pflogsumm':
    command  => '/root/create-pflogsumm.output.sh',
    hour     => '*',
    minute   => '1',
  }

  file { '/root/create-pflogsumm.output.sh':
    owner    => 'root',
    mode     => '07050',
    source   => 'puppet:///modules/pflogsumm/create-pflogsumm.output.sh',
  }

}
