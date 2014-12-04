include fail2ban

class asf-fail2ban::config (
  $filters,
  $jails,
) {
  create_resources(fail2ban::jail, $jails)
  create_resources(fail2ban::filter, $filters)
}

