util = require 'util'
module.exports = class Debug
	stateTxt:
		'1': 'On'
		'0': 'Off'
		'true': 'On'
		'false': 'Off'
	constructor: (@mode) ->
	log: (args...) -> console.log args... if @mode
	dir: (args...) -> console.log util.inspect args..., false, null  if @mode
