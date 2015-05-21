
# Make the Meteor object available to all templates
Template.registerHelper "Meteor", ->Meteor

Accounts.ui.config
  passwordSignupFields: "USERNAME_ONLY"
  
local_chat_collections = {}


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
					Meteor.call "add_chat", Session.get("active_room"), text

			# clear the text entry
			$('.new_chat').val("")

Template.Chat.helpers
	cached_chat: ->
		console.warn "*******In template.chat.helpers, this:"
		console.log this
		local_chat_collections[@_id].find()
	

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
		moment(time).format("HH:mm:ss")
	
Meteor.startup ->
	Meteor.subscribe "chat"; 


Template.Logout.events
	'click': -> 
		Meteor.logout() if confirm "You are about to logout."

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
	active: -> 
		if Session.get('active_room') == @name then 'active' else ''

Meteor.startup ->
	Meteor.subscribe "my_rooms"
	
	room_collection.find().observeChanges
		added: (id, room)->
			console.warn "ObserveChanges added: #{id} for #{room.name}"
			console.log room
			local_chat_collections[id] = new Mongo.Collection null
			local_chat_collections[id].insert line for line in room.chat || []
				
				
		changed: (id, fields)->
			console.warn "ObserveChanges changed: #{id}"
			console.log fields
			for line in fields.chat by -1
				if local_chat_collections[id].find(id: line.id).count() == 0
					local_chat_collections[id].insert line
				else
					break

	Tracker.autorun ->
		console.log "in tracker autorun checking for login"
		console.log Meteor.userId()
		if Meteor.userId() and Meteor.status().connected
			console.log "logged in and connected"
			Meteor.call "join_room", "default"
			Meteor.call "join_room", "default2"
			Session.set("active_room", "default")
		
		else
			console.log "not logged in"
		
		
	Tracker.autorun ->
		console.error "Checking for active room" 
		if room_collection.findOne() && room_collection.find({name: Session.get("active_room")}).count() == 0
			console.log "active room missing"
			Session.set("active_room", room_collection.findOne().name)
		else
			console.log "Active room still exists"
	
Template.Room.helpers
	active: -> console.log "Room helpers: ";console.log(this); console.log Session.get "active_room"; if Session.get("active_room") == @name then 'active' else ''
	

