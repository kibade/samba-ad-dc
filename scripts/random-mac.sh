#!/bin/bash
##
## random-mac.sh
##
## Generate a random MAC address that is both:
## - a unicast address (LSB of first octet is 0)
## - a Locally Administrated Address (2nd LSB of first octet is 1)
##
set -eu

octets=(
	$( hexdump -e '1/1 "%02x" 5/1 " %02x"' -n 6 /dev/urandom )
)

octets[0]=$( printf "%02x" $[ 0x${octets[0]} & 0xfe | 0x02 ] )

echo ${octets[*]} | sed 's/ /:/g'

