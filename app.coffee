Debug = require './debug'
GrowSystems = require './grow-systems'
Time = require './time'
fs = require 'fs'


debug = new Debug 0

growConfig = JSON.parse fs.readFileSync 'config.json', 'utf8'



class Grow

	growSystems = 0
	root: {}
	systems = []

	constructor: (@config) ->

		growSystems = new GrowSystems @config.controllers

		@initSystems @config, @root

		if @config.rooms
			@root.rooms = {}
			for room in @config.rooms
				for roomName, roomConfig of room
					roomConfig.day ?= @config.day
					@root.rooms[roomName] = {}
					@initSystems roomConfig, @root.rooms[roomName]

		@growSystems = growSystems if debug.mode
		debug.log 'All Systems initalized'
	initSystems: (config, root) ->
		root.systems = []
		for systemConfig in config.systems
			for systemName, system of systemConfig
				system.day ?= config.day
				root.systems[systemName] = new growSystems.init system
				systems.push root.systems[systemName]
	down = ->
		for system in systems
			system.power = off  if system.power?
		process.exit()


grow = new Grow growConfig


# cleanup on exit
process.stdin.resume()
#do something when app is closing
process.on "exit", grow.down
#catches ctrl+c event
process.on "SIGINT", grow.down
#catches uncaught exceptions
process.on "uncaughtException", grow.down


############### TEST SHIT:

#debug.dir grow.root
###time = new Time {
	begin: 8
	end: 6
	length: 0.0002
}
time.interval 60, ->
	console.log time.now()
	console.log if time.is 'day' then 'day' else 'night'
###
# time = new Time 1/ (24*60)


# time.interval 60, ->
# 	console.log 'x'
# 	console.log time.now()


# setInterval (->
#  	console.log 'x'
#  	console.log time.now()
# ), 1000

if false
	time = new Time

	time.interval 1/60, ->
		grow.root.rooms.CloneRoom.systems.MainWater.level (range) =>
			if 100 > range > 0
				if 2 < range < 10
					pwr = on
				else if 11 < range < 17
					pwr = off
				else return
				grow.root.systems.MainLight.power = pwr
