require 'active_record'

module MotherBrain
  module Gear
    class Mysql < RealModelBase
      include MB::Gear
      register_gear :mysql

      # @see [MB::Gear::Mysql::Action]
      #
      # @return [MB::Gear::Mysql::Action]
      def action(sql, options)
        Action.new(context, sql, options)
      end

      class Action < RealModelBase
        # @return [String]
        attr_reader :sql
        # @return [Hash]
        attr_reader :options

        # @param [MB::Context] context
        # @param [String] sql the sql to run
        #
        # @option options [Hash] :data_bag
        #   specify the data bag, item, and location inside the item to find the MySQL credentials
        def initialize(context, sql, options)
          super(context)

          @sql = sql
          @options = options

          validate_options!
        end

        # Ensures valid options were passed to the action.
        #
        # @raise [MB::ArgumentError] if the options are invalid
        def validate_options!
          unless options.key? :data_bag
            raise ArgumentError, "You are missing a :data_bag key in your MySQL gear options!"
          end

          unless options[:data_bag].key? :name
            raise ArgumentError, "You are missing a :name key in your MySQL gear data bag options!"
          end
        end

        # Run this action on the specified nodes
        #
        # @param [Array<Ridley::Node>] nodes the nodes to run this action on
        def run(nodes)
          nodes.each do |node|
            ActiveRecord::Base.establish_connection(connection_info(node))
            ActiveRecord::Base.connection.execute(sql)
          end
        end

        # The MySQL connection information/credentials for the specified node.
        #
        # @param [Ridley::Node] node the node to to find connection information for
        #
        # @raise [MB::ArgumentError] if any MySQL credentials are missing
        #
        # @return [Hash] MySQL connection information for the node
        def connection_info(node)
          connection_spec = {
            adapter: adapter,
            host: node.public_hostname
          }

          data_bag = context.chef_conn.data_bag.find!(data_bag_spec[:name])
          dbi = data_bag.encrypted_item.find!(data_bag_spec[:item]).attributes

          credentials = Hash[data_bag_keys.map { |key, dbi_key| [key, dbi.dig(dbi_key)] }]

          credentials.each do |key, value|
            if value.nil?
              err_msg = "Missing a MySQL credential.  Could not find a #{key} at the location you specified. "
              err_msg << "You specified that the #{key} can be found at '#{data_bag_keys[key]}' "
              err_msg << "in the '#{data_bag_spec[:item]}' data bag item inside the '#{data_bag_spec[:name]}' "
              err_msg << "data bag."
              raise GearError, err_msg
            end
          end

          connection_spec = connection_spec.merge(credentials)
          connection_spec
        end

        # @return [#to_s] the adapter to use for MySQL connections
        def adapter
          MB.jruby? ? "jdbcmysql" : "mysql2"
        end

        # @return [Hash] The keys used to look up MySQL connection information in a data bag item.
        def data_bag_keys
          hash = data_bag_spec[:location][:hash]

          if hash
            Hash[data_bag_spec[:location][:keys].map { |k, v| [k, "#{hash}.#{v}"] }]
          else
            data_bag_spec[:location][:keys]
          end
        end

        # @return [Hash] where to find the MySQL connection information
        def data_bag_spec
          @data_bag_spec ||= options[:data_bag].deep_merge(default_data_bag_spec)
        end

        # @return [Hash] the default specification for where to find MySQL connection information
        def default_data_bag_spec
          {
            item: self.environment,
            location: {
              keys: {
                username: "username",
                password: "password",
                database: "database",
                port: "port"
              }
            }
          }
        end
      end
    end
  end
end
