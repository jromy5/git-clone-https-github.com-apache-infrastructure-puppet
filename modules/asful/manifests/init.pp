#/etc/puppet/modules/asful/manifests/init.pp

class asful (
  $nodename       = 'ul1-eu-central',
  $nodeip         = '10.91.64.150',
  $clusterlist    = '[]',
  $minimum_master_nodes = 2

){
  include 'elasticsearch'

  File<|title == '/etc/elasticsearch/asful/elasticsearch.asful.yml'|> {
      ensure => file,
      mode   => '0755',
      owner  => 'elasticsearch',
      group  => 'elasticsearch',
      content => template('asful/yaml.erb'),
    }
}
