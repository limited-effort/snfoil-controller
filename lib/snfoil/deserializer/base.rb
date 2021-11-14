# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/string/inflections'

module SnFoil
  module Deserializer
    module Base
      extend ActiveSupport::Concern

      class_methods do
        attr_reader :snfoil_attribute_transforms,
                    :snfoil_key_transform

        def key_transform(transform = nil, &block)
          @snfoil_key_transform = transform || block
        end

        def attributes(*fields, **options)
          fields.each { |field| attribute(field, **options) }
        end

        def attribute(key, **options)
          (@snfoil_attribute_transforms ||= {})[key] = options.merge(transform_type: :attribute)
        end

        def belongs_to(key, deserializer:, **options)
          (@snfoil_attribute_transforms ||= {})[key] = options.merge(deserializer: deserializer, transform_type: :has_one)
        end
        alias_method :has_one, :belongs_to

        def has_many(key, deserializer:, **options) # rubocop:disable Naming/PredicateName
          (@snfoil_attribute_transforms ||= {})[key] = options.merge(deserializer: deserializer, transform_type: :has_many)
        end

        def inherited(subclass)
          super

          instance_variables.grep(/@snfoil_.+/).each do |i|
            subclass.instance_variable_set(i, instance_variable_get(i).dup)
          end
        end
      end

      included do
        attr_reader :input, :options

        def initialize(input, **options)
          @input = key_transform(input)
          @options = options
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

      private

      def key_transform(hash)
        hash = hash.transform_keys do |key|
          process_key_transform(key)
        end

        hash.transform_values do |value|
          value_transform(value)
        end
      end

      def value_transform(value)
        case value
        when Hash
          key_transform(value)
        when Array
          value.map { |v| value_transform(v) }
        else
          value
        end
      end

      def process_key_transform(key)
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
