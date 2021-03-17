
DEST=/auto/share/matlab-local/nlx2matlab

# install matlab and mex stuff for lab-wide use
install:
	mkdir -p ${DEST}
	cp *.m ${DEST}

# compile binaries - this should RARELY need to be done
binaries: FORCE
	sh ./compile.sh
	cp binaries/* ${DEST}

FORCE:
