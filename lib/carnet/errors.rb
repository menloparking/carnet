# frozen_string_literal: true

module Carnet
  # Root error class for the Carnet gem. All domain
  # exceptions descend from this.
  class Error < StandardError; end

  # Signals that a caller referenced an ability not
  # present in the host application's registry. Useful
  # when the host validates ability strings at write
  # time.
  class UnregisteredAbilityError < Error
    attr_reader :ability

    def initialize(ability)
      @ability = ability
      super("#{ability} is not a registered ability")
    end
  end

  # Raised by RoleAssignment when an insert would
  # create a time-window overlap against an existing
  # active assignment for the same (principal, role,
  # roleable) triple.
  class OverlappingAssignmentError < Error
    def initialize(msg = nil)
      super(
        msg || "overlaps an existing assignment for " \
               "this principal, role, and roleable"
      )
    end
  end
end
