require 'rbrss/config.rb'
require 'rbrss/feedlist.rb'
require 'rbrss/ui.rb'

module RbRSS
    TITLE = 'RbRSS'
    VERSION = '0.2'
    DESCRIPTION = 'A RSS aggregator.'
    COPYRIGHT = 'Copyright (C) 2004 Pascal Terjan'
    AUTHORS = [ 'Pascal Terjan <pterjan@linuxfr.org>' ]
    DOCUMENTERS = [ 'Pascal Terjan <pterjan@linuxfr.org>' ]  
    TRANSLATORS = [ 'Pascal Terjan <pterjan@linuxfr.org>' ]
    LIST = 'rbrss@fasmz.org'

    def self.main
        RbRSS::UI.main
    end
end
