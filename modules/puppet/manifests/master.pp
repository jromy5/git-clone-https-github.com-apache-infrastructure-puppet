class puppet::master {

  cron { updatepuppet:
    command => "cd /etc/puppet; /usr/bin/git pull",
    user    => root,
    minute  => '*/5',
  }

}

