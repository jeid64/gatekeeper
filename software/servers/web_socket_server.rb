require 'em-websocket'
require 'user'

module Gatekeeper
	class WebSocketServer < EM::WebSocket::Connection
		include ApiServer

		def initialize(options)
			EM::WebSocket::Connection.instance_method(:initialize).bind(self).call(options)
			super(options)

			@onopen    = method(:onopen)
			@onmessage = method(:onmessage)
			@onerror   = method(:onerror)
			@onclose   = method(:onclose)

			@user = User.new(1, false)
		end

		def onopen
		end

		def onmessage(msg)
			command, payload, id = msg.split(':')

			unless command and payload
				send("Malformed instruction (Command:Payload:Id)")
				return
			end

			case command
				when 'AUTH'
					#TODO: authenticate the user
					send({:result => true, :error => nil}.to_json)
				when 'POP'
					do_action(@user, :pop, payload.to_i) do |result|
						send(result.merge({:id => id}).to_json)
					end
				when 'LOCK'
					do_action(@user, :lock, payload.to_i) do |result|
						send(result.merge({:id => id}).to_json)
					end
				when 'UNLOCK'
					do_action(@user, :unlock, payload.to_i) do |result|
						send(result.merge({:id => id}).to_json)
					end
				else
					send({:success => false, :error => "Unrecognized command '#{command}'"})
			end
		end

		def onerror(error)
			p $@
			p error
		end

		def onclose
		end
	end
end
