module God
  module Conditions
    
    class Ping < PollCondition
      attr_accessor :timeout, :host, :trigger_on
      
      def initialize
        super
        self.timeout = 2 # s
        self.host = nil
        self.trigger_on=true
      end
      
      def valid?
        valid = true
        valid &= complain("Attribute 'host' must be specified", self) if self.host.nil?
        valid &= complain("Attribute 'timeout' must be specified", self) if self.timeout.nil?
        valid
      end
      
      def test
#        ping_time = `df -P | grep -i " #{self.mount_point}$" | awk '{print $5}' | sed 's/%//'`

        cmd = "ping -t #{self.timeout} #{self.host}"
        # puts cmd
        ping_result = `#{cmd}`
        # if ping_result=~ /no route to host/
        #   self.info "no route to host: #{self.host}"
        #   return false
        # end
        if ping_result=~/time=/
          self.info = "Server reachable via ping!"
          return self.trigger_on
        end
        self.info = "Server unreachable via ping!!!"
        return !self.trigger_on
      end
    end
  end
end