# frozen_string_literal: true

require_relative "../test_helper"

class Carnet::RoleAbilityTest < Minitest::Test
  include CarnetTestSetup

  def setup
    super
    Carnet::RoleEvent.delete_all
    Carnet::RoleAssignment.delete_all
    Carnet::RoleAbility.delete_all
    Carnet::Role.delete_all
  end

  def test_ability_is_required
    role = Carnet::Role.create!(name: "editor")
    assert_raises(ActiveRecord::RecordInvalid) do
      Carnet::RoleAbility.create!(role: role, ability: nil)
    end
  end

  def test_ability_is_unique_per_role
    role = Carnet::Role.create!(name: "editor")
    Carnet::RoleAbility.create!(
      role: role, ability: "articles.publish"
    )

    assert_raises(ActiveRecord::RecordInvalid) do
      Carnet::RoleAbility.create!(
        role: role, ability: "articles.publish"
      )
    end
  end

  def test_belongs_to_role
    role = Carnet::Role.create!(name: "editor")
    ability = Carnet::RoleAbility.create!(
      role: role, ability: "articles.publish"
    )

    assert_equal role, ability.role
  end

  def test_same_ability_on_different_roles
    editor = Carnet::Role.create!(name: "editor")
    admin = Carnet::Role.create!(name: "admin")

    a1 = Carnet::RoleAbility.create!(
      role: editor, ability: "articles.publish"
    )
    a2 = Carnet::RoleAbility.create!(
      role: admin, ability: "articles.publish"
    )

    assert a1.persisted?
    assert a2.persisted?
    refute_equal a1.id, a2.id
  end
end
