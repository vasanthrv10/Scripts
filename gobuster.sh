#!/usr/bin/env bash

while getopts x:d:p:w: option
do
	case "${option}" in
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

if [ ext!="" ]
then
	gobuster dir -u "http://{$1}${dir}${prt}" -w $wlist -t 100 -x $ext
else
	gobuster dir -u "http://{$1}${dir}${prt}" -w $wlist -t 100
fi
