module RbRSS
module UI
    class GladeBase
        def initialize(filename)
            file = File.join(RbRSS::Config::DATA_DIR, 'glade', filename)
            glade = GladeXML.new(file) { |handler| method(handler) }
            glade.widget_names.each do |name|
                begin
                    instance_variable_set("@#{name}".intern, glade[name])
                rescue
                end
            end
        end
    end
end
end
