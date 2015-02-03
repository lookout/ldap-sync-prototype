require 'conjur/ldap/reporting/reporter'
module Conjur
  module Ldap
    module Reporting
      def self.included base
        base.extend self
      end
      
      extend self
      
      def report *args, &block
        reporter.report *args, &block
      end

      def reporter
        @reporter ||= Reporter.new
      end

    end
  end
end