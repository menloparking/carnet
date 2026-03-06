# frozen_string_literal: true

module Carnet
  # High-level operations on roles and abilities. Each
  # method pairs a model write with an audit event so
  # that callers get automatic logging for free.
  #
  #   Carnet::RoleService.assign_role(
  #     principal: user,
  #     role_name: "editor",
  #     roleable: org,
  #     actor: current_user
  #   )
  module RoleService
    module_function

    # Assign the named role to +principal+ on
    # +roleable+. Records a "role.assigned" audit
    # event.
    #
    # @raise [ActiveRecord::RecordNotFound] missing role
    # @raise [Carnet::OverlappingAssignmentError]
    # @return [Carnet::RoleAssignment]
    def assign_role(principal:, role_name:, roleable:,
      actor: nil, starts_at: nil,
      expires_at: nil, metadata: nil)
      role = Carnet::Role.find_by!(name: role_name)

      assignment = Carnet::RoleAssignment.create!(
        principal: principal,
        role: role,
        roleable: roleable,
        starts_at: starts_at,
        expires_at: expires_at
      )

      Carnet::RoleEvent.record_event!(
        actor: actor,
        target: principal,
        action: "role.assigned",
        role_name: role_name,
        roleable: roleable,
        metadata: metadata
      )

      assignment
    end

    # Add +ability+ to the named role. Idempotent.
    # Records an "ability.granted" audit event.
    #
    # @return [Carnet::RoleAbility]
    def grant_ability(role_name:, ability:,
      actor: nil, metadata: nil)
      role = Carnet::Role.find_by!(name: role_name)
      record = role.grant_ability!(ability)

      Carnet::RoleEvent.record_event!(
        actor: actor,
        target: role,
        action: "ability.granted",
        role_name: role_name,
        metadata: (metadata || {}).merge(
          ability: ability
        )
      )

      record
    end

    # Strip +ability+ from the named role. Idempotent.
    # Records an "ability.revoked" audit event.
    def revoke_ability(role_name:, ability:,
      actor: nil, metadata: nil)
      role = Carnet::Role.find_by!(name: role_name)
      role.revoke_ability!(ability)

      Carnet::RoleEvent.record_event!(
        actor: actor,
        target: role,
        action: "ability.revoked",
        role_name: role_name,
        metadata: (metadata || {}).merge(
          ability: ability
        )
      )
    end

    # Destroy all active assignments of +role_name+ for
    # +principal+ on +roleable+. Only records a
    # "role.revoked" event when at least one assignment
    # was actually removed.
    #
    # @return [Integer] number destroyed
    def revoke_role(principal:, role_name:, roleable:,
      actor: nil, metadata: nil)
      role = Carnet::Role.find_by!(name: role_name)

      hits = Carnet::RoleAssignment
        .for_principal(principal)
        .for_role(role)
        .for_roleable(roleable)
        .active

      destroyed = hits.count
      hits.destroy_all

      if destroyed > 0
        Carnet::RoleEvent.record_event!(
          actor: actor,
          target: principal,
          action: "role.revoked",
          role_name: role_name,
          roleable: roleable,
          metadata: metadata
        )
      end

      destroyed
    end
  end
end
