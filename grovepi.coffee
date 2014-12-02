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



	send = ( cmd, data, callback ) ->
		writeCmd = if Array.isArray data then 'writeBytes' else 'writeByte'
		wire[writeCmd] cmd, data, ( error ) ->
			callback()
			debug.log "Send", cmd, data
			debug.log "ERROR:", error if error

	receive = ( port, args... ) ->
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
		send CMD[type].write, data, callback

	read: ( type, args... ) ->
		send CMD[type].read, args...

	input: (callback) ->
		wire.writeByte CMD.mode, 0, -> # Switch to input
			callback() # Do what you want
			wire.writeByte CMD.mode, 1, -> # Switch to output

	ranger: ( port, callback ) ->
		write CMD.ranger, port, [0,0], ->
			read port, 3, (err, value) ->
				callback value[2] + value[1]

