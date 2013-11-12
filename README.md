# Import-O-Matic (WIP)

Import-O-Matic is a WIP Rails 4 gem for import data to active record models.

Features:

 - Supports multiple formats (only csv now :disappointed:).
 - Clean configuration (external class).
 - Text logs.
 - Multiple actions per row (create, update, delete).

Import-O-Matic is in develop for a ruby 2 and rails 4 project, so it is tested in this environments only by the moment

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

Select column names from file to import with an array:

```ruby
  import_columns [:column1]
```

Map column names with model attributes with a hash:

```ruby
  import_columns column1: :attribute1
```

Apply a function to a value before update the attribute with a Proc:

```ruby
  import_transforms column1: ->(value) { value.next }
```

Apply a function to a value before update the attribute with a method:

```ruby
  import_transforms column1: :plus_one

  def plus_one value
    value.next
  end
```

Apply a function to a value before update the attribute with a method:
```ruby
  incremental relation: :column1
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
