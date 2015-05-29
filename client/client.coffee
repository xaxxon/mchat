
# Make the Meteor object available to all templates
Template.registerHelper "Meteor", ->Meteor

Accounts.ui.config
  passwordSignupFields: "USERNAME_ONLY"

@all_rooms = new Mongo.Collection null


Template.Chat.events

	'keypress .new_chat': (event, template) ->

		# if enter was pressed
		if event.which == 13
			text = $(template.find('.new_chat')).val()?.trim()
			if command_data = text?.match /^[/](\S+)\s*(.*)\s*$/
				console.log "command #{command_data[1]} with parameters #{command_data[2]}"
				handle_command command_data[1..]...
						
			else
				if text?.length > 0
					room = @name
					console.log "add chat called"
					Meteor.call "add_chat", get_active_room(), text unless @client_only

			# clear the text entry
			$('.new_chat').val("")
			
	'click': (event, template)->
		template.$(".new_chat").focus()

	
Template.Rooms.helpers
	rooms: -> all_rooms.find()
	

# This should move into a Tracker.afterFlush, most likely	
Template.ChatLine.rendered = ->
	scroll_height = $('#chat').prop 'scrollHeight'
	$('#chat').scrollTop scroll_height - $('#chat').height()
	
Template.ChatLine.helpers
	time: (time)->
		moment(time).format("HH:mm")


Template.Logout.events
	'click': -> 
		Meteor.logout() if confirm "You are about to logout."

Template.Menubar.helpers
	rooms: -> all_rooms.find()



Template.ActiveRoomButton.events

	'click': (event)->
		console.log "setting active room to #{@_id}"
		set_active_room @_id



Template.ActiveRoomButton.helpers
	active: ->
		# console.log "Comparing #{get_active_room()} and #{@_id}"
		if get_active_room() == @_id then 'active' else ''


Meteor.startup ->
	Meteor.subscribe "my_rooms"
	
	all_rooms.insert
		name: "_server",
		users: []
		invited_users: [],
		chat: []
	
	
	
	
	room_collection.find().observeChanges
		added: (id, room)->
			console.log "added room:"
			room._id = id
			console.log room
			insert_id = all_rooms.insert(room)
			console.log "local collection insert id: #{insert_id}"
			
			
			# highlight the tab unless it's the current tab (already being looked at)
			# $(".room_button.#{id}").addClass "new_content" if get_active_room() != id && room.chat

		changed: (id, fields)->
			console.log "room_collection changed for ID: then fields:"
			console.log id
			console.log fields
			if fields.chat?
				all_rooms.update id,
					$addToSet: 
						chat:
							$each: fields.chat,
					{},
					(error, count)-> console.log "observe:changed error #{error}, count #{count}"
							
			if fields.users?
				all_rooms.update id,
					$set:
						users: fields.users
				
			console.log all_rooms.findOne(id).chat
		
		removed: (id)->
			all_rooms.remove id
								

	Tracker.autorun ->
		if Meteor.userId() and Meteor.status().connected
			Meteor.call "join_room", "default"

		

	

get_active_room = ->
	Session.get "active_room"	
	
set_active_room = (id)->
	Session.set("active_room", id)
	$(".room_button.#{id}").removeClass "new_content"
	Tracker.afterFlush ->$("##{id} .new_chat").focus()
	
Tracker.autorun ->
	active_room = get_active_room()	
	if !active_room || /^>/ && all_rooms.find(active_room).count() == 0
		set_active_room all_rooms.findOne()?._id


Template.Room.helpers
	# sets the active class on the room so it is the room that is shown to the user
	log: ->
		console.log "Template.Room.helpers this:"
		console.log this
		""
	active: -> 
		if get_active_room() == @_id then 'active' else ''

Template.RoomUsers.helpers
	log: ->
		console.log "Template.Roomusers.helpers this:"
		console.log this
		""
	connected_users: ->
		this.users
		
	invited_users_not_connected: ->
		results = _.difference this.invited_users, this.users
		
		console.log results
		results

Template.RoomUser.helpers
	log: ->
		console.log "Template.RoomUser.helpers this:"
		console.log this
	user_status: (user_status)->
		console.log "Room user helper this:"
		console.log this
		user_status
	user_name: ->this.user_name


