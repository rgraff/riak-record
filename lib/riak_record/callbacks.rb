module RiakRecord
  module Callbacks

    CALLBACK_TRIGGERS = [
      :before_create, :after_create,
      :before_save, :after_save,
      :before_update, :after_update
    ]

    def call_callbacks!(trigger)
      callbacks = self.class._callbacks(trigger)
      callbacks.each do |callback|
        if callback.is_a? Symbol
          self.send(callback)
        elsif callback.is_a? Proc
          callback.call(self)
        elsif callback.is_a? String
          eval(callback)
        else
          callback.send(trigger, self)
        end
      end
    end

    CALLBACK_TRIGGERS.each do |trigger|
      define_method("#{trigger}!") do
        call_callbacks!(trigger)
      end
    end

    module ClassMethods
      def _callbacks(trigger)
        @_callbacks ||= {}
        @_callbacks[trigger] ||= []
      end

      CALLBACK_TRIGGERS.each do |trigger|

          ruby = <<-END_OF_RUBY

              def append_#{trigger}(*args)
                _callbacks(:#{trigger}).concat(args)
              end

              def #{trigger}(*args)
                append_#{trigger}(*args)
              end

              def prepend_#{trigger}(*args)
                _callbacks(:#{trigger}).unshift(*args)
              end

          END_OF_RUBY

          class_eval ruby
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
    end

  end
end
