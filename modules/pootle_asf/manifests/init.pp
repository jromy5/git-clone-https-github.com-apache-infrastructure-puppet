# module for installing custom asf pootle service (translate.a.o)

class pootle_asf (
  $x1               = '/x1',
  $pootle_dbname    = 'pootle',        # eyaml
  $pootle_dbuser    = 'pootleuser',    # eyaml
  $pootle_dbhost    = '',              # eyaml
  $pootle_dbpass    = '',              # eyaml
  $pootle_secretkey = '',              # eyaml

) {

  # build some default paths

  $pootle_wwwroot   = "${x1}/www"
  $pootle_root      = "${pootle_wwwroot}/pootle"
  $pootle_poroot    = "${pootle_wwwroot}/po"
  $pootle_reporoot  = "${pootle_wwwroot}/repos"
  $pootle_venv      = "${pootle_wwwroot}/pootle_venv"

  file { $x1:
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  -> file { $pootle_wwwroot:
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0775',
    require => File['/x1'],
  }

  -> file { $pootle_root:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0775',
  }

  -> file { $pootle_poroot:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0775',
  }

  -> file { $pootle_reporoot:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0775',
  }

  file { "${pootle_root}/wsgi.py":
    ensure  => present,
    content => template('pootle_asf/wsgi.py.erb'),
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
  }

  file { "${pootle_root}/asf_db.py":
    ensure  => present,
    content => template('pootle_asf/asf_db.py.erb'),
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
  }

  -> file { "${pootle_venv}/lib/python2.7/site-packages/pootle/asf_db.py":
    ensure => link,
    target => "${pootle_root}/asf_db.py",
  }

  file { "${pootle_root}/settings.py":
    ensure  => present,
    content => template('pootle_asf/settings.py.erb'),
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
  }

  -> file { "${pootle_venv}/lib/python2.7/site-packages/pootle/settings.py":
    ensure => link,
    target => "${pootle_root}/settings.py",
  }

  file { "${pootle_root}/assets":
    ensure => link,
    target => "${pootle_venv}/lib/python2.7/site-packages/pootle/assets",
  }

}
