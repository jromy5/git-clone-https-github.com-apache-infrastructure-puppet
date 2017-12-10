#/environments/windows/modules//asf999_windows/manifests/create_user.pp

class asf999_windows::create_user (

  $groups      = [],
  $password    = '',

) {
  user { 'asf999_windows':
    ensure   => present,
    comment  => 'Emergency local access account for the Infrastructure team',
    groups   => $groups,
    password => $password, #password has to meet whatever policy exists or the account doesn't get created with no error
  }
}
