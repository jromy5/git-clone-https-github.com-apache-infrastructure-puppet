#/etc/puppet/modules/mboxer/manifests/init.pp

# class for mboxer - automatic archiving of ASF email.
class mboxer (

){

  $archive_dir    = '/x1/archives'
  $install_base  = '/usr/local/etc/mboxer'

# apmail user/group
user { 'apmail':
    ensure => present,
    home   => '/home/apmail'
  }
  
file {
# Tools dir
    $install_base:
      ensure  => directory,
      recurse => true,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/mboxer',
      require => Package['python3-yaml'];
# mbox archive
    $archive_dir:
      ensure => directory,
      owner  => 'apmail',
      group  => 'apmail',
      mode   => '0750';

# Alias file for archiver@mbox-vm.apache.org
    "/etc/mbox_alias":
      content => "archiver: |python3 ${install_base}/tools/archive.py",
      owner  => 'root',
      group  => 'root',
      mode    => '0755';
  }
}
