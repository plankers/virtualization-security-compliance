#!/bin/sh

##################
# A script to clean up an EL9 template for deployment
# As with other scripts, this is not a complete solution, but it is a starting point.
# Leave it in /root in your templates and call it before you shut the VM template down.

# You got this from https://github.com/plankers/virtualization-security-compliance/templates

# Stop services that might be fighting you.
/sbin/service rsyslog stop
/sbin/service puppet stop
/sbin/service auditd stop

# Easily corrupted, prevents logging
/bin/rm -f /var/lib/rsyslog/imjournal.state

# Remove all extra kernels
dnf -y remove $(dnf repoquery --installonly --latest-limit=-1 -q)

# Force the logs to rotate and then delete old ones.
/usr/sbin/logrotate -f /etc/logrotate.conf
/bin/rm -f /var/log/*-????????
/bin/rm -f /var/log/*-????????.gz
/bin/rm -f /var/log/dmesg.old
/bin/rm -rf /var/log/anaconda
/bin/find /var/log -type f -name \*gz -delete -print

# Some logs and log-like things need to be made empty in another way
/bin/cat /dev/null > /var/log/audit/audit.log
/bin/cat /dev/null > /var/log/wtmp
/bin/cat /dev/null > /var/log/lastlog
/bin/cat /dev/null > /var/log/grubby
/bin/cat /dev/null > /run/utmp

# Don't leave junk in /tmp or /var/tmp
/bin/find /tmp -type l -delete -print
/bin/find /tmp -type f -delete -print
/bin/find /var/tmp -type l -delete -print
/bin/find /var/tmp -type f -delete -print
/bin/rm -rf /tmp/*
/bin/rm -rf /var/tmp/*

# You want all your new VMs to have their own SSH keys
/bin/rm -f /etc/ssh/*key*

# Don't let bash create more history for us
export HISTFILESIZE=0
export HISTSIZE=0
unset HISTFILE

# More history to remove from users
/bin/find / -name .ssh -type d -print -exec rm -rf {}\;
/bin/find / -name .Xauthority -type f -delete -print
/bin/rm -rf /root/.java/ /root/.cache/ /root/.oracle_jre_usage/ /root/.nano_history 
/bin/find / -name .bash_history -type f -delete -print
/bin/find / -name .history -type f -delete -print

# Remove the backup files for the system auth.
/bin/rm -f /etc/group-
/bin/rm -f /etc/gshadow-
/bin/rm -f /etc/passwd-
/bin/rm -f /etc/shadow-
/bin/rm -f /etc/subgid-
/bin/rm -f /etc/subuid-

# Bad things seem to happen when this is missing, doesn't just regenerate.
# We want to make sure it's unique, so we'll just delete it and force it to be regenerated.
/bin/rm -f /etc/machine-id
/bin/systemd-machine-id-setup

# Lots of random stuff we probably shouldn't keep on a template.
# Not all of it is going to be on your template, so you'll likely see some errors. No big deal.
/bin/rm -f /etc/Pegasus/.cnf
/bin/rm -f /etc/Pegasus/.crt
/bin/rm -f /etc/Pegasus/.csr
/bin/rm -f /etc/Pegasus/.pem
/bin/rm -f /etc/Pegasus/.srl
/bin/rm -f /root/anaconda-ks.cfg
/bin/rm -f /root/anaconda-post.log
/bin/rm -f /root/initial-setup-ks.cfg
/bin/rm -f /root/install.log
/bin/rm -f /root/install.log.syslog
/bin/rm -f /root/original-ks.cfg
/bin/rm -f /var/cache/fontconfig/
/bin/rm -f /var/cache/gdm/*
/bin/rm -f /var/cache/man/*
/bin/rm -f /var/lib/AccountService/users/*
/bin/rm -f /var/lib/fprint/*
/bin/rm -f /var/lib/logrotate.status
/bin/rm -f /var/log/.log
/bin/rm -f /var/log/BackupPC/LOG
/bin/rm -f /var/log/ConsoleKit/*
/bin/rm -f /var/log/anaconda.syslog
/bin/rm -f /var/log/anaconda/*
/bin/rm -f /var/log/apache2/_log
/bin/rm -f /var/log/apache2/_log-*
/bin/rm -f /var/log/apt/*
/bin/rm -f /var/log/aptitude*
/bin/rm -f /var/log/audit/*
/bin/rm -f /var/log/btmp*
/bin/rm -f /var/log/ceph/.log
/bin/rm -f /var/log/chrony/.log
/bin/rm -f /var/log/cron*
/bin/rm -f /var/log/cups/_log
/bin/rm -f /var/log/debug*
/bin/rm -f /var/log/dmesg*
/bin/rm -f /var/log/exim4/*
/bin/rm -f /var/log/faillog*
/bin/rm -f /var/log/firewalld*
/bin/rm -f /var/log/gdm/*
/bin/rm -f /var/log/glusterfs/glusterd.vol.log
/bin/rm -f /var/log/glusterfs/glusterfs.log
/bin/rm -f /var/log/grubby
/bin/rm -f /var/log/httpd/log
/bin/rm -f /var/log/installer/
/bin/rm -f /var/log/jetty/jetty-console.log
/bin/rm -f /var/log/journal/*
/bin/rm -f /var/log/lastlog*
/bin/rm -f /var/log/libvirt/libvirtd.log
/bin/rm -f /var/log/libvirt/libxl/.log
/bin/rm -f /var/log/libvirt/lxc/.log
/bin/rm -f /var/log/libvirt/qemu/.log
/bin/rm -f /var/log/libvirt/uml/.log
/bin/rm -f /var/log/lightdm/*
/bin/rm -f /var/log/mail/*
/bin/rm -f /var/log/maillog*
/bin/rm -f /var/log/messages*
/bin/rm -f /var/log/ntp
/bin/rm -f /var/log/ntpstats/*
/bin/rm -f /var/log/ppp/connect-errors
/bin/rm -f /var/log/rhsm/*
/bin/rm -f /var/log/sa/*
/bin/rm -f /var/log/secure*
/bin/rm -f /var/log/setroubleshoot/.log
/bin/rm -f /var/log/spooler
/bin/rm -f /var/log/squid/.log
/bin/rm -f /var/log/syslog
/bin/rm -f /var/log/tallylog*
/bin/rm -f /var/log/tuned/tuned.log
/bin/rm -f /var/log/wtmp*
/bin/rm -f /var/log/xferlog*
/bin/rm -f /var/named/data/named.run
/bin/rm -f /var/log/*.log
/bin/rm -f /var/log/*.log.0

# Remove remnants of patches and such. Don't need these on a template.
/bin/find / -name \*.bak -type f -delete -print
/bin/find / -name \*.rpmnew -type f -delete -print
/bin/find / -name \*.rpmsave -type f -delete -print

# Some systems used to use this. If you need it here it is.
# /bin/touch /.unconfigured

# Remove remnants of Puppet so it'll re-register cleanly
# Your own configuration management tool will likely have a different way to do this.
/bin/find /etc/puppetlabs/puppet/ssl -type f -delete
/bin/find /opt/puppetlabs/puppet/cache/ -delete
/bin/find /etc/puppetlabs/ -delete

# Unsubscribe from any vendors or providers, and clean up the package cache.
# In this case we're using a Red Hat subscription.
# Do this last because other things depend on them.
/usr/sbin/subscription-manager remove --all
/usr/sbin/subscription-manager unregister
/usr/sbin/subscription-manager clean
/usr/bin/dnf -y clean all
/bin/find /var/cache/dnf -delete -print

# Ensure the guest can be customized with a script.
# You'll want to set this to false again on deployment, so that a malicious user can't redeploy a clone of a VM
# and then re-customize the clone to give themselves admin access.
/usr/bin/vmware-toolbox-cmd config set deployPkg enable-custom-scripts true
/usr/bin/vmware-toolbox-cmd config set deployPkg enable-customization true