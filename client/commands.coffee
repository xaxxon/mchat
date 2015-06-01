
@handle_command = (command, parameters)->
	
		console.log "command #{command} parameters: #{parameters}"
		console.log parameters
		
		switch command
			when "join"
				make_remote_call "join_room", parameters.split(/\s+/)...
			when "leave"
				make_remote_call "leave_room", parameters.split(/\s+/)...
			when "invite"
				make_remote_call "invite_users", parameters.split(/\s+/)...
			when "addmanager"
				make_remote_call "add_manager", parameters.split(/\s+/)...

		
make_remote_call = (parameters...)->
	Meteor.call parameters..., (error, result)->
		console.log "error calling #{parameters[0]}: #{error}" if error
		console.log "Result from calling #{parameters[0]}: #{result}" unless error