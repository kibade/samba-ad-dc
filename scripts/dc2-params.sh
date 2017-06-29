INTERFACE_NAME="enp0s17"
IP_ADDRESS="10.45.10.4"
SUBNET_MASK="255.255.254.0"
GATEWAY="10.45.11.254"
DOMAIN_FQDN="sfg.ad.sd57.bc.ca"
DOMAIN="SFG"
REALM="SFG.AD.SD57.BC.CA"
ADMIN_PASSWORD="secRet!23"
HOSTNAME="dc2"
NTP_SERVER1="time.sd57.bc.ca"
DC1_ADDRESS="10.45.10.3"
DC1_HOSTNAME="dc1"

if which smbd >&/dev/null; then
CONFIGFILE=$(smbd -b |egrep CONFIGFILE |cut -f2- -d':' |sed 's/^ *//')
LOCKDIR=$(smbd -b |egrep LOCKDIR |cut -f2- -d':' |sed 's/^ *//')
STATEDIR=$(smbd -b |egrep STATEDIR |cut -f2- -d':' |sed 's/^ *//')
CACHEDIR=$(smbd -b |egrep CACHEDIR |cut -f2- -d':' |sed 's/^ *//')
PRIVATE_DIR=$(smbd -b |egrep PRIVATE_DIR |cut -f2- -d':' |sed 's/^ *//')
fi

