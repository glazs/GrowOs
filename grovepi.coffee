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

	analog:
		write: (byte, callback) ->
			wire.writeByte CMD.analog.write, byte, callback
		read: (callback) ->
			wire.writeBytes CMD.analog.read, 0, ->
				wire.readByte (err, byte) -> callback byte

	digital:
		write: (bytes, callback) ->
			writeCmd = if Array.isArray bytes then 'writeBytes' else 'writeByte'
			wire[writeCmd] CMD.digital.write, bytes, ( error ) ->
				callback()
				debug.log "Digital write", CMD.digital.write, bytes
				debug.log "ERROR:", error if error
		read: (isBlock, callback) ->
			readCmd = if isBlock then 'readBytes' else 'readByte'
			wire.writeBytes CMD.digital.read, 0, ->
				wire[readCmd] (err, byte) -> callback byte
				debug.log "Digital read", CMD.digital.read, byte

	input: (callback) ->
		wire.writeByte CMD.mode, 0, -> # Switch to input
			callback() # Do what you want
			wire.writeByte CMD.mode, 1, -> # Switch to output

	ranger: ( port, callback ) ->
		wire.writeBytes CMD.ranger, [port,0,0], ->
			wire.readBytes port, 3, (err, value) ->
				callback value[2] + value[1]

	# getinfo: ( callback ) ->
	# 	wire.writeBytes 50, [0, 0, 0] ->
	# 		wire.readByte ( err, byte ) -> callback byte

