module MotherBrain
  class NodeFilter
    class << self
      # Filters the given nodes based on the given segments
      #
      # @param [Array<String>] segments
      #   strings to match nodes on
      # @param [Array<Ridley::NodeObject>] nodes
      #
      # @return [Array] nodes that matched the segments
      def filter(segments, nodes)
        new(segments).filter(nodes)
      end

      # Expands any IP address ranges in the given segments and
      # returns the segments Array with any IP ranges expanded.
      #
      # @param [Array<String>] segments
      #   an Array of hostnames or IPs
      #
      # @return [Array<String>]
      def expand_ipranges(segments)
        node_filter = new(segments)
        segments.collect do |segment|
          range = node_filter.iprange(segment)
          range.nil? ? segment : range
        end.flatten
      end
    end

    # @return [Array<String>]
    attr_reader :segments

    # @param [Array<String>, String] segments
    #   an Array of hostnames or IPs
    def initialize(segments)
      @segments = Array(segments).flatten
    end

    # Filters the given array of nodes against the segments
    # and returns the matched nodes.
    #
    # @param [Array<Ridley::NodeObject>] nodes
    #
    # @return [Array] nodes that matched
    def filter(nodes)
      nodes.select { |node| matches?(node) }
    end

    # Checks the node against the instance's segments
    # and returns nodes that match an ipaddress or hostname.
    #
    # @param [Ridley::NodeObject] node
    #
    # @return [Boolean]
    def matches?(node)
      segments.empty? ||
      segments.any? do |s|
        if ipaddress?(s)
          s == node.public_ipv4
        elsif r = iprange(s)
          r.include?(node.public_ipv4)
        # elsif regex?(s)
        else
          s == node.public_hostname || s == node.public_hostname.sub(/\..*/,'')
        end
      end
    end

    # Checks the given segment and returns true if it
    # is an ipaddress.
    #
    # @param [String] segment
    #
    # @return [Boolean]
    def ipaddress?(segment)
      segment.match(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)
    end

    # Checks the given segment and either returns nil, if
    # it is not a range of IPs or expands and returns the range
    # as an array.
    #
    # @param [String] segment
    #
    # @example
    #   iprange("192.168.2.1-2") #=> ["192.168.2.1", "192.168.2.2"]
    #
    # @return [Array]
    def iprange(segment)
      match = segment.match(/^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3}-\d{1,3})$/)
      return nil unless match
      first,last = match[2].split('-')
      (first..last).to_a.collect {|l| "#{match[1]}.#{l}" }
    end
  end
end
