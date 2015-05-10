
Meteor.methods
	join_room: (room_name)->
		throw new Meteor.Error "Not Logged In", "You must be logged in to join a room" unless @userId
		console.log "#{@userId} trying to join room #{room_name}"
		room_collection.upsert {name: room_name},
			$addToSet: 
				users: @userId

Array.prototype.find = (item)->
	return true for current_item in this when current_item = item
	return false

user_socket_map = {}
socket_user_map = {}
verify_connection = (socket)->
	user_id = Streamy.userId(socket)
	throw new Meteor.Error "Logged in", "You must be logged in" unless user_id
	
	console.log "adding userid #{user_id} to socket #{socket}"
	socket_array = user_socket_map[user_id]||[]
	
	# if this socket isn't associated with the user, do that now
	socket_array.push(socket) if socket_array.missing socket
	user_socket_map[user_id] = socket_array	
	
	console.log "user #{user_id} now has #{user_socket_map[user_id].length} sockets"
	
	socket_user_map[socket] = user_id

Meteor.publish 'my_rooms', ->
	room_collection.find()

Streamy.on "command", (data, socket)->
	verify_connection socket
	console.log "Got command"
	

Streamy.on "new_chat", (data, socket)->
	verify_connection socket
	
	Streamy.broadcast "chat",
		user: sending_user?.username || "anonymous"
		text: data.text
		date: new Date().getTime()


# sends a test message every 10 seconds
# setInterval(
# 	->Streamy.broadcast "chat", {user: 'pretend_user', text: 'test text from set interval'},
# 	10000)
	
Streamy.onConnect (socket)->
	console.log "#{socket} connected #{Streamy.userId(socket)}"
	setInterval(
		(->console.log "1s interval:: #{socket} connected #{Streamy.userId(socket)}"), 1000)
	Tracker.autorun ->
		console.log "tracker autorun for streamy socket user id: #{Streamy.userId(socket)}"
		
	

user_gone = (user_id)->
	console.log "user_gone() not implemented yet"


Streamy.onDisconnect (socket)->
	console.log "#{socket} disconnected"
	
	user_id = socket_user_map[socket]
	if user_id
		console.log "Found userid #{user_id} for disconnected socket"
		delete socket_user_map[socket]
		user_socket_map[user_id] = filter_array user_socket_map[user_id], socket
		delete user_socket_map[user_id] if user_socket_map[user_id].length == 0
		console.log "Sockets remaining for user: #{user_socket_map[user_id]?.length || 0}"
		
		# if the user is no longer connected on any socket, then remove them from all chats
		user_gone(user_id) unless user_socket_map[user_id]
	
	else
		console.log "Found no entry in socket_user_map - happens if no stream data was ever sent from a logged in client"


Meteor.startup ->
	# clear out the user socket mapping since there are no users during startup
	room_collection.remove {}
	
