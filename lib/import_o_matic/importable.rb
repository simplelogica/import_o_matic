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
        cattr_accessor :import_class, :import_options, :import_log, :raw_data
        self.import_class = import_class
        self.import_options = import_class.new self
      end

      def importable?
        respond_to? :import_class
      end

      def import_from_local
          import_from_file import_options.local_file_path
      end

      def import_from_file file_path
        result = {}
        self.import_log = ImportOMmatic::Logger.new(self.name.underscore, import_options.logs)
        if file_path && File.exists?(Rails.root.join file_path)
          self.import_log.info "---- Init #{self.model_name.human} importation from file #{file_path}"
          format_class = "import_o_matic/formats/#{import_options.format.to_s}".classify.constantize

          format_class.import_from_file file_path, import_options.format_options do |row|
            begin
              item_attributes = import_options.get_attributes row
              unless import_options.translated_attributes.nil?
                item_attributes[:translations_attributes] = import_options.get_translated_attributes row
              end

              action = row[import_options.incremental_action_column.to_s] || import_options.default_action
              incremental_id = row[import_options.incremental_id_column.to_s]
              self.import_log.counter :total

              element = self.initialize_element item_attributes, incremental_id
              # Assign raw data in case is useful in callbacks
              element.raw_data = row if element
              import_options.call_before_actions element if import_options.befores.any?
              element = self.execute_action element, item_attributes, action
              import_options.call_after_actions element if import_options.afters.any?
            rescue Exception => e
              self.import_log.counter :errors
              self.import_log.error "Unexpected exception: #{e.message}"
              self.import_log.error "Backtrace: #{e.backtrace.join("\n\t")}"
              self.import_log.error "Data: #{row}"
              self.import_log.error "Element: #{element.inspect}" if element
            end
          end
          result.merge! self.import_log.finish
        else
          self.import_log.info "---- Init #{self.model_name.human} importation from file #{file_path}"
          self.import_log.error " File not found."
        end
      rescue Exception => e
        self.import_log.error "Unexpected exception: #{e.message}"
        self.import_log.error "Backtrace: #{e.backtrace.join("\n\t")}"
      ensure
        result.merge! log: self.import_log.path unless self.import_log.blank?
        return result
      end

      def initialize_element attributes, incremental_id
        unless import_options.incremental_id_attribute.blank?
          element_scope = self.where(import_options.incremental_id_attribute => incremental_id)
          element_scope = element_scope.send(import_options.scope_name) if import_options.scope_name
          element_scope.first
        end || self.new(attributes) # If no incremental or element not found
      end

      def execute_action element, attributes, action
        if action == import_options.actions[:destroy]
          destroy_element element
        elsif !element.new_record?
          update_element element, attributes
        else
          save_element element
        end
      end

      def save_element element
        if element.save(validate: import_options.validate)
          self.import_log.counter :create
        else
          self.import_log.print_errors(element.attributes.inspect, element)
        end
        element
      end

      def destroy_element element
        if element
          self.import_log.counter :destroy
          element.destroy
        end
        element
      end

      def update_element element, attributes
        if element
          # Extract translations_attributes for update one to one
          translations_attributes = attributes.delete :translations_attributes
          element.assign_attributes attributes
          if element.save(validate: import_options.validate)
            # Translatio id is needed for nested update so we do updates one to one
            # If there is no id, the translation is created
            translations_attributes.each do |translation_attributes|
              translation = element.translation_for translation_attributes[:locale]
              translation.update_attributes translation_attributes
            end if translations_attributes
            self.import_log.counter :update
          else
            self.import_log.print_errors(attributes.inspect, element)
          end
        end
        element
      end

    end

  end
end

ActiveRecord::Base.send :include, ImportOMmatic::Importable
