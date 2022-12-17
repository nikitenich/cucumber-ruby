# frozen_string_literal: true

require 'pathname'
require 'cucumber/core/test/location'
require 'cucumber/core/test/around_hook'

module Cucumber
  # Hooks quack enough like `Cucumber::Core::Ast` source nodes that we can use them as
  # source for test steps
  module Hooks
    class << self
      def before_hook(id, location, name: nil, &block)
        build_hook_step(id, location, block, BeforeHook, Core::Test::UnskippableAction, name: name)
      end

      def after_hook(id, location, name: nil, &block)
        build_hook_step(id, location, block, AfterHook, Core::Test::UnskippableAction, name: name)
      end

      def after_step_hook(id, test_step, location, name: nil, &block)
        raise ArgumentError if test_step.hook?

        build_hook_step(id, location, block, AfterStepHook, Core::Test::Action, name: name)
      end

      def around_hook(&block)
        Core::Test::AroundHook.new(&block)
      end

      private

      def build_hook_step(id, location, block, hook_type, action_type, name: nil)
        action = action_type.new(location, &block)
        hook = hook_type.new(action.location, name: name)
        Core::Test::HookStep.new(id, hook.text, location, action)
      end
    end

    class AfterHook
      attr_reader :location, :name

      def initialize(location, name: nil)
        @location = location
        @name = name
      end

      def text
        "After hook#{name.nil? ? '' : ": #{name}"}"
      end

      def to_s
        "#{text} at #{location}"
      end

      def match_locations?(queried_locations)
        queried_locations.any? { |other_location| other_location.match?(location) }
      end

      def describe_to(visitor, *args)
        visitor.after_hook(self, *args)
      end
    end

    class BeforeHook
      attr_reader :location, :name

      def initialize(location, name: nil)
        @location = location
        @name = name
      end

      def text
        "Before hook#{name.nil? ? '' : ": #{name}"}"
      end

      def to_s
        "#{text} at #{location}"
      end

      def match_locations?(queried_locations)
        queried_locations.any? { |other_location| other_location.match?(location) }
      end

      def describe_to(visitor, *args)
        visitor.before_hook(self, *args)
      end
    end

    class AfterStepHook
      attr_reader :location, :name

      def initialize(location, name: nil)
        @location = location
        @name = name
      end

      def text
        "AfterStep hook#{name.nil? ? '' : ": #{name}"}"
      end

      def to_s
        "#{text} at #{location}"
      end

      def match_locations?(queried_locations)
        queried_locations.any? { |other_location| other_location.match?(location) }
      end

      def describe_to(visitor, *args)
        visitor.after_step_hook(self, *args)
      end
    end
  end
end
