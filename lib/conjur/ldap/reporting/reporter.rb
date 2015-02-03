module Conjur::Ldap
  module Reporting
    class Reporter
      def initialize
        @reports = []
      end

      def dump io=$stdout
        io.write(to_json)
      end
      
      def to_json
        as_json.to_json
      end

      def as_json
        {
            actions: actions,
            succeeded: succeeded,
            failed: failed
        }
      end

      # return a snapshot of reportss
      def reports
        @reports.dup
      end
      
      def actions
        @reports.map(&:as_json)
      end

      def failed
        @reports.select(&:failed?).map(&:as_json)
      end

      def succeeded
        @reports.select(&:succeeded?).map(&:as_json)
      end

      def report tag, message, extras = {}
        @reports << (report = Report.new tag, message, extras)
        begin
          yield if block_given?
          report.succeed
        rescue => ex
          report.fail ex
          raise ex
        end
      end

      class Report

        def initialize tag, message, extras
          @tag = tag
          @message = message
          @extras = extras || {}
          @extras[:result] = :pending
        end

        attr_reader :tag, :message

        def extras
          @extras ||= {}
        end

        def succeed
          extras[:result] = :success
        end

        def fail ex
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
          {tag: tag, message: message}.merge(extras)
        end

        def to_json
          as_json.to_json
        end
      end
    end
  end
end