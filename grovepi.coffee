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

	write: ( type, data, callback ) ->
		switch type
			when 'digital'
				writeCmd = if Array.isArray data then 'writeBytes' else 'writeByte'
				wire[writeCmd] CMD.digital.write, data, ( error ) ->
					callback()
					debug.log "Digital write", CMD.digital.write, data
					debug.log "ERROR:", error if error
			when 'analog'
				wire.writeByte CMD.analog.write, data,  ( error ) ->
					callback()
					debug.log "Analog write", CMD.analog.write, data
					debug.log "ERROR:", error if error
	read: ( type, callback ) ->
		switch type
			when 'digital'
				isBlock = true
				readCmd = if isBlock then 'readBytes' else 'readByte'
				wire.writeBytes CMD.digital.read, 0, ->
					wire[readCmd] (error, data) ->
						callback data
						debug.log "Digital read", CMD.digital.read, data
						debug.log "ERROR:", error if error
			when 'analog'
				wire.writeBytes CMD.analog.read, 0, ->
					wire.readByte (err, data) ->
						callback data
						debug.log "Analog read", CMD.analog.read, data
						debug.log "ERROR:", error if error



	digital:
		write: (bytes, callback) ->
			@write 'digital', bytes, callback
		read: (isBlock, callback) ->
			@read 'digital', callback

	analog:
		write: (byte, callback) ->
			@write 'analog', byte, callback
		read: (callback) ->
			@read 'analog', callback

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

