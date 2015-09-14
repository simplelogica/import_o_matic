# import_o_matic/test/import_o_matic_test.rb

require 'test_helper'

class ArrayColumnsOptions < ImportOMmatic::Options
  import_matches [:string_field]
end

class HashColumnsOptions < ImportOMmatic::Options
  import_matches string_field: :extra_field
end

class ProcTransformOptions < ImportOMmatic::Options
  import_transforms integer_field: ->(value) { value.next }
end

class MethodTransformOptions < ImportOMmatic::Options
  import_transforms integer_field: :plus_one
  def plus_one value; value.next; end
end

class MultipleTransformColumnsOptions < ImportOMmatic::Options
  import_matches string_field: [:string_field, :extra_field]

  import_transforms string_field: :full_string
  def full_string string, extra
    "#{string} #{extra}"
  end
end

class IncrementalOptions < ImportOMmatic::Options
  incremental relation: :integer_field
end

class IncrementalRelationOptions < ImportOMmatic::Options
  incremental relation: {external_id: :string_field}
end

class LocalImportOptions < ImportOMmatic::Options
  file_path Rails.root.join('test/fixtures/import_models.csv')
end

class StripImportOptions < ImportOMmatic::Options
  strip_values
  import_matches string_field: :extra_field
end

class BeforeProcImportOptions < ImportOMmatic::Options
  before_actions ->(element) { element.string_field = 'before' }
end

class BeforeMethodImportOptions < ImportOMmatic::Options
  before_actions :plus_one

  def plus_one element
    element.integer_field = element.integer_field.next
  end
end

class BeforeProcMethodImportOptions < ImportOMmatic::Options
  before_actions :plus_one,
    ->(element) { element.string_field = 'before' }

  def plus_one element
    element.integer_field = element.integer_field.next
  end
end

class AfterProcImportOptions < ImportOMmatic::Options
  after_actions ->(element) { element.update_attributes string_field: 'after' }
end

class AfterMethodImportOptions < ImportOMmatic::Options
  after_actions :plus_one

  def plus_one element
    element.update_attributes integer_field: element.integer_field.next
  end
end

class AfterProcMethodImportOptions < ImportOMmatic::Options
  after_actions :plus_one,
    ->(element) { element.update_attributes string_field: 'after' }

  def plus_one element
    element.update_attributes integer_field: element.integer_field.next
  end
end

class ImportOMaticTest < ActiveSupport::TestCase
  fixtures :import_models
  # called before every single test
  def setup
    @last_import_data = { string_field: "import four", integer_field: 4, extra_field: "  extra" }
  end

  test "should_be_importable" do
    ImportModel.import_o_matic

    assert ImportModel.importable?
  end

  test "should_import_all_rows" do
    ImportModel.import_o_matic

    count_before = ImportModel.count
    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    count_after = ImportModel.count

    assert_equal 4, count_after - count_before
  end

  test "should_import_from_local" do
    ImportModel.import_o_matic LocalImportOptions

    count_before = ImportModel.count
    ImportModel.import_from_local
    count_after = ImportModel.count

    assert_equal 4, count_after - count_before
  end

  test "should_not_import_from_local_when_not_exists" do
    ImportModel.import_o_matic

    count_before = ImportModel.count
    ImportModel.import_from_local
    count_after = ImportModel.count

    assert_equal 0, count_after - count_before
  end

  test "should_import_all_attributes" do
    ImportModel.import_o_matic

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:string_field], last_import.string_field
    assert_equal @last_import_data[:integer_field], last_import.integer_field
  end

  test "should_strip_attributes" do
    ImportModel.import_o_matic StripImportOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:extra_field].strip, last_import.string_field
  end

  test "should_import_import_array_columns" do
    ImportModel.import_o_matic ArrayColumnsOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:string_field], last_import.string_field
    assert_equal nil, last_import.integer_field
  end

  test "should_import_import_hash_columns" do
    ImportModel.import_o_matic HashColumnsOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:extra_field], last_import.string_field
    assert_equal nil, last_import.integer_field
  end

  test "should_transform_attributes_with_proc" do
    ImportModel.import_o_matic ProcTransformOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:integer_field].next, last_import.integer_field
  end

  test "should_transform_attributes_with_method" do
    ImportModel.import_o_matic ProcTransformOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:integer_field].next, last_import.integer_field
  end

  test "should_multiple_transform_attributes_with_method" do
    ImportModel.import_o_matic MultipleTransformColumnsOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal "#{@last_import_data[:string_field]} #{@last_import_data[:extra_field]}", last_import.string_field
  end

  test "should_call_before_action_with_proc" do
    ImportModel.import_o_matic BeforeProcImportOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal 'before', last_import.string_field
  end

  test "should_call_before_action_with_method" do
    ImportModel.import_o_matic BeforeMethodImportOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:integer_field].next, last_import.integer_field
  end

  test "should_call_before_action_with_proc_and_method" do
    ImportModel.import_o_matic BeforeProcMethodImportOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal 'before', last_import.string_field
    assert_equal @last_import_data[:integer_field].next, last_import.integer_field
  end

  test "should_call_after_action_with_proc" do
    ImportModel.import_o_matic AfterProcImportOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal 'after', last_import.string_field
  end

  test "should_call_after_action_with_method" do
    ImportModel.import_o_matic AfterMethodImportOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:integer_field].next, last_import.integer_field
  end

  test "should_call_after_action_with_proc_and_method" do
    ImportModel.import_o_matic AfterProcMethodImportOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal 'after', last_import.string_field
    assert_equal @last_import_data[:integer_field].next, last_import.integer_field
  end

  test "should_do_import_incremental" do
    ImportModel.import_o_matic IncrementalOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/incremental_import_models.csv'
    first_import_data = { string_field: "import one", integer_field: 1, extra_field: "extra" }
    last_import = ImportModel.last

    assert_equal first_import_data[:string_field], import_models(:one).string_field
    assert_raises(ActiveRecord::RecordNotFound) { import_models(:two) }
    assert_equal @last_import_data[:integer_field], last_import.integer_field
    assert_equal @last_import_data[:string_field], last_import.string_field
    assert_equal @last_import_data[:integer_field], last_import.integer_field
  end

  test "should_do_import_incremental_with_match_column" do
    ImportModel.import_o_matic IncrementalRelationOptions

    ImportModel.import_from_file Rails.root.join 'test/fixtures/incremental_import_models.csv'
    first_import_data = { string_field: "import one", integer_field: 1, extra_field: "extra", external_id: 1 }
    last_import = ImportModel.last

    assert_equal first_import_data[:string_field], import_models(:one).string_field
    assert_raises(ActiveRecord::RecordNotFound) { import_models(:two) }
    assert_equal @last_import_data[:integer_field], last_import.integer_field
    assert_equal @last_import_data[:string_field], last_import.string_field
    assert_equal @last_import_data[:integer_field], last_import.integer_field
  end
end
