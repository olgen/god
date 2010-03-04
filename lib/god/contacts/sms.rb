require 'time'
require 'net/smtp'
require 'god/smtp_tls' #need this hack for tls in smtp

module God
  module Contacts
    
    class Sms < Contact
      class << self
        attr_accessor :message_settings, :delivery_method, :server_settings, :sendmail_settings, :format
      end
      
      self.message_settings = {
                                :from => 'god@example.com',
                                :gateway_key=>'1234',
                                :gateway_email=>'email2sms@sms77.de'}
      
      self.delivery_method = :smtp # or :sendmail
      
      self.server_settings = {:address => 'localhost',
                              :port => 25}
                            # :domain
                            # :user_name
                            # :password
                            # :authentication

      self.sendmail_settings = {:location  => '/usr/sbin/sendmail',
                                :arguments => '-i -t'
      }
      
      self.format = lambda do |phone, message, time, priority, category, host|
<<-EOF
From: god <#{self.message_settings[:from]}>
To: sms-gateway #{self.message_settings[:gateway_email]}>
Subject: [message from god] #{message}; Host: #{host};
Date: #{Time.now.httpdate}
Message-Id: <#{rand(1000000000).to_s(36)}.#{$$}.#{self.message_settings[:from]}>

#{self.message_settings[:gateway_key]}##{phone}
EOF
      end
      
      attr_accessor :phone
      
      def valid?
        valid = true
        valid &= complain("Attribute 'phone' must be specified", self) if self.phone.nil?
        valid
      end
      
      def notify(message, time, priority, category, host)
        begin
          body = Sms.format.call(self.phone, message, time, priority, category, host)

          case Sms.delivery_method
          when :smtp
            notify_smtp(body)
          when :sendmail
            notify_sendmail(body)
          else
            raise "unknown delivery method: #{Sms.delivery_method}"
          end
          
          self.info = "sent sms to #{self.name}:#{self.phone}"
        rescue => e
          applog(nil, :info, "failed to send sms to #{self.name}:#{self.phone}: #{e.message}")
          applog(nil, :debug, e.backtrace.join("\n"))
        end
      end

      # private

      def notify_smtp(mail)
        args = [Sms.server_settings[:address], Sms.server_settings[:port]]
        if Sms.server_settings[:authentication]
          args << Sms.server_settings[:domain]
          args << Sms.server_settings[:user_name]
          args << Sms.server_settings[:password]
          args << Sms.server_settings[:authentication] 
        end

        Net::SMTP.start(*args) do |smtp|
          smtp.send_message mail, Sms.message_settings[:from], Sms.message_settings[:gateway_email]
        end
      end

      def notify_sendmail(mail)
        IO.popen("#{Sms.sendmail_settings[:location]} #{Sms.sendmail_settings[:arguments]}","w+") do |sm|
          sm.print(mail.gsub(/\r/, ''))
          sm.flush
        end
      end
    end

  end
end
