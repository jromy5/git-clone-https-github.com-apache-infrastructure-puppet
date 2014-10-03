class svnpubsub (
) {

    anchor { 'svnpubsub::begin': } ->
    class { '::svnpubsub::config': } ~>
    class { '::svnpubsub::service': } ->
    anchor { 'svnpubsub::end': }
}
