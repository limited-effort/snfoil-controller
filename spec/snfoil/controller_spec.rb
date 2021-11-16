# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe SnFoil::Controller do
  subject(:including_class) { Class.new ControllerSpecClass }

  let(:canary) { Canary.new }

  describe '#self.context' do
    let(:context) { double }

    before { including_class.context(context) }

    it 'sets snfoil_context' do
      expect(including_class.snfoil_context).to eq context
    end
  end

  describe '#self.serializer' do
    let(:serializer) { double }

    before { including_class.serializer(serializer) }

    it 'sets snfoil_serializer' do
      expect(including_class.snfoil_serializer).to eq serializer
    end

    context 'when called with a block' do
      let(:serializer_block) { proc {} }

      it 'sets snfoil_serializer' do
        including_class.serializer(serializer, &serializer_block)
        expect(including_class.snfoil_serializer_block).to eq serializer_block
      end
    end
  end

  describe '#self.deserializer' do
    let(:deserializer) { double }

    it 'sets snfoil_deserializer' do
      including_class.deserializer(deserializer)
      expect(including_class.snfoil_deserializer).to eq deserializer
    end

    context 'when called with a block' do
      let(:deserializer_block) { proc {} }

      it 'sets snfoil_deserializer' do
        including_class.deserializer(deserializer, &deserializer_block)
        expect(including_class.snfoil_deserializer_block).to eq deserializer_block
      end
    end
  end

  describe '#self.endpoint' do
    it 'creates setup_#{name} hooks' do # rubocop:disable Lint/InterpolationCheck
      including_class.endpoint(:demo, with: :render_demo)
      expect(including_class.respond_to?(:setup_demo)).to be true
    end

    it 'creates process_#{name} hooks' do # rubocop:disable Lint/InterpolationCheck
      including_class.endpoint(:demo, with: :render_demo)
      expect(including_class.respond_to?(:process_demo)).to be true
    end

    it 'defines an instance method' do
      including_class.endpoint(:demo, with: :render_demo)
      expect(including_class.new.respond_to?(:demo)).to be true
    end

    context 'when called with a method' do
      it 'calls the method on the instance call' do
        including_class.endpoint(:demo, with: :render_demo)
        including_class.define_method(:render_demo) { |**options| options[:canary].sing('Method Call') }
        including_class.new.demo(canary: canary)

        expect(canary.sung?('Method Call')).to be true
      end
    end

    context 'when called with a block' do
      it 'calls the block on the instance call' do
        including_class.endpoint(:demo) { |**options| options[:canary].sing('Block Call') }
        including_class.new.demo(canary: canary)

        expect(canary.sung?('Block Call')).to be true
      end
    end

    describe '#entity' do
      context 'when current_entity is defined' do
        before { including_class.define_method(:current_entity) { 'entity' } }

        it 'uses it' do
          expect(including_class.new.entity).to eq 'entity'
        end
      end

      context 'when current_user is defined' do
        before { including_class.define_method(:current_user) { 'user' } }

        it 'uses it' do
          expect(including_class.new.entity).to eq 'user'
        end
      end
    end

    describe '#serialize' do
      let(:object) { double }
      let(:serializer) { double }
      let(:serializer_instance) { double }

      before do
        allow(serializer).to receive(:new).and_return(serializer_instance)
        allow(serializer_instance).to receive(:to_hash).and_return({})
      end

      context 'when a serializer is configured' do
        it 'calls the serializer and uses the default call' do
          including_class.serializer serializer
          including_class.new.serialize(object)
          expect(serializer).to have_received(:new).with(object, anything)
          expect(serializer_instance).to have_received :to_hash
        end

        context 'when a block is configured' do
          before do
            including_class.serializer(serializer) do |_o, _s, **options|
              options[:canary].sing('class block')
            end
          end

          it 'uses the block to process the call' do
            including_class.new.serialize(object, canary: canary)
            expect(serializer).not_to have_received(:new)
            expect(canary.sung?('class block')).to be true
          end
        end

        context 'when a block is passed in the options' do
          before do
            including_class.serializer(serializer)
          end

          it 'uses the block to process the call' do
            block = proc { |_o, _s, **options| options[:canary].sing('options block') }
            including_class.new.serialize(object, canary: canary, serialize: block)

            expect(serializer).not_to have_received(:new)
            expect(canary.sung?('options block')).to be true
          end
        end

        context 'when a method is passed in the options' do
          before do
            including_class.define_method(:method_serialize) do |_o, _s, **options|
              options[:canary].sing('options method')
            end
            including_class.serializer(serializer)
          end

          it 'uses the method to process the call' do
            including_class.new.serialize(object, canary: canary, serialize_with: :method_serialize)

            expect(serializer).not_to have_received(:new)
            expect(canary.sung?('options method')).to be true
          end
        end
      end

      context 'when a serializer is in the options' do
        it 'uses the serializers passed in' do
          including_class.new.serialize(object, serializer: serializer)
          expect(serializer).to have_received(:new).with(object, anything)
          expect(serializer_instance).to have_received :to_hash
        end
      end

      context 'when a serializer is not configured' do
        it 'returns the object without alteration' do
          expect(including_class.new.serialize(object)).to eq object
        end
      end
    end

    describe '#deserialize' do
      let(:params) { {} }
      let(:deserializer) { double }
      let(:deserializer_instance) { double }

      before do
        allow(deserializer).to receive(:new).and_return(deserializer_instance)
        allow(deserializer_instance).to receive(:to_hash).and_return({})
      end

      context 'when a deserializer is configured' do
        it 'calls the deserializer and uses the default call' do
          including_class.deserializer deserializer
          including_class.new.deserialize(params)
          expect(deserializer).to have_received(:new).with(params, anything)
          expect(deserializer_instance).to have_received :to_hash
        end

        context 'when a block is configured' do
          before do
            including_class.deserializer(deserializer) do |_o, _s, **options|
              options[:canary].sing('class block')
            end
          end

          it 'uses the block to process the call' do
            including_class.new.deserialize(params, canary: canary)
            expect(deserializer).not_to have_received(:new)
            expect(canary.sung?('class block')).to be true
          end
        end

        context 'when a block is passed in the options' do
          before do
            including_class.deserializer(deserializer)
          end

          it 'uses the block to process the call' do
            block = proc { |_o, _s, **options| options[:canary].sing('options block') }
            including_class.new.deserialize(params, canary: canary, deserialize: block)

            expect(deserializer).not_to have_received(:new)
            expect(canary.sung?('options block')).to be true
          end
        end

        context 'when a method is passed in the options' do
          before do
            including_class.define_method(:method_deserialize) do |_o, _s, **options|
              options[:canary].sing('options method')
            end
            including_class.deserializer(deserializer)
          end

          it 'uses the method to process the call' do
            including_class.new.deserialize(params, canary: canary, deserialize_with: :method_deserialize)

            expect(deserializer).not_to have_received(:new)
            expect(canary.sung?('options method')).to be true
          end
        end
      end

      context 'when a deserializer is in the options' do
        it 'uses the deserializers passed in' do
          including_class.new.deserialize(params, deserializer: deserializer)
          expect(deserializer).to have_received(:new).with(params, anything)
          expect(deserializer_instance).to have_received :to_hash
        end
      end

      context 'when a deserializer is not configured' do
        it 'returns the params without alteration' do
          expect(including_class.new.deserialize(params)).to eq params
        end
      end
    end
  end

  describe '#serialize' do
    let(:serializer) { double }
    let(:serializer_instance) { double }

    before do
      including_class.serializer(serializer)
      allow(serializer).to receive(:new).and_return(serializer_instance)
      allow(serializer_instance).to receive(:to_hash)
    end

    it 'uses the base serializer' do
      including_class.new.serialize({})

      expect(serializer).to have_received(:new).once
      expect(serializer_instance).to have_received(:to_hash).once
    end

    context 'when options[:serializer] => value' do
      let(:other_serializer) { double }
      let(:other_serializer_instance) { double }

      before do
        allow(other_serializer).to receive(:new).and_return(other_serializer_instance)
        allow(other_serializer_instance).to receive(:to_hash)
      end

      it 'uses the serializer in the options' do
        including_class.new.serialize({}, serializer: other_serializer)

        expect(serializer_instance).not_to have_received(:to_hash)
        expect(other_serializer_instance).to have_received(:to_hash).once
      end
    end

    context 'when options[:serialize] => value' do
      let(:serialize_block) do
        proc do |_object, serializer, **options|
          options[:canary].sing(serializer)
          'options block'
        end
      end

      it 'uses the block provided' do
        including_class.new.serialize({}, serialize: serialize_block, canary: canary)

        expect(canary.song.first[:data]).to eq serializer
      end

      it 'returns the block return' do
        ret = including_class.new.serialize({}, serialize: serialize_block, canary: canary)

        expect(ret).to eq 'options block'
      end
    end

    context 'when options[:serialize_with] => value' do
      before do
        including_class.define_method(:serialize_method) do |_object, serializer, **options|
          options[:canary].sing(serializer)
          'options method'
        end
      end

      it 'uses the block provided' do
        including_class.new.serialize({}, serialize_with: :serialize_method, canary: canary)

        expect(canary.song.first[:data]).to eq serializer
      end

      it 'returns the block return' do
        ret = including_class.new.serialize({}, serialize_with: :serialize_method, canary: canary)

        expect(ret).to eq 'options method'
      end
    end

    context 'when self.snfoil_serializer_block is defined' do
      let(:serializer_block) do
        proc do |_object, serializer, **options|
          options[:canary].sing(serializer)
          'class block'
        end
      end

      before do
        including_class.serializer(serializer, &serializer_block)
      end

      it 'uses the block provided' do
        including_class.new.serialize({}, canary: canary)

        expect(canary.song.first[:data]).to eq serializer
      end

      it 'returns the block return' do
        ret = including_class.new.serialize({}, canary: canary)

        expect(ret).to eq 'class block'
      end
    end
  end

  describe '#deserialize' do
    let(:deserializer) { double }
    let(:deserializer_instance) { double }

    before do
      including_class.deserializer(deserializer)
      allow(deserializer).to receive(:new).and_return(deserializer_instance)
      allow(deserializer_instance).to receive(:to_hash)
    end

    it 'uses the base deserializer' do
      including_class.new.deserialize({})

      expect(deserializer).to have_received(:new).once
      expect(deserializer_instance).to have_received(:to_hash).once
    end

    context 'when options[:deserializer] => value' do
      let(:other_deserializer) { double }
      let(:other_deserializer_instance) { double }

      before do
        allow(other_deserializer).to receive(:new).and_return(other_deserializer_instance)
        allow(other_deserializer_instance).to receive(:to_hash)
      end

      it 'uses the deserializer in the options' do
        including_class.new.deserialize({}, deserializer: other_deserializer)

        expect(deserializer_instance).not_to have_received(:to_hash)
        expect(other_deserializer_instance).to have_received(:to_hash).once
      end
    end

    context 'when options[:deserialize] => value' do
      let(:deserialize_block) do
        proc do |_object, deserializer, **options|
          options[:canary].sing(deserializer)
          'options block'
        end
      end

      it 'uses the block provided' do
        including_class.new.deserialize({}, deserialize: deserialize_block, canary: canary)

        expect(canary.song.first[:data]).to eq deserializer
      end

      it 'returns the block return' do
        ret = including_class.new.deserialize({}, deserialize: deserialize_block, canary: canary)

        expect(ret).to eq 'options block'
      end
    end

    context 'when options[:deserialize_with] => value' do
      before do
        including_class.define_method(:deserialize_method) do |_object, deserializer, **options|
          options[:canary].sing(deserializer)
          'options method'
        end
      end

      it 'uses the block provided' do
        including_class.new.deserialize({}, deserialize_with: :deserialize_method, canary: canary)

        expect(canary.song.first[:data]).to eq deserializer
      end

      it 'returns the block return' do
        ret = including_class.new.deserialize({}, deserialize_with: :deserialize_method, canary: canary)

        expect(ret).to eq 'options method'
      end
    end

    context 'when self.snfoil_deserializer_block is defined' do
      let(:deserializer_block) do
        proc do |_object, deserializer, **options|
          options[:canary].sing(deserializer)
          'class block'
        end
      end

      before do
        including_class.deserializer(deserializer, &deserializer_block)
      end

      it 'uses the block provided' do
        including_class.new.deserialize({}, canary: canary)

        expect(canary.song.first[:data]).to eq deserializer
      end

      it 'returns the block return' do
        ret = including_class.new.deserialize({}, canary: canary)

        expect(ret).to eq 'class block'
      end
    end
  end

  describe '#run_context' do
    let(:context) { double }
    let(:context_instance) { double }

    before do
      including_class.context(context)
      allow(context).to receive(:new).and_return(context_instance)
      allow(context_instance).to receive(:controller_action)
    end

    it 'calls the context using the controller action' do
      including_class.new.run_context(controller_action: :controller_action)

      expect(context).to have_received(:new).once
      expect(context_instance).to have_received(:controller_action).once
    end

    context 'with options[:context] => value' do
      let(:other_context) { double }
      let(:other_context_instance) { double }

      before do
        allow(other_context).to receive(:new).and_return(other_context_instance)
        allow(other_context_instance).to receive(:controller_action)
      end

      it 'calls that options context' do
        including_class.new.run_context(context: other_context, controller_action: :controller_action)

        expect(context_instance).not_to have_received(:controller_action)
        expect(other_context_instance).to have_received(:controller_action).once
      end
    end

    context 'with options[:context_action] => value' do
      before do
        allow(context_instance).to receive(:context_action)
      end

      it 'sends the options context_action' do
        including_class.new.run_context(context_action: :context_action, controller_action: :controller_action)

        expect(context_instance).not_to have_received(:controller_action)
        expect(context_instance).to have_received(:context_action).once
      end
    end
  end
end

class ControllerSpecClass
  include SnFoil::Controller
end
