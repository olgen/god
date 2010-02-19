module God
  module Conditions
    
    class Lambda < PollCondition
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
          @timeline.push self.lambda.call()
          history = "TRUE [#{@timeline.select { |x| x }.size}/#{@timeline.length}]"
          if @timeline.select { |x| x }.size >= self.times.first
            self.info = "lambda PASSED #{history}"
            return true
          else
            self.info = "lambda FAILED #{history}"
            return false
          end        
      end

    end

  end
end