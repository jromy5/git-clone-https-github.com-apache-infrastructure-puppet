#/etc/puppet/modules/mx_asf/manifests/init.pp

class mx_asf (
  ){

  postfix::file {
    'recipient_canonical_maps':
      ensure  => present,
      content => "## This file is managed by puppet - all local changes will be lost\n\n/^(.*)@(.*).incubator.apache.org$/ \${1}@\${2}.apache.org", # lint:ignore:140chars
  }
}
