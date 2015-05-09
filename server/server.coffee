
Meteor.methods
	join_room: (room_name)->
		throw new Meteor.Error "Not Logged In", "You must be logged in to join a room" unless @userId
		console.log "#{@userId} trying to join room #{room_name}"
		room_collection.upsert {name: room_name},
			$addToSet: 
				users: @userId

		
Streamy.on "new_chat", (data, socket)->
	sending_user = Streamy.user(socket)
	# ￿ "Got new chat message from #{sending_user?.username || "anonymous"}: #{data.text}"
	
	Streamy.broadcast "chat",
		user: sending_user?.username || "anonymous"
		text: data.text
		date: new Date().getTime()


# sends a test message every 10 seconds
# setInterval(
# 	->Streamy.broadcast "chat", {user: 'pretend_user', text: 'test text from set interval'},
# 	10000)
	