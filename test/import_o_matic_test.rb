# import_o_matic/test/import_o_matic_test.rb

require 'test_helper'

class ImportOMaticTest < ActiveSupport::TestCase
  # called before every single test
  def setup
    @last_import_data = { string_field: "import two", integer_field: 2 }
  end

  test "should_import_all_rows" do
    ImportModel.import_o_matic import_options: { headers: true }

    count_before = ImportModel.count
    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    count_after = ImportModel.count

    assert_equal 2, count_after - count_before
  end

  test "should_import_all_attributes" do
    ImportModel.import_o_matic import_options: { headers: true }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import_model = ImportModel.last

    assert_equal @last_import_data[:string_field], last_import_model.string_field
    assert_equal @last_import_data[:integer_field], last_import_model.integer_field
  end

  test "should_import_import_attributes" do
    ImportModel.import_o_matic import_attributes: [:string_field],
                  import_options: { headers: true }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import_model = ImportModel.last

    assert_equal @last_import_data[:string_field], last_import_model.string_field
    assert_equal nil, last_import_model.integer_field
  end

  test "should_transform_attributes_with_proc" do
    ImportModel.import_o_matic import_options: { headers: true },
                  transforms: { integer_field: ->(value) { value.next } }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import_model = ImportModel.last

    assert_equal 3, last_import_model.integer_field
  end

  test "should_transform_attributes_with_method" do
    ImportModel.import_o_matic import_options: { headers: true },
                  transforms: { integer_field: :plus_one }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import_model = ImportModel.last

    assert_equal 3, last_import_model.integer_field
  end

  test "should_ignore_nil_attribute_transform" do
    ImportModel.import_o_matic import_attributes: [:integer_field, :extra_field],
                  import_options: { headers: true },
                  transforms: { extra_field: ->(value) { nil } }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import_model = ImportModel.last

    assert_equal 2, last_import_model.integer_field
  end
end
