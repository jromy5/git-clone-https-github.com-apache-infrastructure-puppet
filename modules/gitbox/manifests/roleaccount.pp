#/etc/puppet/modules/gitbox/manifests/roleaccount.pp


class gitbox::roleaccount (
  $rausername = '',
  $rapassword = '',
) {
  file {
    '/x1/gitbox/auth/roleaccounts':
        mode    => '0644',
        owner   => 'www-data',
        group   => 'www-data',
        content => template('gitbox/roleaccounts.erb');
  }
}
