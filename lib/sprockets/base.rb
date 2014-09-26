require 'sprockets/asset'
require 'sprockets/bower'
require 'sprockets/errors'
require 'sprockets/resolve'
require 'sprockets/server'

module Sprockets
  # `Base` class for `Environment` and `Cached`.
  class Base
    include PathUtils, HTTPUtils
    include Configuration
    include Server
    include Resolve
    include Bower

    # Get persistent cache store
    attr_reader :cache

    # Set persistent cache store
    #
    # The cache store must implement a pair of getters and
    # setters. Either `get(key)`/`set(key, value)`,
    # `[key]`/`[key]=value`, `read(key)`/`write(key, value)`.
    def cache=(cache)
      @cache = Cache.new(cache, logger)
    end

    # Return an `Cached`. Must be implemented by the subclass.
    def cached
      raise NotImplementedError
    end
    alias_method :index, :cached

    # Internal: Compute hexdigest for path.
    #
    # path - String filename or directory path.
    #
    # Returns a String SHA1 hexdigest or nil.
    def file_hexdigest(path)
      if stat = self.stat(path)
        # Caveat: Digests are cached by the path's current mtime. Its possible
        # for a files contents to have changed and its mtime to have been
        # negligently reset thus appearing as if the file hasn't changed on
        # disk. Also, the mtime is only read to the nearest second. Its
        # also possible the file was updated more than once in a given second.
        cache.fetch(['file_hexdigest', path, stat.mtime.to_i]) do
          if stat.directory?
            # If its a directive, digest the list of filenames
            Digest::SHA1.hexdigest(self.entries(path).join(','))
          elsif stat.file?
            # If its a file, digest the contents
            Digest::SHA1.file(path.to_s).hexdigest
          end
        end
      end
    end

    # Internal: Compute hexdigest for a set of paths.
    #
    # paths - Array of filename or directory paths.
    #
    # Returns a String SHA1 hexdigest.
    def dependencies_hexdigest(paths)
      digest = Digest::SHA1.new
      paths.each { |path| digest.update(file_hexdigest(path).to_s) }
      digest.hexdigest
    end

    # Find asset by logical path or expanded path.
    def find_asset(path, options = {})
      if uri = resolve_asset_uri(path, options)
        Asset.new(build_asset_by_uri(uri))
      end
    end

    def find_asset_by_uri(uri)
      _, params = AssetURI.parse(uri)
      asset = params.key?(:id) ?
        build_asset_by_id_uri(uri) :
        build_asset_by_uri(uri)
      Asset.new(asset)
    end

    def find_all_linked_assets(path, options = {})
      return to_enum(__method__, path, options) unless block_given?

      asset = find_asset(path, options)
      return unless asset

      yield asset
      stack = asset.links.to_a

      while uri = stack.shift
        yield asset = find_asset_by_uri(uri)
        stack = asset.links.to_a + stack
      end

      nil
    end

    # Preferred `find_asset` shorthand.
    #
    #     environment['application.js']
    #
    def [](*args)
      find_asset(*args)
    end

    # Pretty inspect
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} " +
        "root=#{root.to_s.inspect}, " +
        "paths=#{paths.inspect}>"
    end

    protected
      def build_asset_by_id_uri(uri)
        path, params = AssetURI.parse(uri)

        # Internal assertion, should be routed through build_asset_by_uri
        unless id = params.delete(:id)
          raise ArgumentError, "expected uri to have an id: #{uri}"
        end

        asset = build_asset_by_uri(AssetURI.build(path, params))

        if id && asset[:id] != id
          raise VersionNotFound, "could not find specified id: #{id}"
        end

        asset
      end

      def build_asset_by_uri(uri)
        filename, params = AssetURI.parse(uri)

        # Internal assertion, should be routed through build_asset_by_id_uri
        if params.key?(:id)
          raise ArgumentError, "expected uri to have no id: #{uri}"
        end

        type = params[:type]
        load_path, logical_path = paths_split(self.paths, filename)

        if !file?(filename)
          raise FileNotFound, "could not find file: #{filename}"
        elsif type && !resolve_path_transform_type(filename, type)
          raise ConversionError, "could not convert to type: #{type}"
        elsif !load_path
          raise FileOutsidePaths, "#{filename} is no longer under a load path: #{self.paths.join(', ')}"
        end

        logical_path, file_type, engine_extnames = parse_path_extnames(logical_path)
        logical_path = normalize_logical_path(logical_path)

        asset = {
          uri: uri,
          load_path: load_path,
          filename: filename,
          name: logical_path,
          logical_path: logical_path
        }

        if type
          asset[:content_type] = type
          asset[:logical_path] += mime_types[type][:extensions].first
        end

        processed_processors = unwrap_preprocessors(file_type) +
          unwrap_engines(engine_extnames).reverse +
          unwrap_transformer(file_type, type) +
          unwrap_postprocessors(type)

        bundled_processors = params[:skip_bundle] ? [] : unwrap_bundle_processors(type)

        processors = bundled_processors.any? ? bundled_processors : processed_processors
        processors += unwrap_encoding_processors(params[:encoding])

        if processors.any?
          asset.merge!(process(
            [method(:read_input)] + processors,
            asset[:uri],
            asset[:filename],
            asset[:load_path],
            asset[:name],
            asset[:content_type]
          ))
        else
          asset.merge!({
            encoding: Encoding::BINARY,
            length: self.stat(asset[:filename]).size,
            digest: digest_class.file(asset[:filename]).hexdigest,
            metadata: {}
          })
        end

        metadata = asset[:metadata]
        metadata[:dependency_paths] = Set.new(metadata[:dependency_paths]).merge([asset[:filename]])
        metadata[:dependency_digest] = dependencies_hexdigest(metadata[:dependency_paths])

        asset[:id]  = Utils.hexdigest(asset)
        asset[:uri] = AssetURI.build(filename, params.merge(id: asset[:id]))

        asset
      end
  end
end
