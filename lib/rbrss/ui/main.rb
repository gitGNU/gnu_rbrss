module RbRSS
  module UI
    class MainApp < GladeBase 
      def initialize
        super("rbrss.glade")
      end
     
      def old_init 
        @last_modified = {}
        @models = {}
        @gconf_client = GConf::Client.new
        @conf={}
        @conf["auto_save"] = @gconf_client.get "/apps/rbrss/auto_save"
        @conf["cache_dir"] = @gconf_client.get "/apps/rbrss/cache_dir"
        @useragent = "rbRSS/1.0"
        begin
          @configfile = Document.new File.new(ENV["HOME"]+'/.rbrss/config.xml')
        rescue
          begin
            Dir.mkdir(ENV["HOME"]+'/.rbrss')
          rescue Errno::EEXIST
          end
          FileUtils::copy_file("/usr/share/rbrss/config.xml", ENV["HOME"]+'/.rbrss/config.xml')
          @configfile = Document.new File.new(ENV["HOME"]+'/.rbrss/config.xml')
          # If it still fails, let's violently exit :]
        end
        if File.exist?("/usr/share/rbrss/rbrss.glade")
          gladepath="/usr/share/rbrss/rbrss.glade"
        else
          gladepath="rbrss.glade"
        end
        
        # Disable Properties and Clear in the Edit menu until a feed is selected
        set_feed_selected(FALSE)
        
        @model = Gtk::TreeStore.new(String, String, String, String, Integer, Integer) #Name, Description, URL, site/category, timer, refresh time
        col_cat = Gtk::TreeViewColumn.new("Nom", Gtk::CellRendererText.new, {:text => 0})
        @treeview2.append_column(col_cat)
        col_name = Gtk::TreeViewColumn.new("Description", Gtk::CellRendererText.new, {:text => 1})
        @treeview2.append_column(col_name)

        @feedlist = FeedList.new(@config.elements['config'])
        @feedlist.fill_tree(@model)
        
        @treeview2.set_model(@model)
        @treeview2.set_headers_clickable(FALSE)
        @treeview2.columns_autosize()
        
        col = Gtk::TreeViewColumn.new("Titre", Gtk::CellRendererText.new, {:text => 0})
        @treeview3.append_column(col)
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
        tv = @glade.get_widget("treeview3")
        if (@models)
          tv.set_model(@models[url])
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
          @config=Document.new "<?xml version=\"1.0\" encoding=\"iso-8859-15\"?>\n<config>"+s+"</config>"
        rescue REXML::ParseException
          puts "Invalid XML : "+s
        end
        #	on_save1_activate(nil) if(@conf["auto_save"])
      end

      ##############
      # Menu items #
      ##############

      def on_save1_activate(widget)
        @config.write(File.new(ENV["HOME"]+'/.rbrss/config.xml','w'))
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
