require 'active_record'

module MotherBrain
  module Gear
    class Mysql < RealModelBase
      include MB::Gear
      register_gear :mysql

      def action(sql, options)
        Action.new(context, sql, options)
      end

      class Action < RealModelBase
        attr_reader :sql
        attr_reader :options

        def initialize(context, sql, options)
          super(context)

          @sql = sql
          @options = options

          validate_options!
        end

        def validate_options!
          unless options.key? :data_bag
            raise GearError, "You are missing a :data_bag key in your MySQL gear options!"
          end

          unless options[:data_bag].key? :name
            raise GearError, "You are missing a :name key in your MySQL gear data bag options!"
          end
        end

        def run(nodes)
          nodes.each do |node|
            ActiveRecord::Base.establish_connection(connection_info(node))
            ActiveRecord::Base.connection.execute(sql)
          end
        end

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

        def adapter
          MB.jruby? ? "jdbcmysql" : "mysql2"
        end

        def data_bag_keys
          hash = data_bag_spec[:location][:hash]

          if hash
            Hash[data_bag_spec[:location][:keys].map { |k, v| [k, "#{hash}.#{v}"] }]
          else
            data_bag_spec[:location][:keys]
          end
        end

        def data_bag_spec
          @data_bag_spec ||= options[:data_bag].deep_merge(default_data_bag_spec)
        end

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
