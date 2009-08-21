class openerp::base {
  user {"openerp":
    ensure  => present,
    shell   => "/bin/bash",
    home    => "/srv/openerp",
    managehome => true,
    groups  => "dialout",
  }

  file {"/srv/openerp/.ssh":
    ensure => directory,
    owner  => openerp,
    group  => openerp,
    mode   => 0755,
    require=> User['openerp'],
  }
}
