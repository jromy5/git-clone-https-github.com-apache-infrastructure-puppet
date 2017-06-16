#/etc/puppet/modules/gitbox/manifests/roleaccount.pp


class gitbox::roleaccount (
  $role_account_username = '',
  $role_account_password = '',
  $role_account_token = '',
) {
  file {
    '/x1/gitbox/auth/roleaccounts':
        mode    => '0644',
        owner   => 'www-data',
        group   => 'www-data',
        content => template('gitbox/roleaccounts.erb');
  }
}
