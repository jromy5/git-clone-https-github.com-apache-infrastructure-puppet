class jenkins_slave_windows::install (

  $ant = $jenkins_slave_windows::params::ant,
  $chromedriver = $jenkins_slave_windows::params::chromedriver,
  $geckodriver = $jenkins_slave_windows::params::geckodriver,
  $iedriver = $jenkins_slave_windows::params::iedriver,
  $jdk = $jenkins_slave_windows::params::jdk,
  $maven = $jenkins_slave_windows::params::maven,
  $nant = $jenkins_slave_windows::params::nant,
) {

  include jenkins_slave_windows::params

  #### Install JDK 9 silently for the system, but only if C:\Program Files\Java doesn't exist
  exec { 'install jdk' :
    command => 'powershell.exe c:\temp\asf-build-jdk9.0.exe /s',
    onlyif    => "if (Test-Path 'C:\\Program Files\\Java') { exit 1;}  else { exit 0; }",
    logoutput => true,
    provider => powershell,
  }

  #### Install winSVN ####
  package { 'winsvn':
    ensure => present,
    source => 'c:\temp\Setup-Subversion-1.8.17.msi',
  }
  
  #### Install Git silently for the system, but only if C:\Program Files\Git doesn't exist
  exec { 'install Git' :
    command => 'powershell.exe c:\temp\Git-2.14.3-64-bit.exe /SILENT',
    onlyif    => "if (Test-Path 'C:\\Program Files\\Git') { exit 1;}  else { exit 0; }",
    logoutput => true,
    provider => powershell,
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
}