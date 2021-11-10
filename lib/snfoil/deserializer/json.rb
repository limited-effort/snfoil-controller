# frozen_string_literal: true

require 'active_support/concern'

module SnFoil
  module Deserializer
    module JSON
      extend ActiveSupport::Concern

      included do
        include SnFoil::Deserializer::Base
        
        def parse
          attribute_transforms.reduce(attributes) do |output, transform|
            apply_attribute_transform(output, transform[0], **transform[1])
          end
        end  
      end

      protected

      def find_attribute(data, key, **options)
        value_key = options.fetch(:key) { key }
        value_key = "#{options[:prefix]}#{key}".to_sym if options[:prefix] 

        data[value_key]
      end

      private

      included do
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
          value_key = options.fetch(:key) { key }
          return attributes unless input[value_key]
  
          attributes.merge key => input[value_key]
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
