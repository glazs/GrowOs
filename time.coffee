Debug = require './debug'
debug = new Debug 0



module.exports = class Time

	constructor: (@config = {}) ->
		@factor = @config.length or 1
		@from = @config.start or new Date

	delay: (min, callback) ->
		setTimeout callback, Math.round min * 1000*60 * @factor

	interval: (min, callback) ->
		callback()
		setInterval callback, Math.round min * 1000*60 * @factor

	on: (hour, callback) ->
		now = @now()
		hoursToStart = hour - now.getHours()
		hoursToStart = hoursToStart + 24  if hoursToStart < 0
		min = hoursToStart * 60 - now.getMinutes()
		@delay  min, callback

	every: (hour, callback) ->
		@on hour, =>
			@interval 24 * 60, callback

	elapsed: ->
		new Date 1 / @factor * (
			(new Date).getTime() - @from.getTime()
		)

	now: ->
		new Date @from.getTime() + @elapsed().getTime()
	is: (daytime) ->
		hours = @now()
		hours = hours.getHours() + hours.getMinutes() / 60
		begin = @config.begin
		end = @config.end
		#console.log begin, hours, end
		if begin > end
			begin -= 24
		isDay = begin < hours < end
		if daytime is 'day' then isDay else not isDay


