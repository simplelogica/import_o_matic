# import_o_matic/lib/import_o_matic/importable.rb
require 'import_o_matic/formats/csv'

module ImportOMmatic
  module Importable
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def import_o_matic options
        cattr_accessor :import_attributes, :import_format, :import_options, :transforms
        self.import_attributes = options[:import_attributes] || self.attribute_names
        self.import_format = options[:import_format] || :csv
        self.import_options = options[:import_options] || {}
        self.transforms = options[:transforms] || {}
      end

      def import_from_file file_path
        format_class = "import_o_matic/formats/#{import_format.to_s}".classify.constantize
        format_class.import_from_file file_path, import_options do |row|
          attributes = {}
          self.import_attributes.each do |attribute|
            if row[attribute.to_s]
              value = self.transform_attribute(attribute, row[attribute.to_s])
              attributes[attribute] = value if value
            end
          end
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
