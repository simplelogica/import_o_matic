class ImportModel < ActiveRecord::Base
  scope :custom_scope, -> { where(integer_field: 1) }
end
