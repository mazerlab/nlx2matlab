#!/bin/sh
#
# run csc2snip in matlab to process most recent datafiles and then quit
#

#matlab -nox -r csc2snip,quit

cat <<EOF | matlab -nox
csc2snip;
quit;
EOF
