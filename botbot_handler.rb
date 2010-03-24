class BotHandler
  def handle_private(connection, from, message)
    puts "Got message from #{from}: #{message}"
	@verified = [] if @verified.nil?
    if @verified.include?(from)
      if match = message.match(/^nick ([^ ]+)$/)
        connection.nick(match[1])
      elsif match = message.match(/^join ([^ ]+)$/)
        connection.join(match[1])
      elsif match = message.match(/^part ([^ ]+)$/)
        connection.part(match[1])
      elsif match = message.match(/^say ([^ ]+) (.*)$/)
        connection.privmsg(match[1], match[2])
      end
    elsif match = message.match(/^verify (.*)$/)
      @verified << from if match[1] == "please" and not @verified.include?(from)
    end
  end

  def handle_public(connection, channel, message)
    puts "Got message from channel #{channel}: #{message}"
  end
end
