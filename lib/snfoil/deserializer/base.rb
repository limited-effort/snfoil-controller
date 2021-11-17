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
require 'active_support/core_ext/string/inflections'

module SnFoil
  module Deserializer
    # ActiveSupport::Concern for base deserializer functionality
    # Add the following class methods:
    # * attribute
    # * attributes
    # * belongs_to
    # * has_many
    # * has_one
    # * key_transform
    #
    # @author Matthew Howes
    #
    # @since 0.1.0
    module Base
      extend ActiveSupport::Concern

      class_methods do
        attr_reader :snfoil_attribute_transforms,
                    :snfoil_key_transform

        def key_transform(transform = nil, &block)
          @snfoil_key_transform = transform || block
        end

        def attribute(key, **options, &block)
          (@snfoil_attribute_transforms ||= {})[key] = options.merge(transform_type: :attribute, block: block)
        end

        def attributes(*fields, **options, &block)
          fields.each { |field| attribute(field, **options, &block) }
        end

        def belongs_to(key, deserializer:, **options, &block)
          (@snfoil_attribute_transforms ||= {})[key] = options.merge(deserializer: deserializer, transform_type: :has_one, block: block)
        end
        alias_method :has_one, :belongs_to

        def has_many(key, deserializer:, **options, &block) # rubocop:disable Naming/PredicateName
          (@snfoil_attribute_transforms ||= {})[key] = options.merge(deserializer: deserializer, transform_type: :has_many, block: block)
        end

        def inherited(subclass)
          super

          instance_variables.grep(/@snfoil_.+/).each do |i|
            subclass.instance_variable_set(i, instance_variable_get(i).dup)
          end
        end
      end

      included do
        attr_reader :data, :config

        def initialize(input, **config)
          @data = normalize_keys(input)
          @config = config
        end

        def parse
          raise '#parse not implemented'
        end

        def to_hash
          parse
        end

        alias_method :to_hash, :parse
        alias_method :to_h, :parse
      end

      protected

      def normalize_keys(input)
        input = input.transform_keys do |key|
          apply_key_normalize(key)
        end

        input.transform_values do |value|
          check_deep_keys(value)
        end
      end

      def check_deep_keys(value)
        case value
        when Hash
          normalize_keys(value)
        when Array
          value.map { |v| check_deep_keys(v) }
        else
          value
        end
      end

      def apply_key_normalize(key)
        @snfoil_key_transform ||= self.class.snfoil_key_transform ||
                                  :underscore
        case @snfoil_key_transform
        when Symbol
          key.to_s.send(@snfoil_key_transform)
        when Proc
          @snfoil_key_transform.call(key.to_s)
        else
          key
        end.to_sym
      end
    end
  end
end
