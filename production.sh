#!/bin/bash

# Create custom fact to refelct the environment
/bin/mkdir -p /etc/puppetlabs/facter/facts.d
cat > /etc/puppetlabs/facter/facts.d/application_tier << 'EOF'
#!/bin/bash
echo "application_tier=production"
EOF

/bin/chmod 0755 /etc/puppetlabs/facter/facts.d/application_tier
