# frozen_string_literal: true

require 'action_dispatch/http/mime_type'

module AbstractController
  module Collector
    def self.generate_method_for_mime(mime)
      sym = mime.is_a?(Symbol) ? mime : mime.to_sym
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{sym}(*args, &block)
          custom(Mime[:#{sym}], *args, &block)
        end
        ruby2_keywords(:#{sym})
      RUBY
    end

    Mime::SET.each do |mime|
      generate_method_for_mime(mime)
    end

    Mime::Type.register_callback do |mime|
      generate_method_for_mime(mime) unless instance_methods.include?(mime.to_sym)
    end

    private

    def method_missing(symbol, *args, &block)
      unless (mime_constant = Mime[symbol])
        raise NoMethodError, 'To respond to a custom format, register it as a MIME type first: ' \
          'https://guides.rubyonrails.org/action_controller_overview.html#restful-downloads. ' \
          'If you meant to respond to a variant like :tablet or :phone, not a custom format, ' \
          'be sure to nest your variant response within a format response: ' \
          'format.html { |html| html.tablet { ... } }'
      end

      if Mime::SET.include?(mime_constant)
        AbstractController::Collector.generate_method_for_mime(mime_constant)
        public_send(symbol, *args, &block)
      else
        super
      end
    end
    ruby2_keywords(:method_missing)
  end
end
