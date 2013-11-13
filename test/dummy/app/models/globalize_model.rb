class GlobalizeModel < ActiveRecord::Base
  translates :title, :body
  accepts_nested_attributes_for :translations
end
