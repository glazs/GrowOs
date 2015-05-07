util = require 'util'
Mailer = require './mailer'
mailer = new Mailer
module.exports = class Debug
	stateTxt:
		'1': 'On'
		'0': 'Off'
		'true': 'On'
		'false': 'Off'
	constructor: (@mode) ->
	log: (args...) -> console.log new Date, args... if @mode
	dir: (args...) -> console.log util.inspect args..., false, null  if @mode
	mail: (subject, message) -> 
	    mailer.send subject, message