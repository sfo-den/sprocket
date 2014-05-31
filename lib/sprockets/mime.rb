module Sprockets
  module Mime
    # Returns a `Hash` of mime types registered on the environment and those
    # part of `Rack::Mime`.
    attr_reader :mime_types

    attr_reader :mime_type_decoders

    # Register a new mime type.
    def register_mime_type(mime_type, options = {})
      # Legacy extension argument, will be removed from 4.x
      if options.is_a?(String)
        options = { extensions: [options] }
      end

      extnames = Array(options[:extensions]).map { |extname|
        Sprockets::Utils.normalize_extension(extname)
      }

      type = options[:type] || :binary
      unless type == :binary || type == :text
        raise ArgumentError, "type must be :binary or :text"
      end

      decoder = options[:decoder]
      decoder ||= Encoding.method(:decode) if type == :text

      extnames.each do |extname|
        @mime_types[extname] = mime_type
        @mime_type_decoders[mime_type] = decoder
      end
    end

    def mime_type_for_extname(extname)
      @mime_types[extname] # || 'application/octet-stream'
    end

    def matches_content_type?(mime_type, path)
      # TODO: Disallow nil mime type
      mime_type.nil? ||
        mime_type == "*/*" ||
        # TODO: Review performance
        mime_type == mime_type_for_extname(parse_path_extnames(path)[1])
    end
  end
end
