# frozen_string_literal: true

require_relative "lib/carnet/version"

Gem::Specification.new do |spec|
  spec.name = "carnet"
  spec.version = Carnet::VERSION
  spec.authors = ["Gandalf"]
  spec.summary = "Role-based access control for Turnstile"
  spec.description = <<~DESC
    Carnet provides persistent roles, time-bounded role
    assignments, a role-ability mapping, and an append-only
    audit log. It sits beneath Turnstile's policy layer as
    the data store policies consult -- never making
    authorization decisions on its own.
  DESC
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "turnstile"

  spec.metadata["rubygems_mfa_required"] = "true"
end
