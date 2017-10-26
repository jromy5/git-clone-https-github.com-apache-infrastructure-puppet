class jenkins_slave_windows (

  $user_password    = '',
  $ant = ['apache-ant-1.9.9','apache-ant-1.9.7','apache-ant-1.9.4','apache-ant-1.8.4','apache-ant-1.10.1'],
  $chromedriver = ['2.29'],
  $geckodriver = ['0.16.1'],
  $iedriver = ['2.53.1','3.4.0'],
  $jdk = ['jdk1.5.0-22-32','jdk1.5.0-22-64','jdk1.6.0-30','jdk1.7.0-79-unlimited-security','jdk1.8.0-121-unlimited-security','jdk1.8.0-121','jdk1.8.0-144-unlimited-security','jdk1.8.0-144','jdk1.8.0-92-unlimited-security','jdk1.9.0'],
  $maven = ['apache-maven-2.0.10','apache-maven-2.0.9','apache-maven-2.2.1','apache-maven-3.0.2','apache-maven-3.0.4','apache-maven-3.0.5','apache-maven-3.1.1','apache-maven-3.2.1','apache-maven-3.2.5','apache-maven-3.3.3','apache-maven-3.3.9','apache-maven-3.5.0'],
  $nant = ['0.92'],
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
  file { ['F:\jenkins','F:\jenkins\tools','F:\jenkins\tools\ant','F:\jenkins\tools\ant\zips','F:\jenkins\tools\chromedriver','F:\jenkins\tools\chromedriver\zips','F:\jenkins\tools\geckodriver','F:\jenkins\tools\geckodriver\zips','F:\jenkins\tools\iedriver','F:\jenkins\tools\iedriver\zips','F:\jenkins\tools\java','F:\jenkins\tools\java\zips','F:\jenkins\tools\maven','F:\jenkins\tools\maven\zips','F:\jenkins\tools\nant','F:\jenkins\tools\nant\zips']:
    ensure => directory
  }

###################### Setup ANT #############################

  define download_ant($ant_version = $title){
      download_file { "Download asf-build-${ant_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-${ant_version}.zip",
        destination_directory => 'F:\jenkins\tools\ant\zips',
      }
    }

  define extract_ant($ant_version = $title){
      file { ["F:\\jenkins\\tools\\ant\\${ant_version}"]:
        ensure => directory,
      }
       
      file { ["F:\\jenkins\\tools\\ant\\zips\\asf-build-${ant_version}.zip"]:
        audit => mtime,
      }

      exec { "extract ${ant_version}" :
        command => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\ant\\zips\\asf-build-${ant_version}.zip -DestinationPath F:\\jenkins\\tools\\ant\\${ant_version}",
        #onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip') { exit 0;}  else { exit 1; }",
        provider => powershell,
        subscribe   => File["F:\\jenkins\\tools\\ant\\zips\\asf-build-${ant_version}.zip"],
        refreshonly => true,
      }
    }

  download_ant { $ant:} -> extract_ant { $ant:}

#################################################################


###################### Setup Chromedriver #############################

  define download_chromedriver($chromedriver_version = $title){
      download_file { "Download asf-build-chromedriver-${chromedriver_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-chromedriver-${chromedriver_version}.zip",
        destination_directory => 'F:\jenkins\tools\chromedriver\zips',
      }
    }

  define extract_chromedriver($chromedriver_version = $title){
      file { ["F:\\jenkins\\tools\\chromedriver\\${chromedriver_version}"]:
        ensure => directory,
      }
       
      file { ["F:\\jenkins\\tools\\chromedriver\\zips\\asf-build-chromedriver-${chromedriver_version}.zip"]:
        audit => mtime,
      }

      exec { "extract ${chromedriver_version}" :
        command => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\chromedriver\\zips\\asf-build-chromedriver-${chromedriver_version}.zip -DestinationPath F:\\jenkins\\tools\\chromedriver\\${chromedriver_version}",
        #onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip') { exit 0;}  else { exit 1; }",
        provider => powershell,
        subscribe   => File["F:\\jenkins\\tools\\chromedriver\\zips\\asf-build-chromedriver-${chromedriver_version}.zip"],
        refreshonly => true,
      }
    }

  download_chromedriver { $chromedriver:} -> extract_chromedriver { $chromedriver:}

#################################################################

###################### Setup Geckodriver #############################

  define download_geckodriver($geckodriver_version = $title){
      download_file { "Download asf-build-geckodriver-${geckodriver_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-geckodriver-${geckodriver_version}.zip",
        destination_directory => 'F:\jenkins\tools\geckodriver\zips',
      }
    }

  define extract_geckodriver($geckodriver_version = $title){
      file { ["F:\\jenkins\\tools\\geckodriver\\${geckodriver_version}"]:
        ensure => directory,
      }
       
      file { ["F:\\jenkins\\tools\\geckodriver\\zips\\asf-build-geckodriver-${geckodriver_version}.zip"]:
        audit => mtime,
      }

      exec { "extract ${geckodriver_version}" :
        command => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\geckodriver\\zips\\asf-build-geckodriver-${geckodriver_version}.zip -DestinationPath F:\\jenkins\\tools\\geckodriver\\${geckodriver_version}",
        #onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip') { exit 0;}  else { exit 1; }",
        provider => powershell,
        subscribe   => File["F:\\jenkins\\tools\\geckodriver\\zips\\asf-build-geckodriver-${geckodriver_version}.zip"],
        refreshonly => true,
      }
    }

  download_geckodriver { $geckodriver:} -> extract_geckodriver { $geckodriver:}

#################################################################

###################### Setup IEdriver #############################

  define download_iedriver($iedriver_version = $title){
      download_file { "Download asf-build-iedriver-${iedriver_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-iedriver-${iedriver_version}.zip",
        destination_directory => 'F:\jenkins\tools\iedriver\zips',
      }
    }

  define extract_iedriver($iedriver_version = $title){
      file { ["F:\\jenkins\\tools\\iedriver\\${iedriver_version}"]:
        ensure => directory,
      }
       
      file { ["F:\\jenkins\\tools\\iedriver\\zips\\asf-build-iedriver-${iedriver_version}.zip"]:
        audit => mtime,
      }

      exec { "extract ${iedriver_version}" :
        command => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\iedriver\\zips\\asf-build-iedriver-${iedriver_version}.zip -DestinationPath F:\\jenkins\\tools\\iedriver\\${iedriver_version}",
        #onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip') { exit 0;}  else { exit 1; }",
        provider => powershell,
        subscribe   => File["F:\\jenkins\\tools\\iedriver\\zips\\asf-build-iedriver-${iedriver_version}.zip"],
        refreshonly => true,
      }
    }

  download_iedriver { $iedriver:} -> extract_iedriver { $iedriver:}

#################################################################

###################### Setup JDK #############################

  define download_jdk($jdk_version = $title){
      download_file { "Download asf-build-${jdk_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-${jdk_version}.zip",
        destination_directory => 'F:\jenkins\tools\java\zips',
      }
    }

  define extract_jdk($jdk_version = $title){
      file { ["F:\\jenkins\\tools\\java\\${jdk_version}"]:
        ensure => directory,
      }
       
      file { ["F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk_version}.zip"]:
        audit => mtime,
      }

      exec { "extract ${jdk_version}" :
        command => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk_version}.zip -DestinationPath F:\\jenkins\\tools\\java\\${jdk_version}",
        #onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip') { exit 0;}  else { exit 1; }",
        provider => powershell,
        subscribe   => File["F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk_version}.zip"],
        refreshonly => true,
      }
    }

  download_jdk { $jdk:} -> extract_jdk { $jdk:}

