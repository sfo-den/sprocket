require 'digest/sha1'

module Sprockets
  # `Utils`, we didn't know where else to put it!
  module Utils
    extend self

    # Prepends a leading "." to an extension if its missing.
    #
    #     normalize_extension("js")
    #     # => ".js"
    #
    #     normalize_extension(".css")
    #     # => ".css"
    #
    def normalize_extension(extension)
      extension = extension.to_s
      if extension[/^\./]
        extension
      else
        ".#{extension}"
      end
    end

    # Internal: Inject into target module for the duration of the block.
    #
    # mod - Module
    #
    # Returns result of block.
    def module_include(base, mod)
      old_methods = {}

      mod.instance_methods.each do |sym|
        method = mod.instance_method(sym)
        if base.method_defined?(sym)
          old_methods[sym] = base.instance_method(sym)
        end
        base.send(:define_method, sym, method)
      end

      yield
    ensure
      mod.instance_methods.each do |sym|
        base.send(:undef_method, sym)
      end
      old_methods.each do |sym, method|
        base.send(:define_method, sym, method)
      end
    end

    # Internal: Generate a hexdigest for a nested JSON serializable object.
    #
    # obj - A JSON serializable object.
    #
    # Returns a String SHA1 digest of the object.
    def hexdigest(obj)
      digest = Digest::SHA1.new
      queue  = [obj]

      while queue.length > 0
        obj = queue.shift
        klass = obj.class

        if klass == String
          digest << 'String'
          digest << obj
        elsif klass == Symbol
          digest << 'Symbol'
          digest << obj.to_s
        elsif klass == Fixnum
          digest << 'Fixnum'
          digest << obj.to_s
        elsif klass == TrueClass
          digest << 'TrueClass'
        elsif klass == FalseClass
          digest << 'FalseClass'
        elsif klass == NilClass
          digest << 'NilClass'
        elsif klass == Array
          digest << 'Array'
          queue.concat(obj)
        elsif klass == Hash
          digest << 'Hash'
          queue.concat(obj.sort)
        else
          raise TypeError, "couldn't digest #{klass}"
        end
      end

      digest.hexdigest
    end

    def benchmark_start
      Time.now.to_f
    end

    def benchmark_end(start_time)
      ((Time.now.to_f - start_time) * 1000).to_i
    end
  end
end
