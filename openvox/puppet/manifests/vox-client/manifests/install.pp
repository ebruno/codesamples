if $facts['os']['family'] == 'Debian' {
  # Code specific to Debian/Ubuntu nodes
  package { 'emacs-nox':
    ensure => present,
  }
} elsif $facts['os']['family'] == 'RedHat' {
  # Code specific to RHEL/CentOS nodes
  package { 'emacs-nox':
    ensure => installed,
  }
}
