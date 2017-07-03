#!/bin/bash
###############################################################################
### Script to do an online (or "hot") backup of Samba TDB/LDB databases
###############################################################################

###############################################################################
### Config Variables
###############################################################################

# Destination directory for the backups:
dest_dir="/var/backups/samba_tdb_backup"

###############################################################################
### End of Config Variables
###############################################################################

##
## Prevent multiple copies of this script from running at the same time.
##

[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :

##
## Get a safe scratch space to do our work, and prep to cleanup on exit.
##

set -eu

scratch=$(mktemp -d) || exit 1

cleanup () {
	rm -rf "$scratch"
}
trap cleanup EXIT

work_dir="${scratch}/work"

##
## Query Samba for the locations of its databases.
##

smbd -b | awk '/^Paths:/,/^ *$/' > "${scratch}/paths"

db_dirs_raw=(
	$(cat "${scratch}/paths" |
		awk '$1~/CONFIGFILE|LMHOSTSFILE|SMB_PASSWD_FILE/ {print $2}'|
		xargs dirname)
	$(cat "${scratch}/paths" |
		awk '$1~/CACHEDIR|LOCKDIR|PRIVATE_DIR|STATEDIR/ {print $2}')
)

db_dirs=(
	$(for d in "${db_dirs_raw[@]}"; do echo "$d"; done | sort | uniq)
)

##
## Search Samba's database dirs for .tdb and .ldb files.
##

db_files=(
	$(find "${db_dirs[@]}" \( -iname '*.tdb' -o -iname '*.ldb' \) \
		-type f -print | sort | uniq)
)

##
## Remove any .bak files sitting next to .tdb/.ldb files, as they
## will prevent 'tdbbackup' from doing its work.
##

bak_files=(
	$(for dbf in "${db_files[@]}"; do echo "${dbf}.bak"; done)
)

for bkf in "${bak_files[@]}"; do echo "$bkf"; done | xargs rm -f

##
## Create the .bak backup files.
## Allow errors to occur withou aborting the script,
## since some .tdb/.ldb files will be locked and not backup-able.
##

set +e
for dbf in "${db_files[@]}"; do	tdbbackup -s .bak "$dbf"; done
set -e

##
## Copy all .bak files (and their corresponding .tdb/.ldb files)
## to a scratch working tree.
##
## The .tdb/.ldb files are copied not for their data, which is
## not reliably copy-able while samba is running, but for their
## metadata (hardlinks, ownerships, permissions, ACLs, etc.).
##

(
for bkf in "${bak_files[@]}"; do
	if [ -e "$bkf" ]; then
		echo "${bkf%.bak}"
		echo "$bkf"
	fi
done
) |
rsync --files-from=- -aAXH / "$work_dir"

##
## In the scratch dir, replace the .tdb/.ldb files' data with
## their corresponding .bak data, then remove the .bak files.
## The .tdb/.ldb files original metadata are preserved (except
## for file times, of course).
##

find "$work_dir" -type f -iname '*.bak' -print |
while read bkf; do
	cp "${bkf}" "${bkf%.bak}"
	rm -f "${bkf}"
done

##
## Copy the contents of the working tree to the destination dir.
##

rsync -aAXH --delay-updates --delete-delay "${work_dir}/" "${dest_dir}"

##
## Done.
##

exit 0

