# frozen_string_literal: true

require "logger"

module Carnet
  # Centralised logging for the gem. When Rails is
  # available we delegate to its logger; otherwise we
  # fall back to a silent sink so that callers never
  # need to nil-check.
  module Logging
    # Discards every message. Used when no meaningful
    # logger is available.
    class NullLogger < ::Logger
      def initialize
        super(File::NULL)
        self.level = ::Logger::FATAL
      end

      def add(*_args, &_block) = nil
    end

    module_function

    # Pick the best available logger at configuration
    # time. Prefer the Rails logger when present.
    def default_logger
      if defined?(::Rails) &&
          ::Rails.respond_to?(:logger) &&
          ::Rails.logger
        ::Rails.logger
      else
        NullLogger.new
      end
    end
  end
end
