include Make.def.44

PROGS = pty
all:	${PROGS}

pty:	main.o loop.o driver.o error.o spipe.o ttymodes.o writen.o signalintr.o
		${LINK.c} -o pty $^ -lutil

clean:
	rm -f ${PROGS} ${TEMPFILES}
