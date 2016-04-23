# Apique

Apique modules replace tons of API cotrollers code which makes trivial actions including searching and CRUD, and provides front-end with thought-out errors and explanations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apique'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apique

## Usage

There is 8 modules with the following hierarchy:
```
- Basics (auth)
- - Pickable (singular actions)
- - - Editable (singular write actions)
- - Listable (plural actions)
- - - Filterable
- - - Sortable
- - - Paginatable
- - - Searchable (sum of the previous 3)
```
Modules suppose to be injected into an ActionController instance to provide needed functional, for example
```ruby
# In Rails 5 you may also want to inherit from ActionController::API
class ApiController < ApplicationController
  include Apique::Searchable
  include Apique::Editable
end
```
Since ApiController has both highest-level modules injected, it now provides all the functional and default controller actions which utilize all the power of Apique.

Now what is left is to make routes to these actions. In future releases it will be done by one engine mount based on the definition of #collection_name method.

```ruby
  get 'api/:model' => 'api#index'
  get 'api/:model/:id' => 'api#show'
  post 'api/:model' => 'api#create'
  patch 'api/:model/:id' => 'api#update'
  delete 'api/:model/:id' => 'api#destroy'
```

In order to create controllers with _specific_ actions, just inherit from ApiController (in this example) and define routes... as usual!

## Current restrictions

For the moment #filter_collection! used in #index works only with PostgreSQL and #sort_collection! used in #index works only with SQL databases.
There will be support for other SQL DBs and Mongoid in the future.

## TODO

Describe search facilities and future plans.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tinbka/apique.

