Accounts.ui.config
  passwordSignupFields: "USERNAME_ONLY"
  
@chat_local_collection = new Mongo.Collection null

Template.Chat.events
	'keypress #new_chat': (event) ->
		if event.which == 13
			text = $('#new_chat').val()?.trim()
			
			if results = text.match /[/](\S+)\s*(.*)\s*$/
				console.log "Got command #{results[1]}"
				if results[1] == "join"
					Meteor.call "join_room", results[2]
			else
				if text?.length > 0
					Streamy.emit "chat", {text: text, room: "default"}

			$('#new_chat').val("")
			


Template.MenuBar.events
	'click': -> 
		params = if $('#menubar').hasClass("expanded")
			{width: 20}
		else
			{width: 100}
			
		options = 
			duration: 1000
			easing: "easeInOutCubic"
		# params.effect = 'size'
		# params.duration = 1000
		# params.complete = -> console.log "animation done"
		#
		# console.table params
		# console.log "animating"
		# $('#menubar').effect params
		$('#menubar').animate(params, options).toggleClass("expanded")

Template.Chat.helpers
	chat_lines: -> chat_local_collection.find()
	
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
	Meteor.subscribe "chat"


Streamy.on "chat", (data, socket)->
	chat_local_collection.insert data
	
Template.Logout.events
	'click': -> 
		Meteor.logout() if confirm "You are about to logout."
		false


Tracker.autorun ->
	console.log "In tracker autorun trying to join default room"
	# if Meteor.userId()
		

Meteor.startup ->
	Meteor.subscribe "my_rooms"
	Meteor.call "join_room", "default"
	Meteor.call "join_room", "default2"