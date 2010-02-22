module God
  module Conditions

    module ConditionHelper
      
      def timeline_test(res)
        @timeline << res
        history = " - SUCCESS RATE: [#{@timeline.select { |x| x }.size}/#{@timeline.length}]"
        if @timeline.select { |x| x }.size >= self.times[0]
          self.info = " PASSED #{history}"
          return true
        elsif @timeline.select { |x| !x }.size > self.times[1] - self.times[0]
          self.info = " FAILED #{history}"
          return false
        else
          self.info = "history too short: #{history}"
          return nil # do not trigger a transition
        end
      end

    end
  end
end