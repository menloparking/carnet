# frozen_string_literal: true

require_relative "../test_helper"

class Carnet::RoleServiceTest < Minitest::Test
  include CarnetTestSetup

  def setup
    super
    Carnet::RoleEvent.delete_all
    Carnet::RoleAssignment.delete_all
    Carnet::RoleAbility.delete_all
    Carnet::Role.delete_all
    User.delete_all
    Organization.delete_all

    @admin = Carnet::Role.create!(name: "admin")
    @actor = User.create!(name: "Gandalf")
    @user = User.create!(name: "Frodo")
    @org = Organization.create!(name: "Fellowship")
  end

  # -- assign_role -------------------------------------------

  def test_assign_role_creates_assignment
    assignment = Carnet::RoleService.assign_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor
    )

    assert assignment.persisted?
    assert_equal @user, assignment.principal
    assert_equal @admin, assignment.role
  end

  def test_assign_role_raises_for_missing_role
    assert_raises(ActiveRecord::RecordNotFound) do
      Carnet::RoleService.assign_role(
        principal: @user,
        role_name: "nonexistent",
        roleable: @org,
        actor: @actor
      )
    end
  end

  def test_assign_role_raises_for_overlap
    Carnet::RoleService.assign_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor
    )

    assert_raises(Carnet::OverlappingAssignmentError) do
      Carnet::RoleService.assign_role(
        principal: @user,
        role_name: "admin",
        roleable: @org,
        actor: @actor
      )
    end
  end

  def test_assign_role_records_event
    Carnet::RoleService.assign_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor
    )

    event = Carnet::RoleEvent.last
    assert_equal "role.assigned", event.action
    assert_equal "admin", event.role_name
    assert_equal @actor, event.actor
    assert_equal @user, event.target
  end

  def test_assign_role_stores_metadata_in_event
    Carnet::RoleService.assign_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor,
      metadata: {"reason" => "quest"}
    )

    event = Carnet::RoleEvent.last
    assert_equal "quest", event.metadata["reason"]
  end

  def test_assign_role_with_time_bounds
    assignment = Carnet::RoleService.assign_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor,
      starts_at: 1.hour.ago,
      expires_at: 1.hour.from_now
    )

    assert assignment.active?
  end

  # -- grant_ability -----------------------------------------

  def test_grant_ability_creates_ability
    Carnet::RoleService.grant_ability(
      role_name: "admin",
      ability: "users.manage",
      actor: @actor
    )

    assert @admin.has_ability?("users.manage")
  end

  def test_grant_ability_raises_for_missing_role
    assert_raises(ActiveRecord::RecordNotFound) do
      Carnet::RoleService.grant_ability(
        role_name: "nonexistent",
        ability: "users.manage",
        actor: @actor
      )
    end
  end

  def test_grant_ability_records_event
    Carnet::RoleService.grant_ability(
      role_name: "admin",
      ability: "users.manage",
      actor: @actor
    )

    event = Carnet::RoleEvent.for_action("ability.granted")
      .last
    assert_equal "admin", event.role_name
    assert_equal "users.manage", event.metadata["ability"]
  end

  # -- revoke_ability ----------------------------------------

  def test_revoke_ability_raises_for_missing_role
    assert_raises(ActiveRecord::RecordNotFound) do
      Carnet::RoleService.revoke_ability(
        role_name: "nonexistent",
        ability: "users.manage",
        actor: @actor
      )
    end
  end

  def test_revoke_ability_records_event
    @admin.grant_ability!("users.manage")

    Carnet::RoleService.revoke_ability(
      role_name: "admin",
      ability: "users.manage",
      actor: @actor
    )

    event = Carnet::RoleEvent.for_action("ability.revoked")
      .last
    assert_equal "admin", event.role_name
    assert_equal "users.manage", event.metadata["ability"]
  end

  def test_revoke_ability_removes_ability
    @admin.grant_ability!("users.manage")

    Carnet::RoleService.revoke_ability(
      role_name: "admin",
      ability: "users.manage",
      actor: @actor
    )

    refute @admin.has_ability?("users.manage")
  end

  # -- revoke_role -------------------------------------------

  def test_revoke_role_destroys_assignment
    Carnet::RoleService.assign_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor
    )

    count = Carnet::RoleService.revoke_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor
    )

    assert_equal 1, count
    assert_equal 0,
      Carnet::RoleAssignment.for_principal(@user)
        .active.count
  end

  def test_revoke_role_noop_when_no_assignment
    count = Carnet::RoleService.revoke_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor
    )

    assert_equal 0, count
    # No event recorded when nothing was revoked.
    revoked = Carnet::RoleEvent.for_action("role.revoked")
    assert_equal 0, revoked.count
  end

  def test_revoke_role_raises_for_missing_role
    assert_raises(ActiveRecord::RecordNotFound) do
      Carnet::RoleService.revoke_role(
        principal: @user,
        role_name: "nonexistent",
        roleable: @org,
        actor: @actor
      )
    end
  end

  def test_revoke_role_records_event
    Carnet::RoleService.assign_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor
    )

    Carnet::RoleService.revoke_role(
      principal: @user,
      role_name: "admin",
      roleable: @org,
      actor: @actor
    )

    events = Carnet::RoleEvent.for_action("role.revoked")
    assert_equal 1, events.count
  end
end
