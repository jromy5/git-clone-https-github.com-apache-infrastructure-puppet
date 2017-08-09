# module for installing custom asf pootle service (translate.a.o)

class pootle_asf (
  $po_root       = '/x1/www/po',
  $repo_root     = '/x1/www/repos',
  $pootle_dbname = 'pootle',        # eyaml
  $pootle_dbuser = 'pootleuser',    # eyaml
  $pootle_dbhost = '',              # eyaml
  $pootle_dbpass = '',              # eyaml
) {

  file { $po_root:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0775',
  }

  file { $repo_root:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0775',
  }

  file { '/x1/www/pootle/asf_db.py':
    ensure  => present,
    content => template('pootle_asf/asf_db.py.erb'),
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
  }

  file { '/usr/local/lib/python2.7/dist-packages/pootle/settings.py':
    ensure => link,
    target => '/x1/www/pootle/settings.py',
  }

  file { '/usr/local/lib/python2.7/dist-packages/pootle/asf_db.py':
    ensure => link,
    target => '/x1/www/pootle/asf_db.py',
  }

}
