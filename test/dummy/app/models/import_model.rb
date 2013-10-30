class ImportModel < ActiveRecord::Base
  def self.plus_one value
    value.next
  end
end
