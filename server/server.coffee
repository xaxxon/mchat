		


Meteor.methods
	join_room: (room_name, make_private = false)->
		throw new Meteor.Error "Not Logged In", "You must be logged in to join a room" unless @userId
		throw new Meteor.Error "No room name specified" unless room_name?
		throw new Meteor.Error "Invalid room name, must start with a-z and contain only a-z and _" unless room_name.match valid_regexes.room_name

		# check to see if it's a private room and if user is allowed
		room = room_collection.findOne name: room_name
		
		throw new Meteor.Error "Cannot make an existing room private" if room? and make_private
		
		if room? && room.private && room.invited_users.missing @userId
			throw new Meteor.Error "Room is private and you are not invited"
		else			
			room_collection.upsert {name: room_name},
				$addToSet: 
					users: @userId
					managers: if room? then undefined else @userId
				$set:	
					private: make_private
					invited_users: []
					locked: false
				{} 
				(error, updated_document_count)-> console.log error; console.log updated_document_count
			
			
	set_room_private: (room_name, make_private)->
		unless room_collection.find(name: room_name).locked
			room_collection.update {name: room_name},
				$set: private: make_private
			
	
	leave_room: (room_name)->
		room_collection.update {name: room_name},
			$pull: users: Meteor.userId()
			
			
	invite_users: (room_name, user_name_list...)->
		user_id_list = get_user_ids_from_user_names user_name_list
		room_collection.update name: room_name,
			$addToSet: invited_users: $each: user_id_list,
			{},
			(error,count)-> console.log "error/count #{error} #{count}"
			
			
	add_managers: (room_name, user_ids...)->
		room_collection name: room_name
			$addToSet: managers: $each: user_ids
			
			
	remove_managers: (room_name, user_ids...)->
		room_collection name: room_name
			$pull: managers: $each: user_ids
			

	add_chat: (room_id, text)->
		room_collection.update {_id: room_id},
			$addToSet:
				chat:
					user_id: @userId
					date: Date.now()
					text: text
					id: Random.id(),
			{},
			(error, count)->
				console.log "add chat results error: #{error}" if error?n
					
					
	broadcast_chat: (text)->
		room_collection.update {},
			$addToSet:
				chat:
					user_id: @userId
					date: Date.now()
					text: text
					id: Random.id()


get_user_ids_from_user_names = (user_names)->
	results = Meteor.users.find({
		username:
			$in: user_names},
		fields:
			_id: 1).fetch()
	(user._id for user in results)
		


Meteor.publishComposite "my_rooms",
	find: ->
		room_collection.find "users": @userId
	children: [
		{find: (room)->
			combined_users = _.union room.users, room.invited_users, room.managers
			Meteor.users.find {_id: $in: combined_users}, fields: {_id: 1, username: 1}}
	]
		
	
	

UserStatus.events.on "connectionLogout", (fields)->
	user_connection_count = UserStatus.connections.find({userId: fields.userId}).count()
	user_gone fields.userId unless user_connection_count > 0

	

user_gone = (user_id)->
	# figured out this is how to remove a user by playing around in `meteor mongo`
	# > db.rooms.update({},{$pull: {users: {user_id: "mH8qZQmjedRHKAsfj"}}},{multi: true})
	room_collection.update {},
		{$pull:	{users: user_id}},
		{multi: true}


Meteor.startup ->
	console.log "Removing all room info"
	room_collection.remove {}
	unless Meteor.users.find(username: "admin").count() == 1 
		console.log "Creating admin user with default password"
		Accounts.createUser username: "admin", password: "admin"

	Meteor.users.update username: "admin",
		$set: admin: true,
		{},
		(error, count)->console.log "adding admin flag to admin user #{error} #{count}"
		
	room_collection.insert
		name: "common"
		private: false
		locked: true
		users: []
		managers: []
		invited_users: []
		


Meteor.setInterval (->
	# console.log "Checking for old chats #{moment().subtract 10, 'seconds'}"

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


			
	


