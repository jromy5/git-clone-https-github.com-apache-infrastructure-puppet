#/etc/puppet/modules/aardvark_asf/manifests/init.pp

# requires lua dependencies in basepackages on target host

# base::basepackages:
  # - issues-data
  # - 'lua5.2'
  # - 'liblua5.2-dev'
  # - 'lua5.2-cjson'
  # - 'lua5.2-socket'
  # - 'lua5.2-sec'
  # - 'mod-lua-asf'

class aardvark_asf (
  # below are contained in eyaml
  $aardvark_filter_content  = '',
){

  $aardvark                 = '/usr/local/etc/aardvark'
  $aardvark_filter          = "${aardvark}/filter.lua"

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
    $aardvark_filter:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => $aardvark_filter_content,
      require => [ File[$aardvark], Package['mod-lua-asf'] ]
  }

}
