Debug = require './debug'
i2c = require 'i2c'
#sync = require 'sync'

debug = new Debug 1



module.exports = class GrovePI

	wire = 0

	# ID команды на контроллере
	CMD = 
		error: 1
		analog_read: 4
		analog_write: 5
		digital_read: 2
		digital_write: 3
		mode: 6
		ranger: 101
		temperature: 40

	modes = {}

	MODES = {
		input: 0
		output: 1
	}

	getCmd = (id) -> 
		for cmd, cmdId of CMD
			if cmdId is id 
				return cmd


	constructor: (@address, @id) ->
		wire = new i2c @address, device: "/dev/i2c-1" 

		# Use fake API if no controller found
		@fake = false # wire.address?

		@wire = wire  if debug.mode
		debug.log "Connecting to controller with address #{@address}."
		if @fake
			debug.log "Fail: Using fake api; can't connect to controller"
		else
			debug.log 'Connected'


	mode: (port, mode, callback = ->) ->
		if modes[port] isnt mode
			modes[port] = mode
			@send CMD.mode, port, mode, -> callback()
		else
			callback()


	send: ( cmd, port, args... ) ->
		writeArgs = [cmd]
		if args[1]
			data = args[0]
			callback = args[1]
			writeArgs.push [port].concat data
			writeCmd = 'writeBytes'
		else if args[0]
			writeArgs.push [port]
			callback = args[0]
			writeCmd = 'writeBytes' #TODO add writeByte
		else 
			callback = port
			writeCmd = 'writeByte' #TODO add writeByte


		writeArgs.push (error) ->
			callback()

			debug.log 'ERROR:', error  if error

		namedCmd = (getCmd cmd) + "(#{cmd})"

		portAndData = [ 'to port', port ] if port isnt callback
		portAndData.push 'with data', data  if data?

		debug.log 'Send', namedCmd, portAndData...

		unless @fake
			wire[writeCmd] writeArgs...
		else
			callback()



	receive: ( port, args... ) ->
		readArgs = []
		if args[1]
			length = args[0]
			callback = args[1]
			readArgs.push port
			readArgs.push length
			readCmd = 'readBytes'
		else if args[0]
			length = port
			callback = args[0]
			readArgs.push length
			readCmd = 'readBytes'
		else
			callback = port
			readCmd = 'readByte'

		if args[1] is callback
			debug.log 'Receiving from port', port
		else
			debug.log 'Receiving bytes:', port


		debug.log 'args', readArgs

		readArgs.push (error, data) ->
			callback data
			debug.log 'Received', (Array.prototype.slice.call data, 0)
			debug.log 'ERROR:', error  if error

		unless @fake
			wire[readCmd] readArgs...
		else
			callback()

	write: ( type, port, args... ) ->
		@send CMD[type + '_write'], port, args...


	read: ( type, args... ) ->
		@send CMD[type + '_read'], args...

	relay: ( port, state, callback ) ->

	lastError: ( callback ) ->
		@send CMD.error, =>
			@receive 2, (data) ->
			 	callback data

	ranger: ( port, callback ) ->
		@mode port, MODES.input, =>
			@send CMD.ranger, port, =>
				@receive 2, (data) =>
				 	callback data[1] + data[0]
				 	@lastError (data) -> debug.log data


