#/etc/puppet/modules/aardvark_asf/manifests/init.pp

# requires lua dependencies in basepackages on target host

# base::basepackages:
  # - issues-data
  # - 'lua5.2'
  # - 'liblua5.2-dev'
  # - 'lua5.2-cjson'
  # - 'lua5.2-socket'
  # - 'lua5.2-sec'
  # - 'lua5.2-yaml'
  # - 'mod-lua-asf'

class aardvark_asf (){

  $aardvark                 = '/usr/local/etc/aardvark'
  $aardvark_filter          = "${aardvark}/filter.lua"
  $aardvark_ruleset         = "${aardvark}/ruleset.yaml"
  $aardvark_whitelist       = "${aardvark}/whitelist"
  $aardvark_debug           = "${aardvark}/debug"

  exec { 'check_aardvark':
    command => "/bin/mkdir -p ${aardvark}",
    onlyif  => "/usr/bin/test ! -e ${aardvark}",
    before  => File[$aardvark_filter],
  }

  file {
    $aardvark:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $aardvark_debug:
      ensure => directory,
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0755';
    $aardvark_filter:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/aardvark_asf/filter.lua',
      require => [ File[$aardvark]];
    $aardvark_ruleset:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/aardvark_asf/ruleset.yaml',
      require => [ File[$aardvark]];
    $aardvark_whitelist:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/aardvark_asf/whitelist',
      require => [ File[$aardvark]]
  }

}
