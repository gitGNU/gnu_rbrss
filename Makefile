all:
	make -C po

install:
	mkdir -p $(DESTDIR)/usr/share/rbrss/
	cp -f rbrss.glade *.png config.xml $(DESTDIR)/usr/share/rbrss/
	mkdir -p $(DESTDIR)/usr/share/locale/fr/LC_MESSAGES/
	cp -f po/fr.mo $(DESTDIR)/usr/share/locale/fr/LC_MESSAGES/rbrss.mo
	mkdir -p $(DESTDIR)/usr/bin
	cp -f rbrss $(DESTDIR)/usr/bin/rbrss
	chmod 755 $(DESTDIR)/usr/bin/rbrss
	cp -f rbrss.schemas $(DESTDIR)/etc/gconf/schemas/rbrss.schemas

uninstall:
	rm -rf $(DESTDIR)/usr/share/rbrss/
	rm -f $(DESTDIR)/usr/share/locale/*/LC_MESSAGES/rbrss.mo
	rm -f $(DESTDIR)/usr/bin/rbrss
	rm -f $(DESTDIR)/etc/gconf/schemas/rbrss.schemas