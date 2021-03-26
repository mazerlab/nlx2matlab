
DEST=/auto/share/matlab-local/nlx2matlab

all: tags install

# install matlab and mex stuff for lab-wide use
install:
	mkdir -p ${DEST}
	cp *.m ${DEST}
	cp csc2snips.sh /auto/share/pypeextra/csc2snips
	cp csc2lfp.sh /auto/share/pypeextra/csc2lfp
	cp showallsnips.sh /auto/share/pypeextra/showallsnips

# compile binaries - this should RARELY need to be done
binaries: FORCE
	sh ./compile.sh
	cp binaries/* ${DEST}

tags: FORCE
	mtags *.m


FORCE:
