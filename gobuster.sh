#!/usr/bin/env bash

wlist='/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt'

gobuster dir -u "http://$1/" -w $wlist -t 100

if [ $2 == '-x']
then
	gobuster dir -u "http://$1/" -w $wlist -x $3 -t 100
fi
