# frozen_string_literal: true

require 'abstract_controller/error'
require 'action_view'
require 'action_view/view_paths'
require 'set'

module AbstractController
  class DoubleRenderError < Error
    DEFAULT_MESSAGE = 'Render and/or redirect were called multiple times in this action. Please note that you may only call render OR redirect, and at most once per action. Also note that neither redirect nor render terminate execution of the action, so if you want to exit an action after redirecting, you need to do something like "redirect_to(...); return".'

    def initialize(message = nil)
      super(message || DEFAULT_MESSAGE)
    end
  end

  module Rendering
    extend ActiveSupport::Concern
    include ActionView::ViewPaths

    # Normalizes arguments and options, and then delegates to render_to_body and
    # sticks the result in <tt>self.response_body</tt>.
    #
    # Supported options depend on the underlying +render_to_body+ implementation.
    def render(*args, &block)
      options = _normalize_render(*args, &block)
      rendered_body = render_to_body(options)
      if options[:html]
        _set_html_content_type
      else
        _set_rendered_content_type rendered_format
      end
      _set_vary_header
      self.response_body = rendered_body
    end

    # Similar to #render, but only returns the rendered template as a string,
    # instead of setting +self.response_body+.
    #
    # If a component extends the semantics of +response_body+ (as ActionController
    # extends it to be anything that responds to the method each), this method
    # needs to be overridden in order to still return a string.
    def render_to_string(*args, &block)
      options = _normalize_render(*args, &block)
      render_to_body(options)
    end

    # Performs the actual template rendering.
    def render_to_body(options = {}); end

    # Returns +Content-Type+ of rendered content.
    def rendered_format
      Mime[:text]
    end

    DEFAULT_PROTECTED_INSTANCE_VARIABLES = %i[@_action_name @_response_body @_formats @_prefixes].freeze

    # This method should return a hash with assigns.
    # You can overwrite this configuration per controller.
    def view_assigns
      variables = instance_variables - _protected_ivars

      variables.each_with_object({}) do |name, hash|
        hash[name.slice(1, name.length)] = instance_variable_get(name)
      end
    end

    private

    # Normalize args by converting <tt>render "foo"</tt> to
    # <tt>render action: "foo"</tt> and <tt>render "foo/bar"</tt> to
    # <tt>render file: "foo/bar"</tt>.
    # :doc:
    def _normalize_args(action = nil, options = {})
      if action.respond_to?(:permitted?)
        raise ArgumentError, 'render parameters are not permitted' unless action.permitted?

        action



      elsif action.is_a?(Hash)
        action
      else
        options
      end
    end

    # Normalize options.
    # :doc:
    def _normalize_options(options)
      options
    end

    # Process extra options.
    # :doc:
    def _process_options(options)
      options
    end

    # Process the rendered format.
    def _process_format(format) # :nodoc:
    end

    def _process_variant(options); end

    def _set_html_content_type # :nodoc:
    end

    def _set_vary_header # :nodoc:
    end

    def _set_rendered_content_type(format) # :nodoc:
    end

    # Normalize args and options.
    def _normalize_render(*args, &block) # :nodoc:
      options = _normalize_args(*args, &block)
      _process_variant(options)
      _normalize_options(options)
      options
    end

    def _protected_ivars
      DEFAULT_PROTECTED_INSTANCE_VARIABLES
    end
  end
end
