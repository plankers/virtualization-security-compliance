**VMware vSphere/VCF TPM Recovery Key Backup Utility**  
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

This script emits information that should be protected. Someone with these keys
can gain access to the data they protect. Use appropriate precautions.

Also, don't store this data on the infrastructure itself. A good place for it
is where you securely store your Native Key Provider backups, too.

Introduction
============

Trusted Platform Modules are an important part of ESXi host security, and if
they are installed and enabled correctly they will hold an encryption key
used to decrypt the ESXi host's encrypted configuration.

If the TPM is cleared, replaced, or for some reason no longer can provide the
key to ESXi, the host will not boot. There is only one method to recover from
this situation: re-enter the key. After vSphere 7.0.2 you cannot conduct any
sort of "recovery boot." You have to reinstall ESXi at that point.

To avoid this, proactively back the TPM Recovery Keys up. vCenter will prompt
you to do so, but won't help you much with the actual task. That's where this
example script comes in.

Usage
=====

backup-tpm-recovery-keys.ps1 has one mandatory argument:

OutputFileName, which is the file to which it will append the keys

and two optional arguments:

AcceptEULA, if you're tired of my warnings.

NoSafetyChecks, which will omit the checks for versions, number of vCenters, etc.

The script does not change the environment and should be safe at all times.

Entering a Recovery Key
=======================

If you do need to enter a recovery key, use Shift-O at the ESXi boot prompt and
append:

encryptionRecoveryKey=<YOUR KEY>

to the boot parameters. Yes, it's long. You might want to paste it into a text
editor, make it large, and make it a monospaced font. Not that I've ever had
to do that before...

Once the host boots you can run:

/sbin/auto-backup.sh

manually if you want to write the key to the TPM again, or wait a while and ESXi
will run it automatically, too (helpful if you want to reboot again right away,
though).

More Information
================

I publish a lot of vSphere/VCF security material at:

https://bit.ly/vcf-security

including links to videos about Native Key Provider, vTPM, and more, all of which
would be relevant here. It also includes discussions on where you might (and where
you might NOT) want to use different key providers, etc.
