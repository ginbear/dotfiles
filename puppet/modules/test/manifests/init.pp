class test::require_parameter {

  file {'/tmp/rp-test1':
    ensure  => present,
    content => "test",
  }

  file {'/tmp/rp-test2':
    ensure  => present,
    content => "test",
    require => File['/tmp/rp-test1']
  }

  file {'/tmp/rp-test3':
    ensure  => present,
    content => "test",
    require => File['/tmp/rp-test2']
  }

}

class test::require_function {

  require nginx
  contain sshd
  include chrony

  file {'/tmp/rf-test1':
    ensure  => present,
    content => "Hi.",
  }

}

class test::arrow_operator {

  file {'/tmp/ao-test1':
    ensure  => present,
    content => "test",
  }

  file {'/tmp/ao-test2':
    ensure  => present,
    content => "test",
  }

  file {'/tmp/ao-test3':
    ensure  => present,
    content => "test",
  }

  File['/tmp/ao-test1'] -> File['/tmp/ao-test2'] -> File['/tmp/ao-test3']

}
