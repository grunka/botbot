#!/usr/bin/env ruby
require 'socket'
require 'botbot_handler.rb'

def main(argv)
  server = port = nick = nil
  channels = []
  until (arg = argv.shift).nil?
    if server.nil?
      server = arg
	elsif port.nil?
      port = arg.to_i
    elsif nick.nil?
      nick = arg
    else
	  channels << "##{arg}"
    end
  end
  puts "You need to specify a server to connect to" if server.nil?
  puts "You need to specify a port" if port.nil?
  puts "You need to specify a nick" if nick.nil?
  if server.nil? or port.nil? or nick.nil?
    puts "Usage: #{$0} server port nick [channels]"
	exit
  end
  puts "Connecting to #{server}:#{port}", "Using nick #{nick}", "Joining #{channels.size} channel(s) #{channels.inspect}"
  Bot.new(server, port, nick, channels).connect()
end

class Bot
  def initialize(host, port, nick, channels)
    @host = host
    @port = port
    @nick = nick
    @channels = channels
    @handler = BotHandler.new
	
    trap("TERM") do
      quit
    end

    trap("INT") do
      quit
    end

    trap("HUP") do
      begin
        load('botbot_handler.rb')
        @handler = BotHandler.new
        puts "Handler reloaded"
      rescue Exception => e
        puts "Could not reload handler", e.message, e.backtrace.join("\n")
      end
    end
  end
  
  def raw(message)
    puts "-> #{message}"
    @socket.print "#{message}\r\n"
  end

  def quit()
    raw "QUIT"
	@socket.close
  end

  def privmsg(to, message)
    raw "PRIVMSG #{to} :#{message}"
  end
  
  def join(channel)
    raw "JOIN :#{channel}"
  end
  
  def part(channel)
    raw "PART :#{channel}"
  end
  
  def nick(nick)
    @nick = nick
    raw "NICK #{nick}"
  end
  
  def connect()
    @socket = TCPSocket.open(@host, @port)
    nick(@nick)
    raw "USER #{@nick} 0 * :#{@nick}"

    while line = @socket.gets
      line = line.strip
      puts "<- #{line}"
      if match = line.match(/^PING :(.*)$/)
        raw "PONG #{match[1]}"
      elsif line.match(/^:[^ ]+ MODE #{@nick} [:]?\+i$/)
        @channels.each do |channel|
          join(channel)
        end
      elsif match = line.match(/^:([^ ]+) PRIVMSG ([^ ]+) :(.*)$/)
        next unless from = match[1].match(/^([^!]+)!(.*)$/)
        to = match[2]
        message = match[3]
        begin
          if to == @nick
            respond_to = from[1]
            @handler.handle_private(self, respond_to, message)
          elsif @channels.include?(to)
            respond_to = to
            @handler.handle_public(self, respond_to, message)
          end
        rescue Exception => e
          puts "Failure in handler", e.message, e.backtrace.join("\n")
          privmsg(respond_to, "Failure in handler!")
		end
      end
    end
  end
end

main(ARGV.dup)
