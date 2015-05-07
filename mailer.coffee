#Debug = require './debug'
#debug = new Debug 1

module.exports = class Mailer
    
	constructor: () ->
		@mailer = require 'nodemailer'
		@transporter = @mailer.createTransport
			service: 'Gmail'
			auth:
				user: 'mailer@rock.su'
				pass: 'pw4mailer'

		@baseEmail = 
			from: 'Local game server <mailer@rock.su>'
			to: 'admin@rock.su, fil@rock.su'
		@send 'System is up'
		
	send: ( subject, message, callback ) ->
		console.log 'Sending email...'
		@baseEmail.text = message or '..?'
		@baseEmail.subject = 'GameServer: ' + ( subject or '...' ) + ' | ' + new Date
		@transporter.sendMail @baseEmail, (error, info) ->
			if error
				console.log 'Send email error: ', error
			else
				console.log 'Message sent: ' + info.response
			callback() if callback
		
