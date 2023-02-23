#!/bin/bash

dat=`date "+%Y%m%d"`
nas="/mnt/backups/T24_backups/RMAN"

if [ `whoami` != "oracle" ]; then
	echo 'script must be run by oracle user.....!'
	exit
fi


# backup function......
Backup() {
	export ORACLE_SID=$1
	bkppath=$2
	mkdir -p $bkppath
	LOG=$bkppath/rman-$ORACLE_SID-bkp.log
	touch $LOG
	echo ''
	echo "***********************************************" >> $LOG
	echo "******           Backup log              ******" >> $LOG
	echo "***********************************************" >> $LOG
	echo ''
	cp $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora $bkppath >> $LOG
	sqlplus / as sysdba << EOF1 >> $LOG
	shut immediate;
	startup mount;
	exit;
EOF1
	rman target/ << EOF2 >> $LOG
	show all;
	configure backup optimization on;
	configure controlfile autobackup on;
	configure controlfile autobackup format for device type disk to '${bkppath}/%F';
	show all;
	run{
	allocate channel ch1 type disk format '${bkppath}/%I-%Y%M%D-%U' maxpiecesize 3G;
	allocate channel ch2 type disk format '${bkppath}/%I-%Y%M%D-%U' maxpiecesize 3G;
	allocate channel ch3 type disk format '${bkppath}/%I-%Y%M%D-%U' maxpiecesize 3G;
	allocate channel ch4 type disk format '${bkppath}/%I-%Y%M%D-%U' maxpiecesize 3G;
	allocate channel ch5 type disk format '${bkppath}/%I-%Y%M%D-%U' maxpiecesize 3G;
	backup as compressed backupset database plus archivelog;
	release channel ch1;
	release channel ch2;
	release channel ch3;
	release channel ch4;
	release channel ch5;
	}
	catalog start with '${bkppath}/' noprompt;
	list backup summary;
	crosscheck backup;
	delete noprompt expired backup;
	list backup summary;
	crosscheck backup;
	alter database open;
	exit;
EOF2
	echo -e "\n-----------------------\n" >> $LOG
	cd $bkppath
	tar -zcvf $nas/$ORACLE_SID.$dat.tgz . >> $nas/tar-$ORACLE_SID.$dat.log
}


SIDs=("R22DB26" "APPT24" "APPT24ARC")

for SID in ${SIDs[@]}; do
	bkpath="/home/oracle/backups/${dat}/${SID}"
	Backup $SID $bkpath &
done