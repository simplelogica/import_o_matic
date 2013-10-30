# import_o_matic/lib/import_o_matic/importable.rb
require 'import_o_matic/formats/csv'

module ImportOMmatic
  module Importable
    ACTIONS = {
      create: "ADD",
      update: "UPDATE",
      destroy: "REMOVE"
    }.freeze

    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def import_o_matic options
        cattr_accessor :import_columns, :import_format, :import_options, :transforms,
          :incremental_action_column, :incremental_actions, :incremental_id_column
        self.import_columns = options[:import_columns] || self.attribute_names
        self.import_format = options[:import_format] || :csv
        self.import_options = options[:import_options] || {}
        self.transforms = options[:transforms] || {}
        incremental_import = options[:incremental_import]
        if incremental_import
          incremental_import = {} unless incremental_import.is_a? Hash
          self.incremental_action_column = incremental_import[:incremental_action_column] || :action
          self.incremental_id_column = incremental_import[:incremental_id_column] || :id
          self.incremental_actions = calculate_actions incremental_import[:incremental_actions]
        end
        self.incremental_actions ||= ACTIONS
      end

      def calculate_actions actions
        if actions.is_a? Hash
          actions.keys.short == ACTIONS.keys.short ? actions : ACTIONS
        else
          ACTIONS
        end
      end

      def import_from_file file_path
        format_class = "import_o_matic/formats/#{import_format.to_s}".classify.constantize
        format_class.import_from_file file_path, import_options do |row|
          attributes = {}
          self.import_columns.each do |attribute|
            if row[attribute.to_s]
              value = self.transform_attribute(attribute, row[attribute.to_s])
              attributes[attribute] = value if value
            end
          end
          action = row[self.incremental_action_column.to_s]
          external_id = row[self.incremental_id_column.to_s]
          self.import_attributes attributes, action, external_id
        end
      end

      def import_attributes attributes, action, external_id
        case action
        when self.incremental_actions[:update]
          element = self.where(self.incremental_id_column.to_s => external_id).first
          element.update_attributes attributes if element
        when self.incremental_actions[:destroy]
          element = self.where(self.incremental_id_column => external_id).first
          element.destroy if element
        else
          self.create attributes
        end
      end

      def transform_attribute attribute_name, value
        transform = self.transforms[attribute_name.to_sym]
        case transform
        when Proc
          transform.call(value)
        when String
          self.send(transform, value)
        when Symbol
          self.send(transform, value)
        else
          value
        end
      end
    end

  end
end

ActiveRecord::Base.send :include, ImportOMmatic::Importable
