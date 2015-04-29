#/etc/puppet/modules/base/manifests/install/freebsd/100release.pp

class base::install::freebsd::100release (
) {

  pkgng::repo { 'pkg.freebsd.org': }


}

