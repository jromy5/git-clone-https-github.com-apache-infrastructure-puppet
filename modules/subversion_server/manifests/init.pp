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
     ensure   => directory,
     owner    => 'www-data',
     group    => 'svnadmins',
     mode     => '0775';
   '/x1/svn/authorization/templates':
     ensure   => present,
     recurse  => true,
     owner    => 'www-data',
     group    => 'svnadmins',
     mode     => '0775',
     source   => "puppet:///modules/subversion_server/authorization",
     require  => File['/x1/svn/authorization'];
  }

  # File block to setup the plethora of symlinks needed
  # Generic Files
  file { 
    '/x1/svn/asf-mailer.conf':
      ensure  => link,
      target  => '/x1/svn/authorization/templates/asf-mailer.conf',
      owner   => 'www-data',
      group   => 'svnadmins',
      require => File['/x1/svn/authorization'];
    '/x1/svn/asf-authorization':
      ensure  => link,
      target  => '/x1/svn/authorization/asf-authorization',
      owner   => 'www-data',
      group   => 'svnadmins',
      require => File['/x1/svn/authorization'];
    '/x1/svn/pit-authorization':
      ensure  => link,
      target  => '/x1/svn/authorization/pit-authorization',
      owner   => 'www-data',
      group   => 'svnadmins',
      require => File['/x1/svn/authorization'];
    '/x1/svn/asf-dist-authorization':
      ensure  => link,
      target  => '/x1/svn/authorization/asf-dist-authorization',
      owner   => 'www-data',
      group   => 'svnadmins',
      require => File['/x1/svn/authorization'];
    }


    # /repos/asf specific files
    file {
    '/x1/svn/repos/asf/hooks/pre-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-commit',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/asf/hooks/start-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/start-commit',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/asf/hooks/post-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/post-commit',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/asf/hooks/pre-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-lock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/asf/hooks/post-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-lock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/asf/hooks/post-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/post-revprop-change',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/asf/hooks/pre-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-revprop-change',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/asf/hooks/pre-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-unlock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/asf/hooks/post-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-unlock',
      owner   => 'www-data',
      group   => 'svnadmins';
    }

    # /repos/dist specific files
    file {
    '/x1/svn/repos/dist/hooks/pre-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-commit',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/dist/hooks/start-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/start-commit',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/dist/hooks/post-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/post-commit-dist',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/dist/hooks/pre-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-lock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/dist/hooks/post-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-lock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/dist/hooks/post-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/post-revprop-change',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/dist/hooks/pre-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-revprop-change',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/dist/hooks/pre-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-unlock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/dist/hooks/post-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-unlock',
      owner   => 'www-data',
      group   => 'svnadmins';
    }

    # /repos/infra specific files
  file {
    '/x1/svn/repos/infra/hooks/pre-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-commit-infra',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/infra/hooks/start-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/start-commit',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/infra/hooks/post-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/post-commit-infra',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/infra/hooks/pre-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-lock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/infra/hooks/post-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-lock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/infra/hooks/post-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/post-revprop-change',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/infra/hooks/pre-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-revprop-change',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/infra/hooks/pre-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-unlock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/infra/hooks/post-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-unlock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/infra-backups.d':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins';
    }

    # /repos/private specific files
    file {
    '/x1/svn/repos/private/hooks/pre-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-commit-private',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/private/hooks/start-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/start-commit',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/private/hooks/post-commit':
      ensure  => link,
      target  => '/x1/svn/hooks/post-commit-private',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/private/hooks/pre-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-lock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/private/hooks/post-lock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-lock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/private/hooks/post-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/post-revprop-change',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/private/hooks/pre-revprop-change':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-revprop-change',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/private/hooks/pre-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/pre-unlock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/repos/private/hooks/post-unlock':
      ensure  => link,
      target  => '/x1/svn/hooks/post-unlock',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/svn/private-backups.d':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins';
    }
}
