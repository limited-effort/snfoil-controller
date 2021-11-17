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

module SnFoil
  # ActiveSupport::Concern for Controller functionality
  # A SnFoil::Controller is essentially a context but instead of using #action uses a more simplified workflow
  # called #endpoint.  The method or block passed to endpoint is ultimately what renders.
  # #endpoint creates the following intervals:
  # * setup_*
  # * process_*
  #
  # This concern also adds the following class methods
  # * context - The context associated with the controller to process the business logic
  # * deserializer - the deserializer associated with the controller to allow list incoming params
  # * endpoint - helper function to build endpoint methods
  # * serializer - The serializer associated to render the context's output
  #
  # @author Matthew Howes
  #
  # @since 0.1.0
  module Controller
    extend ActiveSupport::Concern

    class Error < RuntimeError; end

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
        raise SnFoil::Controller::Error, "context already defined for #{self}" if @snfoil_context

        @snfoil_context = klass
      end

      def serializer(klass = nil, &block)
        raise SnFoil::Controller::Error, "serializer already defined for #{self}" if @snfoil_serializer || @snfoil_serializer_block

        @snfoil_serializer = klass
        @snfoil_serializer_block = block
      end

      def deserializer(klass = nil, &block)
        raise SnFoil::Controller::Error, "deserializer already defined for #{self}" if @snfoil_deserializer || @snfoil_deserializer_block

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

    def run_context(context: nil, context_action: nil, controller_action: nil, **_options)
      (context || self.class.snfoil_context).new(entity).send(context_action || controller_action)
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
