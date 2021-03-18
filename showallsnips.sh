#!/bin/sh
#
# run showallsnips in matlab to process exper in current dir and then quit
#

#matlab -nox -r showallsnips,quit

cat <<EOF | matlab -nox
showallsnips;
quit;
EOF
