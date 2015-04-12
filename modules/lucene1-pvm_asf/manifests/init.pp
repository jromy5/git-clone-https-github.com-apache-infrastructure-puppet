class lucene-pvm_asf {

  # manifest for lucene project vm

  user { 'jenkins':
    name     => 'jenkins',
    ensure   => present,
    comment  => 'lucene project VM jenkins slave',
    home     => '/home/jenkins',
    uid      => '3082',
  }
}


