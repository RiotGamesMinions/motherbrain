require 'optparse'

module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  module AgentCtl
    class << self
      extend Forwardable

      def_delegator "MB::Agent", :default_options

      def parse(args, filename)
        options = Hash.new

        OptionParser.new("Usage: #{filename} [options]") do |opts|
          opts.on("-h", "--host ADDR", "listen address", "(default: '#{default_options[:host]}')") do |v|
            options[:host] = v
          end

          opts.on("-p", "--port PORT", "listen port", "(default: '#{default_options[:port]}')") do |v|
            options[:port] = v.to_i
          end

          opts.on("-n", "--node-id NAME", "name to register agent as", "(default: fqdn or hostname of machine)") do |v|
            options[:node_id] = v
          end

          opts.on_tail("--help", "show this message") do
            puts opts
            exit
          end
        end.parse!(args)

        default_options.reverse_merge(options)
      end

      def run(args, filename)
        options = parse(args, filename)
        
        puts "==> motherbrain agent running on #{options[:host]}:#{options[:port]}..."
        MB::Agent.start(options)
      end
    end
  end
end
