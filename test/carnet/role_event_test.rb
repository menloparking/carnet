# frozen_string_literal: true

require_relative "../test_helper"

class Carnet::RoleEventTest < Minitest::Test
  include CarnetTestSetup

  def setup
    super
    Carnet::RoleEvent.delete_all
    Carnet::RoleAssignment.delete_all
    Carnet::RoleAbility.delete_all
    Carnet::Role.delete_all
    User.delete_all
    Organization.delete_all

    @actor = User.create!(name: "Gandalf")
    @target = User.create!(name: "Frodo")
    @org = Organization.create!(name: "Fellowship")
  end

  def test_action_is_required
    assert_raises(ActiveRecord::RecordInvalid) do
      Carnet::RoleEvent.record_event!(
        actor: @actor,
        target: @target,
        action: nil
      )
    end
  end

  def test_actor_is_optional
    event = Carnet::RoleEvent.record_event!(
      actor: nil,
      target: @target,
      action: "role.assigned"
    )

    assert event.persisted?
    assert_nil event.actor
  end

  def test_for_action_scope
    Carnet::RoleEvent.record_event!(
      actor: @actor, target: @target,
      action: "role.assigned"
    )
    Carnet::RoleEvent.record_event!(
      actor: @actor, target: @target,
      action: "role.revoked"
    )

    assigned = Carnet::RoleEvent.for_action("role.assigned")
    assert_equal 1, assigned.count
  end

  def test_for_actor_scope
    Carnet::RoleEvent.record_event!(
      actor: @actor, target: @target,
      action: "role.assigned"
    )

    assert_equal 1,
      Carnet::RoleEvent.for_actor(@actor).count
  end

  def test_for_roleable_scope
    Carnet::RoleEvent.record_event!(
      actor: @actor, target: @target,
      action: "role.assigned", roleable: @org
    )

    found = Carnet::RoleEvent.for_roleable(@org)
    assert_equal 1, found.count
  end

  def test_for_target_scope
    Carnet::RoleEvent.record_event!(
      actor: @actor, target: @target,
      action: "role.assigned"
    )

    assert_equal 1,
      Carnet::RoleEvent.for_target(@target).count
  end

  def test_immutable_on_destroy
    event = Carnet::RoleEvent.record_event!(
      actor: @actor,
      target: @target,
      action: "role.assigned"
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      event.destroy!
    end
  end

  def test_immutable_on_update
    event = Carnet::RoleEvent.record_event!(
      actor: @actor,
      target: @target,
      action: "role.assigned"
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      event.update!(action: "role.revoked")
    end
  end

  def test_metadata_round_trips
    event = Carnet::RoleEvent.record_event!(
      actor: @actor,
      target: @target,
      action: "role.assigned",
      metadata: {"reason" => "testing", "score" => 42}
    )

    event.reload
    assert_equal "testing", event.metadata["reason"]
    assert_equal 42, event.metadata["score"]
  end

  def test_recent_scope
    3.times do |i|
      Carnet::RoleEvent.record_event!(
        actor: @actor, target: @target,
        action: "test.action.#{i}"
      )
    end

    assert_equal 2, Carnet::RoleEvent.recent(2).count
  end

  def test_record_event
    event = Carnet::RoleEvent.record_event!(
      actor: @actor,
      target: @target,
      action: "role.assigned",
      role_name: "admin",
      roleable: @org,
      metadata: {reason: "promoted"}
    )

    assert event.persisted?
    assert_equal "role.assigned", event.action
    assert_equal "admin", event.role_name
    assert_equal @actor, event.actor
    assert_equal @target, event.target
  end
end
