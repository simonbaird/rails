require "cases/helper"
require 'logger'
require 'active_support/core_ext/object/inclusion'

class SanitizerTest < ActiveModel::TestCase
  attr_accessor :logger

  class Authorizer < ActiveModel::MassAssignmentSecurity::PermissionSet
    def deny?(key)
      key.in?(['admin'])
    end
  end

  def setup
    @logger_sanitizer = ActiveModel::MassAssignmentSecurity::LoggerSanitizer.new(self)
    @strict_sanitizer = ActiveModel::MassAssignmentSecurity::StrictSanitizer.new(self)
    @authorizer = Authorizer.new
  end

  test "sanitize attributes" do
    original_attributes = { 'first_name' => 'allowed', 'admin' => 'denied' }
    attributes = @logger_sanitizer.sanitize(original_attributes, @authorizer)

    assert attributes.key?('first_name'), "Allowed key shouldn't be rejected"
    assert !attributes.key?('admin'),     "Denied key should be rejected"
  end

  test "debug mass assignment removal with LoggerSanitizer" do
    original_attributes = { 'first_name' => 'allowed', 'admin' => 'denied' }
    log = StringIO.new
    self.logger = Logger.new(log)
    @logger_sanitizer.sanitize(original_attributes, @authorizer)
    assert_match(/admin/, log.string, "Should log removed attributes: #{log.string}")
  end

  test "debug mass assignment removal with StrictSanitizer" do
    original_attributes = { 'first_name' => 'allowed', 'admin' => 'denied' }
    assert_raise ActiveModel::MassAssignmentSecurity::Error do
      @strict_sanitizer.sanitize(original_attributes, @authorizer)
    end
  end

end
