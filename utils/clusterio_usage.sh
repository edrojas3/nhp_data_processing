#!/bin/bash


total=225

user="TOTAL"
used=$(qstat -u "*" | awk '{print $5}' | egrep '^r$' | wc -l)
queue=$(qstat -u "*" | awk '{print $5}' | egrep '*q.' | wc -l)


printf "User\tused/total\tqueue\nTOTAL\t%s/%s\t%s\n" $used $total $queue


users=($(qstat -u "*" | tail -n +3 | awk '{print $4}' | sort | uniq))

for u in ${users[@]};
do
	used=$(qstat -u $u | awk '{print $5}' | egrep '^r$' | wc -l)
	queue=$(qstat -u $u | awk '{print $5}' | egrep '*q.' | wc -l)

	printf "%s\t%s/%s\t%s\n" $u $used $total $queue
done

	

