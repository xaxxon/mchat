
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

Meteor.publish "custom", ->
	
