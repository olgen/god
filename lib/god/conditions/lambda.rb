module God
  module Conditions
    
    class Lambda < PollCondition
      include ConditionHelper
      attr_accessor :lambda, :times

      def initialize
        super
        self.times = [1, 1]
      end
      
      def prepare
        if self.times.kind_of?(Integer)
          self.times = [self.times, self.times]
        end
        @timeline = Timeline.new(self.times[1])
      end
      
      def valid?
        valid = true
        valid &= complain("Attribute 'lambda' must be specified", self) if self.lambda.nil?
        valid
      end

      def test  
        return timeline_test(self.lambda.call)
      end

    end

  end
end