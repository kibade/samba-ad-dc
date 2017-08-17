#!/bin/bash
set -eu

# Guest wifi account name
gname="guestwifi"

# Minimum password length
minlen=8

# Pick a word at random from the 6- and 7-letter word list.
word=$(shuf -n1 /usr/local/sbin/words67.txt)

# Construct the password:
# 1. Upcase the first letter of the word.
# 2. Add a random digit (but not 0 or 1) to the end.
# 3. Add more random digits (but not 0 or 1) to the end,
#    to pad it up to the minimum length.
pword=${word^}$[ $RANDOM % 8 + 2 ]
while [[ ${#pword} < ${minlen} ]] ; do
	pword=${pword}$[ $RANDOM % 8 + 2 ]
done

# Set the guest password to the chosen password (Active Directory):
samba-tool user setpassword --filter=samaccountname=${gname} --newpassword=${pword} -U Administrator

## Set the guest password to the chosen password (UNIX):
#echo ${gname}:${pword} | chpasswd

# Generate the daily guest wifi message.

date=$(date +"%A, %b %d, %Y")

msg="Below is the account and password for the Guest-SD57 wireless network \
as of ${date}:

Username:		${gname}
Password:		${pword}
"

echo "${msg}" | mailx -s "${date}: Guest-SD57 Wireless" guestwifi

exit 0
