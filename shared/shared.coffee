@room_collection = new Meteor.Collection "rooms"

# Override Meteor._debug to filter for custom msgs
Meteor._debug = ((super_meteor_debug)->
	(error, info) ->
		if !(info && _.has info, 'msg')
			super_meteor_debug error, info
)(Meteor._debug)

