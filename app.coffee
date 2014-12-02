Debug = require './debug'
GrowSystems = require './grow-systems'
Time = require './time'
fs = require 'fs'


debug = new Debug 1

growConfig = JSON.parse fs.readFileSync 'config.json', 'utf8'



class Grow

	growSystems = 0
	root: {}

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


grow = new Grow growConfig




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

if true
	time = new Time

	time.interval 1/60, ->
		grow.root.rooms.CloneRoom.systems.MainWater.level (range) =>
			console.log range
			if 100 > range > 0
				if 2 < range < 10
					pwr = on
				else if 15 < range < 20
					pwr = off
				else return
				grow.root.systems.MainLight.power pwr
