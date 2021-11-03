# frozen_string_literal: true

# Copyright 2021 Matthew Howes, Cliff Campbell

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
require 'snfoil/context'

require_relative 'deserializer/jsonapi'

module SnFoil
  module Controller
    extend ActiveSupport::Concern

    included do
      include SnFoil::Context

      module_eval do
        def entity
          @entity ||= if defined? current_entity
                        current_entity
                      elsif defined? current_user
                        current_user
                      end
        end
      end
    end

    class_methods do
      attr_reader :snfoil_endpoints, :snfoil_context,
                  :snfoil_serializer, :snfoil_serializer_block,
                  :snfoil_deserializer, :snfoil_deserializer_block

      def context(klass = nil)
        @snfoil_context = klass
      end

      def serializer(klass = nil, &block)
        @snfoil_serializer = klass
        @snfoil_serializer_block = block
      end

      def deserializer(klass = nil, &block)
        @snfoil_deserializer = klass
        @snfoil_deserializer_block = block
      end

      def endpoint(name, **options, &block)
        (@snfoil_endpoints ||= {})[name] =
          options.merge(controller_action: name, method: options[:with], block: block)

        interval "setup_#{name}"
        interval "process_#{name}"

        define_endpoint_method(name)
      end
    end

    def serialize(object, **options)
      serializer = options.fetch(:serializer) { self.class.snfoil_serializer }
      return object unless serializer

      exec_serialize(serializer, object, **options)
    end

    def deserialize(params, **options)
      deserializer = options.fetch(:deserializer) { self.class.snfoil_deserializer }
      return params unless deserializer

      exec_deserialize(deserializer, params, **options)
    end

    protected

    class_methods do
      def define_endpoint_method(name)
        define_method(name) do |**options|
          options = options.merge self.class.snfoil_endpoints[name]
          options = run_interval("setup_#{name}", **options)
          options = run_interval("process_#{name}", **options)
          exec_render(**options)
        end
      end
    end

    private

    def exec_render(method: nil, block: nil, **options)
      return send(method, **options) if method

      instance_exec(**options, &block)
    end

    def exec_serialize(serializer, object, **options)
      serializer_block = options.fetch(:serialize) { self.class.snfoil_serializer_block }
      if options[:serialize_with]
        send(options[:serialize_with], object, serializer, **options, current_entity: entity)
      elsif serializer_block
        instance_exec(object, serializer, **options, current_entity: entity, &serializer_block)
      else
        serializer.new(object, **options, current_entity: entity).to_hash
      end
    end

    def exec_deserialize(deserializer, params, **options)
      deserializer_block = options.fetch(:deserialize) { self.class.snfoil_deserializer_block }
      if options[:deserialize_with]
        send(options[:deserialize_with], params, deserializer, **options, current_entity: entity)
      elsif deserializer_block
        instance_exec(params, deserializer, **options, current_entity: entity, &deserializer_block)
      else
        deserializer.new(params, **options, current_entity: entity).to_hash
      end
    end
  end
end
