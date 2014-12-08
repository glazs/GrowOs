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
		subState = 0 # for speed control using relay
		cycleLength = 1/60*3 # for speed control using relay

		constructor: (@config) ->

			fan = new grove.Relay @config.ports.fan
			dht = new grove.Dht @config.ports.dht
			@state = {}

			@time = new Time length: 1 #time for speed control

			@state.power = fan.state
			@state.speed = .3 #TODO remove

			@power = 1 #run fan

			@fan = fan  if debug.mode
			debug.log "Init Air. Fan is #{ debug.stateTxt[@state.power] }"

		controlSpeed: ->
			return  unless @state.power

			minStep = 1/60 * .33 # 1/3s min relay switch time
			delay = cycleLength * @state.speed
			delay = cycleLength - delay unless subState
			delay = Math.max delay, minStep
			@time.delay delay, =>
				subState = !subState
				fan.power subState
				@controlSpeed()


		@property 'power',
			get: -> @state.power
			set: (state) ->
				fan.power state
				@state.power = state
				@controlSpeed()

				debug.log "Fan is #{ debug.stateTxt[@state.power] }"

		@property 'speed',
			get: -> @state.speed
			set: (state) ->
				@state.speed = state

				debug.log "Fan speed is #{ @state.speed * 100 }%"



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

			@time = new Time @config.day

			@flowStart ?= new Date 1 #TODO replace with real data from db
			@ebbStart ?= new Date 1

			@planEbb()

			@pump = pump  if debug.mode
			@ruler = ruler  if debug.mode
			debug.log "Init EbbFlow system #{config.name}. State: #{ STATE[pump.state] }"

		level: (callback) ->
			ruler.measure (value) -> callback value

		planEbb: ->
			fromFlow = @time.from( @flowStart )
			schedule = if @time.is 'day' then @config.schedule.day else @config.schedule.night
			if fromFlow >= schedule.off
				@ebb()
				@planFlow()
			else
				debug.log 'Going to Ebb in ', schedule.off - fromFlow, 'min'
				@time.delay schedule.off - fromFlow, => @planEbb()

		planFlow: ->
			fromEbb = @time.from( @ebbStart )
			schedule = if @time.is 'day' then @config.schedule.day else @config.schedule.night
			if fromEbb >= schedule.on
				@flow()
				@planEbb()
			else
				debug.log 'Going to Flow in ', schedule.on - fromEbb, 'min'
				@time.delay schedule.on - fromEbb, => @planFlow()


		ebb: ->
			@ebbStart = @time.now()
			pump.power 1
			debug.log "EbbFlow system going to #{ STATE[pump.state] }"

		flow: -> 
			@flowStart = @time.now()
			pump.power 0
			debug.log "EbbFlow system going to #{ STATE[pump.state] }"
