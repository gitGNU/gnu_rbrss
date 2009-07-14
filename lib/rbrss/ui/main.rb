require 'rss/1.0'
require 'rss/2.0'

module RbRSS
  module UI
    class MainApp < GladeBase 
      def initialize
        super("rbrss.glade")
        load_conf
        load_feeds
        init_ui
      end

      def load_conf
        @gconf_client = GConf::Client.default
        @conf={}
        @conf["auto_save"] = @gconf_client.get "/apps/rbrss/auto_save"
        @conf["cache_dir"] = @gconf_client.get "/apps/rbrss/cache_dir"
        @useragent = "rbRSS/1.0"        
      end

      def load_feeds
        @models = {}
        @last_modified = {}
        config_file = File.join(ENV["HOME"], '.rbrss', 'config.xml')
        begin
          @configfile = Document.new File.new(config_file)
        rescue
          begin
            Dir.mkdir(File.join(ENV["HOME"], '.rbrss'))
          rescue Errno::EEXIST
          end
          FileUtils::copy_file(File.join(RbRSS::Config::DATA_DIR, 'config.xml'), config_file)
          @configfile = Document.new File.new(config_file)
          # If it still fails, let's violently exit :]
        end
        @model = Gtk::TreeStore.new(String, String, String, String, Integer, Integer) #Name, Description, URL, site/category, timer, refresh time
        @feedlist = FeedList.new(@configfile.elements['config'])
        @feedlist.fill_tree(@model)
      end

      def init_ui
        # Disable Properties and Clear in the Edit menu until a feed is selected
        set_feed_selected(FALSE)
        
        col_cat = Gtk::TreeViewColumn.new("Nom", Gtk::CellRendererText.new, {:text => 0})
        @treeview2.append_column(col_cat)
        col_name = Gtk::TreeViewColumn.new("Description", Gtk::CellRendererText.new, {:text => 1})
        @treeview2.append_column(col_name)
        
        @treeview2.set_model(@model)
        @treeview2.set_headers_clickable(FALSE)
        @treeview2.columns_autosize()
        
        col = Gtk::TreeViewColumn.new("Titre", Gtk::CellRendererText.new, {:text => 0})
        @treeview3.append_column(col)
      end

      def update_site(iter, event)
        Thread.new {
          do_update_site(iter, event)
        }
      end

      def do_update_site(iter, event)
        url = @model.get_value(iter, 2) || return
        timer = @model.get_value(iter, 4)
        refresh = @model.get_value(iter, 5)
        if(timer && timer!=0)
          Gtk.timeout_remove(timer)
        end
        uri = URI.parse(url)
        h = Net::HTTP.new(uri.host)
        begin
          resp,data = h.get(uri.path, {'User-Agent'=>@useragent})
        rescue
          puts "You are not connected, the server is down or the adress is wrong."
          return
        end
        resp.each_header{
          |header, val|
          if header=="last-modified"
            if @last_modified[url] == val
              if(refresh)
                timer = Gtk.timeout_add(refresh*60000){
                  update_site(iter, nil)
                  false
                }
                @model.set_value(iter, 4, timer)
              end
              return
            end
            @last_modified[url] = val
          end
        }
        rss = RSS::Parser.parse(data, false)
        # Should check what needs to be added, meanwhile...
        @models = {} unless @models
        model = @models[url]
        if model==nil
          model = Gtk::TreeStore.new(String, String, String)
          @models[url]=model
          @treeview3.set_model(@models[url]) if @treeview3.model==nil 
        end
        model.clear
        rss.items.each{
          |element|
          element.title || next
          n=model.append(nil)
          n.set_value(0, element.title)
          element.description && n.set_value(1, element.description)
          element.link && n.set_value(2, element.link)
        }
        if(refresh)
          timer = Gtk.timeout_add(refresh*60000){
            update_site(iter, nil)
            false
          }
          # Segfault with Ruby/Gnome2 0.5.0
          @model.set_value(iter, 4, timer)
        end
      end

      def fetch_feed_info(url)
        uri = URI.parse(url)
        h = Net::HTTP.new(uri.host)
        begin
          resp,data = h.get(uri.path, {'User-Agent'=>@useragent})
        rescue
          puts "Unable to connect to grab specified URL"
          return nil
        end
        rss = RSS::Parser.parse(data, false)
        info = {}
	info['title'] = rss.channel.title
	info['link'] = rss.channel.link
	info['description'] = rss.channel.description
        return info
      end

      ###################
      # Toolbar buttons #
      ###################

      def on_addbutton_released(widget)
        add = @addDialog
        add.show_all
      end
      
      def on_removebutton_released(widget)
        on_effacer1_activate(nil)
      end
      
      def set_feed_selected(bool)
        @properties1.set_sensitive(bool)
        @effacer1.set_sensitive(bool)
        @button1.set_sensitive(bool)
        @button3.set_sensitive(bool)
        @button4.set_sensitive(bool)
      end
      
      def on_refreshbutton_released(widget)
        treeview = @treeview2
        iter = treeview.selection.selected || return
        update_site(iter, nil)
      end

      #######################
      # Source adding druid #
      #######################
      def on_druid2_cancel(widget)
        widget.set_page(@druidpagestart2)
        @addDialog.hide
      end
      
      def on_druid2_close(widget, event)
        on_druid2_cancel(@druid2)
      end
      
      def on_druid2_finish(widget, event)
        @druid2.set_page(@druidpagestart2)
        @addDialog.hide
        #TODO If a category is selected, add into it
        url = @urlEntry.text
        description = @descEntry.text
        name = @nameEntry.text

        n=@model.append(nil)
        n.set_value(0,name)
        description && n.set_value(1, description)
        n.set_value(2, url)
        n.set_value(3, 'site')		
        #element.elements['refresh'] && n.set_value(5, element.elements['refresh'].text.to_i)
        update_config
      end

      def on_druid2_next(page, druid)
        url = @urlEntry.text
        if(!url) 
          return true
        end
        info = fetch_feed_info(url)
        if(!info)
          return true
        end
        description = info['description'] || ""
        name = info['title'] || ""
        @descEntry.text=description
        @nameEntry.text=name
        false
      end

      ##################################
      # Tree and lists events handling #
      ##################################

      def on_news_activated(widget, plop)
        model=widget.model || return
        iter = widget.selection.selected
        desc = model.get_value(iter, 1) ||  model.get_value(iter, 2) || "No description nor url for this news"
        buffer=Gtk::TextBuffer.new
        buffer.set_text(desc)
        textview=@news
        textview.set_buffer(buffer)
      end

      # Click on a feed name
      def on_feed_activated(widget,plop)
        iter = widget.selection.selected || return
        set_feed_selected(TRUE)
        url = @model.get_value(iter, 2) || return

        # Clear current news
        textview=@news
        textview.buffer.text=''

        # Display the matching news list
        if (@models)
          @treeview3.set_model(@models[url])
        end
        update_site(iter, nil)
        return
      end

      def on_treeview2_key_release_event(treeview, event)
        on_effacer1_activate(nil) if event.keyval==65535
      end

      def on_treeview2_drag_end(treeview, dragcontext)
        # Parse new model to update config object
        set_feed_selected(FALSE)
        update_config
      end
      def update_config
        d=0
        s = ""
        type = ""
        @model.each{
          |plop|
          iter=plop[2]
          name = @model.get_value(iter, 0)
          d2=@model.iter_depth(iter)
          while (d2<d) ||((d2==d) && (type=="category"))
            s+="</category>\n"
            d-=1
          end
          desc = @model.get_value(iter, 1)
          url = @model.get_value(iter, 2)
          type = @model.get_value(iter, 3) # category/site
          s+="<"+type+">\n"
          s+="<name>"+name+"</name>\n"
          s+="<description>"+desc+"</description>\n" if desc
          s+="<url>"+url+"</url>\n" if url
          s+="</site>\n" if type=="site"
          d=d2
          next #to avoid stopping the loop when d2==0...
        }
        while d>0||(d==0&&type=="category")
          s+="</category>\n"
          d-=1
        end
        begin
          @config=Document.new "<?xml version=\"1.0\" ?>\n<config>"+s+"</config>"
        rescue REXML::ParseException
          puts "Invalid XML : "+s
        end
        on_save1_activate(nil) if(@conf["auto_save"])
      end

      ##############
      # Menu items #
      ##############

      def on_save1_activate(widget)
        @config.write(File.new(File.join(ENV["HOME"], '.rbrss', 'config.xml'),'w'))
      end

      def on_preferences1_activate(widget)
      end

      def on_about1_activate(widget)
        @about2.show
      end
      
      def on_effacer1_activate(widget)
        iter = @treeview2.selection.selected || return
        @models.delete(url) if url = @model.get_value(iter, 2) && @models[url]
        @model.remove(iter)
        @properties1.set_sensitive(FALSE)
        @effacer1.set_sensitive(FALSE)
        update_config
      end
      
      def on_copy1_activate(widget)
      end
      
      def on_open1_activate(widget)
      end
      
      def on_properties1_activate(widget)
      end
      
      def on_save_as1_activate(widget)
      end

      def quit
        Gtk.main_quit
      end


    end
  end
end
