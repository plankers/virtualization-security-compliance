**VMware vSphere/VCF Key Provider Audit & Change Examples**  
Copyright (C) 2024 Bob Plankers. All rights reserved.  
bob.plankers@broadcom.com or bob@plankers.com  

License
===============	

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Disclaimer/EULA
===============

This software is provided as is and any express or implied warranties,
including, but not limited to, the implied warranties of merchantability and
fitness for a particular purpose are disclaimed. In no event shall the
copyright holder or contributors be liable for any direct, indirect,
incidental, special, exemplary, or consequential damages (including, but not
limited to, procurement of substitute goods or services; loss of use, data,
or profits; or business interruption) however caused and on any theory of
liability, whether in contract, strict liability, or tort (including
negligence or otherwise) arising in any way out of the use of this software,
even if advised of the possibility of such damage. The provider makes no
claims, promises, or guarantees about the accuracy, completeness, or adequacy
of this sample. Organizations should engage appropriate legal, business,
technical, and audit expertise within their specific organization for review
of requirements and effectiveness of implementations. You acknowledge that
there may be performance or other considerations, and that this example may
make assumptions which may not be valid in your environment or organization.

Support
===============

This software is not supported, though the techniques it uses are supported by 
Broadcom. While I am grateful for suggested improvements and I do enjoy
helping people, I am not an official support path, and I will not respond
in that manner. I put this together because lots of people wanted an example 
of how to do it, but the responsibility is yours.

For that, look to official support channels. If you need more specific
support ask Broadcom about Professional Services, who can shepherd an
operation like this.

Warning
=======

Make backups of all configurations and data before using this tool. Where
prompted, monitor task progress directly in the vSphere Client.

Introduction
============

Data-at-rest encryption in VMware vSphere and Cloud Foundation can be enabled:

- For virtual machines using VM Encryption, which allows you to selectively
  encrypt some or all of the components (VMDK, configuration, etc.) of a
  virtual machine.

- For virtual machines via the virtual TPM (vTPM), which uses VM Encryption
  to selectively encrypt the VM NVRAM and swap files to protect the secrets
  held in the vTPM

- For entire vSAN datastores, as part of the data-at-rest protections in vSAN

- For ESXi hosts, where host core dumps and support bundles are encrypted, as
  they may contain data about encrypted virtual machines

- Inside the virtual machines as with any OS installation, though this is
  outside the scope of discussion here.

Types of Key Providers
======================

To enable data-at-rest encryption, you need to configure a key provider. A
key provider does what its name suggests: provides encryption keys to the
environment. There are two types of key providers:

- Standard Key Provider, which uses the KMIP protocol to speak to an external
  Key Management System (not provided as part of vSphere/VCF). Standard Key
  Providers have been available since vSphere 6.5.

- Native Key Provider, which is part of vSphere/VCF and handles encryption
  keys internally within the system. Anyone running vSphere 7.0.2 or VCF 4.2
  or newer can use the Native Key Provider.

You can define up to 32 key providers per vCenter. Key providers are
configured on all hosts attached to that vCenter. You cannot selectively
assign key providers to hosts. Beginning with vSphere 8.0.1 you can specify
different default providers on a per-cluster basis.

If you use Enhanced Linked Mode the providers are not synchronized, and will
only be available to hosts that are directly attached to a particular vCenter.

You can configure (or restore, for Native Key Provider) the same provider
across multiple vCenters if you want, which will enable seamless use of 
cross-vCenter vMotion, as well as the ability to import DR copies of 
encrypted VMs.

Encrypted objects find their key provider by name, so do not use the same name
for different providers, even across different vCenters. It will be confusing
and error-prone, especially for Native Key Provider backups where you might
end up with multiple files on disk with the same name. 

If the provider is unique always give it a unique name. If it's shared, such as
with a Standard Key Provider, always give it the same name.

Types of Encryption Keys
========================

There are two keys associated with data-at-rest encryption:

- Data Encryption Key (DEK) which protects the object itself.

- Key Encryption Key (KEK) which protects the DEK.

Hosts only have one key for their core dumps and support bundles.

