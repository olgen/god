module God
  module Conditions
    
    class Ping < PollCondition
      include ConditionHelper
      attr_accessor :timeout, :host, :trigger_on, :times
      
      def initialize
        super
        self.timeout = 2 # s
        self.host = nil
        self.trigger_on=true
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
        valid &= complain("Attribute 'host' must be specified", self) if self.host.nil?
        valid &= complain("Attribute 'timeout' must be specified", self) if self.timeout.nil?
        valid
      end
      
      def test
        cmd = "ping -W #{self.timeout} -c 5 #{self.host}"
        ping_result = `#{cmd}`
        if ping_result=~/time=/
          self.info = "Server reachable via ping!"
          return timeline_test(true)
        end
        self.info = "Server unreachable via ping!!!"
        return timeline_test(false)
      end
    end
  end
end