
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
				handle_command command_data[1..]...
						
			else
				if text?.length > 0
					room = @name
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
	username: ->
		result = Meteor.users.findOne @user_id,
			fields: username: 1
		result.username
	time: (time)->
		moment(time).format("HH:mm")


Template.Logout.events
	'click': -> 
		Meteor.logout() if confirm "You are about to logout."

Template.Menubar.helpers
	rooms: -> all_rooms.find()



Template.ActiveRoomButton.events

	'click': (event)->
		set_active_room @_id



Template.ActiveRoomButton.helpers
	active: ->
		if get_active_room() == @_id then 'active' else ''


Meteor.startup ->
	Meteor.subscribe "my_rooms"
	
	all_rooms.insert
		name: "_server"
		users: []
		invited_users: []
		managers: []
		chat: []
	
	
	
	# Keeps local room collection up to date with server-controlled rooms
	room_collection.find().observeChanges
		added: (id, room)->
			room._id = id
			insert_id = all_rooms.insert(room)
			
		changed: (id, fields)->
			if fields.chat?
				all_rooms.update id,
					$addToSet: 
						chat:
							$each: fields.chat,
					{},
					(error, count)-> console.log "observe:changed error #{error}" if error?
							
			if fields.users?
				all_rooms.update id,
					$set: users: fields.users
						
			if fields.invited_users?
				all_rooms.update id,
					$set: invited_users: fields.invited_users
						
			if fields.managers?
				all_rooms.update id,
					$set: managers: fields.managers
				

		removed: (id)->
			all_rooms.remove id
								

	
	Tracker.autorun ->
		if Meteor.userId() and Meteor.status().connected
			Meteor.call "join_room", "common"


	Tracker.autorun ->
		active_room = get_active_room()	
		if !active_room || /^>/ && all_rooms.find(active_room).count() == 0
			set_active_room all_rooms.findOne()?._id



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


Template.RoomUsers.helpers
	managers: ->
		console.log "HI"
		results = Meteor.users.find _id: $in: @managers
		console.log "THERE"
		console.log "#{@name} manager count #{results.count()}"
		results
	connected_users: ->
		results = Meteor.users.find _id: $in: _.difference @users, @managers
		console.log "#{@name} connected users count #{results.count()}"
		results
	invited_users_not_connected: ->
		results = Meteor.users.find _id: $in: _.difference this.invited_users, this.users
		console.log "#{@name} invited users not connected count #{results.count()}"
		results
		
		
Template.RoomUser.helpers
	type: ->
		room = Template.parentData 1
		if room.managers.find @_id
			"manager"
		else if room.users.find @_id
			"user"
		else if room.invited_users.find @_id
			"invited_user"
		else
			console.error "Unknown user not in room data: #{@_id}"
	


