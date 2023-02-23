#!/bin/sh

dat=`date "+%T_%Y%m%d"`

if [ `whoami` != "oracle" ]; then
	echo 'script must be run by oracle user.....!'
	exit
fi
echo -e "What you want to do:)\n a)backup\n b)restore"
read -p "option: " option
read -p "Enter backup path: " bkppath

# create log file
createLog() {
	LOG=$bkppath/rman-$1_$dat.log
	touch $LOG
	echo "The log file was generated '$LOG'"
}

# backup function......
Backup() {
	createLog ${FUNCNAME[0]}
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
	configure controlfile autobackup off;
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
	configure controlfile autobackup on;
	configure controlfile autobackup format for device type disk to '${bkppath}/%F';
	backup current controlfile format '${bkppath}/${ORACLE_SID}.ctl';
	catalog start with '${bkppath}/' noprompt;
	list backup summary;
	crosscheck backup;
	alter database open;
	exit;
EOF2
}

# Restore functions.........
# this func used to restore the DB backup in same DB name and in same server where the backup was taken 
SameDBSameServer() {
	createLog ${FUNCNAME[0]}
	echo ''
	echo "***********************************************" >> $LOG
	echo "*****   Restoration log SameDBSameServer   ****" >> $LOG
	echo "***********************************************" >> $LOG
	echo ''
	sqlplus / as sysdba << EOF3 >> $LOG
	shut immediate;
	startup nomount;
	exit;
EOF3
	rman target/ << EOF3 >> $LOG
	restore controlfile from '${bkppath}/${ORACLE_SID}.ctl';
	alter database mount;
	catalog start with '${bkppath}/' noprompt;
	run{
	allocate channel ch1 type disk;
	allocate channel ch2 type disk;
	allocate channel ch3 type disk;
	allocate channel ch4 type disk;
	allocate channel ch5 type disk;
	restore database;
	release channel ch1;
	release channel ch2;
	release channel ch3;
	release channel ch4;
	release channel ch5;
	}
	recover database noredo;
	alter database open resetlogs;
	exit;
EOF3
}

# this func used to restore the DB backup in same DB name on different server
SameDBnameDiffServer() {
	createLog ${FUNCNAME[0]}
	echo ''
	echo "*******************************************************" >> $LOG
	echo "******    Restoration log SameDBnameDiffServer   ******" >> $LOG
	echo "*******************************************************" >> $LOG
	echo ''
	read -p "Enter SID of db: " SID >> $LOG
	rm -rf /tmp/*$SID >> $LOG
	rm -rf $ORACLE_HOME/dbs/*$SID*/ >> $LOG
	rm -rf $ORACLE_BASE/admin/$SID/adump/* >> $LOG
	mkdir -p $ORACLE_BASE/admin/$SID/adump/ >> $LOG
	mkdir -p $ORACLE_BASE/oradata/$SID/ >> $LOG 
	mkdir -p $ORACLE_BASE/recovery_area/$SID/ >> $LOG 
	sqlplus / as sysdba << EOF4 >> $LOG
	shut immediate;
	exit;
EOF4
	export ORACLE_SID=$SID
	sqlplus / as sysdba << EOF5 >> $LOG
	create pfile from spfile='${bkppath}/spfile${SID}.ora';
	startup nomount pfile='${ORACLE_HOME}/dbs/init${SID}.ora';
	create spfile from pfile='${ORACLE_HOME}/dbs/init${SID}.ora';
	show parameter spfile;
	alter system set spfile='${ORACLE_HOME}/dbs/spfile${SID}.ora';
	show parameter spfile;
	exit;
EOF5
	rman target/ << EOF5 >> $LOG
	restore controlfile from '${bkppath}/${SID}.ctl'
	alter database mount;
	catalog start with '${bkppath}/' noprompt;
	list backup summary;
	crosscheck backup;
	delete noprompt expired backup;
	list backup summary;
	crosscheck backup;
	run{
	allocate channel ch1 type disk;
	allocate channel ch2 type disk;
	allocate channel ch3 type disk;
	allocate channel ch4 type disk;
	allocate channel ch5 type disk;
	restore database;
	release channel ch1;
	release channel ch2;
	release channel ch3;
	release channel ch4;
	release channel ch5;
	}
	recover database;
	alter database open resetlogs;
	exit;
EOF5
}

# this func used to restore DB backup in different DB name
DiffDBname() {
	createLog ${FUNCNAME[0]}
	echo ''
	echo "***********************************************" >> $LOG
	echo "*******    Restoration log NewDBname     ******" >> $LOG
	echo "***********************************************" >> $LOG
	echo ''
	read -p "Enter SID of newdb: " newSID >> $LOG
	sqlplus / as sysdba << EOF6 >> $LOG
	shut immediate;
	create pfile='init${SID}.ora' from spfie='${bkppath}/spfile${SID}.ora';
	startup nomount pfile='${ORACLE_HOME}/dbs/init${SID}.ora';
	create spfile from pfile;
	alter system set spfile='${ORACLE_HOME}/dbs/spfile${SID}.ora';
	exit;
EOF6
	rman target/ << EOF7 >> $LOG
	restore controlfile from '${bkppath}/ctlbkp${SID}.ctl'
	alter database monut;
	catalog start with '${bkppath}/' noprompt;
	run{
	allocate channel ch1 type disk;
	allocate channel ch2 type disk;
	allocate channel ch3 type disk;
	set newname for database to '${ORACLE_BASE}/oradata/${newSID}/%U'; 
	restore database;
	switch datafile all;
	switch tempfile all;
	recover database;
	release channel ch1;
	release channel ch2;
	release channel ch3;
	}
	exit;
EOF7
	sqlplus / as sysdba << EOF8 >> $LOG
	select * from v\$tempfile;
	select * from v\$logfile;
	alter database rename file '${ORACLE_BASE}/oradata/${SID}/redo01.log' to '${ORACLE_BASE}/oradata/${newSID}/redo01.log';
	alter database open resetlogs;
	shut immediate;
	startup mount;
	exit;
EOF8
	nid target=$usrname/$passwd dbname=$newSID << EOF9 >> $LOG
	Y
EOF9
	sqlplus / as sysdba << EOF10 >> $LOG
	startup nomount;
	alter system set db_name=${newSID} scope=spfile;
	create pfile from spfile;
	shut immediate;
	startup mount;
	alter database open resetlogs;
	exit;
EOF10
	echo "consistency check........!"
	sqlplus / as sysdba << EOF11 >> $LOG
	shut immediate;
	startup;
	select name,open_mode,log_mode form v\$database;
	exit;
EOF11
}

if [ "$option" = "a" ]; then
	Backup
elif [ "$option" = "b" ]; then
	echo -e "Restore options:)\n a)same DBname same Server\n b)same DBname different Server\n c)Different DBname"
	read -p 'option: ' option
	if [ "$option" = "a" ]; then
		SameDBSameServer
	elif [ "$option" = "b" ]; then
		SameDBnameDiffServer
	elif [ "$option" = "c" ]; then
		DiffDBname
	else
		echo "Enter valid option.......!"
		exit
	fi
else
	echo "Enter valid option.......!"
	exit
fi