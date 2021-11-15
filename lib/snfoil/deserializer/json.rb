# frozen_string_literal: true

require 'active_support/concern'
require_relative 'base'

module SnFoil
  module Deserializer
    module JSON
      extend ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength reason: These methods need to be in included to be overridable
        include SnFoil::Deserializer::Base

        def parse
          apply_transforms({}, data)
        end

        protected

        def apply_transforms(output, input)
          (self.class.snfoil_attribute_transforms || {}).reduce(output) do |transformed_output, transform|
            apply_transform(transformed_output, input, transform[0], **transform[1])
          end
        end

        def apply_transform(output, input, key, **options)
          case options[:transform_type]
          when :attribute
            parse_attribute_transform(output, input, key, **options)
          when :has_one
            parse_has_one_transform(output, input, key, **options)
          when :has_many
            parse_has_many_transform(output, input, key, **options)
          end
        end

        def parse_attribute_transform(output, input, key, **options)
          value = find_attribute(input, key, **options)
          return output unless value

          output.merge key => value
        end

        def parse_has_one_transform(output, input, key, deserializer:, **options)
          resource_data = find_attribute(input, key, **options)
          return output unless resource_data

          output[key] = deserializer.new(resource_data, **options).parse
          output
        end

        def parse_has_many_transform(output, input, key, deserializer:, **options)
          array_data = find_attribute(input, key, **options)
          return output unless array_data

          array_data = [array_data] if array_data.is_a? Hash
          output[key] = array_data.map { |r| deserializer.new(r, **options).parse }
          output
        end

        def find_attribute(input, key, **options)
          return unless input

          value_key = options.fetch(:key) { key }
          value_key = "#{options[:prefix]}#{key}".to_sym if options[:prefix]

          input[value_key.to_sym]
        end
      end
    end
  end
end
