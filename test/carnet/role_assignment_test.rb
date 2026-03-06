# frozen_string_literal: true

require_relative "../test_helper"

class Carnet::RoleAssignmentTest < Minitest::Test
  include CarnetTestSetup

  def setup
    super
    Carnet::RoleEvent.delete_all
    Carnet::RoleAssignment.delete_all
    Carnet::RoleAbility.delete_all
    Carnet::Role.delete_all
    User.delete_all
    Organization.delete_all

    @role = Carnet::Role.create!(name: "admin")
    @user = User.create!(name: "Frodo")
    @org = Organization.create!(name: "Fellowship")
  end

  def test_active_predicate
    a = Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org,
      starts_at: 1.hour.ago
    )

    assert a.active?
  end

  def test_active_scope_excludes_expired
    Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org,
      starts_at: 2.hours.ago,
      expires_at: 1.hour.ago
    )

    assert_equal 0, Carnet::RoleAssignment.active.count
  end

  def test_active_scope_excludes_future
    Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org,
      starts_at: 1.hour.from_now
    )

    assert_equal 0, Carnet::RoleAssignment.active.count
  end

  def test_active_scope_includes_current
    Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org,
      starts_at: 1.hour.ago
    )

    assert_equal 1, Carnet::RoleAssignment.active.count
  end

  def test_create_assignment
    a = Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org
    )

    assert a.persisted?
    assert_equal @user, a.principal
    assert_equal @role, a.role
    assert_equal @org.class.name, a.roleable_type
  end

  def test_expired_predicate
    a = Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org,
      starts_at: 2.hours.ago,
      expires_at: 1.hour.ago
    )

    assert a.expired?
  end

  def test_for_principal_scope
    Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org
    )

    found = Carnet::RoleAssignment.for_principal(@user)
    assert_equal 1, found.count
  end

  def test_for_role_scope
    Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org
    )

    found = Carnet::RoleAssignment.for_role(@role)
    assert_equal 1, found.count
  end

  def test_for_roleable_scope
    Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org
    )

    found = Carnet::RoleAssignment.for_roleable(@org)
    assert_equal 1, found.count
  end

  def test_non_overlapping_after_expiry_is_allowed
    Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org,
      starts_at: 2.hours.ago,
      expires_at: 1.hour.ago
    )

    a = Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org,
      starts_at: Time.current
    )

    assert a.persisted?
  end

  def test_overlapping_assignment_raises
    Carnet::RoleAssignment.create!(
      principal: @user, role: @role, roleable: @org
    )

    assert_raises(Carnet::OverlappingAssignmentError) do
      Carnet::RoleAssignment.create!(
        principal: @user, role: @role, roleable: @org
      )
    end
  end
end
