# https://collectd.org/wiki/index.php/Plugin:Tail:Postfix
class collectd::plugin::postfix (
  $ensure     = present,
) {

  collectd::plugin {'postfix':
    ensure  => $ensure,
    content => template('collectd/plugin/postfix.conf.erb'),
  }
}
