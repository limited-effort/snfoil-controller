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
  context PeopleDeserializer

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/limited-effort/snfoil-controller. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/limited-effort/snfoil-controller/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [Apache 2 License](https://opensource.org/licenses/Apache-2.0).

## Code of Conduct

Everyone interacting in the Snfoil::Controller project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/limited-effort/snfoil-controller/blob/main/CODE_OF_CONDUCT.md).
