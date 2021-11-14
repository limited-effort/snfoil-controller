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
          (self.class.snfoil_attribute_transforms || {}).reduce({}) do |output, transform|
            apply_attribute_transform(output, transform[0], **transform[1])
          end
        end

        protected

        def find_attribute(data, key, **options)
          value_key = options.fetch(:key) { key }
          value_key = "#{options[:prefix]}#{key}".to_sym if options[:prefix]

          data[value_key.to_sym]
        end

        def apply_attribute_transform(attributes, key, **options)
          case options[:transform_type]
          when :attribute
            parse_attribute_transform(attributes, key, **options)
          when :has_one
            parse_has_one_relationship(attributes, key, **options)
          when :has_many
            parse_has_many_relationship(attributes, key, **options)
          end
        end

        def parse_attribute_transform(attributes, key, **options)
          value = find_attribute(input, key, **options)
          return attributes unless value

          attributes.merge key => value
        end

        def parse_has_one_relationship(attributes, key, deserializer:, **options)
          resource_data = find_attribute(input, key, **options)
          return attributes unless resource_data

          attributes[key] = deserializer.new(resource_data, **options).parse
          attributes
        end

        def parse_has_many_relationship(attributes, key, deserializer:, **options)
          array_data = find_attribute(input, key, **options)
          return attributes unless array_data

          array_data = [array_data] if array_data.is_a? Hash
          attributes[key] = array_data.map { |r| deserializer.new(r, **options).parse }
          attributes
        end
      end
    end
  end
end
