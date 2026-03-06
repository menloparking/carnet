# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "active_record"
require "active_support"
require "minitest/autorun"
require "carnet"

# In-memory SQLite database for tests.
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Build the schema in memory so every test run starts fresh.
ActiveRecord::Schema.define do
  create_table :carnet_roles, force: true do |t|
    t.string :name, null: false
    t.string :description
    t.timestamps
    t.index :name, unique: true
  end

  create_table :carnet_role_abilities, force: true do |t|
    t.references :role, null: false,
      foreign_key: {to_table: :carnet_roles}
    t.string :ability, null: false
    t.datetime :created_at, null: false
    t.index %i[role_id ability], unique: true
    t.index :ability
  end

  create_table :carnet_role_assignments, force: true do |t|
    t.string :principal_type, null: false
    t.bigint :principal_id, null: false
    t.references :role, null: false,
      foreign_key: {to_table: :carnet_roles}
    t.string :roleable_type, null: false
    t.bigint :roleable_id, null: false
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

  create_table :carnet_role_events, force: true do |t|
    t.string :actor_type
    t.bigint :actor_id
    t.string :target_type, null: false
    t.bigint :target_id, null: false
    t.string :action, null: false
    t.string :role_name
    t.string :roleable_type
    t.bigint :roleable_id
    t.json :metadata
    t.datetime :created_at, null: false
    t.index %i[target_type target_id]
    t.index %i[actor_type actor_id]
    t.index %i[roleable_type roleable_id]
    t.index :action
    t.index :created_at
  end

  # Dummy models for testing.
  create_table :users, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :organizations, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :projects, force: true do |t|
    t.references :organization
    t.string :name
    t.timestamps
  end
end

# Minimal test models.
class User < ActiveRecord::Base
  include Carnet::RoleBearer
end

class Organization < ActiveRecord::Base; end

class Project < ActiveRecord::Base
  belongs_to :organization, optional: true
end

# Reset configuration before each test.
module CarnetTestSetup
  def setup
    super
    Carnet.reset_configuration!
  end
end
