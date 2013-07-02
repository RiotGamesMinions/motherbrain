module MotherBrain
  class NodeFilter

    class << self
      def filter(segments, nodes)
        new(segments).filter(nodes)
      end
    end

    # @return [Array]
    attr_reader :segments

    def initialize(segments)
      @segments = segments
    end

    def filter(nodes)
      nodes.select do |node|
        matches?(node)
      end
    end

    def matches?(node)
      segments.any? do |s|
        if ipaddress?(s)
	  s == node.public_ipv4
	elsif r = iprange(s)
          r.include?(node.public_ipv4)
	# elsif regex?(s)
	else
	  s == node.public_hostname ||
	  s == node.public_hostname.sub(/\..*/,'')
	end
      end
    end

    def ipaddress?(segment)
      segment.match(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)
    end

    def iprange(segment)
      match = segment.match(/^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3}-\d{1,3})$/)
      return nil unless match
      first,last = match[2].split('-')
      (first..last).to_a.collect {|l| "#{match[1]}.#{l}" }
    end
  end
end
