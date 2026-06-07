# frozen_string_literal: true

module Carnet
  # Migration helper. Host applications call
  # Carnet::Schema.create_tables from a migration to
  # stand up the four RBAC tables. Primary key type is
  # inherited from the application's generator config.
  #
  #   class CreateCarnetTables < ActiveRecord::Migration[7.0]
  #     def change
  #       Carnet::Schema.create_tables(self)
  #     end
  #   end
  module Schema
    module_function

    # rubocop:disable Metrics/MethodLength
    def create_tables(migration)
      # Resolve the polymorphic _id column type from the app's
      # generator config so that UUID apps get uuid columns and
      # bigint apps get bigint columns. Defaults to :bigint when
      # no generator config is present (Rails default).
      pk_type = begin
        Rails.configuration.generators.options
          .dig(:active_record, :primary_key_type) || :bigint
      rescue
        :bigint
      end

      migration.create_table :carnet_roles do |t|
        t.string :name, null: false
        t.string :description
        t.timestamps
        t.index :name, unique: true
      end

      migration.create_table :carnet_role_abilities do |t|
        t.references :role, null: false,
          foreign_key: {to_table: :carnet_roles}
        t.string :ability, null: false
        t.datetime :created_at, null: false
        t.index %i[role_id ability], unique: true
        t.index :ability
      end

      migration.create_table :carnet_role_assignments do |t|
        t.string :principal_type, null: false
        t.column :principal_id, pk_type, null: false
        t.references :role, null: false,
          foreign_key: {to_table: :carnet_roles}
        t.string :roleable_type, null: false
        t.column :roleable_id, pk_type, null: false
        t.datetime :starts_at
        t.datetime :expires_at
        t.timestamps
        t.index %i[principal_type principal_id
          role_id roleable_type roleable_id],
          name: "idx_carnet_assignments_lookup"
        t.index %i[principal_type principal_id]
        t.index %i[roleable_type roleable_id]
        t.index :expires_at
      end

      migration.create_table :carnet_role_events do |t|
        t.string :actor_type
        t.column :actor_id, pk_type
        t.string :target_type, null: false
        t.column :target_id, pk_type, null: false
        t.string :action, null: false
        t.string :role_name
        t.string :roleable_type
        t.column :roleable_id, pk_type
        t.json :metadata
        t.datetime :created_at, null: false
        t.index %i[target_type target_id]
        t.index %i[actor_type actor_id]
        t.index %i[roleable_type roleable_id]
        t.index :action
        t.index :created_at
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
