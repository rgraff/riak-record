module RiakRecord
  module Associations

    module ClassMethods
      def belongs_to_riak(association_name, options = {})
        class_name = options[:class_name] ||= association_name.to_s.split("_").collect(&:capitalize).join
        foreign_key = options[:foreign_key] || "#{association_name}_id"
        method_def = <<-END_OF_RUBY

        def #{association_name}
          @belongs_to_riak_#{association_name} = nil if @belongs_to_riak_#{association_name} && @belongs_to_riak_#{association_name}.id.to_s != Array(#{foreign_key}).first.to_s
          @belongs_to_riak_#{association_name} ||= #{class_name}.find(#{foreign_key})
        end

        def #{association_name}=(obj)
          raise ArgumentError, "not an instance of RiakRecord" unless obj.kind_of?(RiakRecord::Base)
          @belongs_to_riak_#{association_name} = obj
          self.#{foreign_key} = obj.id
        end

        END_OF_RUBY

        class_eval method_def
      end

      def has_many_riak(association_name, options = {})
        class_name = options[:class_name]
        foreign_key = options[:foreign_key]
        class_name && foreign_key or raise ArgumentError, "has_many_riak requires class_name and foreign_key options"

        method_def = <<-END_OF_RUBY

        def #{association_name}
          @has_many_riak_#{association_name} ||= #{class_name}.where(:#{foreign_key} => self.id.to_s)
        end

        END_OF_RUBY

        class_eval method_def
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
    end

  end
end
