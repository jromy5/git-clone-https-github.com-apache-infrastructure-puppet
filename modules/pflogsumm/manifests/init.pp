#/etc/puppet/modules/pflogsumm/manifests/init.pp

class pflogsumm (
  $packages   = ['pflogsumm'],

){

  package {
    $packages:
      ensure => installed,
  }

  cron {
    'create-pflogsumm':
      command => '/root/create-pflogsumm.output.sh',
      hour    => '*',
      minute  => '10',
  }

  file {
    '/root/create-pflogsumm.output.sh':
      owner  => 'root',
      mode   => '0750',
      source => 'puppet:///modules/pflogsumm/create-pflogsumm.output.sh',
  }

}
