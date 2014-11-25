define download_file(
        $site="",
        $cwd="",
        $creates="",
        $require="",
        $user="") {

    exec { $name: 
        command => "wget ${site}/${name}",
        cwd => $cwd,
        creates => "${cwd}/${name}",
        require => $require,
        user => $user,
    }

}

file { [ "/usr/local/etc/svn2gitupdate" ]:
    ensure => "directory",
}

download_file { [
    "svn2gitupdate.py",
    "svn2gitupdate.cfg"
    ]:
    site => "https://svn.apache.org/repos/infra/infrastructure/trunk/projects/git/svn2gitupdate/",
    cwd => "/usr/local/etc/svn2gitupdate",
    creates => "/usr/local/etc/svn2gitupdate/$name",
    require => File["/usr/local/etc/svn2gitupdate"],
    user => 'root',
}