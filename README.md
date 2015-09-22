# Import-O-Matic (WIP)

Import-O-Matic is a WIP Rails 4 gem for import data to active record models.

Features:

 - Supports multiple formats (only csv now :disappointed:).
 - Clean configuration (external class).
 - Text logs.
 - Multiple actions per row (create, update, delete).
 - Globalize support.

Import-O-Matic is in development for a ruby 2 and rails 4 project, so it is only tested in this environment at the moment.

## :floppy_disk: Install

Add the gem to your gemfile:

```ruby
  gem 'import_o_matic', github: 'simplelogica/import_o_matic'
```

Add to Import-O-Matic your model:

```ruby
  class MyModel < ActiveRecord::Base
    ...
    import_o_matic
    ...
  end
```

Ask your model:

```ruby
  MyModel.importable?
```

Import data:

Add to Import-O-Matic your model:

```ruby
  MyModel.import_from_file 'path/to/file'
```

Or use a default local file (see file_path option):

```ruby
  MyModel.import_from_local
```

Take a look at _log/importations_ for process information.


By default, Import-O-Matic creates a new instance of the model and try to map each column in the importation file with an attribute with same name.

## :video_game: Configure

Create an import config class in app/imports:

```ruby
  class MyModelImport < ImportOMmatic::Options
    ...
  end
```

And use it in your model:

```ruby
  class MyModel < ActiveRecord::Base
    ...
    import_o_matic MyModelImport
    ...
  end
```

### :book: Configure options:

Select format (default :csv):

```ruby
  import_format :csv
```

Select format with options (default { headers: true }):

```ruby
  import_format csv: { headers: true }
```

Set a default file for local import (with import_from_local method):

```ruby
  file_path 'path/to/file'
```

Strip blanks arround columns after read (default false):

```ruby
  strip_values
```

Select column names from file to import with an array:

```ruby
  import_matches [:attribute1]
```

Map model attribute names with column names with a hash:

```ruby
  import_matches attribute1: :column1
```

Apply a function to values before update the attribute with a Proc:

```ruby
  import_transforms attribute1: ->(value) { value.next }
```

Apply a function to a value before update the attribute with a method:

```ruby
  import_transforms attribute1: :plus_one

  def plus_one value
    value.next
  end
```

You can assign multiple columns to an attribute, but it needs a transformation or it will use first column by default. Take care with the params order, it needs to be the same of the columns declaration:

```ruby
  import_matches full_name: [:name, :last_name]
  import_transforms full_name: :join_name

  def join_name name, last_name
    "#{name} #{last_name}"
  end
```

Apply procs or methods to the attribute hash before import action:
```ruby
  before_actions :plus_one,
    ->(element) { element.string_attribute = 'after' }

  def plus_one attributes
    attributes.integer_attribute += 1
  end
```

Apply procs or methods to an element after import action:
```ruby
  after_actions :plus_one,
    ->(element) { element.update_attributes string_attribute: 'after' }

  def plus_one element
    element.update_attributes integer_attribute: element.integer_attribute.next
  end
```

Apply a named scope of the model when an item is search in incremental imports
```ruby
  use_scope :custom_scope
```


You can use different actions (create, update or delete) for incremental imports. You need a column for set the relation between import data and existing objects, and another column with the action. **When the import can´t match an action, it uses create by default**.

- Default relation column: *_id_*
- Default relation model attribute: *_id_*
- Default action column: *_action_*
- Default actions values: *_{ create: "ADD", update: "UPDATE", destroy: "REMOVE" }_*

Set relation column:

```ruby
  incremental relation: :column1
```

Set map relation column with relation model attribute:

```ruby
  incremental relation: { column1: :attribute1 }
```

Set action column:

```ruby
  incremental action_column: :action
```

Set action column values:

```ruby
  incremental actions: { create: "ADD", update: "UPDATE", destroy: "REMOVE" }
```

### :earth_africa: Globalize 4 support

```ruby
  globalize
```

You can import globalize translated attributes with this option. It's not configurable at the moment.

**NOTE: The gem will add *'accepts_nested_attributes_for :translations'* to model if is not already set.**

The gem gets automatically the model translated attributes and search for columns named "attribute-locale" for each available locale. For example:

```ruby
  class MyModel < ActiveRecord::Base
    ...
    transtales :name
    ...
    import_o_matic MyModelImport
    ...
  end

  class MyModelImport < ImportOMmatic::Options
    ...
    globalize
    ...
  end
```

The import looks for name-en, name-es... columns in the file, one for each locale in I18n.available_locales.


# :white_check_mark: TODO:

- Better tests.
- Better logs.
- More ruby and rails versions.
- Configuration for globalize fields.
- Multiple assigns for globalize fields.
...
- Some cool stuff :disappointed:.
