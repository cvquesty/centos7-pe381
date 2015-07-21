#!/bin/bash

# Perform a few steps first
export PATH=$PATH:/opt/puppet/bin

# Install Zack's r10k module
/opt/puppet/bin/puppet module install 'zack-r10k'

# Stop and disable Firewalld
/bin/systemctl stop  firewalld.service
/bin/systemctl disable firewalld.service

# Place the r10k configuration file
cat > /var/tmp/configure_r10k.pp << 'EOF'
class { 'r10k':
  version           => '2.0.2',
  sources           => {
    'puppet' => {
      'remote'  => 'https://github.com/cvquesty/puppet_repository.git',
      'basedir' => "${::settings::confdir}/environments",
      'prefix'  => false,
    }
  },
  manage_modulepath => false,
}
EOF

# Place the directory environments config file
cat > /var/tmp/configure_directory_environments.pp << 'EOF'
######                           ######
##  Configure Directory Environments ##
######                           ######

# Default for ini_setting resources:
Ini_setting {
  ensure => present,
  path   => "${::settings::confdir}/puppet.conf",
}

ini_setting { 'Configure environmentpath':
  section => 'main',
  setting => 'environmentpath',
  value   => '$confdir/environments',
}

ini_setting { 'Configure basemodulepath':
  section => 'main',
  setting => 'basemodulepath',
  value   => '$confdir/modules:/opt/puppet/share/puppet/modules',
}
EOF

# Now place the hiera.yaml in the proper location
cat > /etc/puppetlabs/puppet/hiera.yaml << 'EOF'
---
:backends:
  - yaml
:hierarchy:
  - "%{clientcert}"
  - "%{environment}"
  - common
:yaml:
  :datadir: "/etc/puppetlabs/puppet/environments/%{environment}/hieradata"
EOF

# Now, apply your new configuration
/opt/puppet/bin/puppet apply /var/tmp/configure_r10k.pp

# Then configure directory environments
/opt/puppet/bin/puppet apply /var/tmp/configure_directory_environments.pp

# And add the purgedirs setting to r10k
cat >> /etc/r10k.yaml << 'EOF'
:purgedirs:
  - /etc/puppetlabs/puppet/environments
EOF

# Do the first deployment run
/opt/puppet/bin/r10k deploy environment -pv

# Restart Puppet to pick up the new hiera.yaml
/sbin/service pe-puppet restart
/sbin/service pe-httpd restart
