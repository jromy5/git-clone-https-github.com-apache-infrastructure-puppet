#/etc/puppet/modules/postfix_asf/manifests/init.pp

class postfix_asf (
  $sender_access = '',
) {

  $dbfile = hiera_hash('postfix::dbfile', {})
  create_resources(postfix::dbfile, $dbfile)

  file {
    '/etc/postfix/sender_access':
      ensure => file,
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      content => template('postfix_asf/sender_access.erb');
    }
}
