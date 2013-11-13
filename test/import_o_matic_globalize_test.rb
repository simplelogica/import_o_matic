# import_o_matic/test/import_o_matic_test.rb

require 'test_helper'

class GlobalizeOptions < ImportOMmatic::Options
  globalize
end

class ImportOMaticTest < ActiveSupport::TestCase
  fixtures :globalize_models

  test "should_import_globalize_rows" do
    last_globalize_data = {
      "title-en" => "title 4",
      "title-es" => "título 4",
      "body-en" => "body 4",
      "body-es" => "cuerpo 4"
    }

    GlobalizeModel.import_o_matic GlobalizeOptions

    GlobalizeModel.import_from_file 'test/dummy/test/fixtures/globalize_models.csv'
    last_import = GlobalizeModel.last

    assert_equal last_globalize_data["title-en"], last_import.read_attribute(:title, locale: :en)
    assert_equal last_globalize_data["title-es"], last_import.read_attribute(:title, locale: :es)
    assert_equal last_globalize_data["body-en"], last_import.read_attribute(:body, locale: :en)
    assert_equal last_globalize_data["body-es"], last_import.read_attribute(:body, locale: :es)
  end
end
