# Handcuffs

[![Circle CI](https://circleci.com/gh/procore/handcuffs.svg?style=svg)](https://circleci.com/gh/procore/handcuffs)

Handcuffs provides an easy way to run migrations in phases in your [Ruby on
Rails](https://rubyonrails.org/) application.

To configure, first create a handcuff initializer and define a configuration

```ruby
# config/initializers/handcuffs.rb

Handcuffs.configure do |config|
  config.phases = [:pre_restart, :post_restart]
end
```

Then call `phase` from inside your migrations

```ruby
# db/migrate/20160318230933_add_on_sale_column.rb

class AddOnSaleColumn < ActiveRecord::Migration

  phase :pre_restart

  def up
    add_column :products, :on_sale, :boolean
  end

  def down
    remove_column :products, :on_sale
  end

end
```

```ruby
# db/migrate/20160318230988_add_on_sale_index

class AddOnSaleIndex < ActiveRecord::Migration

  phase :post_restart

  def up
    add_index :products, :on_sale, algorithm: :concurrently
  end

  def down
    remove_column :products, :on_sale
  end

end
```

You can then run your migrations in phases using
```bash
rake 'handcuffs:migrate[pre_restart]'
```
or
```bash
rake 'handcuffs:migrate[post_restart]'
```

You can run all migrations using
```bash
rake 'handcuffs:migrate[all]'
```

This differs from running `rake db:migrate` in that specs will be run in the
_order that the phases are defined in the handcuffs config_.

If you run a handcuffs rake task and any migration does not have a phase
defined, an error will be raised before any migrations are run. To prevent this
error, you can define a default phase for migrations that don't define one.
```ruby
# config/initializers/handcuffs.rb

Handcuffs.configure do |config|
  config.phases = [:pre_restart, :post_restart]
  config.default_phase = :pre_restart
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'handcuffs'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install handcuffs

## Running specs

The specs for handcuffs are in the dummy application at `/spec/dummy/spec`.
Run `rake db:create` to create the test Sqlite database before you run the specs
for the first time. You can then run the specs using `rake spec`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/procore/handcuffs. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## About Procore

<img
  src="https://www.procore.com/images/procore_logo.png"
  alt="Procore Logo"
  width="250px"
/>

Handcuffs is maintained by Procore Technologies.

Procore - building the software that builds the world.

Learn more about the #1 most widely used construction management software at [procore.com](https://www.procore.com/)
