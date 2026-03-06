# frozen_string_literal: true

require_relative "../test_helper"

class VersionTest < Minitest::Test
  def test_version_is_set
    refute_nil Carnet::VERSION
  end

  def test_version_is_semantic
    assert_match(/\A\d+\.\d+\.\d+\z/, Carnet::VERSION)
  end
end
