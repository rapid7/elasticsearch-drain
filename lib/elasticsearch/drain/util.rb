require 'thor/shell/color'

module Elasticsearch
  class Drain
    module Util
      def wait_until(expected, max_attempts = 5, delay = 60, &block)
        1.upto(max_attempts) do |i|
          result = block.call
          if result == expected
            return
          else
            to_thor('Waiting', "Waiting #{delay} seconds for #{i}/#{max_attempts} attempts", :yellow)
            sleep delay
          end
        end
        fail Errors::WaiterExpired
      end

      def to_thor(name, message, color)
        @thor_shell_client ||= Thor::Shell::Basic.new
        @thor_shell_client.say_status(name, message, color)
      end
    end
  end
end
