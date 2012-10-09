module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # A class to encapsulate running Chef on a set of nodes.
  class ChefRunner
    class << self
      # @param [Hash] options
      #
      # @raise [MotherBrain::ArgumentError] if the given options are invalid
      #
      # @return [Boolean]
      def validate_options(options)
        unless options.has_key?(:keys) || (options.has_key?(:user) && options.has_key?(:password))
          raise ArgumentError, "Must specify an option for 'keys' or 'user' and 'password'"
        end

        if options.has_key?(:keys) && (options.has_key?(:user) || options.has_key?(:password))
          raise ArgumentError, "Cannot specify an option for 'keys' and 'user' or 'password'"
        end

        true
      end

      # @param [Rye::Rap] response
      #
      # @example response containing no failures
      #
      #   handle_response(response) => [ :ok, [] ]
      #
      # @example response containing failures
      #
      #   handle_response(response) => [ :error, [#<Rye::Rap>] ]
      #
      # @return [Array]
      def handle_response(response)
        errors = response.select { |rap| rap.exit_status != 0 }

        if errors.empty?
          [ :ok, [] ]
        else
          [ :error, errors ]
        end
      end
    end

    extend Forwardable

    DEFAULT_OPTIONS = {
      parallel: true,
      sudo: true
    }.freeze

    DEFAULT_ADDRESS_ATTRIBUTE = 'ipaddress'

    # @return [Rye::Set]
    attr_reader :connection

    # @return [Rye::Box]
    def_delegator :connection, :boxes, :nodes

    # @option options [String] :address_attribute
    #   a dotted path representing the Chef attribute containing the connection address. (Default: 'ipaddress')
    # @option options [Boolean] :safe
    #   should Rye be safe? Default: true
    # @option options [Integer] :port
    #   remote server ssh port. Default: SSH config file or 22
    # @option options [Array<String>, String] :keys
    #   one or more private key file paths
    # @option options [Rye::Hop] :via
    #   the Rye::Hop to access this host through
    # @option options [IO] :info
    #   an IO object to print Rye::Box command info to. Default: nil
    # @option options [IO] :debug
    #   an IO object to print Rye::Box debugging info to. Default: nil
    # @option options [IO] :error
    #   an IO object to print Rye::Box errors to. Default: STDERR
    # @option options [Boolean] :getenv
    #   pre-fetch +host+ environment variables? (default: true)
    # @option options [String] :password
    #   the user's password (ignored if there's a valid private key)
    # @option options [Symbol] :templates
    #   the template engine to use for uploaded files. One of: :erb (default)
    # @option options [Boolean] :sudo
    #   Run all commands via sudo (default: true)
    # @option options [Boolean] :parallel
    #   run the commands in parallel? (default: true).
    def initialize(options = Hash.new)
      self.class.validate_options(options)

      @address_attribute = options.delete(:address_attribute) { DEFAULT_ADDRESS_ATTRIBUTE }
      @connection = Rye::Set.new("motherbrain", DEFAULT_OPTIONS.merge(options))
    end

    # @param [Array<Ridley::Node>, Ridley::Node] nodes
    def add_nodes(nodes)
      Array(nodes).each { |node| add_node(node) }
    end

    # @param [Ridley::Node] node
    #
    # @raise [NoValueForAddressAttribute] if a value for the connection address is not found at
    #   the address_attribute of this instance of {ChefRunner}
    #
    # @return [Rye::Set]
    def add_node(node)
      address = node.automatic.dig(address_attribute)
      
      if address.nil?
        raise NoValueForAddressAttribute, "No address found at automatic node attribute '#{address_attribute}'."
      end

      self.connection.add_boxes(address)
    end

    # @return [Boolean]
    def run
      self.class.handle_response(self.connection.chef_client)
    end

    private

      # @return [String]
      attr_reader :address_attribute
  end
end

::Rye::Cmd.add_command :chef_client, 'chef-client'
