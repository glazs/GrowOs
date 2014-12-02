Debug = require './debug'
i2c = require 'i2c'
#sync = require 'sync'

debug = new Debug 1



module.exports = class GrovePI

	wire = 0

	# ID команды на контроллере
	CMD = 
		analog:
			read: 3
			write: 4
		digital:
			read: 1
			write: 2
		mode: 5
		ranger: 7
		temperature: 40


	constructor: (@address, @id) ->
		wire = new i2c @address, device: "/dev/i2c-1" 
		@wire = wire  if debug.mode

	send: ( cmd, data, callback ) ->
		writeCmd = if Array.isArray data then 'writeBytes' else 'writeByte'
		wire[writeCmd] cmd, data, ( error ) ->
			callback()
			debug.log "Send", cmd, data
			debug.log "ERROR:", error if error

	receive: ( port, args... ) ->
		if args[1]
			size = args[0]
			callback = args[1]
		else
			callback = args[0]
		readCmd = if size then 'readBytes' else 'readByte'
		writeArgs = [ port ]
		writeArgs.push size  if size
		wire[readCmd] writeArgs..., (error, data) ->
			callback data
			debug.log "Reveive", port, data
			debug.log "ERROR:", error if error

	write: ( type, port, data, callback ) ->
		data = [port].concat data
		switch type
			when 'digital'
				@send CMD.digital.write, data, callback
			when 'analog'
				@send CMD.analog.write, data, callback

	read: ( type, args... ) ->
		switch type
			when 'digital'
				isBlock = args[0]
				callback = args[1]
				readCmd = if isBlock then 'readBytes' else 'readByte'
				wire.writeBytes CMD.digital.read, 0, ->
					wire[readCmd] (error, data) ->
						callback data
						debug.log "Digital read", CMD.digital.read, data
						debug.log "ERROR:", error if error
			when 'analog'
				callback = args[0]
				wire.writeBytes CMD.analog.read, 0, ->
					wire.readByte (err, data) ->
						callback data
						debug.log "Analog read", CMD.analog.read, data
						debug.log "ERROR:", error if error

	input: (callback) ->
		wire.writeByte CMD.mode, 0, -> # Switch to input
			callback() # Do what you want
			wire.writeByte CMD.mode, 1, -> # Switch to output

	ranger: ( port, callback ) ->
		wire.writeBytes CMD.ranger, [port,0,0], ->
			wire.readBytes port, 3, (err, value) ->
				callback value[2] + value[1]

