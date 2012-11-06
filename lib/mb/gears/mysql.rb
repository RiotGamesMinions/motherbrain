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
        end

        def adapter
          MB.jruby? ? "jdbcmysql" : "mysql2"
        end

        def connection_info(node)
          options[:connection].merge({adapter: adapter, host: node.public_hostname})
        end

        def run(nodes)
          nodes.each do |node|
            ActiveRecord::Base.establish_connection(connection_info(node))
            ActiveRecord::Base.connection.execute(sql)
          end
        end
      end
    end
  end
end
