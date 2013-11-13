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
                    :importable_class

    self.columns = {}
    self.transforms = {}
    self.format = :csv
    self.format_options = {headers: true}
    self.actions = DEFAULT_ACTIONS

    def initialize importable_class
      if importable_class.is_a?(Class)
        self.importable_class = importable_class
        if self.columns.blank?
          self.columns = self.class.convert_to_match_values(importable_class.attribute_names)
        end
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

    def get_attributes row
      attributes = {}
      self.columns.each do |column, attribute|
        if row[column.to_s]
          value = self.transform_column(column, row[column.to_s])
          attributes[attribute] = value if value
        end
      end
      attributes
    end

    private

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
  end
end
