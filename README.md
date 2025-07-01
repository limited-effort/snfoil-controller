# SnFoil::Controller

![build](https://github.com/limited-effort/snfoil-controller/actions/workflows/main.yml/badge.svg) [![maintainability](https://api.codeclimate.com/v1/badges/10885d7b7231f3e9b0b7/maintainability)](https://codeclimate.com/github/limited-effort/snfoil-controller/maintainability)

SnFoil Controllers help seperate your business logic from your api layer.  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'snfoil-controller'
```

## Usage
Ultimately SnFoil Controllers are just SnFoil Contexts, but they setup their workflow a little differently.  `endpoint` creates `setup_*` and `process_*` intervals to handle your data, and the method or block provided renders it.

### Quickstart Example

```ruby
# app/controllers/people_controller.rb

class PeopleController < ActionController::API
  include SnFoil::Controller

  context PeopleContext
  serializer PeopleSerializer
  deserializer PeopleDeserializer

  endpoint :create, do |object:, **options|
    if object.errors
      render json: object.errors, status: :unprocessable_entity
    else
      render json: serialize(object, **options), status: :created
    end
  end

  endpoint :update, do |object:, **options|
    if object.errors
      render json: object.errors, status: :unprocessable_entity
    else
      render json: serialize(object, **options), status: :ok
    end
  end

  endpoint :show, do |object:, **options|
    render json: serialize(object, **options), status: :created
  end

  endpoint :delete, do |object:, **options|
    if object.errors
      render json: object.errors, status: :unprocessable_entity
    else
      render json: {}, status: :no_content
    end
  end

  setup_create { |**options| options[:params] = deserialize(params, **options) }
  setup_update { |**options| options[:params] = deserialize(params, **options) }

  process_create { |**options| run_context(**options) }
  process_update { |**options| run_context(**options) }
  process_show { |**options| run_context(**options) }
  process_delete { |**options| run_context(**options) }
end
```

### Controller

A controller is a combination of a Context, Serializer, Deserializer, and a some Endpoints.  See the Quickstart exaple above and the description of functions below for more details.

##### Ussing SSR

You don't need a serializer.  You can just use a standard render in the endpoint's function. 

```ruby
# taken from https://guides.rubyonrails.org/layouts_and_rendering.html

class BooksController < ApplicationController
  def index
    @books = Book.all
  end
end

# becomes

class BooksController < ApplicationController
  include SnFoil::Controller

  endpoint(:index) { |**options| @books = Book.all }
end

```

#### Endpoint

Endpoint creates a workflow with two intervals and a primary function for rendering.


```ruby
class PeopleController < ActionController::API
  include SnFoil::Controller

  endpoint(:create) { |**options| render json: options[:object] }
end
```

In this exmaple the `setup_create` and `process_create` intervals are defined for you and the method finally returns the block.  If you don't want to provide a block you can instead pass in a method name

```ruby
class PeopleController < ActionController::API
  include SnFoil::Controller

  endpoint(:create, with: :render_create)
  
  def render_create(**options)
    render json: options[:object]
  end
end
```

Any options passed in as arguements to endpoint will be passed to the intervals and flow through just like a Context (becuase it is a Context under the hood).

```ruby
class PeopleController < ActionController::API
  include SnFoil::Controller

  endpoint(:create, with: :render_create, interesting: 'key you have there')

  setup_create do |**options|
    puts options[:interesting] # => 'key you have there'
    ...
  end
end
```
##### Arguments

<table>
  <thead>
    <th>name</th>
    <th>type</th>
    <th>description</th>
    <th>required</th>
  </thead>

  <tbody>
    <tr>
      <td>name</td>
      <td>string|symbol</td>
      <td>The name of the method to be defined on the controller and the intervals</td>
      <td>true</td>
    </tr>
    <tr>
      <td>options</td>
      <td>keyword arguments</td>
      <td>The options you want passed down the chain of intervals and to the context</td>
      <td>false</td>
    </tr>
    <tr>
      <td>block</td>
      <td>proc</td>
      <td>The function you want to render your controller action</td>
      <td>conditionally based on if you don't provide a `:with` in the only</td>
    </tr>
  </tbody>
</table>

There are a few reserved keyword arguements that cause different functionlity/configuration for options:

* `with` - The method name to use if a block is not provided to the endpoint
* `context` - The context to use for this endpoint.  Overrides the one configured using #self.context
* `context_action` - The method name to call on the context.  Defaults to the endpoint name.
* `serializer` - The serializer to use for this endpoint. Overrides the one configured using #self.serializer
* `serialize` - The block used to process the serializer. Overrides the one configured using #self.serializer
* `serialize_with` - The method used to process the serializer. Overrides the one configured using #self.serializer
* `deserializer` - The deserializer to use for this endpoint. Overrides the one configured using #self.deserializer
* `deserialize` - The block used to process the deserializer. Overrides the one configured using #self.deserializer
* `deserialize_with` - The method used to process the deserializer. Overrides the one configured using #self.deserializer

#### Context

The main context intended to be called by the Controller.

```ruby
class PeopleController < ActionController::API
  include SnFoil::Controller

  context PeopleContext
end
```
##### Arguments

<table>
  <thead>
    <th>name</th>
    <th>type</th>
    <th>description</th>
    <th>required</th>
  </thead>

  <tbody>
    <tr>
      <td>name</td>
      <td>class</td>
      <td>The context class for the controller</td>
      <td>true</td>
    </tr>
  </tbody>
</table>

You can directly call the context using the `#run_context` method and pass it the options.  It will automatically process either the `:context_action` or the `:controller_action` from the options.  This can be overridden by passing a method name to `#run_context`.

```ruby
...
  context PeopleContext

  def some_method(**options)
    run_context(:elevate, **options) #=> Calls PeopleContext#elevate
  end
...
```

#### Serializer

The main serializer intended to be called by the Controller.  Also the default serializer and block used by the '#serialize` method.

```ruby
class PeopleController < ActionController::API
  include SnFoil::Controller

  serializer PeopleSerializer
end
```
##### Arguments

<table>
  <thead>
    <th>name</th>
    <th>type</th>
    <th>description</th>
    <th>required</th>
  </thead>

  <tbody>
    <tr>
      <td>name</td>
      <td>class</td>
      <td>The serializer class for the controller</td>
      <td>false</td>
    </tr>
    <tr>
      <td>block</td>
      <td>proc</td>
      <td>The block to be called to serialize the data</td>
      <td>false</td>
    </tr>
  </tbody>
</table>

##### Default Call

If no block or method is provided, `#serialize` will try to new up the Serializer class with arguments `object` and `options` and call `#to_hash`.

```ruby
Serializer.new(object, **options).to_hash
```

##### Passing in a Block

If you provide a block to the `#self.serializer` method you can define how you want the serializer to be called.

```ruby
class PeopleController < ActionController::API
  include SnFoil::Controller

  serializer(PeopleSerializer) { |object, serializer, **_options| serializer.new(object).serialize }
end
```

#### Deserializer

The main deserializer intended to be called by the Controller.  Also the default deserializer and block used by the '#deserialize` method.

```ruby
class PeopleController < ActionController::API
  include SnFoil::Controller

  deserializer PeopleDeserializer
end
```
##### Arguments

<table>
  <thead>
    <th>name</th>
    <th>type</th>
    <th>description</th>
    <th>required</th>
  </thead>

  <tbody>
    <tr>
      <td>name</td>
      <td>class</td>
      <td>The deserializer class for the controller</td>
      <td>false</td>
    </tr>
    <tr>
      <td>block</td>
      <td>proc</td>
      <td>The block to be called to deserialize the data</td>
      <td>false</td>
    </tr>
  </tbody>
</table>

##### Default Call

If no block or method is provided, `#deserialize` will try to new up the Deserializer class with arguments `object` and `options` and call `#to_hash`.

```ruby
Deserializer.new(object, **options).to_hash
```

##### Passing in a Block

If you provide a block to the `#self.deserializer` method you can define how you want the deserializer to be called.

```ruby
class PeopleController < ActionController::API
  include SnFoil::Controller

  deserializer(PeopleDeserializer) { |object, deserializer, **_options| deserializer.new(object).deserialize }
end
```

### Serializers and Deserializers

Since Serializers seem so abundant SnFoil Controllers does not ship with any.  We recommend the awesome [jsonapi-serializer](https://github.com/jsonapi-serializer/jsonapi-serializer).

Deserializers haven't come so far - so we've setup two:

* SnFoil::Deserializer::JSON
* SnFoil::Deserializer::JSONAPI

These allow you to allow-list and format any incoming data into a standard more usable by your business logic.

##### Usage

```ruby
class PeopleDeserializer
  include SnFoil::Deserializer::JSON

  key_transform :underscore

  attributes :first_name, :middle_name, :last_name
  attributes :line1, :line2, :city, :state, :zip, prefix: :address_

  has_many :books, deserializer: BookDeserializer
end
```

Both these deserializers share some common functions

##### key_transform

How you want to format the keys in the incoming payload.  SnFoil::Deserializers will always `:to_sym` all of the keys and will by default `:underscore` them.  You can pass in most active_support inflections or you can run some custom logic on them.

###### Arguments

<table>
  <thead>
    <th>name</th>
    <th>type</th>
    <th>description</th>
    <th>required</th>
  </thead>
  <tbody>
    <tr>
      <td>transform</td>
      <td>symbol</td>
      <td>The inflection you want called on the key value. ex: `underscore`, `camelcase`</td>
      <td>false</td>
    </tr>
    <tr>
      <td>block</td>
      <td>proc</td>
      <td>A custom proc passed the input request and the key the return value will be stored under.</td>
      <td>false</td>
    </tr>
  </tbody>
</table>

##### attribute

An attribute to be taken from the input payload.

```ruby
attribute :first_name 
attribute :last_name
attribute :line1, :prefix: :addr_
attribute :line2, :prefix: :addr_
attribute :city, :prefix: :addr_
attribute :state, :prefix: :addr_
attribute :zip_code, key: :addr_postal_code
```

###### Arguments

<table>
  <thead>
    <th>name</th>
    <th>type</th>
    <th>description</th>
    <th>required</th>
  </thead>
  <tbody>
    <tr>
      <td>name</td>
      <td>symbol</td>
      <td>The name of the key to be output in the final hash</td>
      <td>true</td>
    </tr>
    <tr>
      <td>options</td>
      <td>keyword arguments</td>
      <td>The options you want passed down the chain of intervals and to the context</td>
      <td>false</td>
    </tr>
    <tr>
      <td>block</td>
      <td>proc</td>
      <td></td>
      <td>false</td>
    </tr>
  </tbody>
</table>

If you are using a block or the `:with` argument it will be passed the input, the key, and any options for the deserializer.  The return of the block or method is what will be used as the value instead of looking up the key directly in the input.

example:

```ruby
attribute(:test) { |request, key, **options| request[:data][key] }
```

There are a few reserved keyword arguements that cause different functionlity/configuration for options:

* `key` the name of the key from the original input payload.  If not provided this defaults to the name of the attribute.
* `prefix` a prefix for the key you are looking for.  ex `attribute(:line1, prefix: :addr_)` will look for a key labeled `:addr_line1`
* `with` the method name you want to call to lookup/parse an attribute

##### attributes

The same as attribute except you can pass in multiple keys.


```ruby
attributes :first_name, :last_name
attributes :line1, :line2, :city, :state :prefix: :addr_
```

##### belongs_to

A standard belongs_to relationship.  Instead of grabbing a single key from the payload, expects to grab a hash.

```ruby
belongs_to :team
```

###### Arguments

<table>
  <thead>
    <th>name</th>
    <th>type</th>
    <th>description</th>
    <th>required</th>
  </thead>
  <tbody>
    <tr>
      <td>transform</td>
      <td>symbol</td>
      <td>The inflection you want called on the key value. ex: `underscore`, `camelcase`</td>
      <td>false</td>
    </tr>
    <tr>
      <td>block</td>
      <td>proc</td>
      <td>A custom proc passed the input request and the key the return value will be stored under.</td>
      <td>false</td>
    </tr>
  </tbody>
</table>

##### has_one

Just an alias for `#belongs_to`

##### has_many

A standard has_many relationship.  Instead of grabbing a single key from the payload, expects to grab an array.

```ruby
has_many :pets
```

###### Arguments

<table>
  <thead>
    <th>name</th>
    <th>type</th>
    <th>description</th>
    <th>required</th>
  </thead>
  <tbody>
    <tr>
      <td>transform</td>
      <td>symbol</td>
      <td>The inflection you want called on the key value. ex: `underscore`, `camelcase`</td>
      <td>false</td>
    </tr>
    <tr>
      <td>block</td>
      <td>proc</td>
      <td>A custom proc passed the input request and the key the return value will be stored under.</td>
      <td>false</td>
    </tr>
  </tbody>
</table>

### JSON Deserializer

##### Attrbute - Namespace

The JSON Deserializer has attribute namespacing that isn't available in JSONAPI due to its structured nature.  

- `namespace` an array of the nested keys needed to access a value

This works with both `attribute` and `attributes`.


```ruby
attribute :rank, namespace: [:military_information]
```

Which would pull a nested field like in the following example.

```json
{
  "name":"John",
  ...
  "military-info": {
    "branch":"Army",
    "rank":"Private First Class"
  }
  ...
}
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/limited-effort/snfoil-controller. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/limited-effort/snfoil-controller/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [Apache 2 License](https://opensource.org/licenses/Apache-2.0).

## Code of Conduct

Everyone interacting in the Snfoil::Controller project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/limited-effort/snfoil-controller/blob/main/CODE_OF_CONDUCT.md).
