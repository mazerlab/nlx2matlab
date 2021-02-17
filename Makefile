
DEST=/auto/share/matlab-local/nlx2matlab

install:
	mkdir ${DEST}
	cp binaries/* ${DEST}
	cp *.m ${DEST}

binaries:
	sh ./compile.sh
