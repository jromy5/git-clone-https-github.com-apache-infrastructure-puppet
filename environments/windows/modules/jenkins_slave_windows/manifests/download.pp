class jenkins_slave_windows::download (

  $ant = $jenkins_slave_windows::params::ant,
  $chromedriver = $jenkins_slave_windows::params::chromedriver,
  $geckodriver = $jenkins_slave_windows::params::geckodriver,
  $iedriver = $jenkins_slave_windows::params::iedriver,
  $jdk = $jenkins_slave_windows::params::jdk,
  $maven = $jenkins_slave_windows::params::maven,
  $nant = $jenkins_slave_windows::params::nant,
) {
  include jenkins_slave_windows::params
  #### Download CMake 3.7.2 from Bintray
  download_file { "Download Cmake from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/cmake-3.7.2-win64-x64.msi',
    destination_directory => 'C:\temp',
  } 
  #### Download cygwin from Bintray
  download_file { "Download cygwin from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/cygwin64.zip',
    destination_directory => 'C:\temp',
  }
  #### Download Firefox from Bintray ####
  download_file { "Download Firefox from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/Firefox%20Installer.exe',
    destination_directory => 'C:\temp',
  }
  #### Download Git from Bintray
  download_file { "Download Git from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/Git-2.14.3-64-bit.exe',
    destination_directory => 'C:\temp',
  }

  #### Download JDK9 from Bintray
  download_file { "Download JDK9 from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/asf-build-jdk9.0.exe',
    destination_directory => 'C:\temp',
  }
    #### Download Visual Studio 2015 from Bintray ####
  download_file { "Download Visual Studio 2015 from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/vs_2015_community_ENU.exe',
    destination_directory => 'C:\temp',
  }

  #### Download winSVN ####
  download_file { "Download winsvn from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/Setup-Subversion-1.8.17.msi',
    destination_directory => 'C:\temp',
  }

  ###### download ant ######
  define download_ant($ant_version = $title){
    download_file { "Download asf-build-${ant_version} zip from bintray" :
      url                   => "https://apache.bintray.com/WindowsPackages/asf-build-${ant_version}.zip",
      destination_directory => 'F:\jenkins\tools\ant\zips',
    }
  }
  define download_chromedriver($chromedriver_version = $title){
      download_file { "Download asf-build-chromedriver-${chromedriver_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-chromedriver-${chromedriver_version}.zip",
        destination_directory => 'F:\jenkins\tools\chromedriver\zips',
      }
    }
  define download_geckodriver($geckodriver_version = $title){
      download_file { "Download asf-build-geckodriver-${geckodriver_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-geckodriver-${geckodriver_version}.zip",
        destination_directory => 'F:\jenkins\tools\geckodriver\zips',
      }
    }
  define download_iedriver($iedriver_version = $title){
      download_file { "Download asf-build-iedriver-${iedriver_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-iedriver-${iedriver_version}.zip",
        destination_directory => 'F:\jenkins\tools\iedriver\zips',
      }
    }
  define download_jdk($jdk_version = $title){
      download_file { "Download asf-build-${jdk_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-${jdk_version}.zip",
        destination_directory => 'F:\jenkins\tools\java\zips',
      }
    }
  define download_maven($maven_version = $title){
      download_file { "Download asf-build-${maven_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-${maven_version}.zip",
        destination_directory => 'F:\jenkins\tools\maven\zips',
      }
    }
  define download_nant($nant_version = $title){
      download_file { "Download asf-build-nant-${nant_version} zip from bintray" :
        url                   => "https://apache.bintray.com/WindowsPackages/asf-build-nant-${nant_version}.zip",
        destination_directory => 'F:\jenkins\tools\nant\zips',
      }
    }

  download_ant { $ant:}
  download_chromedriver { $chromedriver:}
  download_geckodriver { $geckodriver:}
  download_iedriver { $iedriver:}
  download_jdk { $jdk:}
  download_maven { $maven:}
  download_nant { $nant:}

}