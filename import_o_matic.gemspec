$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "import_o_matic/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "import_o_matic"
  s.version     = ImportOMatic::VERSION
  s.authors     = ["Ruben Sierra Gonzelez"]
  s.email       = ["ruben@simplelogica.net"]
  s.summary     = "Data importation"
  s.description = "Data importation"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 5"

  s.add_development_dependency "sqlite3"
  # Comment dependency while globalize has not tag for rails 5
  # s.add_development_dependency "globalize", "~> 5.1.0"
end
