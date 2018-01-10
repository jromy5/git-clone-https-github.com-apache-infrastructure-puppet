#/etc/puppet/modules/whimsy_server/manifests/cronjobs.pp

class whimsy_server::cronjobs (

  $ruby_version = hiera('ruby_version'),

) {

  $ruby = "/usr/local/bin/ruby${ruby_version}"
  $rake = "/usr/local/bin/rake${ruby_version}"

  cron { 'svnupdate':
    ensure  => present,
    command => "bash -c 'cd /srv/whimsy; (flock -x 1; ${rake} svn:update) > www/logs/svn-update 2>&1'",
    user    => whimsysvn,
    minute  => '*/10'
  }

  cron { 'gitpull':
    ensure  => present,
    command => "bash -c 'cd /srv/whimsy; (flock -x 1; ${rake} git:pull) > www/logs/git-pull 2>&1'",
    user    => whimsysvn,
    minute  => '*/10'
  }

  cron { 'public_committee':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_committee_info.rb public/committee-info.json > logs/public-committee-info 2>&1)",
    user    => $apache::user,
    minute  => '*/15'
  }

  cron { 'public_icla':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_icla_info.rb public/icla-info.json public/icla-info_noid.json > logs/public-icla-info 2>&1)", # lint:ignore:140chars
    user    => $apache::user,
    minute  => '*/15'
  }

  cron { 'public_member':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_member_info.rb public/member-info.json > logs/public-member-info 2>&1)",
    user    => $apache::user,
    minute  => '*/15'
  }

  cron { 'public_ldap_committees':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_ldap_committees.rb public/public_ldap_committees.json > logs/public-ldap-committees 2>&1)", # lint:ignore:140chars
    user    => $apache::user,
    minute  => [2, 17, 32, 47]
  }

  cron { 'public_ldap_people':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_ldap_people.rb public/public_ldap_people.json > logs/public-ldap-people 2>&1)",
    user    => $apache::user,
    minute  => [4, 19, 34, 49]
  }

  cron { 'public_ldap_groups':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_ldap_groups.rb public/public_ldap_groups.json > logs/public-ldap-groups 2>&1)",
    user    => $apache::user,
    minute  => [6, 21, 36, 51]
  }

  cron { 'public_nonldap_groups':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_nonldap_groups.rb public/public_nonldap_groups.json > logs/public-nonldap-groups 2>&1)", # lint:ignore:140chars
    user    => $apache::user,
    minute  => [8, 23, 38, 53]
  }

  cron { 'public_ldap_authgroups':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_ldap_authgroups.rb public/public_ldap_authgroups.json > logs/public-ldap-authgroups 2>&1)", # lint:ignore:140chars
    user    => $apache::user,
    minute  => [10, 25, 40, 55]
  }

  cron { 'public_ldap_services':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_ldap_services.rb public/public_ldap_services.json > logs/public-ldap-services 2>&1)", # lint:ignore:140chars
    user    => $apache::user,
    minute  => 40
  }

  cron { 'public_podlings':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_podlings.rb public/public_podling_status.json public/public_podlings.json > logs/public-podlings 2>&1)", # lint:ignore:140chars
    user    => $apache::user,
    minute  => 45
  }

  cron { 'public_ldap_projects':
    ensure  => present,
    command => "(cd /srv/whimsy/www; ${ruby} roster/public_ldap_projects.rb public/public_ldap_projects.json > logs/public-ldap-projects 2>&1)", # lint:ignore:140chars
    user    => $apache::user,
    minute  => 50
  }

  cron { 'board_minutes':
    ensure  => present,
    command => "(cd /srv/whimsy/tools; ${ruby} collate_minutes.rb > ../www/logs/collate_minutes 2>&1)",
    user    => $apache::user,
    minute  => 10
  }

  cron { 'site-scan':
    ensure  => present,
    command => "(cd /srv/whimsy/tools; ${ruby} site-scan.rb ../www/public/site-scan.json ../www/public/pods-scan.json > ../www/logs/site-scan 2>&1)", # lint:ignore:140chars
    user    => $apache::user,
    minute  => 55
  }

  cron { 'letsencrypt_auto':
    ensure  => present,
    command => '/srv/git/letsencrypt/letsencrypt-auto renew > /srv/whimsy/www/logs/letsencrypt-auto 2>&1',
    user    => root,
    weekday => 3,
    hour    => 5,
    minute  => 57
  }
}
