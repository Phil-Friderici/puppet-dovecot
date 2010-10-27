class app-c2c-centos-openvz {
  include buildenv::c
  include python::dev
  $rdiff_backup_enable_mail = 0

  file {"/opt/rdiff-backup":
    ensure => directory,
  }

  file {"/etc/vz/conf/ve-default.conf-sample":
    ensure => present,
    source => "puppet:///modules/c2c/etc/vz/conf/ve-default.conf-sample",
    owner  => root,
    group  => root,
    mode   => 0644,
  }

  package {
    "librsync-devel": ensure => present, alias => "librsync-devel";
  }

  rdiff-backup::server::install {"1.2.5": }

  package {"rdiff-backup":
    ensure => absent,
  }
}
