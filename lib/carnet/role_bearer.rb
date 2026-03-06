# frozen_string_literal: true

module Carnet
  # ActiveSupport::Concern for any model whose
  # instances may hold role assignments (users, teams,
  # service accounts, etc.).
  #
  #   class User < ActiveRecord::Base
  #     include Carnet::RoleBearer
  #   end
  #
  # Provides query methods (+can?+, +has_role?+,
  # +roles_on+) but never makes authorization
  # decisions -- that responsibility stays with
  # Turnstile's policy layer.
  module RoleBearer
    extend ActiveSupport::Concern

    included do
      has_many :carnet_role_assignments,
        class_name: "Carnet::RoleAssignment",
        as: :principal,
        dependent: :destroy,
        inverse_of: :principal
    end

    # Does the principal hold any role granting
    # +ability+ on +on+ at time +at+?
    def can?(ability, on:, at: Time.current)
      cfg = Carnet.configuration
      QueryBudget.enforce(
        "can?(#{ability})",
        mode: cfg.query_budget_mode,
        budget: cfg.query_budget
      ) do
        carnet_role_assignments
          .joins(role: :role_abilities)
          .where(
            carnet_role_abilities: {ability: ability}
          )
          .for_roleable(on)
          .active(at)
          .exists?
      end
    end

    # Does the principal currently hold the named role
    # on +on+?
    def has_role?(role_name, on:, at: Time.current)
      cfg = Carnet.configuration
      QueryBudget.enforce(
        "has_role?(#{role_name})",
        mode: cfg.query_budget_mode,
        budget: cfg.query_budget
      ) do
        carnet_role_assignments
          .joins(:role)
          .where(carnet_roles: {name: role_name})
          .for_roleable(on)
          .active(at)
          .exists?
      end
    end

    # Which Role records does the principal hold on
    # +on+ at time +at+?
    #
    # @return [ActiveRecord::Relation<Carnet::Role>]
    def roles_on(on, at: Time.current)
      Carnet::Role.where(
        id: carnet_role_assignments
          .for_roleable(on)
          .active(at)
          .select(:role_id)
      )
    end
  end
end
