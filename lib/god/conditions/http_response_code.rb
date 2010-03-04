require 'net/http'

module God
  module Conditions
    
    # Condition Symbol :http_response_code
    # Type: Poll
    # 
    # Trigger based on the response from an HTTP request.
    #
    # Paramaters
    #   Required
    #     +host+ is the hostname to connect [required]
    #     --one of code_is or code_is_not--
    #     +code_is+ trigger if the response code IS one of these
    #               e.g. 500 or '500' or [404, 500] or %w{404 500}
    #     +code_is_not+ trigger if the response code IS NOT one of these
    #                   e.g. 200 or '200' or [200, 302] or %w{200 302}
    #  Optional
    #     +port+ is the port to connect (default 80)
    #     +path+ is the path to connect (default '/')
    #     +headers+ is the hash of HTTP headers to send (default none)
    #     +times+ is the number of times after which to trigger (default 1)
    #             e.g. 3 (times in a row) or [3, 5] (three out of fives times)
    #     +timeout+ is the time to wait for a connection (default 60.seconds)
    #
    # Examples
    #
    # Trigger if the response code from www.example.com/foo/bar
    # is not a 200 (or if the connection is refused or times out:
    #
    #   on.condition(:http_response_code) do |c|
    #     c.host = 'www.example.com'
    #     c.path = '/foo/bar'
    #     c.code_is_not = 200
    #   end
    #
    # Trigger if the response code is a 404 or a 500 (will not
    # be triggered by a connection refusal or timeout):
    #
    #   on.condition(:http_response_code) do |c|
    #     c.host = 'www.example.com'
    #     c.path = '/foo/bar'
    #     c.code_is = [404, 500]
    #   end
    #
    # Trigger if the response code is not a 200 five times in a row:
    #
    #   on.condition(:http_response_code) do |c|
    #     c.host = 'www.example.com'
    #     c.path = '/foo/bar'
    #     c.code_is_not = 200
    #     c.times = 5
    #   end
    #
    # Trigger if the response code is not a 200 or does not respond
    # within 10 seconds:
    #
    #   on.condition(:http_response_code) do |c|
    #     c.host = 'www.example.com'
    #     c.path = '/foo/bar'
    #     c.code_is_not = 200
    #     c.timeout = 10
    #   end
    class HttpResponseCode < PollCondition
      include ConditionHelper
      attr_accessor :code_is,      # e.g. 500 or '500' or [404, 500] or %w{404 500}
                    :code_is_not,  # e.g. 200 or '200' or [200, 302] or %w{200 302}
                    :times,        # e.g. 3 or [3, 5]
                    :host,         # e.g. www.example.com
                    :port,         # e.g. 8080
                    :timeout,      # e.g. 60.seconds
                    :path,         # e.g. '/'
                    :headers,      # e.g. {'Host' => 'myvirtual.mydomain.com'}
                    :method,       # e.g. :post, :get
                    :data,     # e.g. {:ua=>"Mozilla 3.5"}
                    :trigger_on   # can trigger both on: true or false
      
      def initialize
        super
        self.port = 80
        self.path = '/'
        self.headers = {}
        self.times = [3, 5]
        self.timeout = 60.seconds
        self.method = :get
      end
      
      def prepare
        self.code_is = Array(self.code_is).map { |x| x.to_i } if self.code_is
        self.code_is_not = Array(self.code_is_not).map { |x| x.to_i } if self.code_is_not
        
        if self.times.kind_of?(Integer)
          self.times = [self.times, self.times]
        end
        
        @timeline = Timeline.new(self.times[1])
        @history = Timeline.new(self.times[1])
      end
      
      def reset
        @timeline.clear
        @history.clear
      end
      
      def valid?
        valid = true
        valid &= complain("Attribute 'host' must be specified", self) if self.host.nil?
        valid &= complain("Attribute 'method' must be in [:get, :post]", self) if ![:get, :post].include?(self.method)
        valid &= complain("One (and only one) of attributes 'code_is' and 'code_is_not' must be specified", self) if
          (self.code_is.nil? && self.code_is_not.nil?) || (self.code_is && self.code_is_not)
        valid
      end
      

      def test
        response = nil
        Net::HTTP.start(self.host, self.port) do |http|
          http.read_timeout = self.timeout
          if self.method == :get
            response = http.get(self.path, self.headers)
          else self.method == :post
            req = Net::HTTP::Post.new(self.path, self.headers)
            req.set_form_data(self.data, ';') if self.data
            response =  http.request(req)
          end
        end
        
        # require 'ruby-debug'; debugger
        
        
        actual_response_code = response.code.to_i
        if self.code_is && self.code_is.include?(actual_response_code)
          pass(actual_response_code)
        elsif self.code_is_not && !self.code_is_not.include?(actual_response_code)
          pass(actual_response_code)
        else
          fail(actual_response_code)
        end
      rescue Errno::ECONNREFUSED
        self.code_is ? fail('Refused') : pass('Refused')
      rescue Errno::ECONNRESET
        self.code_is ? fail('Reset') : pass('Reset')
      rescue EOFError
        self.code_is ? fail('EOF') : pass('EOF')
      rescue Timeout::Error
        self.code_is ? fail('Timeout') : pass('Timeout')
      rescue Errno::ETIMEDOUT
        self.code_is ? fail('Timedout') : pass('Timedout')
      rescue Exception => failure
        self.code_is ? fail(failure.class.name) : pass(failure.class.name)
      end
      
      private
      
      def pass(code)
          self.info = "http response 1abnormal #{history(code, true)}"
          return timeline_test(true)
      end
      
      def fail(code)
        self.info = "http response 3nominal #{history(code, false)}"
        return timeline_test(false)
      end
      
      def history(code, passed)
        entry = code.to_s.dup
        entry = '*' + entry if passed
        @history << entry
        '[' + @history.join(", ") + ']'
      end
      
      # def timeline_test(res)
      #   @timeline << res
      #   history = " - SUCCESS RATE: [#{@timeline.select { |x| x }.size}/#{@timeline.length}]"
      #   if @timeline.select { |x| x }.size >= self.times[0]
      #     self.info = " PASSED #{history}"
      #     return true
      #   elsif @timeline.select { |x| !x }.size > self.times[1] - self.times[0]
      #     self.info = " FAILED #{history}"
      #     return false
      #   else
      #     self.info = "history too short: #{history}"
      #     return nil # do not trigger a transition
      #   end
      # end
      
    end
    
  end
end