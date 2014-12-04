#/etc/puppet/modules/subversion_server/manifests/init.pp

class subversion_server {


  # File block to deploy fodlers, scripts etc
  file {
   '/x1/svn/hooks':
     ensure   => present,
     recurse  => true,
     owner    => 'www-data',
     group    => 'svnadmins',
     mode     => '0775',
     source   => "puppet:///modules/subversion_server/hooks";
   '/x1/svn/scripts':
     ensure   => present,
     recurse  => true,
     owner    => 'www-data',
     group    => 'svnadmins',
     mode     => '0775',
     source   => "puppet:///modules/subversion_server/scripts";
   '/x1/svn/authorization':
     ensure   => present,
     recurse  => true,
     owner    => 'www-data',
     group    => 'svnadmins',
     mode     => '0775',
     source   => "puppet:///modules/subversion_server/authorization";
  }

  # File block to setup the plethora of symlinks needed
  # Generic Files
  file { 
    '/x1/svn/asf-mailer.conf':
      ensure  => link,
      target  => '/x1/svn/authorization/asf-mailer.conf'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn';

    # /repos/asf specific files
    '/x1/svn/repos/asf/hooks/pre-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-commit'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/asf/hooks';
    '/x1/svn/repos/asf/hooks/start-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/start-commit'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/asf/hooks';
    '/x1/svn/repos/asf/hooks/post-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/post-commit'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/asf/hooks';
    '/x1/svn/repos/asf/hooks/pre-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-lock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/asf/hooks';
    '/x1/svn/repos/asf/hooks/post-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-lock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/asf/hooks';
    '/x1/svn/repos/asf/hooks/post-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/post-revprop-change'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/asf/hooks';
    '/x1/svn/repos/asf/hooks/pre-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-revprop-change'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/asf/hooks';
    '/x1/svn/repos/asf/hooks/pre-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-unlock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/asf/hooks';
    '/x1/svn/repos/asf/hooks/post-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-unlock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/asf/hooks';

    # /repos/dist specific files
    '/x1/svn/repos/dist/hooks/pre-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-commit'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/dist/hooks';
    '/x1/svn/repos/dist/hooks/start-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/start-commit'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/dist/hooks';
    '/x1/svn/repos/dist/hooks/post-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/post-commit-dist'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/dist/hooks';
    '/x1/svn/repos/dist/hooks/pre-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-lock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/dist/hooks';
    '/x1/svn/repos/dist/hooks/post-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-lock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/dist/hooks';
    '/x1/svn/repos/dist/hooks/post-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/post-revprop-change'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/dist/hooks';
    '/x1/svn/repos/dist/hooks/pre-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-revprop-change'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/dist/hooks';
    '/x1/svn/repos/dist/hooks/pre-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-unlock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/dist/hooks';
    '/x1/svn/repos/dist/hooks/post-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-unlock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/dist/hooks';

    # /repos/infra specific files
    '/x1/svn/repos/infra/hooks/pre-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-commit-infra'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';
    '/x1/svn/repos/infra/hooks/start-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/start-commit'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';
    '/x1/svn/repos/infra/hooks/post-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/post-commit-infra'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';
    '/x1/svn/repos/infra/hooks/pre-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-lock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';
    '/x1/svn/repos/infra/hooks/post-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-lock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';
    '/x1/svn/repos/infra/hooks/post-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/post-revprop-change'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';
    '/x1/svn/repos/infra/hooks/pre-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-revprop-change'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';
    '/x1/svn/repos/infra/hooks/pre-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-unlock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';
    '/x1/svn/repos/infra/hooks/post-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-unlock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';

    # /repos/private specific files
    '/x1/svn/repos/private/hooks/pre-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-commit-private'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/infra/hooks';
    '/x1/svn/repos/private/hooks/start-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/start-commit'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/private/hooks';
    '/x1/svn/repos/private/hooks/post-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/post-commit-private'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/private/hooks';
    '/x1/svn/repos/private/hooks/pre-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-lock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/private/hooks';
    '/x1/svn/repos/private/hooks/post-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-lock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/private/hooks';
    '/x1/svn/repos/private/hooks/post-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/post-revprop-change'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/private/hooks';
    '/x1/svn/repos/private/hooks/pre-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-revprop-change'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/private/hooks';
    '/x1/svn/repos/private/hooks/pre-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-unlock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/private/hooks';
    '/x1/svn/repos/private/hooks/post-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-unlock'
      owner   => 'www-data',
      group   => 'svnadmins',
      onlyif  => '/usr/bin/test -d /x1/svn/repos/private/hooks';

  }
}
