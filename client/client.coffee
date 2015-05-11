Accounts.ui.config
  passwordSignupFields: "USERNAME_ONLY"
  

Template.Chat.events
	'keypress .new_chat': (event, template) ->

		if event.which == 13
			console.log "In new chat event, this: "
			console.log this
			text = $(template.find('.new_chat')).val()?.trim()
			console.log "Got new chat: #{text}"
			
			if results = text?.match /[/](\S+)\s*(.*)\s*$/
				console.log "Got command #{results[1]}"
				if results[1] == "join"
					Meteor.call "join_room", results[2]
			else
				if text?.length > 0
					room = @name
					Streamy.emit "chat", {text: text, room: @name}

			$('.new_chat').val("")



# Template.Menubar.events
# 	'click': ->
# 		params = if $('#menubar').hasClass("expanded")
# 			{width: 20}
# 		else
# 			{width: 100}
#
# 		options =
# 			duration: 1000
# 			easing: "easeInOutCubic"
#
# 		$('#menubar').animate(params, options).toggleClass("expanded")

# Need to remove from this at some point
chat_collections = {}
Template.Chat.helpers
	chat_lines: -> chat_collections[@name] ||= new Meteor.Collection null; chat_collections[@name].find()
	
Template.MasterChat.helpers
	joined_rooms: -> room_collection.find()
	
Template.RoomUsers.helpers
	users: -> 
		console.log this
		users = []
		users.push {name: user.user_name} for user in @users
		users
	
Template.ChatLine.rendered = ->
	scroll_height = $('#chat').prop 'scrollHeight'
	$('#chat').scrollTop scroll_height - $('#chat').height()
	
Template.ChatLine.helpers
	time: (time)->
		moment(time).format("HH:mm")
	
Meteor.startup ->
	Meteor.subscribe "chat"; 


Streamy.on "chat", (data, socket)->
	console.log "got chat message for #{data.room}:"
	console.log data
	chat_collections[data.room].insert data
	
Template.Logout.events
	'click': -> 
		Meteor.logout() if confirm "You are about to logout."
		fal

Template.Menubar.helpers
	rooms: -> room_collection.find();

	

Template.ActiveRoomButton.events
	'click .leave': (event)-> 
		console.log "leave button"
		console.log event
		event.stopImmediatePropagation()
		Meteor.call "leave_room", @name
	'click': (event)-> 

		console.log "setting active room to #{@name}"
		console.log event
		Session.set("active_room", @name)
	
Template.ActiveRoomButton.helpers
	active: -> console.log "activeroombutton helper this:"; console.log this; if Session.get('active_room') == @name then 'active' else ''
	
	

Tracker.autorun ->
	console.log "In tracker autorun trying to join default room"
	# if Meteor.userId()
		

Meteor.startup ->
	Meteor.subscribe "my_rooms"
	Meteor.call "join_room", "default"
	
Template.Room.helpers
	active: -> console.log "Room helpers: ";console.log(this); console.log Session.get "active_room"; if Session.get("active_room") == @name then 'active' else ''
	

Tracker.autorun ->
	console.log "in tracker autorun checking for login"
	console.log Meteor.userId()
	if Meteor.userId()
		console.log "logged in"
		Meteor.call "join_room", "default"
		Meteor.call "join_room", "default2"
		Session.set("active_room", "default")
		
	else
		console.log "not logged in"
		