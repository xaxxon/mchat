
# Make the Meteor object available to all templates
Template.registerHelper "Meteor", ->Meteor

Accounts.ui.config
  passwordSignupFields: "USERNAME_ONLY"

all_rooms = new Mongo.Collection null


Template.Chat.events
		
	'keypress .new_chat': (event, template) ->~

		# if enter was pressed
		if event.which == 13
			text = $(template.find('.new_chat')).val()?.trim()
			if command_data = text?.match /^[/](\S+)\s*(.*)\s*$/
				handle_command command_data...
						
			else
				if text?.length > 0
					room = @name
					Meteor.call "add_chat", get_active_room(), text unless @client_only

			# clear the text entry
			$('.new_chat').val("")

	
Template.MasterChat.helpers
	joined_rooms: -> all_rooms.find()
	

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
	
	Tracker.autorun ->
		check_valid_active_room()
	
	
	room_collection.find().observeChanges
		added: (id, room)->
			all_rooms.insert(room)
			
			
			# highlight the tab unless it's the current tab (already being looked at)
			# $(".room_button.#{id}").addClass "new_content" if get_active_room() != id && room.chat

		changed: (id, fields)->
			console.log "room_collection changed for ID: then fields:"
			console.log id
			console.table fields
			# # Look backwards for the newest chat we've already cached locally and stop
			# for line in fields.chat or [] by -1
			# 	if local_chat_collections[id].find(id: line.id).count() == 0
			# 		local_chat_collections[id].insert line
			# 		console.log ".room_button.#{id}"
			# 		console.log $(".room_button.#{id}")
			# 		$(".room_button.#{id}").addClass "new_content" unless get_active_room() == id
			# 	else
			# 		break
								

	Tracker.autorun ->
		if Meteor.userId() and Meteor.status().connected
			Meteor.call "join_room", "default"
			
		
		

check_valid_active_room  = () ->
	active_room = get_active_room()	
	
	if !active_room || (!active_room =~ /^>/ && all_rooms.find({active_room}).count() == 0)
		console.log "Setting active room because old active room gone"
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

	

