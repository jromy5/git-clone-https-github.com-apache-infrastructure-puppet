#/etc/puppet/modules/postfix_asf/manifests/init.pp

class postfix_asf (
) {

  $dbfile = hiera_hash('postfix::dbfile', {})
  create_resources(postfix::dbfile, $dbfile)

}
