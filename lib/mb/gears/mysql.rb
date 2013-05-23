module MotherBrain
  module Gear
    # @author Jesse Howarth <jhowarth@riotgames.com>
    class Mysql < Gear::Base
      register_gear :mysql

      # @param [String] sql
      #   the sql to run
      #
      # @option options [Hash] :data_bag
      #   specify the data bag, item, and location inside the item to find the MySQL credentials
      #
      # @return [MB::Gear::Mysql::Action]
      def action(sql, options)
        Mysql::Action.new(sql, options)
      end
    end
  end
end
