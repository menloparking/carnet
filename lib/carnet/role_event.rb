# frozen_string_literal: true

module Carnet
  # Immutable audit record for every role mutation.
  # Backed by +carnet_role_events+. Records are
  # append-only: the model prevents updates and
  # destroys after persist.
  class RoleEvent < ActiveRecord::Base
    self.table_name = "carnet_role_events"

    belongs_to :actor, polymorphic: true, optional: true
    belongs_to :target, polymorphic: true

    scope :for_action, lambda { |action|
      where(action: action)
    }

    scope :for_actor, lambda { |actor|
      where(actor: actor)
    }

    scope :for_roleable, lambda { |roleable|
      where(
        roleable_type: roleable.class.name,
        roleable_id: roleable.id
      )
    }

    scope :for_target, lambda { |target|
      where(target: target)
    }

    scope :recent, lambda { |limit = 50|
      order(created_at: :desc).limit(limit)
    }

    validates :action, presence: true

    # Immutability guards.
    before_update { raise_immutable! }
    before_destroy { raise_immutable! }

    # Convenience factory. Callers pass domain objects;
    # the method handles polymorphic decomposition of
    # the roleable.
    def self.record_event!(actor:, target:, action:,
      role_name: nil, roleable: nil,
      metadata: nil)
      create!(
        actor: actor,
        target: target,
        action: action,
        role_name: role_name,
        roleable_type: roleable&.class&.name,
        roleable_id: roleable&.id,
        metadata: metadata
      )
    end

    private

    def raise_immutable!
      raise ActiveRecord::ReadOnlyRecord,
        "Carnet::RoleEvent records are immutable"
    end
  end
end
