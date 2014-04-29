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
end
