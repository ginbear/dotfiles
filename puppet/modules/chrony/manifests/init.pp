class chrony {
  include chrony::install
  include chrony::service

     Class['chrony::install']
  -> Class['chrony::service']
}

class chrony::install {
  package { 'chrony':
    ensure => installed,
  }
}

class chrony::service {
  service { 'chronyd':
    ensure  => running,
    enable  => true,
  }
}
