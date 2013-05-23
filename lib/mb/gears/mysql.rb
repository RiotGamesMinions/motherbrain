module MotherBrain
  module Gear
    # @author Jesse Howarth <jhowarth@riotgames.com>
    class MySQL < Gear::Base
      require_relative 'mysql/action'

      register_gear :mysql

      # @param [String] sql
      #   the sql to run
      #
      # @option options [Hash] :data_bag
      #   specify the data bag, item, and location inside the item to find the MySQL credentials
      #
      # @return [MB::Gear::MySQL::Action]
      def action(sql, options)
        MySQL::Action.new(sql, options)
      end
    end
  end
end
