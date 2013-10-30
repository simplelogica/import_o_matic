# import_o_matic/lib/import_o_matic/csv.rb
require 'csv'

module ImportOMatic
  module Formats
    module Csv
      def self.import_from_file file_path, import_options
        CSV.foreach(file_path, import_options) do |row|
          yield(row)
        end
      end
    end
  end
end
