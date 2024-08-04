#!/bin/sh

##################
# A script to set up a new EL9 system
# As with other scripts, this is not a complete solution, but it is a starting point.
# Leave it in /root in your templates and call it from the Guest Customization script.

# You got this from https://github.com/plankers/virtualization-security-compliance/templates

##################
# Basic cleanup of the template, post-deployment

# Delete the spurious old connection from the template
# You can see the UUID from 'nmcli connection' on the template
# You'll want to add the UUID from your template to the following commands (these are my UUIDs, likely different for you)
/bin/nmcli connection delete f29727c7-88fe-34bc-b354-80dca9ecab23
/bin/nmcli connection delete 87785c1f-309d-3b42-82df-4b1c7b8f85b6

# Disable IPv6 if it isn't in use 
/bin/nmcli connection modify ens33 ipv6.method "disabled"

##################
# Register with any vendors or providers. In this case we're showing a Red Hat subscription.
# Whether it's a good idea to put your activation key in a template is up to you. I wouldn't put usernames and passwords in here.
# You can also put it in the Guest Customization script, register it manually after deployment, even delete the script after it runs.
#
#/usr/bin/subscription-manager unregister
#/usr/bin/subscription-manager register -org=ORG ID --activationkey=KeyName
#/usr/bin/subscription-manager role --set="Red Hat Enterprise Linux Server"
#/usr/bin/subscription-manager service-level --set="Self-Support"
#/usr/bin/subscription-manager usage --set="Development/Test"
#/usr/bin/subscription-manager attach

##################
# Configure and run your configuration management tool
# In this case we're using Puppet. You can also use Chef, Ansible, Salt, or anything else.
# You'll need to install the appropriate package for your tool, either here or in the template.

# Remove any old remnants of Puppet
/bin/find /etc/puppetlabs/puppet/ssl -type f -delete
/bin/find /opt/puppetlabs/puppet/cache/ -delete
/bin/find /etc/puppetlabs/ -delete

# Register the system with Puppet
/opt/puppetlabs/puppet/bin/puppet config set server your.puppet.server.org --section agent
/opt/puppetlabs/puppet/bin/puppet config set environment rhel9 --section agent
/opt/puppetlabs/puppet/bin/puppet agent -t --environment rhel9

# Ensure the guest cannot be further customized.
# You'll want to set this to false on deployment, so that a malicious user can't redeploy a clone of a VM
# and then re-customize the clone to give themselves admin access.
/usr/bin/vmware-toolbox-cmd config set deployPkg enable-custom-scripts false
/usr/bin/vmware-toolbox-cmd config set deployPkg enable-customization false