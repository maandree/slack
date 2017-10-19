.POSIX:

CONFIGFILE = config.mk
include $(CONFIGFILE)

all: slack

slack: slack.o
	$(CC) -o $@ $^ $(LDFLAGS)

slack.o: slack.c
	$(CC) -c -o $@ $< $(CFLAGS) $(CPPFLAGS)

install: slack
	mkdir -p -- "$(DESTDIR)$(PREFIX)/bin"
	mkdir -p -- "$(DESTDIR)$(MANPREFIX)/man1"
	mkdir -p -- "$(DESTDIR)$(PREFIX)/share/licenses/slack"
	cp -- slack "$(DESTDIR)$(PREFIX)/bin/"
	cp -- slack.1 "$(DESTDIR)$(MANPREFIX)/man1/"
	cp -- LICENSE "$(DESTDIR)$(PREFIX)/share/licenses/slack"

uninstall:
	-rm -f -- "$(DESTDIR)$(PREFIX)/bin/slack"
	-rm -f -- "$(DESTDIR)$(MANPREFIX)/man1/slack.1"
	-rm -rf -- "$(DESTDIR)$(PREFIX)/share/licenses/slack"

clean:
	-rm -f -- slack *.o

.SUFFIXES:

.PHONY: all install uninstall clean
