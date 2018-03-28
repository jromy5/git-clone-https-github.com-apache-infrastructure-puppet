#/environments/windows/modules/jenkins_slave_windows/manifests/params.pp

class jenkins_slave_windows::params (

  $user_password    = '',
  $ant = ['apache-ant-1.9.9','apache-ant-1.9.7','apache-ant-1.9.4','apache-ant-1.8.4','apache-ant-1.10.1'],
  $chromedriver = ['2.29'],
  $geckodriver = ['0.16.1'],
  $gradle = ['3.5','4.3','4.3.1'],
  $iedriver = ['2.53.1','3.4.0'],
  $jdk = ['jdk1.5.0_22-32','jdk1.5.0_22-64','jdk1.6.0_30','jdk1.7.0_79-unlimited-security','jdk1.8.0_92-unlimited-security','jdk1.8.0_121-unlimited-security','jdk1.8.0_121','jdk1.8.0_144-unlimited-security','jdk1.8.0_144','jdk1.8.0_152','jdk9.0','jdk9.0.1','jdk10-ea+37','jdk10_46'], # lint:ignore:140chars
  $maven = ['apache-maven-2.0.10','apache-maven-2.0.9','apache-maven-2.2.1','apache-maven-3.0.2','apache-maven-3.0.4','apache-maven-3.0.5','apache-maven-3.1.1','apache-maven-3.2.1','apache-maven-3.2.5','apache-maven-3.3.3','apache-maven-3.3.9','apache-maven-3.5.0','apache-maven-3.5.2'], # lint:ignore:140chars
  $nant = ['0.92'],
) {}
