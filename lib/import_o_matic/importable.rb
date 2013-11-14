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

      def importable?
        true
      end

      def import_from_local
          import_from_file import_options.local_file_path
      end

      def import_from_file file_path
        if file_path && File.exists?(Rails.root.join file_path)
          self.import_log = ImportOMmatic::Logger.new(self.name.underscore)
          self.import_log.info "---- Init #{self.model_name.human} importation from file #{file_path}"
          format_class = "import_o_matic/formats/#{import_options.format.to_s}".classify.constantize

          format_class.import_from_file file_path, import_options.format_options do |row|
            item_attributes = import_options.get_attributes row
            unless import_options.translated_attributes.nil?
              item_attributes[:translations_attributes] = import_options.get_translated_attributes row
            end

            action = row[import_options.incremental_action_column.to_s]
            incremental_id = row[import_options.incremental_id_column.to_s]
            self.import_log.counter :total
            self.import_attributes item_attributes, action, incremental_id
          end
          self.import_log.finish
        else
          self.import_log = ImportOMmatic::Logger.new(self.name.underscore)
          self.import_log.info "---- Init #{self.model_name.human} importation from file #{file_path}"
          self.import_log.info "---- File not found."
        end
      end

      def import_attributes attributes, action, incremental_id
        case action
        when import_options.actions[:update]
          element = self.where(import_options.incremental_id_attribute => incremental_id).first
          if element
            element.update_attributes attributes
            if element.errors.any?
              self.import_log.print_errors(attributes.inspect, element)
            else
              self.import_log.counter import_options.actions[:update]
            end
          end
        when import_options.actions[:destroy]
          element = self.where(import_options.incremental_id_attribute => incremental_id).first
          if element
            self.import_log.counter import_options.actions[:destroy]
            element.destroy
          end
        else
          element = self.create attributes
          if element.errors.any?
            self.import_log.print_errors(attributes.inspect, element)
          else
            self.import_log.counter import_options.actions[:create]
          end
        end
      end

    end

  end
end

ActiveRecord::Base.send :include, ImportOMmatic::Importable
