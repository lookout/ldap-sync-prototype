require 'logger'
module Conjur
  module Ldap
    # Encapsulate logging.  We always log to the stderr, and 
    # if a CONJUR_LDAP_SYNC_LOG_FILE env var is present, we log
    # to the given file. 
    #  
    # Default log level is Logger::INFO, which can be changed using 
    # the CONJUR_LDAP_SYNC_LOG_LEVEL env var.
    module Logging
      
      def self.included base
        base.extend self
      end
      
      def self.logger
        @logger ||= create_logger
      end

      def logger
        Conjur::Ldap::Logging.logger
      end

      alias log logger
      
      private
      def self.create_logger
        targets = [$stderr]
        if (file = ENV['CONJUR_LDAP_SYNC_LOG_FILE'])
          targets << File.open(file, 'a')
        end
        logger = Logger.new(Tee.new(*targets))
        logger.level = Logger::INFO
        if (level_name = ENV['CONJUR_LDAP_SYNC_LOG_LEVEL'])
          level_name = level_name.upcase
          if Logger.const_defined?(level_name)
            logger.level = Logger.const_get(level_name)
          else
            logger.warn "Unknown log level specified: #{level_name}"
          end
        end
        logger
      end
      
      # Helper class to delegate calls to write and close to multiple IOs.
      class Tee
        def initialize *ios
          @ios = ios
        end
        
        def write *a
          @ios.each{|io| io.write *a}
        end

        def close
          @ios.each &:close
        end
      end

    end
  end
end
