# backupkvm
Back up your KVM images using rsync or virtsync
#
This script came from @cabal95 but I modified the code to fit my needs.

The idea is to have a silent backup happen under cron with a log output that gets email to a destination.

I use ssmtp for the email portion. Please not that you can use what ever mail program you would like.

virtsync is an application that you can license and basically does the same thing as rsync --sparse and --inplace. It does have its sperks... You do not need virtsync for this script to work. Just change the line with "virtsync" to your choice of "cp" or "rsync".

This script does use active blockcommit.

#
**From wiki.libvirt.org**

"Active blockcommit" is a two phase operation: (1) once an external snapshot (which results in a qcow2 overlay that tracks the new writes from then on) is taken, the content from the overlay can be copied into its backing file (e.g. 'base'); then (2) pivot live QEMU to 'base'. All of this while the guest is running.

This is possible with versions: QEMU 2.1 (and above), libvirt-1.2.9 (and above)

For more info and exmaple please visit: [Libvirtd Wiki](https://wiki.libvirt.org/page/Live-disk-backup-with-active-blockcommit)
#

