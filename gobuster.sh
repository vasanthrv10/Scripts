#!/usr/bin/env bash

while getopts i:x:d:p:w: option
do
	case "${option}" in
		i) ip=${OPTARG};;
		x) ext=${OPTARG};;
		d) dir=${OPTARG};;
		p) prt=${OPTARG};;
		w) wlist=${OPTARG};;
	esac
done

if [ wlist=="" ]
then
	wlist='/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt'
fi

if [ ext="" ]
then
	gobuster dir -u "http://$ip$prt$dir" -w $wlist -t 75
else
	gobuster dir -u "http://$ip$prt$dir" -w $wlist -x $ext -t 75
fi

