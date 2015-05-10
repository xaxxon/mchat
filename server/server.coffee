
Meteor.methods
	join_room: (room_name)->
		throw new Meteor.Error "Not Logged In", "You must be logged in to join a room" unless @userId
		console.log "#{@userId} trying to join room #{room_name}"
		room_collection.upsert {name: room_name},
			$addToSet: 
				users: 
					user_id: @userId
					user_name: Meteor.user().username

Array.prototype.find = (item)->
	return true for current_item in this when current_item = item
	return false

known_user_ids = []
get_sockets_for_users = (user_ids)->
	user_map = {}
	user_map[user_id] = true for user_id in user_ids
	
	sockets = []
	for socket_id, socket of Streamy.sockets()
		sockets.push socket if user_map[Streamy.userId(socket)]
	# console.log "returning #{sockets.length} sockets for #{user_ids.length} users"
	

get_users_for_room = (room)->
	room = room_collection.findOne
		name: room
	room.users

poll_sockets = ->
	users_found = {}
	console.log "There were #{known_user_ids.length} known users from #{Object.keys(Streamy.sockets()).length} sockets"

	for socket_id, socket of Streamy.sockets()
		if (user_id = Streamy.userId(socket)) isnt null
			console.log "User #{user_id} found for socket #{socket_id}"
			users_found[user_id] = true
		else
			console.log "No user found for socket #{socket_id}"
	console.log "Found #{Object.keys(users_found).length} users"

	# call user_gone for any users which no longer have a socket
	for user_id in known_user_ids
		user_gone(user_id) unless users_found[user_id]
	
	known_user_ids = Object.keys users_found
	console.log "There are now #{known_user_ids.length} known users"


setInterval(
	(->poll_sockets()), 1000)


Meteor.publish 'my_rooms', ->
	room_collection.find()
	

Streamy.on "chat", (data, socket)->
	
	return unless data.room and data.text
	
	console.log "Looking up room #{data.room}"
	room_users = get_users_for_room data.room
	console.log "Got #{room_users.length} users in room #{data.room}"
	room_sockets = get_sockets_for_users room_users
	console.log "and #{room_sockets.length} sockets for those users"
	
	Streamy.broadcast "chat",
		user: Streamy.user(socket)?.username || "anonymous"
		text: data.text
		date: new Date().getTime()


# sends a test message every 10 seconds
# setInterval(
# 	->Streamy.broadcast "chat", {user: 'pretend_user', text: 'test text from set interval'},
# 	10000)
	
Streamy.onConnect (socket)->
	console.log "#{socket} connected #{Streamy.userId(socket)}"
		
	

user_gone = (user_id)->
	console.log "user_gone() not implemented yet"


Streamy.onDisconnect (socket)->
	console.log "#{socket} disconnected"
	poll_sockets()


Meteor.startup ->
	# clear out the user socket mapping since there are no users during startup
	room_collection.remove {}
	
