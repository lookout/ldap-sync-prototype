require 'conjur/ldap/reporting/reporter'
module Conjur
  module Ldap
    module Reporting
      def self.included base
        base.extend self
      end

      # Valid formats are :text and :json
      def self.output_format= fmt
        reporter.output_format = fmt
      end

      def self.output_format
        reporter.output_format
      end
      
      def self.report *args, &block
        reporter.report *args, &block
      end

      def report *args, &block
        Conjur::Ldap::Reporting.report *args, &block
      end

      def self.reporter
        @reporter ||= Reporter.new
      end

      def reporter
        Conjur::Ldap::Reporting.reporter
      end

    end
  end
end