# frozen_string_literal: true

module Carnet
  # A named role that principals may hold. Roles carry
  # abilities and are assigned to principals via
  # RoleAssignment. Backed by +carnet_roles+.
  class Role < ActiveRecord::Base
    self.table_name = "carnet_roles"

    has_many :role_abilities,
      class_name: "Carnet::RoleAbility",
      foreign_key: :role_id,
      dependent: :destroy,
      inverse_of: :role

    has_many :role_assignments,
      class_name: "Carnet::RoleAssignment",
      foreign_key: :role_id,
      dependent: :restrict_with_exception,
      inverse_of: :role

    validates :name, presence: true, uniqueness: true

    # The ability strings currently attached to this
    # role.
    #
    # @return [Array<String>]
    def abilities
      role_abilities.pluck(:ability)
    end

    # Attach an ability. Idempotent: a second call with
    # the same string returns the existing record.
    #
    # @return [Carnet::RoleAbility]
    def grant_ability!(ability)
      role_abilities.find_or_create_by!(ability: ability)
    end

    # Does this role carry +ability+?
    #
    # @return [Boolean]
    def has_ability?(ability)
      role_abilities.exists?(ability: ability)
    end

    # Remove an ability. Idempotent: no-op if the
    # ability was never granted.
    def revoke_ability!(ability)
      role_abilities.where(ability: ability).destroy_all
    end
  end
end
