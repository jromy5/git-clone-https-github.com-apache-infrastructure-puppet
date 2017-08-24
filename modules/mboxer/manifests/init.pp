#/etc/puppet/modules/mboxer/manifests/init.pp

# class for mboxer - automatic archiving of ASF email.
class mboxer (

){

  $archive_dir    = '/x1/archives'
  $install_base  = '/usr/local/etc/mboxer'

# Packages
package {
    'python3-yaml':
      ensure => installed;
}

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

mailalias {
    'archiver':
      name => 'archiver',
      ensure => present,
      provider => aliases,
      recipient => "|python3 ${install_base}/tools/archive.py";
}
