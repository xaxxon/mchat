
Meteor.methods
	join_room: (room_name, private_room = false, invited_user_names = [])->
		throw new Meteor.Error "Not Logged In", "You must be logged in to join a room" unless @userId
		throw new Meteor.Error "Invalid room name, must start with a-z and contain only a-z and _" unless room_name.match valid_regexes.room_name
		
		
		# check to see if it's a private room and if user is allowed
		room = room_collection.findOne name: room_name
		
		console.log "#{@userId} trying to join room #{room_name}"
		console.log room
		console.log room?.private
		console.log room?.invited_users

		if room? && room.private && room.invited_users.missing @userId
			throw new Meteor.Error "Room is private and you are not invited"
		else
			
			invited_users = _.union get_user_ids_from_user_names(invited_user_names), @userId
			
			room_collection.upsert {name: room_name},
				$addToSet: 
					users: 
						user_id: @userId
						user_name: Meteor.user().username
					invited_users: 
						$each: if private_room then invited_users else []
				$set:
					# keep the room in its current privacy state if it already exists
					private: existing_room?.private or private_room
				{} 
				(error, updated_document_count)-> console.log error; console.log updated_document_count
					
	leave_room: (room_name)->
		room_collection.update {name: room_name}, 
			{$pull:	{users: {user_id: Meteor.userId()}}}
			

	add_chat: (room_id, text)->
		console.log "Add chat #{room_id} #{text}"
		room_collection.update {_id: room_id},
			$addToSet:
				chat:
					user_id: @userId
					username: Meteor.user().username
					date: Date.now()
					text: text
					id: Random.id()
					
	broadcast_chat: (text)->
		console.log "Add chat #{room_id} #{text}"
		room_collection.update {},
			$addToSet:
				chat:
					user_id: @userId
					username: Meteor.user().username
					date: Date.now()
					text: text
					id: Random.id()				
		
		
get_user_ids_from_user_names = (user_names)->
	Meteor.users.find(
		username:
			$in: user_names,
		fields:
			_id: 1).fetch()
		
			
				
is_user_in_room = (user_id, room_name)->
	room_collection.find(
		name: room_name,
		"users.user_id": user_id).count() > 0


get_users_for_room = (room)->
	room = room_collection.findOne
		name: room
	room.users


Meteor.publish 'my_rooms', ->
	room_collection.find({"users.user_id": @userId})
	

UserStatus.events.on "connectionLogout", (fields)->
	user_connection_count = UserStatus.connections.find({userId: fields.userId}).count()
	user_gone fields.userId unless user_connection_count > 0

	

user_gone = (user_id)->
	# figured out this is how to remove a user by playing around in `meteor mongo`
	# > db.rooms.update({},{$pull: {users: {user_id: "mH8qZQmjedRHKAsfj"}}},{multi: true})
	room_collection.update {},
		{$pull:	{users: {user_id: user_id}}},
		{multi: true}


Meteor.startup ->
	console.log "Removing all room info on startup"
	room_collection.remove {}


# Meteor.setInterval (->
	# console.log "Checking for old chats #{moment().subtract 10, 'seconds'}"
	
	# Delete stored chat elements older than threshold
	# meteor:PRIMARY> db.rooms.update({}, {$pull: {"chat":{date: {$lt: 1432208317490}}}})
	# room_collection.update {},
	# 	$pull:
	# 		chat:
	# 			date:
	# 				$lt: moment().subtract(10, "seconds").valueOf(),
	# 	{multi: true}
	# 	(error)-> console.log error if error
	#
	# ), 1000
	

			
	


