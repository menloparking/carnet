# frozen_string_literal: true

module Carnet
  # Binds a Role to a polymorphic principal on a
  # polymorphic roleable, optionally bounded in time
  # by +starts_at+ and +expires_at+.
  #
  # Backed by +carnet_role_assignments+.
  class RoleAssignment < ActiveRecord::Base
    self.table_name = "carnet_role_assignments"

    belongs_to :principal, polymorphic: true
    belongs_to :role,
      class_name: "Carnet::Role",
      inverse_of: :role_assignments
    belongs_to :roleable, polymorphic: true

    # Assignments whose time window covers +at+.
    scope :active, lambda { |at = Time.current|
      where(
        "(starts_at IS NULL OR starts_at <= ?) AND " \
        "(expires_at IS NULL OR expires_at > ?)",
        at, at
      )
    }

    scope :for_principal, lambda { |principal|
      where(principal: principal)
    }

    scope :for_role, lambda { |role|
      where(role: role)
    }

    scope :for_roleable, lambda { |roleable|
      where(
        roleable_type: roleable.class.name,
        roleable_id: roleable.id
      )
    }

    validate :no_overlapping_assignment, on: :create

    # Is this particular assignment live at +at+?
    def active?(at = Time.current)
      (starts_at.nil? || starts_at <= at) &&
        (expires_at.nil? || expires_at > at)
    end

    # Has this assignment's window already closed?
    def expired?
      expires_at.present? && expires_at <= Time.current
    end

    private

    # Guard: only one active window per (principal,
    # role, roleable) triple at any instant.
    def no_overlapping_assignment
      scope = self.class
        .where(
          principal_type: principal_type,
          principal_id: principal_id,
          role_id: role_id,
          roleable_type: roleable_type,
          roleable_id: roleable_id
        )
        .active

      scope = scope.where.not(id: id) if persisted?

      return unless scope.exists?

      raise Carnet::OverlappingAssignmentError
    end
  end
end
