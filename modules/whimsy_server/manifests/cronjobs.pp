#/etc/puppet/modules/whimsy_server/manifests/cronjobs.pp

class whimsy_server::cronjobs (

) {

  cron { 'svnupdate':
    ensure  => present,
    command => 'bash -c \'(flock -x 1; cd /srv/whimsy; /usr/local/bin/rake svn:update) > www/logs/svn-update 2>&1\'',
    user    => whimsysvn,
    minute  => '*/10'
  }

  cron { 'public_committee':
    ensure  => present,
    command => '(cd /srv/whimsy/www; /usr/local/bin/ruby2.3.0 roster/public_committee_info.rb public/committee-info.json > logs/public-committee-info 2>&1)',
    user    => $apache::user,
    minute  => '*/15'
  }

  cron { 'public_icla':
    ensure  => present,
    command => '(cd /srv/whimsy/www; /usr/local/bin/ruby2.3.0 roster/public_icla_info.rb public/icla-info.json > logs/public-icla-info 2>&1)',
    user    => $apache::user,
    minute  => '*/15'
  }

  cron { 'public_member':
    ensure  => present,
    command => '(cd /srv/whimsy/www; /usr/local/bin/ruby2.3.0 roster/public_member_info.rb public/member-info.json > logs/public-member-info 2>&1)',
    user    => $apache::user,
    minute  => '*/15'
  }

  cron { 'public_ldap_committees':
    ensure  => present,
    command => '(cd /srv/whimsy/www; /usr/local/bin/ruby2.3.0 roster/public_ldap_committees.rb public/public_ldap_committees.json > logs/public-ldap-committees 2>&1)',
    user    => $apache::user,
    minute  => [2, 17, 32, 47]
  }

  cron { 'public_ldap_committers':
    ensure  => present,
    command => '(cd /srv/whimsy/www; /usr/local/bin/ruby2.3.0 roster/public_ldap_committers.rb public/public_ldap_committers.json > logs/public-ldap-committers 2>&1)',
    user    => $apache::user,
    minute  => [4, 19, 34, 49]
  }

  cron { 'public_ldap_groups':
    ensure  => present,
    command => '(cd /srv/whimsy/www; /usr/local/bin/ruby2.3.0 roster/public_ldap_groups.rb public/public_ldap_groups.json > logs/public-ldap-groups 2>&1)',
    user    => $apache::user,
    minute  => [6, 21, 36, 51]
  }

  cron { 'public_nonldap_groups':
    ensure  => present,
    command => '(cd /srv/whimsy/www; /usr/local/bin/ruby2.3.0 roster/public_nonldap_groups.rb public/public_nonldap_groups.json > logs/public-nonldap-groups 2>&1)',
    user    => $apache::user,
    minute  => 38
  }

  cron { 'board_minutes':
    ensure  => present,
    command => '(cd /srv/whimsy/tools; /usr/bin/ruby collate_minutes.rb > ../www/logs/collate_minutes 2>&1)',
    user    => $apache::user,
    minute  => 10
  }

}
