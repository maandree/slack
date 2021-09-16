.POSIX:

CONFIGFILE = config.mk
include $(CONFIGFILE)


all: slack

slack: slack.o
	$(CC) -o $@ slack.o $(LDFLAGS)

slack.o: slack.c arg.h
	$(CC) -c -o $@ slack.c $(CFLAGS) $(CPPFLAGS)

check:
	test $$(./slack 1ms ./slack get) = 1ms
	test $$(./slack 1ms ./slack GET) = 1000000
	test $$(./slack 1 ./slack reset ./slack GET) = $$(./slack GET)
	./slack 1 true
	./slack reset true
	! ./slack 1 2>/dev/null
	! ./slack reset 2>/dev/null
	! ./slack x 2>/dev/null
	! ./slack x x 2>/dev/null
	! ./slack get x 2>/dev/null
	! ./slack GET x 2>/dev/null

install: slack
	mkdir -p -- "$(DESTDIR)$(PREFIX)/bin"
	mkdir -p -- "$(DESTDIR)$(MANPREFIX)/man1"
	cp -- slack "$(DESTDIR)$(PREFIX)/bin/"
	cp -- slack.1 "$(DESTDIR)$(MANPREFIX)/man1/"

uninstall:
	-rm -f -- "$(DESTDIR)$(PREFIX)/bin/slack"
	-rm -f -- "$(DESTDIR)$(MANPREFIX)/man1/slack.1"

clean:
	-rm -f -- slack *.o *.su

.SUFFIXES:

.PHONY: all check install uninstall clean
