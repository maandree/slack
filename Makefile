# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# The package path prefix, if you want to install to another root, set DESTDIR to that root.
PREFIX ?= /usr
# The binary path excluding prefix.
BIN ?= /bin
# The resource path excluding prefix.
DATA ?= /share
# The binary path including prefix.
BINDIR ?= $(PREFIX)$(BIN)
# The resource path including prefix.
DATADIR ?= $(PREFIX)$(DATA)
# The generic documentation path including prefix
DOCDIR ?= $(DATADIR)/doc
# The info manual documentation path including prefix
INFODIR ?= $(DATADIR)/info
# The license base path including prefix.
LICENSEDIR ?= $(DATADIR)/licenses


# The name of the package as it should be installed.
PKGNAME ?= slack
# The name of the command as it should be installed.
COMMAND ?= slack



# Build rules.

.PHONY: default
default: command info shell

.PHONY: all
all: command doc shell

# Build rules for the command.

.PHONY: command
command: bin/slack

bin/slack: src/slack.c
	mkdir -p bin
	$(CC) -O3 -Wall -Wextra -pedantic $(CFLAGS) $(LDFLAGS) $(CPPFLAGS) -o $@ $<

# Build rules for documentation.

.PHONY: doc
doc: info pdf dvi ps

.PHONY: info
info: slack.info
%.info: info/%.texinfo info/fdl.texinfo
	makeinfo $<

.PHONY: pdf
pdf: slack.pdf
%.pdf: info/%.texinfo info/fdl.texinfo
	@mkdir -p obj
	cd obj ; yes X | texi2pdf ../$<
	mv obj/$@ $@

.PHONY: dvi
dvi: slack.dvi
%.dvi: info/%.texinfo info/fdl.texinfo
	@mkdir -p obj
	cd obj ; yes X | $(TEXI2DVI) ../$<
	mv obj/$@ $@

.PHONY: ps
ps: slack.ps
%.ps: info/%.texinfo info/fdl.texinfo
	@mkdir -p obj
	cd obj ; yes X | texi2pdf --ps ../$<
	mv obj/$@ $@

# Build rules for shell auto-completion.

.PHONY: shell
shell: bash zsh fish

.PHONY: bash
bash: bin/slack.bash
bin/slack.bash: src/completion
	@mkdir -p bin
	auto-auto-complete bash --output $@ --source $<

.PHONY: zsh
zsh: bin/slack.zsh
bin/slack.zsh: src/completion
	@mkdir -p bin
	auto-auto-complete zsh --output $@ --source $<

.PHONY: fish
fish: bin/slack.fish
bin/slack.fish: src/completion
	@mkdir -p bin
	auto-auto-complete fish --output $@ --source $<


# Install rules.

.PHONY: install
install: install-base install-info install-shell

.PHONY: install
install-all: install-base install-doc install-shell

# Install base rules.

.PHONY: install-base
install-base: install-command install-copyright

.PHONY: install-command
install-command: bin/slack
	install -dm755 -- "$(DESTDIR)$(BINDIR)"
	install -m755 $< -- "$(DESTDIR)$(BINDIR)/$(COMMAND)"

.PHONY: install-copyright
install-copyright: install-copying install-license

.PHONY: install-copying
install-copying:
	install -dm755 -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	install -m644 COPYING -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/COPYING"

.PHONY: install-license
install-license:
	install -dm755 -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	install -m644 LICENSE -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/LICENSE"

# Install documentation.

.PHONY: install-doc
install-doc: install-info install-pdf install-ps install-dvi

.PHONY: install-info
install-info: slack.info
	install -dm755 -- "$(DESTDIR)$(INFODIR)"
	install -m644 $< -- "$(DESTDIR)$(INFODIR)/$(PKGNAME).info"

.PHONY: install-pdf
install-pdf: slack.pdf
	install -dm755 -- "$(DESTDIR)$(DOCDIR)"
	install -m644 $< -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).pdf"

.PHONY: install-ps
install-ps: slack.ps
	install -dm755 -- "$(DESTDIR)$(DOCDIR)"
	install -m644 $< -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).ps"

.PHONY: install-dvi
install-dvi: slack.dvi
	install -dm755 -- "$(DESTDIR)$(DOCDIR)"
	install -m644 $< -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).dvi"

# Install shell auto-completion.

.PHONY: install-shell
install-shell: install-bash install-zsh install-fish

.PHONY: install-bash
install-bash: bin/slack.bash
	install -dm755 -- "$(DESTDIR)$(DATADIR)/bash-completion/completions"
	install -m644 $< -- "$(DESTDIR)$(DATADIR)/bash-completion/completions/$(COMMAND)"

.PHONY: install-zsh
install-zsh: bin/slack.zsh
	install -dm755 -- "$(DESTDIR)$(DATADIR)/zsh/site-functions"
	install -m644 $< -- "$(DESTDIR)$(DATADIR)/zsh/site-functions/_$(COMMAND)"

.PHONY: install-fish
install-fish: bin/slack.fish
	install -dm755 -- "$(DESTDIR)$(DATADIR)/fish/completions"
	install -m644 $< -- "$(DESTDIR)$(DATADIR)/fish/completions/$(COMMAND).fish"


# Uninstall rules.

.PHONY: uninstall
uninstall:
	-rm -- "$(DESTDIR)$(BINDIR)/$(COMMAND)"
	-rm -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/COPYING"
	-rm -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/LICENSE"
	-rmdir -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	-rm -- "$(DESTDIR)$(INFODIR)/$(PKGNAME).info"
	-rm -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).pdf"
	-rm -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).ps"
	-rm -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).dvi"
	-rm -- "$(DESTDIR)$(DATADIR)/fish/completions/$(COMMAND).fish"
	-rmdir -- "$(DESTDIR)$(DATADIR)/fish/completions"
	-rmdir -- "$(DESTDIR)$(DATADIR)/fish"
	-rm -- "$(DESTDIR)$(DATADIR)/zsh/site-functions/_$(COMMAND)"
	-rmdir -- "$(DESTDIR)$(DATADIR)/zsh/site-functions"
	-rmdir -- "$(DESTDIR)$(DATADIR)/zsh"
	-rm -- "$(DESTDIR)$(DATADIR)/bash-completion/completions/$(COMMAND)"
	-rmdir -- "$(DESTDIR)$(DATADIR)/bash-completion/completions"
	-rmdir -- "$(DESTDIR)$(DATADIR)/bash-completion"


# Clean rules.

.PHONY: clean
clean:
	-rm -rf obj bin

