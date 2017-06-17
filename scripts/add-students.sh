#!/bin/bash
# This script will batch add user accounts for samba4AD.
#Use a text file with the format username space password on each line Ex:
# bill.smith 123456
# sam.jones 654321
# redirect the txt file into this command: ./add-students.sh < StudentTextFile.txt

# NOTE: Untested with the custom OU!

# Add Account
echo Please enter Username and Password seperated by a space
echo
while read n1 n2; do
       samba-tool user create $n1 $n2 --userou="OU=Students,OU=Student_Users"
       echo Account $n1 Successfully created, press Ctrl D to quit.
done
exit
