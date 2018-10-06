#!/bin/bash
#
#Credit to cabal95.
#Edited for my env.
#The idea is to run silent.
#
#Set log and date/time
DATE=`date +%Y-%m-%d.%H:%M:%S`
LOG=/var/log/kvm-backup.$DATE.LOG

# List domains
DOMAINS=$(virsh list | tail -n +3 | awk '{print $2}')

# Loop over the domains found above and do the
# actual backup

for DOMAIN in $DOMAINS; do
	
	echo "-----------WORKER START $DOMAIN-----------" > $LOG
	echo "Starting backup for $DOMAIN on $(date +'%d-%m-%Y %H:%M:%S')"  >> $LOG

	# Generate the backup folder URI - this is something you should
	# change/check
	BACKUPFOLDER=/your/folder/path/$DOMAIN/$(date +%d-%m-%Y)
	mkdir -p $BACKUPFOLDER

	# Get the target disk
	TARGETS=$(virsh domblklist $DOMAIN --details | grep disk | awk '{print $3}')

	# Get the image page
	IMAGES=$(virsh domblklist $DOMAIN --details | grep disk | awk '{print $4}')

	# Create the snapshot/disk specification
	DISKSPEC=""

	for TARGET in $TARGETS; do
		DISKSPEC="$DISKSPEC --diskspec $TARGET,snapshot=external"
	done

	virsh snapshot-create-as --domain $DOMAIN --name "backup-$DOMAIN" --no-metadata --atomic --disk-only $DISKSPEC >> $LOG

	if [ $? -ne 0 ]; then
		echo "Failed to create snapshot for $DOMAIN" > $LOG
		exit 1
	fi

	# Copy disk image
	for IMAGE in $IMAGES; do
		NAME=$(basename $IMAGE)
		#You can use rsync or cp.
		virtsync -v $IMAGE $BACKUPFOLDER/$NAME >> $LOG
	done

	# Merge changes back
	BACKUPIMAGES=$(virsh domblklist $DOMAIN --details | grep disk | awk '{print $4}')

	for TARGET in $TARGETS; do
		virsh blockcommit $DOMAIN $TARGET --active --pivot >> $LOG

		if [ $? -ne 0 ]; then
			echo "Could not merge changes for disk of $TARGET of $DOMAIN. VM may be in invalid state." > $LOG
			exit 1
		fi
	done

	# Cleanup left over backups
	for BACKUP in $BACKUPIMAGES; do
		rm -f $BACKUP
	done

	# Dump the configuration information.
	virsh dumpxml $DOMAIN > $BACKUPFOLDER/$DOMAIN.xml
	echo "-----------WORKER END $DOMAIN-----------" >> $LOG
	echo "Finished backup of $DOMAIN at $(date +'%d-%m-%Y %H:%M:%S')" >> $LOG

	#Now we email the log file using ssmtp
	ssmtp yourname@yourdomain.com < $LOG
done

exit 0
