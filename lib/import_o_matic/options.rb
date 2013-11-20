module ImportOMmatic
  class Options
    DEFAULT_ACTIONS = {
      create: "ADD",
      update: "UPDATE",
      destroy: "REMOVE"
    }.freeze

    class_attribute :columns, :transforms, :format, :format_options,
                    :actions, :incremental_action_column,
                    :incremental_id_column, :incremental_id_attribute,
                    :importable_class, :translated_attributes,
                    :globalize_options, :local_file_path, :strip,
                    :afters, :befores


    self.columns = {}
    self.transforms = {}
    self.format = :csv
    self.format_options = {headers: true}
    self.actions = DEFAULT_ACTIONS
    self.strip = false
    self.afters = []
    self.befores = []

    def initialize importable_class
      if importable_class.is_a?(Class)
        self.importable_class = importable_class
        if self.columns.blank?
          self.columns = self.class.convert_to_match_values(importable_class.attribute_names)
        end
        self.set_translated_attributes self.globalize_options unless self.globalize_options.nil?
      end
    end

    def self.import_columns options
      self.columns = self.convert_to_match_values(options)
    end

    def self.import_transforms options
      self.transforms = self.convert_to_match_values(options)
    end

    def self.import_format options
      case options
      when String, Symbol
        self.format = options
      when hash
        self.self.format = options.keys.first
        self.format_options = options.values.first
      end
    end

    def self.incremental options
      if options
        options = {} unless options.is_a? Hash
        self.incremental_action_column = options[:action_column] || :action
        self.actions = set_actions options[:actions]

        self.incremental_id_column = self.convert_to_match_values(options[:relation]).keys.first || :id
        self.incremental_id_attribute = self.convert_to_match_values(options[:relation]).values.first || :id
      end
    end

    def self.globalize *options
      self.globalize_options = *options
    end

    def self.file_path path
      self.local_file_path = path if [String, Pathname].include? path.class
    end

    def self.strip_values
      self.strip = true
    end

    def self.after_actions *options
      self.afters = *options
    end

    def self.before_actions *options
      self.befores = *options
    end

    def get_attributes row
      attributes = {}
      self.columns.each do |column, attribute|
        if row[column.to_s]
          column_value = row[column.to_s]
          column_value.strip! if strip
          value = self.transform_column(column, row[column.to_s])
          attributes[attribute] = value if value
        end
      end
      attributes
    end

    def get_translated_attributes row
      self.translated_attributes.map do |locale, attributes|
        translation_attributes = {}
        translation_attributes[:locale] = locale
        attributes.each do |column, attribute|
          if row[column.to_s]
            column_value = row[column.to_s]
            column_value.strip! if strip
            value = self.transform_column(column, column_value)
            translation_attributes[attribute] = value if value
          end
        end
        translation_attributes
      end unless self.translated_attributes.nil?
    end

    def call_after_actions element
      call_actions self.afters, element
    end

    def call_before_actions attributes
      call_actions self.befores, attributes
    end


    protected

    def self.set_actions actions
      if actions.is_a? Hash
        actions.keys.short == DEFAULT_ACTIONS.keys.short ? actions : DEFAULT_ACTIONS
      else
        DEFAULT_ACTIONS
      end
    end

    def self.convert_to_match_values values
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

    def set_translated_attributes options
      self.importable_class.accepts_nested_attributes_for :translations unless self.importable_class.respond_to? :translations_attributes
      self.translated_attributes = {}
      Rails.configuration.i18n.available_locales.each do |locale|
        match_attributes = self.importable_class.translated_attribute_names.map { |attribute| ["#{attribute}-#{locale}", attribute] }
        self.translated_attributes[locale] = self.class.convert_to_match_values(match_attributes)
      end
    end

    def transform_column column, value
      transform = self.transforms[column.to_sym]
      case transform
      when Proc
        transform.call(value)
      when Symbol, String
        self.send(transform, value)
      else
        value
      end
    end

    def call_actions callbacks, element
      callbacks.each do |action|
        case action
        when Proc
          action.call(element)
        when Symbol, String
          self.send(action, element)
        end
      end if callbacks.any? && element.present?
    end
  end
end
