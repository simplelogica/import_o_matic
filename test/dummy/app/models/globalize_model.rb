class GlobalizeModel < ActiveRecord::Base
  translates :title, :body
end
