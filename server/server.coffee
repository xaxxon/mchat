
Meteor.methods
	add_chat: (text)->
		new_chat = { text: text}
		if this.userId
			new_chat.user = this.userId
		else
			new_chat.user = 'anonymous'
		chat_collection.insert new_chat


Meteor.publish "chat", -> 
	chat_collection.find()

Streamy.on "new_chat", (data, socket)->
	sending_user = Streamy.user(socket)
	console.log "Got new chat message from #{sending_user?.username || "anonymous"}: #{data.text}"
	
	Streamy.broadcast "chat", 
		user: sending_user?.username || "anonymous"
		text: data.text


setInterval(
	->Streamy.broadcast "chat", {user: 'pretend_user', text: 'test text from set interval'},
	10000)
	