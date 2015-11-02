class ImportModel < ActiveRecord::Base
  scope :custom_scope, -> { where(integer_field: 1) }

  validates :string_field, presence: true
end
