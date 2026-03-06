# frozen_string_literal: true

module Carnet
  # Gem-wide settings. Access through
  # Carnet.configuration; mutate through
  # Carnet.configure { |c| ... }.
  class Configuration
    # @return [Logger]
    attr_accessor :logger

    # How the query budget is enforced:
    #   :off   -- disabled, zero overhead
    #   :warn  -- log when budget exceeded
    #   :raise -- raise QueryBudget::Exceeded
    attr_accessor :query_budget_mode

    # Maximum SQL queries permitted per permission
    # check (can?, has_role?). Default: 1.
    attr_accessor :query_budget

    def initialize
      @logger = Logging.default_logger
      @query_budget = 1
      @query_budget_mode = :off
    end
  end
end
