#/environments/windows/modules/jenkins_slave_windows/manifests/install.pp

class jenkins_slave_windows::install (

  $ant = $jenkins_slave_windows::params::ant,
  $chromedriver = $jenkins_slave_windows::params::chromedriver,
  $geckodriver = $jenkins_slave_windows::params::geckodriver,
  $gradle = $jenkins_slave_windows::params::gradle,
  $iedriver = $jenkins_slave_windows::params::iedriver,
  $jdk = $jenkins_slave_windows::params::jdk,
  $maven = $jenkins_slave_windows::params::maven,
  $nant = $jenkins_slave_windows::params::nant,
) {

  include jenkins_slave_windows::params
  #### Install winSVN ####
  package { 'CMake':
    ensure => present,
    source => 'c:\temp\cmake-3.7.2-win64-x64.msi',
  }

  #### Install Firefox silently for the system, but only if not already installed
  exec { 'install Firefox' :
    command  => 'powershell.exe c:\temp\Firefox%20Installer.exe -ms',
    creates  => 'C:\Program Files\Mozilla Firefox\firefox.exe',
    provider => powershell,
  }

    #### Install JDK 1.8 silently for the system, but only if C:\Program Files\Java doesn't exist
  exec { 'install jdk' :
    command  => 'powershell.exe c:\temp\asf-build-jdk1.8.0_152.exe /s',
    creates  => 'C:\Program Files\Java\jdk1.8.0_152\bin\java.exe',
    provider => powershell,
  }

  #### Install winSVN ####
  package { 'winsvn':
    ensure => present,
    source => 'c:\temp\Setup-Subversion-1.8.17.msi',
  }

  #### Install Git silently for the system, but only if C:\Program Files\Git doesn't exist
  exec { 'install Git' :
    command  => 'powershell.exe c:\temp\Git-2.14.3-64-bit.exe /SILENT',
    creates  => 'C:\Program Files\Git\git-cmd.exe',
    provider => powershell,
  }

  #### Unzip cygwin into f:\cygwin
  exec { 'extract cygwin64' :
    command  => "powershell.exe Expand-Archive -Force C:\\temp\\cygwin64.zip -DestinationPath F:\\cygwin64",
    creates  => 'F:\Cygwin64\Cygwin.bat',
    provider => powershell,
  }

  ###################### Setup ANT #############################
  define extract_ant($ant_version = $title){
      exec { "extract ${ant_version}" :
        command  => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\ant\\zips\\asf-build-${ant_version}.zip -DestinationPath F:\\jenkins\\tools\\ant\\${ant_version}", # lint:ignore:140chars
        provider => powershell,
        creates  => "F:\\jenkins\\tools\\ant\\${ant_version}\\bin\\ant.cmd",
      }
    }

  extract_ant { $ant:}

#################################################################


###################### Setup Chromedriver #############################
  define extract_chromedriver($chromedriver_version = $title){
      exec { "extract ${chromedriver_version}" :
        command  => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\chromedriver\\zips\\asf-build-chromedriver-${chromedriver_version}.zip -DestinationPath F:\\jenkins\\tools\\chromedriver\\${chromedriver_version}", # lint:ignore:140chars
        provider => powershell,
        creates  => "F:\\jenkins\\tools\\chromedriver\\${chromedriver_version}\\win32\\chromedriver.exe",
      }
    }

  extract_chromedriver { $chromedriver:}

#################################################################

###################### Setup Geckodriver #############################
  define extract_geckodriver($geckodriver_version = $title){
      exec { "extract ${geckodriver_version}" :
        command  => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\geckodriver\\zips\\asf-build-geckodriver-${geckodriver_version}.zip -DestinationPath F:\\jenkins\\tools\\geckodriver\\${geckodriver_version}", # lint:ignore:140chars
        provider => powershell,
        creates  => "F:\\jenkins\\tools\\geckodriver\\${geckodriver_version}\\win32\\geckodriver.exe",
      }
    }

extract_geckodriver { $geckodriver:}

#################################################################

###################### Setup Gradle #############################
  define extract_gradle($gradle_version = $title){
      exec { "extract ${gradle_version}" :
        command  => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\gradle\\zips\\asf-build-gradle-${gradle_version}.zip -DestinationPath F:\\jenkins\\tools\\gradle\\${gradle_version}", # lint:ignore:140chars
        provider => powershell,
        creates  => "F:\\jenkins\\tools\\gradle\\${gradle_version}\\bin\\gradle.bat",
      }
    }

extract_gradle { $gradle:}

#################################################################

###################### Setup IEdriver #############################
  define extract_iedriver($iedriver_version = $title){
      exec { "extract ${iedriver_version}" :
        command  => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\iedriver\\zips\\asf-build-iedriver-${iedriver_version}.zip -DestinationPath F:\\jenkins\\tools\\iedriver\\${iedriver_version}", # lint:ignore:140chars
        provider => powershell,
        creates  => "F:\\jenkins\\tools\\iedriver\\${iedriver_version}\\win32\\iedriverserver.exe",
      }
    }

  extract_iedriver { $iedriver:}

#################################################################

###################### Setup JDK #############################
  define extract_jdk($jdk_version = $title){
      exec { "extract ${jdk_version}" :
        command  => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\java\\zips\\asf-build-${jdk_version}.zip -DestinationPath F:\\jenkins\\tools\\java\\${jdk_version}", # lint:ignore:140chars
        provider => powershell,
        creates  => "F:\\jenkins\\tools\\java\\${jdk_version}\\bin\\java.exe",
      }
    }

  extract_jdk { $jdk:}

#################################################################


###################### Setup Maven #############################
  define extract_maven($maven_version = $title){
      exec { "extract ${maven_version}" :
        command  => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\maven\\zips\\asf-build-${maven_version}.zip -DestinationPath F:\\jenkins\\tools\\maven\\${maven_version}", # lint:ignore:140chars
        provider => powershell,
        creates  => "F:\\jenkins\\tools\\maven\\${maven_version}\\bin\\mvn",
      }
    }

  extract_maven { $maven:}

#################################################################


###################### Setup nant #############################
  define extract_nant($nant_version = $title){
      exec { "extract ${nant_version}" :
        command  => "powershell.exe Expand-Archive -Force F:\\jenkins\\tools\\nant\\zips\\asf-build-nant-${nant_version}.zip -DestinationPath F:\\jenkins\\tools\\nant\\${nant_version}", # lint:ignore:140chars
        provider => powershell,
        creates  => "F:\\jenkins\\tools\\nant\\${nant_version}\\bin\\nant.exe",
      }
    }

  extract_nant { $nant:}

#################################################################
}