# frozen_string_literal: true

# Copyright 2021 Matthew Howes

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'active_support/concern'
require_relative 'base'

module SnFoil
  module Deserializer
    # ActiveSupport::Concern for JSON deserializer functionality
    # Initialize class with json payload and call #parse to output normalized hash
    #
    # @author Matthew Howes
    #
    # @since 0.1.0
    module JSON
      extend ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength reason: These methods need to be in included to be overridable
        include SnFoil::Deserializer::Base

        def parse
          apply_transforms({}, data)
        end

        def to_hash
          parse
        end

        alias_method :to_hash, :parse
        alias_method :to_h, :parse

        protected

        def apply_transforms(output, input)
          (self.class.snfoil_attribute_transforms || {}).reduce(output) do |transformed_output, transform|
            transform_options = transform[1]
            next transformed_output if transform_options[:if] && !check_conditional(transform_options[:if], input)
            next transformed_output if transform_options[:unless] && check_conditional(transform_options[:unless], input)

            apply_transform(transformed_output, input, transform[0], **transform_options)
          end
        end

        def check_conditional(conditional, input)
          if conditional.is_a? Symbol
            send(conditional, input)
          else
            instance_exec(input, &conditional)
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
          return output if value.nil?

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

        def find_attribute(input, key, block: nil, with: nil, **options)
          return unless input

          if block
            instance_exec(input, key, **options, &block)
          elsif with
            send(with, input, key, **options)
          else
            find_by_key(input, key, **options)
          end
        end

        def find_by_key(input, key, **options)
          value_key = options.fetch(:key) { key }
          value_key = "#{options[:prefix]}#{key}".to_sym if options[:prefix]

          if options[:namespace]
            input.dig(*options[:namespace], value_key.to_sym)
          else
            input[value_key.to_sym]
          end
        end
      end
    end
  end
end
