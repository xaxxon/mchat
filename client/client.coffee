Accounts.ui.config
  passwordSignupFields: "USERNAME_ONLY"
  
@chat_local_collection = new Mongo.Collection null

Template.Chat.events
	'keypress #new_chat': (event) ->
		if event.which == 13
			console.log "enter pressed"
			text = $('#new_chat').val()
			if text.length > 0
				console.log "sending to server '#{text}'"
				Streamy.emit "new_chat", {text: text}
				# Meteor.call "add_chat", text
				$('#new_chat').val("")
		else
			console.log "something else pressed"


Template.Chat.helpers
	# chat_lines: -> chat_collection.find()
	chat_lines: -> chat_local_collection.find()
	
Template.ChatLine.rendered = ->
	scroll_height = $('#chat').prop 'scrollHeight'
	console.log "Rendered callback called #{scroll_height} #{$('#chat').height()}"
	$('#chat').scrollTop scroll_height - $('#chat').height()
	
Meteor.startup ->
	Meteor.subscribe "chat"

Streamy.on "chat", (data, socket)->
	console.log "Got chat message from server: "
	console.log data
	chat_local_collection.insert data
	