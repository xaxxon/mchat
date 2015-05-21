
Meteor.methods
	join_room: (room_name)->
		throw new Meteor.Error "Not Logged In", "You must be logged in to join a room" unless @userId
		console.log "#{@userId} trying to join room #{room_name}"
		room_collection.upsert {name: room_name},
			$addToSet: 
				users: 
					user_id: @userId
					user_name: Meteor.user().username
					
	leave_room: (room_name)->
		room_collection.update {name: room_name}, 
			{$pull:	{users: {user_id: Meteor.userId()}}}
			

	add_chat: (room_name, text)->
		console.log "Add chat #{room_name} #{text}"
		room_collection.update {name: room_name},
			$addToSet:
				chat:
					user_id: @userId
					date: Date.now()
					text: text
					id: Random.id()
					

get_users_for_room = (room)->
	room = room_collection.findOne
		name: room
	room.users


Meteor.publish 'my_rooms', ->
	console.log "publishing for user id #{@userId}"
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


Meteor.setInterval (->
	console.log "Checking for old chats #{moment().subtract 10, 'seconds'}"
	
	# Delete stored chat elements older than threshold
	# meteor:PRIMARY> db.rooms.update({}, {$pull: {"chat":{date: {$lt: 1432208317490}}}})
	room_collection.update {},
		$pull:
			chat: 
				date:
					$lt: moment().subtract(10, "seconds").valueOf(),
		{multi: true}
		(error)-> console.log error if error
			
	), 1000
	

			
	


