module God
  module Conditions

    module ConditionHelper
      
      # check the result in the timeline..
      def timeline_test(res)
        self.trigger_on = true if self.trigger_on.nil?
        @timeline << res
        history = " - TRIGGER RATE: [#{@timeline.select { |x| x==self.trigger_on }.size}/#{@timeline.length}]"
        if @timeline.select { |x| x == self.trigger_on }.size >= self.times[0]
          status = trigger_on ? "UP" : "DOWN"
          self.info = " SERVICE STATUS moved to: #{status}"
          return true
        else
          self.info = " PASSED #{history}"
          return false
        end
      end


      # # invert the result if needed...
      # def trigger_check(res)
      #   trigger_on ? res : !res
      # end

    end
  end
end