#################################################################


###################### Setup Maven #############################

  define download_maven($maven_version = $title){
      download_file { "Download asf-build-${maven_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-${maven_version}.zip",
        destination_directory => 'F:\jenkins\tools\maven\zips',
      }
    }

  define extract_maven($maven_version = $title){
      file { ["F:\\jenkins\\tools\\maven\\${maven_version}"]:
        ensure => directory,
      }
       
      file { ["F:\\jenkins\\tools\\maven\\zips\\asf-build-${maven_version}.zip"]:
        audit => mtime,
      }

      exec { "extract ${maven_version}" :
        command => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\maven\\zips\\asf-build-${maven_version}.zip -DestinationPath F:\\jenkins\\tools\\maven\\${maven_version}",
        #onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip') { exit 0;}  else { exit 1; }",
        provider => powershell,
        subscribe   => File["F:\\jenkins\\tools\\maven\\zips\\asf-build-${maven_version}.zip"],
        refreshonly => true,
      }
    }

  download_maven { $maven:} -> extract_maven { $maven:}

#################################################################


###################### Setup nant #############################

  define download_nant($nant_version = $title){
      download_file { "Download asf-build-nant-${nant_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-nant-${nant_version}.zip",
        destination_directory => 'F:\jenkins\tools\nant\zips',
      }
    }

  define extract_nant($nant_version = $title){
      file { ["F:\\jenkins\\tools\\nant\\${nant_version}"]:
        ensure => directory,
      }
       
      file { ["F:\\jenkins\\tools\\nant\\zips\\asf-build-nant-${nant_version}.zip"]:
        audit => mtime,
      }

      exec { "extract ${nant_version}" :
        command => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\nant\\zips\\asf-build-nant-${nant_version}.zip -DestinationPath F:\\jenkins\\tools\\nant\\${nant_version}",
        #onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk}.zip') { exit 0;}  else { exit 1; }",
        provider => powershell,
        subscribe   => File["F:\\jenkins\\tools\\nant\\zips\\asf-build-nant-${nant_version}.zip"],
        refreshonly => true,
      }
    }

  download_nant { $nant:} -> extract_nant { $nant:}

#################################################################




################### create symlinks #############################
  exec { "create symlink for latest Ant":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\ant\\latest F:\\jenkins\\tools\\ant\\apache-ant-1.10.1",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\ant\\latest') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }


  exec { "create symlink for latest Maven":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\maven\\latest F:\\jenkins\\tools\\maven\\apache-maven-3.5.0",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\maven\\latest') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }

  exec { "create symlink for Maven2":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\maven\\latest2 F:\\jenkins\\tools\\maven\\apache-maven-2.2.1",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\maven\\latest2') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }

  exec { "create symlink for Maven3":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\maven\\latest3 F:\\jenkins\\tools\\maven\\apache-maven-3.5.0",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\maven\\latest3') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }

  exec { "create symlink for latest JDK":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest F:\\jenkins\\tools\\java\\jdk1.9.0",
    onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\latest') { exit 1;}  else { exit 0; }",
    provider => powershell,
  }

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
#################################################################

}