#!/bin/bash

##################
# A script to zero out the disks of an EL9 template for deployment
# If you set up your template to send discards to the storage (via fstrim or discard) this will instantly make your VM as small as it can be.
# VMware vSAN supports this natively, but if your storage doesn't do this you might have to storage vMotion it to somewhere else and back
# to get it to zero out the disks.

# This was written for EL6+, but it should work on a lot of other Linux distributions.
# You need 'dd' and 'bc' and 'df' and 'fstrim' installed on your template.

# There is almost no error checking here. Feel free to add some so that a pre-existing file named 'zf' or a logical volume named 'zero' will not be overwritten.
# In general this isn't a problem on a template, but if you use this on a production system you should be careful.

# You got this from https://github.com/plankers/virtualization-security-compliance/templates

export PREFIX="/sbin"

# Is this script already running?
if [ -a /tmp/zero-out-running ]; then
	echo "/tmp/zero-out-running exists, exiting."
	exit 0
fi

/bin/touch /tmp/zero-out-running
/bin/chmod 600 /tmp/zero-out-running

# Find all the xfs filesystems on the VM
# Could also use "egrep '(ext3|ext4|xfs)'" but xfs is the choice for EL systems.
FileSystem=`grep xfs /etc/mtab| awk -F" " '{ print $2 }'`

# For each filesystem, ask df how much space is free and use dd to write that many zeros to a file called zf in the filesystem.
# I did it this way so that it's possible to adjust the amount of space it consumes, and not cause a monitoring system to freak out
# if you run this on a production system (which I used to do -- this script is actually decades old). By saving a little free space 
# you will also avoid harming active processes who are trying to write to the filesystem.
#
# Templates don't really have a need for all of this, so it's set to 100%, but you can adjust the math being piped into bc to
# make it smaller or larger if you desire.
for i in $FileSystem
do
	echo $i
	number=`df -B 512 $i | awk -F" " '{print $3}' | grep -v Used`
	echo $number
	percent=$(echo "scale=0; $number * 100 / 100" | bc )
	echo $percent
	dd count=`echo $percent` if=/dev/zero of=`echo $i`/zf
	rm -f $i/zf
done

# Find all the volume groups
VolumeGroup=`$PREFIX/vgdisplay | grep Name | awk -F" " '{ print $3 }'`

# For each volume group, create a logical volume called zero and write zeros to it until it's full. Nothing fancy here.
for j in $VolumeGroup
do
	echo $j
	$PREFIX/lvcreate -l `$PREFIX/vgdisplay $j | grep Free | awk -F" " '{ print $5 }'` -n zero $j
	if [ -a /dev/$j/zero ]; then
		cat /dev/zero > /dev/$j/zero
		/bin/sync
		sleep 15
		$PREFIX/lvremove -f /dev/$j/zero
	fi
done

# Now that we've written and deleted zeros to all the filesystems and volume groups, we can trim the free space.
# This might cause the VM to pause for a short bit if it's a lot of stuff. Again, template systems don't care much,
# but your storage might. May want to avoid doing a lot of these all at once (or work up to it). vSAN will throttle
# TRIM activity if it's too much (meaning it protects the storage from your DoS attacks! HA!), and you can see it in
# the performance graphs. Doing one template at a time is likely pretty safe.
/sbin/fstrim --all

# Clear the lock file
/bin/rm /tmp/zero-out-running

