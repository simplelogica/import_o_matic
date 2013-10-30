# import_o_matic/test/import_o_matic_test.rb

require 'test_helper'

class ImportOMaticTest < ActiveSupport::TestCase
  fixtures :import_models
  # called before every single test
  def setup
    @last_import_data = { string_field: "import four", integer_field: 4, extra_field: "extra" }
  end

  test "should_import_all_rows" do
    ImportModel.import_o_matic import_options: { headers: true }

    count_before = ImportModel.count
    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    count_after = ImportModel.count

    assert_equal 4, count_after - count_before
  end

  test "should_import_all_attributes" do
    ImportModel.import_o_matic import_options: { headers: true }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:string_field], last_import.string_field
    assert_equal @last_import_data[:integer_field], last_import.integer_field
  end

  test "should_import_import_array_columns" do
    ImportModel.import_o_matic import_columns: [:string_field],
                  import_options: { headers: true }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:string_field], last_import.string_field
    assert_equal nil, last_import.integer_field
  end

  test "should_import_import_hash_columns" do
    ImportModel.import_o_matic import_columns: {extra_field: :string_field},
                  import_options: { headers: true }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:extra_field], last_import.string_field
    assert_equal nil, last_import.integer_field
  end

  test "should_transform_attributes_with_proc" do
    ImportModel.import_o_matic import_options: { headers: true },
                  transforms: { integer_field: ->(value) { value.next } }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:integer_field].next, last_import.integer_field
  end

  test "should_transform_attributes_with_method" do
    ImportModel.import_o_matic import_options: { headers: true },
                  transforms: { integer_field: :plus_one }

    ImportModel.import_from_file 'test/dummy/test/fixtures/import_models.csv'
    last_import = ImportModel.last

    assert_equal @last_import_data[:integer_field].next, last_import.integer_field
  end

  test "should_do_import_incremental" do
    ImportModel.import_o_matic import_options: { headers: true },
                  incremental_import: {
                    incremental_id_column: :integer_field
                  }

    ImportModel.import_from_file 'test/dummy/test/fixtures/incremental_import_models.csv'
    first_import_data = { string_field: "import one", integer_field: 1, extra_field: "extra" }
    last_import = ImportModel.last

    assert_equal first_import_data[:string_field], import_models(:one).string_field
    assert_raises(ActiveRecord::RecordNotFound) { import_models(:two) }
    assert_equal @last_import_data[:integer_field], last_import.integer_field
    assert_equal @last_import_data[:string_field], last_import.string_field
    assert_equal @last_import_data[:integer_field], last_import.integer_field
  end

  test "should_do_import_incremental_with_match_column" do
    ImportModel.import_o_matic import_options: { headers: true },
                  incremental_import: {
                    incremental_id_column: { external_id: :string_field }
                  }

    ImportModel.import_from_file 'test/dummy/test/fixtures/incremental_import_models.csv'
    first_import_data = { string_field: "import one", integer_field: 1, extra_field: "extra", external_id: 1 }
    last_import = ImportModel.last

    assert_equal first_import_data[:string_field], import_models(:one).string_field
    assert_raises(ActiveRecord::RecordNotFound) { import_models(:two) }
    assert_equal @last_import_data[:integer_field], last_import.integer_field
    assert_equal @last_import_data[:string_field], last_import.string_field
    assert_equal @last_import_data[:integer_field], last_import.integer_field
  end
end
