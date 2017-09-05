class ooo_forums (

  # override below in yaml
  $pbpbb_version = '',
  $parent_dir,

  # override below in eyaml

  # required packages

  $required_packages = ['php7.0' , 'php7.0-curl' , 'php7.0-cli' , 'php7.0-json' , 'php7.0-mysql' , 'php7.0-xml' , 'php7.0-zip'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }
}
