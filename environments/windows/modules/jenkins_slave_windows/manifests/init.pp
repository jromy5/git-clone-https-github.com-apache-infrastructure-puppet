class jenkins_slave_windows (

  $user_password    = '',
  $ant = ['foo'],
  $maven = ['foo'],
  $java_jenkins = ['jdk1.5.0-22-32','jdk1.5.0-22-64','jdk1.6.0-30','jdk1.7.0-79-unlimited-security','jdk1.8.0-121-unlimited-security','jdk1.8.0-121','jdk1.8.0-144-unlimited-security','jdk1.8.0-144','jdk1.8.0-92-unlimited-security','jdk1.9.0'],

) {
  user { 'jenkins':
    ensure   => present,
    comment  => 'non-admin Jenkins account',
    groups   => ['Users'],
    password => $user_password, #password has to meet whatever policy exists or the account doesn't get created with no error
  }
 
   #### Download JDK9 from Bintray
  download_file { "Download JDK9 from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/asf-build-jdk1.9.0.exe',
    destination_directory => 'C:\temp',
  }  

  #### Install JDK 9 silently for the system, but only if C:\Program Files\Java doesn't exist
  exec { 'install jdk' :
    command => 'powershell.exe c:\temp\asf-build-jdk1.9.0.exe /s',
    onlyif    => "if (Test-Path 'C:\\Program Files\\Java') { exit 1;}  else { exit 0; }",
    logoutput => true,
    provider => powershell,
  }
  
  #### create directories for Jenkins, tools, and such
  file { ['F:\jenkins','F:\jenkins\tools','F:\jenkins\tools\java\zips','F:\jenkins\tools\java','F:\jenkins\tools\ant','F:\jenkins\tools\maven']:
    ensure => directory
  }

################### download JDK #############################

  define download_jdk($jdk = $title){
      download_file { "Download asf-build-${jdk} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-${jdk}.zip",
        destination_directory => 'F:\jenkins\tools\java\zips',
      }
    }

  define extract_jdk($jdk = $title){
      file { ["F:\\jenkins\\tools\\java\\${jdk}"]:
        ensure => directory,
      }
       
      file { ["F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip"]:
        audit => mtime,
      }

      exec { "extract ${jdk}" :
        command => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip -DestinationPath F:\\jenkins\\tools\\java\\${jdk}",
        #onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip') { exit 0;}  else { exit 1; }",
        provider => powershell,
        subscribe   => File["F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip"],
        refreshonly => true,
      }
    }

  download_jdk { $java_jenkins:} -> extract_jdk { $java_jenkins:}

##############################################################



  exec { "create symlink for JDK1.9":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.9 F:\\jenkins\\tools\\java\\jdk1.9.0",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest1.9') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
    exec { "create symlink for JDK1.8":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.8 F:\\jenkins\\tools\\java\\jdk1.8.0-144",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest1.8') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for JDK1.7":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.7 F:\\jenkins\\tools\\java\\jdk1.7.0-79-unlimited-security",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest1.7') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for JDK1.6":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.6 F:\\jenkins\\tools\\java\\jdk1.6.0-30",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest1.6') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
  exec { "create symlink for JDK1.5":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.5 F:\\jenkins\\tools\\java\\jdk1.5.0-22-64",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest1.5') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }
}