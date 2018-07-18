#/etc/puppet/modules/git_mirror_asf/manifests/init.pp

class git_mirror_asf (
  $directories = ['/x1', '/x1/git', '/x1/log', '/x1/git/mirrors'],
) {

  include git_asf
  include git_mirror_asf::user

  file {
    $directories:
      ensure  => directory,
      owner   => $git_mirror_asf::user::username,
      group   => $git_mirror_asf::user::groupname,
      before  => Service['git-daemon'],
      require => User[$git_mirror_asf::user::username];
    '/x1/git/bin':
      ensure  => directory,
      owner   => $git_mirror_asf::user::username,
      group   => $git_mirror_asf::user::groupname,
      source  => 'puppet:///modules/git_mirror_asf/bin',
      recurse => true,
      require => File['/x1/git'];
    '/x1/git/mirrors/images':
      ensure  => directory,
      owner   => $git_mirror_asf::user::username,
      group   => $git_mirror_asf::user::groupname,
      source  => 'puppet:///modules/git_mirror_asf/images',
      recurse => true,
      require => File['/x1/git/mirrors'];
  }

  -> cron{
    'check git and clean stale connections':
      command => '/bin/bash /root/bin/check_git.sh',
      user    => 'root',
      minute  => '*/10',
      require => Class['rootbin_asf'];
    'update authors.txt':
      command => 'wget https://git-wip-us.apache.org/authors.txt -O /x1/git/authors.txt > /x1/log/authors-cron.log 2>&1',
      user    => $git_mirror_asf::user::username,
      minute  => '*/30',
      require => File['/x1/git', '/x1/log'];
    'update all mirrors':
      command => '/x1/git/bin/update-all-mirrors.sh > /x1/log/update-all-mirrors.log 2>&1',
      user    => $git_mirror_asf::user::username,
      minute  => '45',
      require => File['/x1/git/bin', '/x1/log'];
  }

}
