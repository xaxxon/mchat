@room_collection = new Meteor.Collection "rooms"

# Override Meteor._debug to filter for custom msgs
Meteor._debug = ((super_meteor_debug)->
	(error, info) ->
		if !(info && _.has info, 'msg')
			super_meteor_debug error, info
)(Meteor._debug)


# add some helpers on array
Array.prototype.empty = ->
  this.length == 0

# this should go away because es6 has a find method on array but I can't use it yet
Array.prototype.find = (item)->
  !(item for current_item in this when current_item == item).empty()

Array.prototype.missing = (item)-> !this.find(item)

@filter_array = (array, item)->
	(i for i in array when i != item)