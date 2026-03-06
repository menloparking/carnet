# frozen_string_literal: true

require_relative "carnet/version"
require_relative "carnet/logging"
require_relative "carnet/configuration"
require_relative "carnet/errors"
require_relative "carnet/query_budget"
require_relative "carnet/schema"
require_relative "carnet/role"
require_relative "carnet/role_ability"
require_relative "carnet/role_assignment"
require_relative "carnet/role_event"
require_relative "carnet/role_bearer"
require_relative "carnet/role_service"

# Persistent RBAC data layer for Turnstile.
#
# Four tables (roles, role abilities, role assignments,
# role events) sit beneath Turnstile's stateless policy
# layer. Policies remain the decision-makers; Carnet is
# the data store they consult.
module Carnet
  class << self
    # The current Configuration singleton.
    def configuration
      @configuration ||= Configuration.new
    end

    # Yield the configuration for mutation.
    #
    #   Carnet.configure do |c|
    #     c.query_budget_mode = :raise
    #   end
    def configure
      yield configuration
    end

    # Shortcut to the configured logger.
    def logger
      configuration.logger
    end

    # Replace the logger outright.
    def logger=(new_logger)
      configuration.logger = new_logger
    end

    # Restore default settings. Primarily for tests.
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
