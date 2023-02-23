#!/bin/bash

itophome=/var/www/html/itop
bkppath=/backups/itop
filename="itopbkp_$(date "+%y%m%d_%H%M%S")"

tar -Pcf $bkppath/$filename.tar $itophome && cp $itophome/data/backups/auto/* $bkppath/db

if [ $? -eq 0 ]; then
    gzip $bkppath/$filename.tar
    if [ $? -eq 0 ]; then
        find $bkppath -type f -mtime +2 -delete
	find $bkppath/db -type f -mtime +0.5 -delete
    fi
fi
