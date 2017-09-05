#/etc/puppet/modules/ooo_mwiki/manifests/init.pp

class ooo_mwiki (

  # override below in yaml
  $mwiki_version = '',
  $parent_dir,

  # override below in eyaml

  # required packages

  $required_packages = ['php7.0' , 'php7.0-curl' , 'php7.0-cli' , 'php7.0-json' , 'php7.0-mysql' , 'php7.0-xml' , 'php7.0-zip' , 'imagemagick'], # lint:ignore:140chars
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }
}

