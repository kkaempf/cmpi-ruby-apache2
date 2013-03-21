VERSION = 0.0.1
NAME = cmpi-ruby-apache2
MOFDIR=/usr/share/mof/${NAME}
CMPIDIR=/usr/share/cmpi


dist:
	(cd ..; tar -cj --exclude=.git --exclude=package --exclude=\*~ --exclude-backups -f ${NAME}/package/${NAME}-${VERSION}.tar.bz2 ${NAME})

install:
	mkdir -p ${DESTDIR}${MOFDIR}
	install -m 0644 mof/*.mof ${DESTDIR}${MOFDIR}
	mkdir -p ${DESTDIR}${CMPIDIR}
	install -m 0644 src/*.rb ${DESTDIR}${CMPIDIR}

