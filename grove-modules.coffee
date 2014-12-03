Debug = require './debug'
GrovePI = require './grovepi'

debug = new Debug 0



module.exports = class Modules

	# объявляем тут, чтоб было видно в методах
	wires = 0
	CMD = 0
	controllers = 0


	constructor: (ports) ->

		# Подключаемся к контроллеру
		controllers = ( new GrovePI port, id  for id, port of ports )
		
		@controllers = controllers  if debug.mode

		debug.log 'Init Grove'

		# Та самая всякая хуйня

	#Класс для управления реле
	Relay: class

		controller = controllers[0]

		constructor: (@port) -> 

			if Array.isArray @port
				controller = controllers[ @port[1] ]
				@port = @port[0]

			@state = 0 #TODO: читать состояние по настоящему

			debug.log "Init Relay on port #{@port} of controller #{controller.id}"


		power: (state, callback) -> #Управление питанием реле

			if state?

				if @state isnt state
					@state = state
					bytes = [
						if @state then 1 else 0 # вкл выкл
						0 # хуй знает чо за ноль
					]
					controller.mode @port, 1, =>
						controller.write 'digital', @port, bytes, => # команда, данные, коллбэк
							callback @state  if callback
							debug.log "Relay #{@port} of controller #{controller.id} is #{debug.stateTxt[@state]}"
				else
					callback @state if callback
					debug.log "Relay on port #{@port} of controller #{controller.id} is #{ debug.stateTxt[@state] }. No changes."
			else
				@state

		toggle: -> # Переключение состояния реле на противоположное
			@power  if @state is 1 then 0 else 1


	# Класс для чтения линейки
	Ruler: class 

		controller = controllers[0]

		constructor: (@port) ->

			if Array.isArray @port
				controller = controllers[ @port[1] ]
				@port = @port[0]

			debug.log "Init Ruler on port #{@port} of controller #{controller.id}"
			@ranger = controller.ranger  if debug.mode


		measure: (callback) ->

			controller.ranger @port, (range) =>

				callback range

				debug.log "Range on port #{@port} of controller #{controller.id} is #{range}"
	Dht: class