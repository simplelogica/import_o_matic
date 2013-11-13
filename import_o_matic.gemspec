$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "import_o_matic/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "import_o_matic"
  s.version     = ImportOMatic::VERSION
  s.authors     = ["Rubén Sierra González"]
  s.email       = ["ruben@simplelogica.net"]
  s.summary     = "Data importation"
  s.description = "Data importation"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "globalize", "~> 4.0.0.alpha.2"
end
