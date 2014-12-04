
class asf-fail2ban::config (
  $filters,
  $jails,
) {

  include fail2ban

  create_resources(fail2ban::jail, $jails)
  create_resources(fail2ban::filter, $filters)
}

