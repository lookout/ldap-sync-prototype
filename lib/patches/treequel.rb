require 'treequel/schema'

if Treequel::VERSION == '1.10.0'
  # Fix a bug where the variable name instead of value is checked for length
  class Treequel::Schema
    def ivar_descriptions
      self.instance_variables.sort.collect do |ivar|
        value = self.instance_variable_get( ivar )
        next unless value.respond_to?( :length )
        len = value.length
        "%d %s" % [ len, ivar.to_s.gsub(/_/, ' ')[1..-1] ]
      end
    end
  end

  # Patch to use normalized attrnames
  class Treequel::Model
    def get_converted_object( attrsym )
      value = self.entry ? (normalize_hash self.entry)[ normalize_key attrsym.to_s ] : nil

      if attribute = self.directory.schema.attribute_types[ attrsym ]
        syntax = attribute.syntax
        syntax_oid = syntax.oid if syntax

        if attribute.single?
          value = self.directory.convert_to_object( syntax_oid, value.first ) if value
        else
          value = Array( value ).collect do |raw|
            self.directory.convert_to_object( syntax_oid, raw )
          end
        end
      else
        self.log.info "no attributeType for %p" % [ attrsym ]
      end

      return value
    end
  end
end
