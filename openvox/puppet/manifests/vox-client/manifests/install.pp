# install.pp — OpenVox demo manifest for vox-client
#
# Demonstrates:
#   - Cross-platform package installation (Debian/RedHat)
#   - File management with Facter variable interpolation
#   - Service management (built-in systemd service)
#
# This manifest is applied by the setup scripts as a verification
# that the OpenVox server↔client communication is working correctly.

# ── Package installation ──────────────────────────────────────────────

if $facts['os']['family'] == 'Debian' {
  package { 'emacs-nox':
    ensure => present,
  }
} elsif $facts['os']['family'] == 'RedHat' {
  package { 'emacs-nox':
    ensure => installed,
  }
} else {
  package { 'emacs-nox':
    ensure => present,
  }
}

# ── File management ───────────────────────────────────────────────────

file { '/etc/motd':
  ensure  => file,
  content => @("MOTD")
    ============================================
    Welcome to ${facts['fqdn']}
    Managed by OpenVox server: vox-server
    OS: ${facts['os']['family']} ${facts['os']['release']['full']}
    ============================================
    | MOTD
  ,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
}

# ── Service management ────────────────────────────────────────────────

service { 'systemd-timesyncd':
  ensure => running,
  enable => true,
}
