#!/usr/bin/env bash

if [ $2 == "full" ]
then
	nmap -p- -T5 $1 > nmapfull
else
	nmap -A -sC -sV -O -T3 $1 > nmap
fi

if [ $? == 0 ]
then
	rm ./nmap.sh
fi