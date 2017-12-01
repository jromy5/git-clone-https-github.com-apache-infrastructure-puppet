class jenkins_slave_windows (

  $user_password    = '',
  $ant = [],
  $chromedriver = [],
  $geckodriver = [],
  $iedriver = [],
  $jdk = [],
  $maven = [],
  $nant = [],
) {
  user { 'jenkins':
    ensure   => present,
    comment  => 'non-admin Jenkins account',
    groups   => ['Users'],
    password => $user_password, #password has to meet whatever policy exists or the account doesn't get created with no error
  }

  #### create directories for Jenkins, tools, and such
  file { ['F:\Program Files','F:\jenkins','F:\jenkins\tools','F:\jenkins\tools\ant','F:\jenkins\tools\ant\zips','F:\jenkins\tools\chromedriver','F:\jenkins\tools\chromedriver\zips','F:\jenkins\tools\geckodriver','F:\jenkins\tools\geckodriver\zips','F:\jenkins\tools\iedriver','F:\jenkins\tools\iedriver\zips','F:\jenkins\tools\java','F:\jenkins\tools\java\zips','F:\jenkins\tools\maven','F:\jenkins\tools\maven\zips','F:\jenkins\tools\nant','F:\jenkins\tools\nant\zips']:
    ensure => directory
  }

  include jenkins_slave_windows::params

  class {'jenkins_slave_windows::download': } ->
  class {'jenkins_slave_windows::install': }

################### create symlinks #############################
  exec { "create symlink for CMake":
    command  => "cmd.exe /c mklink /d \"F:\\Program Files\\CMake\" \"C:\\Program Files\CMake\"",
    onlyif    => "if (Test-Path 'F:\\Program Files\\CMake') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for latest Ant":
    command  => "cmd.exe /c mklink /d F:\\jenkins\\tools\\ant\\latest F:\\jenkins\\tools\\ant\\apache-ant-1.10.1",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\ant\\latest') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for latest Maven":
    command  => "cmd.exe /c mklink /d F:\\jenkins\\tools\\maven\\latest F:\\jenkins\\tools\\maven\\apache-maven-3.5.0",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\maven\\latest') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for Maven2":
    command  => "cmd.exe /c mklink /d F:\\jenkins\\tools\\maven\\latest2 F:\\jenkins\\tools\\maven\\apache-maven-2.2.1",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\maven\\latest2') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for Maven3":
    command  => "cmd.exe /c mklink /d F:\\jenkins\\tools\\maven\\latest3 F:\\jenkins\\tools\\maven\\apache-maven-3.5.0",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\maven\\latest3') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for latest JDK":
    command  => "cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest F:\\jenkins\\tools\\java\\jdk9.0.1",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for JDK1.9":
    command  => "cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest9 F:\\jenkins\\tools\\java\\jdk9.0.1",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest9') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
    exec { "create symlink for JDK1.8":
    command  => "cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.8 F:\\jenkins\\tools\\java\\jdk1.8.0_152",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest1.8') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for JDK1.7":
    command  => "cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.7 F:\\jenkins\\tools\\java\\jdk1.7.0_79-unlimited-security",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest1.7') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for JDK1.6":
    command  => " cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.6 F:\\jenkins\\tools\\java\\jdk1.6.0_30",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest1.6') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for JDK1.5":
    command  => "cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.5 F:\\jenkins\\tools\\java\\jdk1.5.0_22-64",
    onlyif   => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest1.5') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
#################################################################

  registry_value { 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled':
    ensure => present,
    type   => dword,
    data   =>  1,
  }

  exec { 'Enable longpaths for git':
    command  => 'git config --system core.longpaths true',
    provider => powershell
  }

}