Two keys are used for flexibility and security. The DEK is generated inside
vSphere and stored in the .VMX configuration file for the virtual machine. To
protect it, it is encrypted with the KEK, where the KEK is stored with the key
provider.

Rekeying
========

At times it is necessary to rotate keys:

- Changing the DEK is referred to as a "deep rekey." A deep rekey of a virtual
  machine requires the virtual machine to be powered off, and requires enough
  free space on the datastore to accommodate a full copy of the data stored
  by the VM. As an example, if the VM is 4.5 TB on disk you will need 4.5 TB
  of free space on that datastore to do a deep rekey.

  A deep rekey of vSAN does not require downtime, but will reformat/rewrite the
  disk groups and objects in the background, which can be time consuming (though
  you do not have to sit and watch it), performance-intensive on the network,
  and impart wear on flash/NVMe/SSD devices, reducing their lifespan. 
  You will need enough free space to accommodate the temporary loss of a disk
  group (for OSA) or the recreation of the largest objects on the datastore
  (for ESA). You can speed the process by checking the box to allow vSAN to
  reduce the redundancy it maintains, but in a production environment that is
  not advised. Just let it proceed in the background.

  Also note that the initial encryption of a VM or a vSAN volume is the same
  deep rekey process, including space requirements.

- Changing the KEK is referred to as a "shallow rekey." A shallow rekey of
  both virtual machines and vSAN can be done quickly and requires no downtime.
  It is relatively fast because it only re-encrypts the DEK with a new
  KEK. vSphere/VCF can do that operation with everything online, and workloads
  do not notice.

Changing Key Providers
======================

We can use the shallow rekey operation to change key providers, by instructing
vSphere/VCF to get the new KEK from a different key provider. You can switch
between both types of provider using this method. It is very flexible, and you
get a "free" key rotation in the process, too.

In the UI this is possible by defining a new default key provider and using the
"VM Policies -> Re-Encrypt" menu item. However, it is also very straightforward
to use PowerCLI to make these changes in bulk. These scripts are examples of
how to do it using PowerCLI 13.1 and newer.

- audit-keyprovider.ps1 is an example of how to print out the encryption state
  of the objects that might be encrypted. It will survey any vCenter you are
  attached to. In general, just be attached to one.

- change-keyprovider.ps1 takes a parameter, NewKeyProviderName, which is the
  name of the provider you want to switch everything to. 

These scripts have some checks built in but you'll want to run it in a test
environment to develop familiarity with it. They assume a fully operational
environment, no maintenance mode, etc. and that you're connected to only
one vCenter via Connect-VIServer.

The change-keyprovider.ps1 script is not all that smart and will pause between
sections to ensure the tasks complete. By that, it wants you to make sure they
are complete, and then hit a key.

Capturing Script Output
=======================

These scripts do not emit fancy output (colored text and such) but that comes
with the advantage that you can use the Powershell output redirection commands
like:

./audit-keyprovider.ps1 | Tee-Object -FilePath output.txt -Append
./change-keyprovider.ps1 -NewKeyProviderName NAME | Tee-Object -FilePath output.txt -Append

to capture the output for analysis later. You can also edit the output if you
desire CSV output or something. Excel is a powerful and overlooked sysadmin
tool, after all.

Default Key Providers
=====================

Beginning in vSphere 8.0.1 individual clusters can define their own default key
provider, versus having to respect the default that is defined at the vCenter
level. There is not a programmatic way to audit that in PowerCLI at this time.
The change script will reset vCenter to use the provider you specify as the
default, and remove any cluster-level customizations you might have. 

Problems
========

The process is resilient, so if it fails you can just start again. You can
always rekey with the same provider you're already using. I probably rekeyed one
of my environments 75 times while putting all this together.

If the script doesn't detect PowerCLI when you know it is installed just comment
or remove that check. Certain methods of installing PowerCLI do not appear
to be "seen" by the Powershell module inventory.

Host Caching of Keys
====================

ESXi caches the encryption keys for encrypted objects in its memory, to prevent
issues if the key provider becomes unavailable. As such, you might not know
you have an issue until you remove the old key provider and reboot a host. It's
important to have backups of key providers and connection information.

