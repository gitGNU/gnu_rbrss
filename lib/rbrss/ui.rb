require 'gdk_pixbuf2'
require 'libglade2'
require 'gnome2'

require 'gconf2'
require 'uri'
require "fileutils"
require 'net/http'

require 'rbrss/ui/glade_base.rb'
require 'rbrss/ui/main.rb'

module RbRSS
module UI
    def self.main
        Gnome::Program.new(TITLE, VERSION)
        MainApp.new
        Gtk.main
    end
end
end
