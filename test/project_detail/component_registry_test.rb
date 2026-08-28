# frozen_string_literal: true

require_relative "test_helper"
require_relative "../../_plugins/project_detail"

class ComponentRegistryTest < TinyTestCase
  SOURCE_PATH = "_projects/example.md"

  class FakeComponent < BoningNet::ProjectDetail::Components::Base
    register_as "fake"

    def compile(_node, _context)
      { "type" => self.class.type }
    end
  end

  def test_registers_and_fetches_component_types
    registry = BoningNet::ProjectDetail::ComponentRegistry.new
    registry.register(FakeComponent)

    assert_equal FakeComponent, registry.fetch("fake", source_path: SOURCE_PATH, line: 3)
    assert_equal ["fake"], registry.types
  end

  def test_rejects_duplicate_component_types
    registry = BoningNet::ProjectDetail::ComponentRegistry.new
    registry.register(FakeComponent)

    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      registry.register(FakeComponent)
    end

    assert_includes error.message, 'duplicate directive registration "fake"'
  end

  def test_rejects_unknown_directives_with_their_source_location
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      BoningNet::ProjectDetail::ComponentRegistry.new.fetch(
        "unknown",
        source_path: SOURCE_PATH,
        line: 3
      )
    end

    assert_includes error.message, "_projects/example.md:3"
    assert_includes error.message, 'unknown directive "unknown"'
  end

  def test_base_registers_an_immutable_public_type
    assert_equal "fake", FakeComponent.type
    assert FakeComponent.type.frozen?
  end

  def test_base_requires_subclasses_to_implement_compile
    error = nil
    begin
      BoningNet::ProjectDetail::Components::Base.new.compile(nil, nil)
    rescue NotImplementedError => raised_error
      error = raised_error
    end

    assert error
    assert_includes error.message, "must implement #compile"
  end
end

TinyTestRunner.run(ComponentRegistryTest)
