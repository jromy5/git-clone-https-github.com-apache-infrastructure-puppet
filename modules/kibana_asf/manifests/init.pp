#/etc/puppet/modules/kibana_asf/manifests/init.pp

class kibana_asf (
    $packages = ['lua5.2']
  ) {

  package { $packages:
    ensure => present,
  }

  file {
    "/usr/local/etc/logproxy":
      ensure => directory,
      mode   => '0755',
      owner  => 'root',
      group  => 'root';
    "/usr/local/etc/logproxy/frombrowser.lua":
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
      source => "puppet:///modules/kibana_asf/frombrowser.lua";
    "/usr/local/etc/logproxy/tobrowser.lua":
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
      source => "puppet:///modules/kibana_asf/tobrowser.lua";
    "/usr/local/etc/logproxy/JSON.lua":
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
      source => "puppet:///modules/kibana_asf/JSON.lua";
  } ->


  exec { 'download kibana 3':
    command => '/usr/bin/curl -o /tmp/kibana.tgz https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz', # lint:ignore:80chars
    unless  => '/bin/ls /tmp/ | /bin/grep -qs kibana.tgz',
  } ->

  exec { 'untar kibana':
    command => '/bin/mkdir -p /usr/local/etc/logproxy/kibana && /bin/tar -C /usr/local/etc/logproxy/kibana -xzf /tmp/kibana.tgz --strip 1', # lint:ignore:80chars
  } ->

  exec { 'sed kibana config':
    command => '/bin/sed "s/:9200\"/\/_query\", withCredentials: true}/" < /usr/local/etc/logproxy/kibana/config.js | /bin/sed "s/http/https/g" > /usr/local/etc/logproxy/kibana/config.js2 && /bin/mv /usr/local/etc/logproxy/kibana/config.js2 /usr/local/etc/logproxy/kibana/config.js', # lint:ignore:80chars
  }

}