Sample Order of Operations for a Key Provider Change
====================================================

All environments are different, and you will need to audit this in the context of
your own installation, but a sample order of operations for changing a key 
provider might be:

1.  Create the new key provider. If creating a new Native Key Provider do not
    check "Use key provider only with TPM protected ESXi hosts (Recommended)"

    If your hosts have a working TPM it will always use it. If you have hosts 
    attached to your vCenter that do not have TPMs they will be unable to
    participate, and you will encounter strange errors later.

    If you know all of your hosts have a TPM and it's enabled and working feel
    free to check the box.

    If you do encounter problems you can remove and restore the key provider from
    the backup you took (and not check that box during the restore!).

2.  Set the new key provider as the default.

3.  Create a sample encrypted VM to test that the key provider works.

4.  Back up all key provider information. For Standard Key Providers this would be
    the connection information and certificates for authentication. For Native
    Key Providers this is the .p12 file that you get from the backup function.

5.  Audit the environment to note your starting condition. Fix errors.

6.  Check your clusters to see if there is a customized key provider default.
    Note anything that isn't set to "Use default for vCenter Server"

7.  Ensure the clusters are fully operational, nothing in maintenance mode, no
    meaningful alarms that need to be addressed.

8.  Change the key provider. Let the script run through everything.
    If you have a busy environment that provisions encrypted VMs you might want to
    temporarily enact a change freeze.

9.  Audit the environment again. Repeat step 8 as needed. As noted earlier it
    can be run multiple times if it stops for some reason.

10. Restore cluster-level default key providers, if there were any.
    Double-check the vCenter-level default key provider.

11. Put one host into maintenance mode. Reboot it. Ensure it comes back online
    without issue, mounts the encrypted vSAN volume, and runs encrypted workloads.

12. Remove old key provider from vCenter. If it is a Native Key Provider ensure
    you have a backup (the .p12 file) stored safely in case it needs to be restored.

13. Reboot one host again. Ensure it comes back online, mounts the encrypted
    vSAN volume, and runs encrypted workloads.

14. Do not decommission your external KMS until after the next time you reboot
    all hosts (good reason to patch everything). See below for discussion on
    decommissioning.

Test Environments
=================

I cannot stress enough that even a simple test environment, such as a nested set
vCenter and ESXi hosts, is very helpful for establishing familiarity with these
sorts of operations. Your production environment should never be the first place
you're trying something.

Decommissioning Key Providers
=============================

One of the largest issues with making general recommendations about encryption
is that only YOU know where encrypted copies of VMs are. For example, if you
use storage replication, and keep a series of snapshots of those volumes, you
will have copies of VMs with the old keys and key provider definitions. If you
were to need those VMs they would not be importable into your environment
until you restored the key provider.

Same for array-based snapshots, too. And some arrays are able to interact with
the key providers to allow both data-at-rest encryption and deduplication.
Consideration for that fancy tech isn't made in the order of operations above.

With Native Key Provider this isn't a huge issue, because it's relatively easy to
keep the small .p12 backup file somewhere secure. For external Key Management
Systems, though, you will probably want to keep those in a state where they can
be restored or powered on again if needed, for as long as your DR/BC retention
policy is.

VM backup products that use the native backup APIs should not be impacted, because
encrypted VMs are decrypted automatically, and the data given to the backup
system "in the clear" (though network communications are still fully protected
with TLS, so don't get too worried). It is done this way to allow backup systems
to do their own deduplication and compression, which would not be possible if 
they only received the ciphertext (encrypted form of the data) from vSphere/VCF.

It may still be worth checking with your backup provider and/or storage provider
to ensure that there's nothing that would be affected when you do this operation.

More Information
================

I publish a lot of vSphere/VCF security material at:

https://bit.ly/vcf-security

including links to videos about Native Key Provider, vTPM, and more, all of which
would be relevant here. It also includes discussions on where you might (and where
you might NOT) want to use different key providers, etc.

Good Luck
=========

This might seem complicated but it's not too bad. Try it out and you'll see how it 
works. Keep your backup keys for Native Key Provider! And change the script to do
what you want. Don't have to put up with my output, after all. :) -Bob
