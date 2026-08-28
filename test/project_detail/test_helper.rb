# frozen_string_literal: true

class AssertionFailure < StandardError; end

class TinyTestCase
  def assert(condition, message = "expected condition to be truthy")
    raise AssertionFailure, message unless condition
  end

  def refute(condition, message = "expected condition to be falsey")
    assert(!condition, message)
  end

  def assert_equal(expected, actual)
    assert(expected == actual, "expected #{expected.inspect}, got #{actual.inspect}")
  end

  def assert_nil(actual)
    assert(actual.nil?, "expected nil, got #{actual.inspect}")
  end

  def assert_empty(actual)
    assert(actual.empty?, "expected #{actual.inspect} to be empty")
  end

  def assert_includes(actual, expected)
    assert(actual.include?(expected), "expected #{actual.inspect} to include #{expected.inspect}")
  end

  def refute_includes(actual, expected)
    refute(actual.include?(expected), "expected #{actual.inspect} not to include #{expected.inspect}")
  end

  def assert_raises(error_class)
    yield
    raise AssertionFailure, "expected #{error_class} to be raised"
  rescue error_class => error
    error
  end
end

module TinyTestRunner
  module_function

  def run(test_case)
    tests = test_case.instance_methods(false).grep(/^test_/).sort
    passed = 0

    tests.each do |test_name|
      test_case.new.public_send(test_name)
      puts "PASS #{label(test_name)}"
      passed += 1
    rescue StandardError => error
      warn "FAIL #{label(test_name)}: #{error.message}"
    end

    failed = tests.length - passed
    puts "#{passed} passed, #{failed} failed"
    exit(failed.zero? ? 0 : 1)
  end

  def label(test_name)
    test_name.to_s.delete_prefix("test_").tr("_", " ")
  end
end
