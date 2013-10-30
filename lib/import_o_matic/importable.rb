# import_o_matic/lib/import_o_matic/importable.rb
require 'import_o_matic/formats/csv'

module ImportOMmatic
  module Importable
    DEFAULT_ACTIONS = {
      create: "ADD",
      update: "UPDATE",
      destroy: "REMOVE"
    }.freeze

    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def import_o_matic options
        cattr_accessor :import_columns, :import_format, :import_options,
          :transforms, :incremental_action_column, :incremental_actions,
          :incremental_id_column, :incremental_id_attribute
        self.import_columns = self.match_values(options[:import_columns] || self.attribute_names)
        self.import_format = options[:import_format] || :csv
        self.import_options = options[:import_options] || {}
        self.transforms = options[:transforms] || {}
        incremental_import = options[:incremental_import]
        if incremental_import
          incremental_import = {} unless incremental_import.is_a? Hash
          self.incremental_action_column = incremental_import[:incremental_action_column] || :action
          self.incremental_id_column = self.match_values(incremental_import[:incremental_id_column]).keys.first || :id
          self.incremental_id_attribute = self.match_values(incremental_import[:incremental_id_column]).values.first || :id
          self.incremental_actions = calculate_actions incremental_import[:incremental_actions]
        end
        self.incremental_actions ||= DEFAULT_ACTIONS
      end

      def calculate_actions actions
        if actions.is_a? Hash
          actions.keys.short == DEFAULT_ACTIONS.keys.short ? actions : DEFAULT_ACTIONS
        else
          DEFAULT_ACTIONS
        end
      end

      def import_from_file file_path
        format_class = "import_o_matic/formats/#{import_format.to_s}".classify.constantize
        format_class.import_from_file file_path, import_options do |row|
          attributes = {}
          self.import_columns.each do |column, attribute|
            if row[column.to_s]
              value = self.transform_attribute(attribute, row[column.to_s])
              attributes[attribute] = value if value
            end
          end
          action = row[self.incremental_action_column.to_s]
          incremental_id = row[self.incremental_id_column.to_s]
          self.import_attributes attributes, action, incremental_id
        end
      end

      def match_values values
        case values
        when Symbol, String
          Hash[values,values]
        when Array
          Hash[*values.collect{ |c| [c, c] }.flatten]
        when Hash
          values
        else
          {}
        end
      end

      def import_attributes attributes, action, incremental_id
        case action
        when self.incremental_actions[:update]
          element = self.where(self.incremental_id_attribute => incremental_id).first
          element.update_attributes attributes if element
        when self.incremental_actions[:destroy]
          element = self.where(self.incremental_id_attribute => incremental_id).first
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
        when Symbol, String
          self.send(transform, value)
        else
          value
        end
      end
    end

  end
end

ActiveRecord::Base.send :include, ImportOMmatic::Importable
