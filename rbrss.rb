#!/usr/bin/ruby 
# Copyright (C) 2003      Pascal Terjan <CMoi@tuxfamily.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.
#

require 'net/http'
require 'libglade2'
require "rexml/document"
require 'uri'
include REXML  # so that we don't have to prefix everything with REXML::

class RbRSS 
  def add_sites(config, model, node)
	config.elements.each("(category|site)"){
	  |element|
	  element.elements['name'] || next
	  n=$model.append(node)
	  n.set_value(0, element.elements['name'].text)
	  element.elements['description'] && n.set_value(1, element.elements['description'].text)
	  element.elements['rss'] && n.set_value(2, element.elements['rss'].text)
	  element.expanded_name=="category" && add_sites(element, model, n)
	}
  end
  def initialize
	config = Document.new File.new('config.xml')
	$glade = GladeXML.new("rbrss.glade") {|handler| method(handler)}
	@treeview = $glade.get_widget("treeview2")
	$model = Gtk::TreeStore.new(String, String, String)
	col_cat = Gtk::TreeViewColumn.new("Nom", Gtk::CellRendererText.new, {:text => 0})
	@treeview.append_column(col_cat)
	col_name = Gtk::TreeViewColumn.new("Description", Gtk::CellRendererText.new, {:text => 1})
	@treeview.append_column(col_name)

	add_sites(config.elements['config'], $model, nil)

	@treeview.set_model($model)
	@treeview.set_headers_clickable(FALSE)
	@treeview.columns_autosize()

	@tv = $glade.get_widget("treeview3")
	col = Gtk::TreeViewColumn.new("Titre", Gtk::CellRendererText.new, {:text => 0})
	@tv.append_column(col)
#	@tv.set_headers_clickable(FALSE)
  end

  def update_site(treeview, event)
	@tv = $glade.get_widget("treeview3")
#	@model = @tv.model
	puts treeview.get_path_at_pos(event.x.floor, event.y.floor)
	puts event.x
	puts event.y
	iter = treeview.selection.selected
	url = $model.get_value(iter, 2) || return
	#$models && @model = $models[url]
	#if @model==nil
	  @model = Gtk::TreeStore.new(String, String, String)
	  #end
	uri = URI.parse(url)
	h = Net::HTTP.new(uri.host)
	begin
	  resp,data = h.get(uri.path)
	rescue
	  return
	end
	rss = Document.new data
	rss.elements['description'] && 
		$model.set_value(iter, 1, rss.elements['description'].text)
	rss.elements.each("//*/item"){
	  |element|
	  element.elements['title'] || next
	  n=@model.append(nil)
	  n.set_value(0, element.elements['title'].text)
	  element.elements['description'] && n.set_value(1, element.elements['description'].text)
	  element.elements['url'] && n.set_value(2, element.elements['url'].text)
	}
	@tv.set_model(@model)
  end

  def on_news_activated(widget, plop, coin)
  end

  def on_feed_activated(widget,plop)
	update_site(widget, plop)
  end
  
  def on_save1_activate(widget)
  end

  def on_preferences1_activate(widget)
  end

  def on_about1_activate(widget)
	$glade.get_widget("about2").show
  end
  
  def on_clear1_activate(widget)
  end
  
  def on_copy1_activate(widget)
  end
  
  def on_cut1_activate(widget)
  end
  
  def on_new1_activate(widget)
  end
  
  def on_open1_activate(widget)
  end
  
  def on_paste1_activate(widget)
  end
  
  def on_properties1_activate(widget)
  end
  
  def on_save_as1_activate(widget)
  end
  
  
  def quit
    Gtk.main_quit
  end
end

Gnome::Program.new("RbRSS", "0.1")
RbRSS.new
Gtk.main
