
class svnwcsub (
) {
    
    anchor { 'svnwcsub::begin': } ->
    class { '::svnwcsub::base': } ->
    class { '::svnwcsub::config': } ->
#    class { '::svnwcsub::service': } ->
    anchor { 'svnwcsub::end': }
}
