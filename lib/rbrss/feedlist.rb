require 'rexml/document'
include REXML  # so that we don't have to prefix everything with REXML::

module RbRSS
class FeedList
  def initialize(xmlrootnode)
    @config = xmlrootnode
  end

  def fill_tree(model)
    add_sites(@config, model, nil)
  end

  def add_sites(config, model, node)
	config.elements.each("(category|site)"){
	  |element|
	  element.elements['name'] || next
	  n=model.append(node)
	  n.set_value(0, element.elements['name'].text)
	  element.elements['description'] && n.set_value(1, element.elements['description'].text)
	  element.elements['url'] && n.set_value(2, element.elements['url'].text)
	  n.set_value(3, element.expanded_name)		
	  element.elements['refresh'] && n.set_value(5, element.elements['refresh'].text.to_i)
	  element.expanded_name=="category" && add_sites(element, model, n)
	}
  end
  private :add_sites

  def update_from_tree(model)
	d = 0
	s = ""
	type = ""
	model.each{
	  |plop|
	  iter=plop[2]
	  name = model.get_value(iter, 0)
	  d2=model.iter_depth(iter)
	  while (d2<d) ||((d2==d) && (type=="category"))
		s+="</category>\n"
		d-=1
	  end
	  desc = model.get_value(iter, 1)
	  url = model.get_value(iter, 2)
	  type = model.get_value(iter, 3) # category/site
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
  end

  def write_file(file)
    @config.write(file)
  end

end
end
