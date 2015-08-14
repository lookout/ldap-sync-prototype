module Conjur::Ldap
  module Reporting
    class Reporter
      include Conjur::Ldap::Logging

      attr_accessor :io

      def output_format
        @output_format ||= :json
      end

      def output_format= fmt
        unless [:text, :json].include? fmt
          raise "output_format must be :text or :json (got '#{fmt}'"
        end
        @output_format = fmt
      end

      def initialize options={}
        @reports = []
        @io = options[:io] || $stderr
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
        report = Report.new tag, extras
        result = nil
        begin
          result = yield if block_given?
        rescue => ex
          logger.error "error in action for #{tag}: #{ex}\n\t#{ex.backtrace.join("\n\t")}"
          report.fail! ex
        ensure
          issue_report report
          result
        end
      end

      def issue_report report
        output = case output_format
          when :json then
            report.to_json
          when :text then
            report.format
          else
            raise 'Unreachable'
        end
        io.puts output
      end

      class Report

        def initialize tag, extras
          @tag = tag
          @extras = extras || {}
          @extras[:result] = :pending
        end

        attr_reader :tag

        def format
          "#{@tag}: #{format_extras}"
        end

        def format_extras
          @extras.collect { |k, v| "#{k}=#{v}" }.join ", "
        end

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