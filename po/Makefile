MO=fr.mo
PO=$(MO:%.mo%.po)

all:	strings.pot po mo

po:	$(PO)

mo: $(MO)

strings.pot:	../rbrss.strings
	xgettext --from-code=UTF8 -C -o strings.pot ../rbrss.strings

%.po:	strings.pot
	msgmerge -v -o $@x $@ $<
	mv -f $@x $@

%.mo:	%.po
	msgfmt -c $< -o $@
