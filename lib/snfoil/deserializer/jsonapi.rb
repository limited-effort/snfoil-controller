# frozen_string_literal: true

require 'active_support/concern'
require_relative 'json'

module SnFoil
  module Deserializer
    module JSONAPI
      extend ActiveSupport::Concern

      included do
        include SnFoil::Deserializer::JSON

        module_eval do
          def parse
            input = data[:data] || data
            return apply_transforms(data_id({}, input), input) unless input.is_a? Array

            input.map { |d| apply_transforms(data_id({}, d), d) }
          end
        end

        def included
          @included ||= config[:included] || data[:included]
        end

        private

        def data_id(output, data)
          if data[:id]
            output[:id] = data[:id]
          elsif data[:'local:id']
            output[:'local:id'] = data[:'local:id']
          end

          output
        end

        def parse_attribute_transform(output, input, key, **options)
          value = find_attribute(input[:attributes], key, **options)
          return output unless value

          output.merge key => value
        end

        def parse_has_one_transform(output, input, key, deserializer:, **options)
          resource_data = find_relationship(input, key, **options)
          return output unless resource_data

          output[key] = deserializer.new(resource_data, **options, included: included).parse
          output
        end

        def parse_has_many_transform(output, input, key, deserializer:, **options)
          resource_data = find_relationships(input, key, **options)
          return output unless resource_data

          output[key] = resource_data.map { |r| deserializer.new(r, **options, included: included).parse }
          output
        end

        def find_relationships(input, key, **options)
          array_data = find_attribute(input[:relationships], key, **options)
          return unless array_data

          array_data = array_data[:data]
          array_data = [array_data] unless array_data.is_a? Array
          array_data.map do |resource_data|
            lookup_relationship(**resource_data) || resource_data
          end
        end

        def find_relationship(input, key, **options)
          resource_data = find_attribute(input[:relationships], key, **options)
          return unless resource_data

          lookup_relationship(**resource_data[:data]) || resource_data
        end

        def lookup_relationship(type:, **options)
          id = options[:id]
          lid = options[:'local:id']

          included&.find do |x|
            x[:type].eql?(type) &&
              if id
                x[:id].eql?(id)
              elsif lid
                x[:'local:id'].eql?(lid)
              end
          end
        end
      end
    end
  end
end
