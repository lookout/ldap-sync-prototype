module Conjur::Ldap
  module Reporting
    class Reporter
      include Conjur::Ldap::Logging

      def initialize
        log.debug "reporter created!"
        @reports = []
      end

      def dump io=$stdout
        log.debug "dumping #{@reports}\n#{actions}"
        io.write(to_json)
      end
      
      def to_json
        as_json.to_json
      end

      def as_json
        {actions: actions}
      end

      # return a snapshot of reports
      def reports
        @reports.dup
      end
      
      def actions
        @reports.map(&:as_json)
      end

      def report tag, extras = {}
        log.debug "report #{tag}, #{extras}"
        @reports << (report = Report.new tag, extras)
        begin
          (yield if block_given?).tap{ report.succeed! }
        rescue => ex
          logger.error "error in action for #{tag}: #{ex}\n\t#{ex.backtrace.join("\n\t")}"
          report.fail! ex
          nil
        end
      end

      class Report

        def initialize tag, extras
          @tag = tag
          @extras = extras || {}
          @extras[:result] = :pending
        end

        attr_reader :tag

        def extras
          @extras ||= {}
        end

        def succeed!
          extras[:result] = :success
        end

        def fail! ex
          extras[:result] = :failure
          extras[:error] = ex.to_s
        end

        def failed?
          extras[:result] == :failure
        end

        def succeeded?
          extras[:result] == :success
        end

        def as_json
          {tag: tag}.merge(extras)
        end

        def to_json
          as_json.to_json
        end
      end
    end
  end
end