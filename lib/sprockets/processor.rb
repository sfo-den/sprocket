module Sprockets
  # `Processor` creates an anonymous processor class from a block.
  #
  #     register_preprocessor 'text/css', :my_processor do |context, data|
  #       # ...
  #     end
  #
  class Processor
    def self.make_processor(klass, &block) # :nodoc:
      return klass unless block_given?

      name  = klass.to_s
      Class.new(Processor) do
        @name      = name
        @processor = block
      end
    end

    # `processor` is a lambda or block
    def self.processor
      @processor
    end

    def self.name
      "Sprockets::Processor (#{@name})"
    end

    def self.to_s
      name
    end

    attr_reader :data

    def initialize(file, &block)
      @data = block.call
    end

    def render(context)
      # Legacy argument style.
      # Call processor block with `context` and `data`.
      if self.class.processor.arity == 2
        self.class.processor.call(context, data)
      else
        input = {
          environment: context.environment,
          context: context,
          data: data
        }
        self.class.processor.call(input)
      end
    end
  end
end
