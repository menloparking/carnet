# frozen_string_literal: true

module Carnet
  # Maps a single ability string to a Role. Backed by
  # +carnet_role_abilities+.
  #
  # Ability names are arbitrary dot-namespaced strings
  # whose semantics are defined by the host application
  # (e.g. "articles.publish", "users.invite").
  class RoleAbility < ActiveRecord::Base
    self.table_name = "carnet_role_abilities"

    belongs_to :role,
      class_name: "Carnet::Role",
      inverse_of: :role_abilities

    validates :ability, presence: true,
      uniqueness: {scope: :role_id}
  end
end
