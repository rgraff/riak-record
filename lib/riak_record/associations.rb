module RiakRecord
  module Associations

    def update_links
      link_definitions.each_pair do |tag, definition|
        tag = tag.to_s
        bucket_name = Object.const_get(definition[:class_name].to_s).bucket_name.to_s
        key = self.send(definition[:foreign_key].to_sym).first

        # remove links with tag name
        self.links.delete_if{|l| l.tag.to_s == tag }

        # add link if key is set
        self.links << Riak::Link.new(bucket_name.to_s, key.to_s, tag.to_s) unless key.nil?
      end
    end

    def link_definitions
      self.class.link_definitions
    end

    module ClassMethods
      def link_definitions
        @link_definitions ||= {}
      end

      def belongs_to_riak(association_name, options = {})
        class_name = options[:class_name] ||= association_name.to_s.split("_").collect(&:capitalize).join
        foreign_key = options[:foreign_key] || "#{association_name}_id"

        if options[:link]
          raise ArgumentError, "link option only available for instances of RiakRecord" unless self < RiakRecord::Base
          link_definitions[association_name.to_sym] = {:class_name => class_name, :foreign_key => foreign_key}
        end

        method_def = <<-END_OF_RUBY

        def #{association_name}
          @belongs_to_riak_#{association_name} = nil if @belongs_to_riak_#{association_name} && @belongs_to_riak_#{association_name}.id.to_s != Array(#{foreign_key}).first.to_s
          related_id = Array(#{foreign_key}).first
          @belongs_to_riak_#{association_name} ||= #{class_name}.find(related_id) if related_id
          @belongs_to_riak_#{association_name}
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
