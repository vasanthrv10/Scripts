#!/bin/bash

# Script for configuring oracle installation
# Developed by: VASANTHAN

# check root privilege and path
if [ '$(id -u)' -ne 0 ]; then
	echo "Only root user can run this script...!"
elif [ $# -ne 1 ]; then
	echo "script usage: $0 {oracle_file_path}"
else
	path=$1
	dat=($(date "+%T_%Y%m%d"))	
	touch $path/oraconf_$dat.log
	logpath=$path/oraconf_$dat.log
	bash_profile="/home/oracle/.bash_profile"
	UserGrpCreation $logpath
	FileConf $logpath $bash_profile
	Installer $path $logpath
fi


UserGrpCreation() {
	# group creation
	logpath=$1

	egrep ^oinstall /etc/group >/dev/null
	if [ $? -ne 0 ]; then
		groupadd oinstall
		if [ $? -eq 0 ]; then
			msg="Group oinstall created...."
			echo $msg; echo $msg >> $logpath 
		else
			msg="Group oinstall not created [EXIT $?]"
			echo $msg; echo $msg >> $logpath
		fi
 	else
		msg="Group oinstall alreday exists"
		echo $msg; echo $msg >> $logpath
	fi

	egrep ^dba /etc/group >/dev/null
	if [ $? -ne 0 ]; then
    	groupadd dba
    	if [ $? -eq 0 ]; then
			msg="Group dba created...."
			echo $msg; echo $msg >> $logpath
		else
			msg="Group dba not created [EXIT $?]"
			echo $msg; echo $msg >> $logpath
		fi
    else
    	msg="Group dba already exists..."
    	echo $msg; echo $msg >> $logpath
    fi

    # oracle user creation
    id oracle >/dev/null
    if [ $? -ne 0 ]; then
    	while :; do
    		read -sp "Create password for oracle user: " password1
    		read -sp "Retype new password: " password2
    		if [ $password1 != $password2 ]; then
    			echo "Password mismath...!"
    			continue
    		else
    			password=$password1
    			break
    		fi
    	done 

		useradd -m -p $password oracle
		if [ $? -eq 0 ]; then
			msg="User oracle created...."
			echo $msg; echo $msg >> $logpath
			usermod -g oinstall oracle
			if [ $? -eq 0 ]; then
				msg="User oracle added in primary group oinstall"
				echo $msg; echo $msg >> $logpath
			else
				msg="Unable to add user oracle to oinstall [EXIT $?]"
				echo $msg; echo $msg >> $logpath
			fi
			usermod -a -G dba oracle 
			if [ $? -eq 0 ]; then
				msg="User oracle added to group dba...."
				echo $msg; echo $msg >> $logpath
			else
				msg="User oracle not added to group dba [EXIT $?]"
				echo $msg; echo $msg >> $logpath
			fi
		else
			msg="Unacle to create user oracle [EXIT $?]"
			echo $msg; echo $msg >> $logpath
		fi
	else
		msg="User oracle already exists..."
		echo $msg; echo $msg >> $logpath
	fi
}


FileConf() {
	logpath=$1
	bash_profile=$2

	sed '6 s/#SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
	if [ $? -eq 0 ]; then
		msg="SELinux set to permissive successfully..."
		echo $msg; echo $msg >> $logpath
	else
		msg="SELinux parameter set failed [EXIT $?]"
		echo $msg; echo $msg >> $logpath
	fi

	setenforce Permissive
	if [ $? -eq 0 ]; then
		msg="setenforce Permissive successfull..."
		echo $msg; echo $msg >> $logpath
	else
		msg="setenforce Permissive failed [EXIT $?]"
		echo $msg; echo $msg >> $logpath
	fi

	systemctl stop firewalld
	if [ $? -eq 0 ]; then
		msg="Firewall stopped..."
		echo $msg; echo $msg >> $logpath
	else
		msg="Firewall stopping failed [EXIT $?]"
		echo $msg; echo $msg >> $logpath
	fi	
	systemctl disable firewalld
	if [ $? -eq 0 ]; then
		msg="Firewall diabled..."
		echo $msg; echo $msg >> $logpath
	else
		msg="Firewall disable failed [EXIT $?]"
		echo $msg; echo $msg >> $logpath
	fi

	# directory creation for oracle database
	mkdir -p /u01/app/oracle/product/12.1.0.2/db_1
	chown -R oracle:oinstall /u01
	chown -R oracle:oinstall /u02
	chmod -R 775 /u01
	chmod -R 775 /u02

	# ./bash_profile conf
	echo "export ORACLE_SID=CDB1" >> $bash_profile
	echo "export ORACLE_BASE=/u01/app/oracle" >> $bash_profile
	echo "export ORACLE_UNQNAME=CDB1" >> $bash_profile
	echo "export ORACLE_HOME=\$ORACLE_BASE/product/12.1.0.2/db_1" >> $bash_profile
	echo "export PATH=/usr/sbin:\$PATH" >> $bash_profile
	echo "export PATH=\$ORACLE_HOME/bin:\$PATH" >> $bash_profile
	echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib" >> $bash_profile
	echo "export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib" >> $bash_profile
}


Installer() {
	path=$1
	logpath=$2
	
	unzip $path/*.zip
	if [ $? -eq 0 ]; then
		sh $path/database/runInstaller
		if [ $? -eq 0 ]; then
			msg="runInstaller runs successfully..."
			echo $msg; echo $msg >> $logpath
		else
			msg="runInstaller fails [EXIT $?]"
			echo $msg; echo $msg >> $logpath
		fi
	else
		msg="Unzip of file failed [EXIT $?]"
		echo $msg; echo $msg >> $logpath
	fi
}