
# Make the Meteor object available to all templates
Template.registerHelper "Meteor", ->Meteor

Accounts.ui.config
  passwordSignupFields: "USERNAME_ONLY"

# Local collections for storing chat for each room even after the server deletes them
local_chat_collections = {"_connection": new Mongo.Collection null}


Template.Chat.events
		
	'keypress .new_chat': (event, template) ->

		# if enter was pressed
		if event.which == 13
			text = $(template.find('.new_chat')).val()?.trim()
			
			if results = text?.match /[/](\S+)\s*(.*)\s*$/
				if results[1] == "join"
					Meteor.call "join_room", results[2]
			else
				if text?.length > 0
					room = @name
					Meteor.call "add_chat", get_active_room(), text unless @client_only

			# clear the text entry
			$('.new_chat').val("")


Template.Chat.helpers
	cached_chat: ->
		local_chat_collections[@_id].find()	
		

	
Template.MasterChat.helpers
	joined_rooms: -> room_collection.find()
	server_connection: ->
		_id: "_connection"
		name: "_connection"
		client_only: true
		
	
Template.RoomUsers.helpers
	users: -> 
		{name: user.user_name} for user in @users if @users
	
	
Template.ChatLine.rendered = ->
	scroll_height = $('#chat').prop 'scrollHeight'
	$('#chat').scrollTop scroll_height - $('#chat').height()
	
Template.ChatLine.helpers
	time: (time)->
		moment(time).format("HH:mm")
	
Meteor.startup ->
	Meteor.subscribe "chat"; 


Template.Logout.events
	'click': -> 
		Meteor.logout() if confirm "You are about to logout."

Template.Menubar.helpers
	rooms: -> room_collection.find()
	server_connection: ->
		name: "_connection"
		_id: "_connection"



Template.ActiveRoomButton.events
	# 'click .leave': (event)->
	# 	event.stopImmediatePropagation()
	# 	Meteor.call "leave_room", @name

	'click': (event)->
		console.log "setting active room to #{@_id}"
		set_active_room @_id



Template.ActiveRoomButton.helpers
	active: ->
		# console.log "Comparing #{get_active_room()} and #{@_id}"
		if get_active_room() == @_id then 'active' else ''

Meteor.startup ->
	
	Tracker.autorun ->
		check_valid_active_room()
	
	Meteor.subscribe "my_rooms"
	
	room_collection.find().observeChanges
		added: (id, room)->
			local_chat_collections[id] = new Mongo.Collection null
			local_chat_collections[id].insert line for line in room.chat || []
			console.log ".room_button.#{id}"
			console.log $(".room_button.#{id}")
			
			# highlight the tab unless it's the current tab (already being looked at)
			$(".room_button.#{id}").addClass "new_content" unless get_active_room() == id

		changed: (id, fields)->
			# Look backwards for the newest chat we've already cached locally and stop
			for line in fields.chat or [] by -1
				if local_chat_collections[id].find(id: line.id).count() == 0
					local_chat_collections[id].insert line
					console.log ".room_button.#{id}"
					console.log $(".room_button.#{id}")
					$(".room_button.#{id}").addClass "new_content" unless get_active_room() == id
				else
					break
					
		removed: ->
			

	Tracker.autorun ->
		if Meteor.userId() and Meteor.status().connected
			try
				Meteor.call "join_room", "default"
				Meteor.call "join_room", "default_two", true
			catch
				console.log "Exception thrown while trying to join default rooms"
		
		
		

check_valid_active_room  = () ->
	active_room = get_active_room()	
	
	if !active_room || (!active_room =~ /^>/ && room_collection.find({active_room}).count() == 0)
		console.log "Setting active room because old active room gone"
		set_active_room room_collection.findOne()?._id
	

	
get_active_room = ->
	Session.get "active_room"	
	
set_active_room = (id)->
	Session.set("active_room", id)
	$(".room_button.#{id}").removeClass "new_content"
	Tracker.afterFlush ->$("##{id} .new_chat").focus()
	


Template.Room.helpers

	# sets the active class on the room so it is the room that is shown to the user
	active: -> 
		if get_active_room() == @_id then 'active' else ''

	

