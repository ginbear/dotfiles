class sshd {

  include sshd::install
  include sshd::service

     Class['sshd::install']
  ~> Class['sshd::service']

}

class sshd::install {

  package { 'openssh-server': ensure => present }

}

class sshd::service {

  service { 'sshd':
      ensure  => running,
      enable  => true,
  }

}
