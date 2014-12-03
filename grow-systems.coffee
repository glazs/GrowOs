Debug = require './debug'
GroveModules = require './grove-modules'
Time = require './time'

debug = new Debug 0

Function::property = (prop, desc) ->
	Object.defineProperty @prototype, prop, desc


module.exports = class GrowSystems

	grove = 0

	constructor: (@grovePiPort) ->

		grove = new GroveModules @grovePiPort

		debug.log 'Init GrowBrain'
		@grove = grove  if debug.mode


	init: (system) => new @[system.type] system


	IndoorLight: class

		lamp = 0

		constructor: (@config) ->

			lamp = new grove.Relay @config.ports.lamp

			@state = lamp.state

			@time = new Time @config.day
			@time.every @config.day.begin, => @power = 1
			@time.every @config.day.end, => @power = 0
			@power = @time.is 'day'

			@lamp = lamp  if debug.mode
			debug.log "Init Light. Light is #{ debug.stateTxt[lamp.state] }"

		@property 'power',
			get: -> @state
			set: (state) ->
				lamp.power state
				@state = state

				debug.log "Light is #{ debug.stateTxt[lamp.state] }"



	IndoorAir: class

		fan = 0
		dht = 0

		constructor: (@config) ->

			fan = new grove.Relay @config.ports.fan
			dht = new grove.Dht @config.ports.dht

			@state = fan.state

			@fan = fan  if debug.mode
			debug.log "Init Air. Fan is #{ debug.stateTxt[fan.state] }"

		power: (state) -> fan.power state



	EbbFlow: class

		pump = 0
		ruler = 0
		STATE = 
			'1': 'Ebb'
			'0': 'Flow'
			'true': 'Ebb'
			'false': 'Flow'
		

		constructor: (@config) ->

			pump = new grove.Relay @config.ports.pump
			ruler = new grove.Ruler @config.ports.ruler  if @config.ports.ruler

			@state = pump.state

			# @time = new Time @config.day
			# @ebb()
			# @time.delay 3/60, =>
			# 	@flow()
			# @time.every @config.day.begin, => @power 1
			# @time.every @config.day.end, => @power 0


			@pump = pump  if debug.mode
			@ruler = ruler  if debug.mode
			debug.log "Init EbbFlow system #{config.name}. State: #{ STATE[pump.state] }"

		level: (callback) ->
			ruler.measure (value) -> callback value

		ebb: ->
			pump.power 1
			debug.log "EbbFlow system going to #{ STATE[pump.state] }"

		flow: -> 
			pump.power 0
			debug.log "EbbFlow system going to #{ STATE[pump.state] }"
