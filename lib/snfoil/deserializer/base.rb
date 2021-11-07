# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/string/inflections'

module SnFoil
  module Deserializer
    module Base
      extend ActiveSupport::Concern

      class_methods do
        attr_reader :snfoil_attribute_fields, :snfoil_attribute_transforms,
                    :snfoil_key_transform

        def key_transform(transform)
          @snfoil_key_transform = transform
        end

        def attributes(*fields)
          @snfoil_attribute_fields ||= []
          @snfoil_attribute_fields |= fields
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

      attr_reader :object, :options

      def initialize(object, **options)
        @object = key_transform(object)
        @options = options
      end

      def attribute_fields
        self.class.snfoil_attribute_fields || []
      end

      def attribute_transforms
        self.class.snfoil_attribute_transforms || {}
      end

      def parse
        raise '#parse not implemented'
      end

      def to_hash
        parse
      end

      alias to_h to_hash

      private

      def key_transform(object)
        object = object.transform_keys do |key|
          process_key_transform(key)
        end

        object.transform_values do |value|
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
