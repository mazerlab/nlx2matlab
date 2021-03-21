#!/bin/sh
#
# run csc2snip in matlab to process most recent datafiles and then quit
#

#matlab -nox -r csc2snips,quit

cat <<EOF | matlab -nox
csc2snips;
quit;
EOF
