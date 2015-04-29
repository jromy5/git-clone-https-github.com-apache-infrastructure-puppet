# A define to make a generic network output for collectd
class collectd::plugin::write_network (
  $ensure  = 'present',
  $servers = { 'localhost'  =>  { 'serverport' => '25826' } },
) {

  warning('Deprecated. This class may be removed in the future. Use collectd::plugin::network instead.') # lint:ignore:80chars

  validate_hash($servers)

  $servernames = keys($servers)
  if empty($servernames) {
    fail('servers cannot be empty')
  }
  $servername = $servernames[0]
  $serverport = $servers[$servername]['serverport']

  class { 'collectd::plugin::network':
    server     => $servername,
    serverport => $serverport,
  }
}
