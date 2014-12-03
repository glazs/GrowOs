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

	modes = {}

	MODES = {
		input: 0
		output: 1
	}


	constructor: (@address, @id) ->
		wire = new i2c @address, device: "/dev/i2c-1" 

		@wire = wire  if debug.mode

	mode: (port, mode, callback) ->
		unless modes[port]? is mode
			modes[port] = mode
			@send CMD.mode, port, [mode, 0]

	send: ( cmd, port, args... ) ->
		unless cmd is CMD.mode
			@mode port, MODES.output
		writeArgs = [cmd]
		if args[1]
			data = args[0]
			callback = args[1]
			writeArgs.push [port].concat data
			writeCmd = 'writeBytes'
		else
			writeArgs.push port
			callback = args[0]
			writeCmd = 'writeByte'

		callback ?= ->

		cmdAndData = [cmd]
		cmdAndData.push [data] if data

		debug.log 'Send', cmdAndData, 'to port', port

		writeArgs.push (error) ->
			callback()
			debug.log 'ERROR:', error if error

		wire[writeCmd] writeArgs...


	receive: ( port, args... ) ->
		@mode port, MODES.input
		readArgs = []
		if args[1]
			length = args[0]
			callback = args[1]
			readArgs.push port
			readArgs.push length
			readCmd = 'readBytes'
		else
			callback = args[0]
			readCmd = 'readByte'

		debug.log 'Receive from port', port
		readArgs.push (error, data) ->
			callback data
			debug.log 'Received', (Array.prototype.slice.call data, 0)
			debug.log 'ERROR:', error if error

		wire[readCmd] readArgs...

	write: ( type, port, data, callback ) ->
		@send CMD[type].write, port, data, callback

	read: ( type, args... ) ->
		@send CMD[type].read, args...

	ranger: ( port, callback ) ->
		@send CMD.ranger, port, [0,0], =>
			@receive port, 3, (data) ->
				callback data[2] + data[1]

