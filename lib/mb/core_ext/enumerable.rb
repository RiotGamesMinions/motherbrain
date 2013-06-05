module Enumerable
  # Map across all members using Celluloid futures, and wait for the results.
  #
  # This chooses the best behavior based on each item, and whether a method and
  # argument list or block are passed.
  #
  # @param [Symbol] method_name
  #   The name of the method to call on each item in the collection
  # @param [Array] args
  #   The argument list, if any, to pass to each method send
  # @param [Proc] block
  #   A block to yield each item to
  #
  # @example Passing a method and arguments
  #
  #   [1, 2, 3].concurrent_map(:next)
  #   # => [2, 3, 4]
  #
  #   [1, 2, 3].concurrent_map(:modulo, 2)
  #   # => [1, 0, 1]
  #
  # @example Passing a block
  #
  #   [1, 2, 3].concurrent_map { |n| n + 1 }
  #   # => [2, 3, 4]
  #
  # @return [Array] a new array containing the values returned by the futures
  def concurrent_map(method_name = nil, *args, &block)
    futures = if method_name
      map { |item|
        if item.respond_to?(:future)
          item.future(method_name, *args)
        else
          Celluloid::Future.new { item.send(method_name, *args) }
        end
      }
    elsif block_given?
      map { |item|
        Celluloid::Future.new { block.yield item }
      }
    else
      raise ArgumentError, "Requires method and argument list, or a block"
    end

    futures.map(&:value)
  end
  alias_method :concurrent_collect, :concurrent_map
end
