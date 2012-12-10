if jruby?
  require 'jdbc/mysql'
  require 'java'
else
  require 'mysql2'
end

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

        class << self
          # @param [Hash] options
          #   the options to validate
          #
          # @raise [MB::ArgumentError] if the options are invalid
          def validate_options(options)
            unless options.key? :data_bag
              raise ArgumentError, "You are missing a :data_bag key in your MySQL gear options!"
            end

            unless options[:data_bag].key? :name
              raise ArgumentError, "You are missing a :name key in your MySQL gear data bag options!"
            end
          end
        end

        # @param [MB::Context] context
        # @param [String] sql 
        #   the sql to run
        #
        # @option options [Hash] :data_bag
        #   specify the data bag, item, and location inside the item to find the MySQL credentials
        def initialize(context, sql, options)
          super(context)

          self.class.validate_options(options)

          @sql = sql
          @options = options
        end

        # Run this action on the specified nodes
        #
        # @param [Array<Ridley::Node>] nodes the nodes to run this action on
        def run(nodes)
          threads = []

          nodes.each do |node| 
            threads << Thread.new(node) do |node|
              query(sql, node)
            end
          end

          threads.each(&:join)
        end

        # The MySQL connection information/credentials for the specified node.
        #
        # @param [Ridley::Node] node 
        #   the node to to find connection information for
        #
        # @return [Hash] MySQL connection information for the node
        def connection_info(node)
          credentials.merge({host: node.public_hostname})
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

        private
          # Runs a sql query on a node.
          #
          # @param [String] sql
          #   the sql query
          # @param [Ridley::Node] node
          #   the node to run the query on
          def query(sql, node)
            jruby? ? jdbc_query(sql, node) : mysql2_query(sql, node)
          end

          # Runs a sql query on a node using jdbc.
          #
          # @param [String] sql
          #   the sql query
          # @param [Ridley::Node] node
          #   the node to run the query on
          def jdbc_query(sql, node)
            info = connection_info(node)
            Java::com.mysql.jdbc.Driver
            connection_url = "jdbc:mysql://#{info[:host]}:#{info[:port]}/#{info[:database]}"
            connection = java.sql.DriverManager.get_connection(connection_url, info[:username], info[:password])
            connection.create_statement.execute(sql)
          end

          # Runs a sql query on a node using mysql2.
          #
          # @param [String] sql
          #   the sql query
          # @param [Ridley::Node] node
          #   the node to run the query on
          def mysql2_query(sql, node)
            connection = Mysql2::Client.new(connection_info(node))
            connection.query(sql)
          end

          # Retrieves the MySQL credentials from the data bag.
          #
          # @raise [MB::ArgumentError] if any MySQL credentials are missing
          #
          # @return [Hash] MySQL credentials
          def credentials
            return @credentials if @credentials

            data_bag = Application.ridley.data_bag.find!(data_bag_spec[:name])
            dbi = data_bag.encrypted_item.find!(data_bag_spec[:item]).attributes

            @credentials = Hash[data_bag_keys.map { |key, dbi_key| [key, dbi.dig(dbi_key)] }]

            @credentials.each do |key, value|
              if value.nil?
                err_msg = "Missing a MySQL credential.  Could not find a #{key} at the location you specified. "
                err_msg << "You specified that the #{key} can be found at '#{data_bag_keys[key]}' "
                err_msg << "in the '#{data_bag_spec[:item]}' data bag item inside the '#{data_bag_spec[:name]}' "
                err_msg << "data bag."
                raise GearError, err_msg
              end
            end

            @credentials
          end

          # @return [Hash] where to find the MySQL connection information
          def data_bag_spec
            @data_bag_spec ||= default_data_bag_spec.deep_merge(options[:data_bag])
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
