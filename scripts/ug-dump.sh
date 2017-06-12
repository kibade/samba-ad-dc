#!/bin/bash
set -eu
echo "USERS:"
samba-tool user list |
while read u; do
        if ! getent passwd "$u" >&/dev/null; then
                getent passwd "BUILTIN/$u" || echo "NOT FOUND: $u"
        else
                getent passwd "$u" || echo "NOT FOUND: $u"
        fi
done
echo "GROUPS:"
samba-tool group list |
while read g; do
        if ! getent group "$g" >&/dev/null; then
                getent group "BUILTIN/$g" || echo "NOT FOUND: $g"
        else
                getent group "$g" || echo "NOT FOUND: $g"
        fi
done
