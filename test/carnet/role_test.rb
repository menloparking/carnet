# frozen_string_literal: true

require_relative "../test_helper"

class Carnet::RoleTest < Minitest::Test
  include CarnetTestSetup

  def setup
    super
    Carnet::RoleEvent.delete_all
    Carnet::RoleAssignment.delete_all
    Carnet::RoleAbility.delete_all
    Carnet::Role.delete_all
  end

  def test_create_role_with_name
    role = Carnet::Role.create!(name: "admin")
    assert_equal "admin", role.name
    assert role.persisted?
  end

  def test_description_is_optional
    role = Carnet::Role.create!(
      name: "viewer",
      description: "Read-only access"
    )
    assert_equal "Read-only access", role.description
  end

  def test_destroy_cascades_to_abilities
    role = Carnet::Role.create!(name: "admin")
    role.grant_ability!("users.manage")

    role.destroy!
    assert_equal 0, Carnet::RoleAbility.count
  end

  def test_destroy_restricted_when_assignments_exist
    role = Carnet::Role.create!(name: "admin")
    user = User.create!(name: "Bilbo")
    org = Organization.create!(name: "Shire")

    Carnet::RoleAssignment.create!(
      principal: user,
      role: role,
      roleable: org
    )

    assert_raises(ActiveRecord::DeleteRestrictionError) do
      role.destroy!
    end
  end

  def test_grant_ability_is_idempotent
    role = Carnet::Role.create!(name: "editor")
    first = role.grant_ability!("articles.publish")
    second = role.grant_ability!("articles.publish")

    assert_equal first.id, second.id
    assert_equal 1, role.role_abilities.count
  end

  def test_has_ability_predicate
    role = Carnet::Role.create!(name: "editor")
    role.grant_ability!("articles.publish")

    assert role.has_ability?("articles.publish")
    refute role.has_ability?("articles.delete")
  end

  def test_abilities_returns_granted_strings
    role = Carnet::Role.create!(name: "editor")
    role.grant_ability!("articles.publish")
    role.grant_ability!("articles.edit")

    assert_includes role.abilities, "articles.publish"
    assert_includes role.abilities, "articles.edit"
    assert_equal 2, role.abilities.size
  end

  def test_name_is_required
    assert_raises(ActiveRecord::RecordInvalid) do
      Carnet::Role.create!(name: nil)
    end
  end

  def test_name_must_be_unique
    Carnet::Role.create!(name: "editor")
    assert_raises(ActiveRecord::RecordInvalid) do
      Carnet::Role.create!(name: "editor")
    end
  end

  def test_revoke_ability
    role = Carnet::Role.create!(name: "editor")
    role.grant_ability!("articles.publish")
    role.revoke_ability!("articles.publish")

    refute role.has_ability?("articles.publish")
    assert_empty role.abilities
  end

  def test_revoke_ability_is_idempotent
    role = Carnet::Role.create!(name: "editor")
    # Revoking a never-granted ability does not raise.
    role.revoke_ability!("nonexistent")
    assert_empty role.abilities
  end
end
