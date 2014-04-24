require 'sprockets/lazy_proxy'
require 'sprockets/legacy_tilt_processor'
require 'sprockets/utils'

module Sprockets
  # `Engines` provides a global and `Environment` instance registry.
  #
  # An engine is a type of processor that is bound to a filename
  # extension. `application.js.coffee` indicates that the
  # `CoffeeScriptTemplate` engine will be ran on the file.
  #
  # Extensions can be stacked and will be evaulated from right to
  # left. `application.js.coffee.erb` will first run `ERBTemplate`
  # then `CoffeeScriptTemplate`.
  #
  # All `Engine`s must follow the `Template` interface. It is
  # recommended to subclass `Template`.
  #
  # Its recommended that you register engine changes on your local
  # `Environment` instance.
  #
  #     environment.register_engine '.foo', FooProcessor
  #
  # The global registry is exposed for plugins to register themselves.
  #
  #     Sprockets.register_engine '.sass', SassTemplate
  #
  module Engines
    # Returns a `Hash` of `Engine`s registered on the `Environment`.
    # If an `ext` argument is supplied, the `Engine` associated with
    # that extension will be returned.
    #
    #     environment.engines
    #     # => {".coffee" => CoffeeScriptTemplate, ".sass" => SassTemplate, ...}
    #
    #     environment.engines('.coffee')
    #     # => CoffeeScriptTemplate
    #
    def engines(ext = nil)
      if ext
        @engines[ext]
      else
        @engines.dup
      end
    end

    # Internal: Returns a `Hash` of engine extensions to mime types.
    #
    # # => { '.coffee' => 'application/javascript' }
    def engine_mime_types
      @engine_mime_types.dup
    end

    # Registers a new Engine `klass` for `ext`. If the `ext` already
    # has an engine registered, it will be overridden.
    #
    #     environment.register_engine '.coffee', CoffeeScriptTemplate
    #
    def register_engine(ext, klass, options = {})
      ext = Sprockets::Utils.normalize_extension(ext)

      from = registered_mime_types[ext]
      if from.nil?
        from = "sprockets/#{ext.sub(/^\./, '')}"
        register_mime_type(from, ext)
      end

      to = klass.respond_to?(:default_mime_type) && klass.default_mime_type ?
        klass.default_mime_type : "*/*"
      register_transformer(from, to, LegacyTiltProcessor.new(klass))
    end

    private
      # Internal: Returns implicit engine content type.
      #
      # `.coffee` files carry an implicit `application/javascript`
      # content type.
      def engine_content_type_for(extnames)
        extnames.each do |extname|
          if mime_type = @engine_mime_types[extname]
            return mime_type
          end
        end
        nil
      end

      def deep_copy_hash(hash)
        initial = Hash.new { |h, k| h[k] = [] }
        hash.each_with_object(initial) { |(k, a),h| h[k] = a.dup }
      end
  end
end
