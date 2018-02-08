# allura project VM
class allura_pvm_asf (

  $rsync_passwd = '', # eyaml

){

  # create rsynclog dir, rsync passwd file
  # install backup script & cron

  file {
    '/root/rsynclogs':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0700';
    '/root/.pw-abi':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $rsync_passwd;
    '/root/allura-daily-abi.sh':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0600',
      source => 'puppet:///modules/allura_pvm_asf/allura-daily-abi.sh';
  }

  cron {
    'allura_daily_abi':
      command => '/root/allura-daily-abi-test.sh',
      user    => 'root',
      hour    => '06',
      minute  => '15',
  }

}

