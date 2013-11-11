# import_o_matic/lib/import_o_matic/importable.rb
require 'import_o_matic/formats/csv'
require 'import_o_matic/options'
require 'import_o_matic/logger'

module ImportOMmatic
  module Importable
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def import_o_matic import_class = ImportOMmatic::Options
        cattr_accessor :import_options, :import_log
        self.import_options = import_class.new self
      end

      def import_from_file file_path
        self.import_log = ImportOMmatic::Logger.new(self.name.downcase)
        self.import_log.info "---- Init #{self.name.downcase} importation from file #{file_path}"
        format_class = "import_o_matic/formats/#{import_options.format.to_s}".classify.constantize

        format_class.import_from_file file_path, import_options.format_options do |row|
          attributes = {}
          import_options.columns.each do |column, attribute|
            if row[column.to_s]
              value = import_options.transform_column(column, row[column.to_s])
              attributes[attribute] = value if value
            end
          end
          action = row[import_options.incremental_action_column.to_s]
          incremental_id = row[import_options.incremental_id_column.to_s]
          self.import_log.counter :total
          item = self.import_attributes attributes, action, incremental_id
          self.import_log.print_errors(row, item) if item.errors.any?
        end
        self.import_log.finish
      end

      def import_attributes attributes, action, incremental_id
        case action
        when import_options.actions[:update]
          self.import_log.counter import_options.actions[:update]
          element = self.where(import_options.incremental_id_attribute => incremental_id).first
          element.update_attributes attributes if element
        when import_options.actions[:destroy]
          self.import_log.counter import_options.actions[:destroy]
          element = self.where(import_options.incremental_id_attribute => incremental_id).first
          element.destroy if element
        else
          self.import_log.counter import_options.actions[:create]
          self.create attributes
        end
      end

    end

  end
end

ActiveRecord::Base.send :include, ImportOMmatic::Importable
