# frozen_string_literal: true

require_relative "../test_helper"

class Carnet::RoleBearerTest < Minitest::Test
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
    @admin.grant_ability!("users.manage")
    @admin.grant_ability!("articles.publish")

    @editor = Carnet::Role.create!(name: "editor")
    @editor.grant_ability!("articles.publish")

    @user = User.create!(name: "Bilbo")
    @org = Organization.create!(name: "Shire")
  end

  def test_can_respects_expiry
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org,
      starts_at: 2.hours.ago,
      expires_at: 1.hour.ago
    )

    refute @user.can?("users.manage", on: @org)
  end

  def test_can_when_ability_granted
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org
    )

    assert @user.can?("users.manage", on: @org)
  end

  def test_can_when_ability_not_granted
    Carnet::RoleAssignment.create!(
      principal: @user, role: @editor, roleable: @org
    )

    # Editor has articles.publish but not users.manage.
    refute @user.can?("users.manage", on: @org)
  end

  def test_can_when_no_assignment
    refute @user.can?("users.manage", on: @org)
  end

  def test_carnet_role_assignments_association
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org
    )

    assert_equal 1, @user.carnet_role_assignments.count
  end

  def test_destroy_user_cascades_assignments
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org
    )

    @user.destroy!
    assert_equal 0, Carnet::RoleAssignment.count
  end

  def test_has_role_respects_expiry
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org,
      starts_at: 2.hours.ago,
      expires_at: 1.hour.ago
    )

    refute @user.has_role?("admin", on: @org)
  end

  def test_has_role_respects_future_start
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org,
      starts_at: 1.hour.from_now
    )

    refute @user.has_role?("admin", on: @org)
  end

  def test_has_role_when_assigned
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org
    )

    assert @user.has_role?("admin", on: @org)
  end

  def test_has_role_when_not_assigned
    refute @user.has_role?("admin", on: @org)
  end

  def test_roles_on
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org
    )
    Carnet::RoleAssignment.create!(
      principal: @user, role: @editor, roleable: @org
    )

    roles = @user.roles_on(@org)
    assert_equal 2, roles.count
    assert_includes roles.pluck(:name), "admin"
    assert_includes roles.pluck(:name), "editor"
  end

  def test_roles_on_excludes_expired
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org,
      starts_at: 2.hours.ago,
      expires_at: 1.hour.ago
    )

    assert_equal 0, @user.roles_on(@org).count
  end

  def test_roles_on_scoped_to_roleable
    other_org = Organization.create!(name: "Mordor")
    Carnet::RoleAssignment.create!(
      principal: @user, role: @admin, roleable: @org
    )

    assert_equal 0, @user.roles_on(other_org).count
    assert_equal 1, @user.roles_on(@org).count
  end
end
