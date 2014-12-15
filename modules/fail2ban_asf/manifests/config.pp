
class fail2ban_asf::config (
) {

  include fail2ban

  $jails = hiera_hash('fail2ban_asf::config::jails', {})
  create_resources(fail2ban::jail, $jails)
  $filters = hiera_hash('fail2ban_asf::config::filters', {})
  create_resources(fail2ban::filter, $filters)
}

