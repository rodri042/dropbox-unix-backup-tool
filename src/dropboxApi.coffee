Dropbox = require("dropbox-fixed")
Promise = require("bluebird")
{ EventEmitter } = require("events")
_ = require("lodash")

module.exports =

class DropboxApi extends EventEmitter
	constructor: (token) ->
		@client = Promise.promisifyAll new Dropbox.Client { token }

	readDir: (path, tail = { changes: [] }) =>
		@client.deltaAsync(tail.cursorTag, pathPrefix: path)
			.catch (e) => throw "Error reading the remote directory #{path}."
			.then (delta) =>
				delta.changes = tail.changes.concat delta.changes
				@emit "reading", _.sum delta.changes, "stat.size"

				if delta.shouldPullAgain
					@readDir path, delta
				else
					_(delta.changes)
						.map (change) => change.stat
						.filter isFile: true
						.map (stats) => @_makeStats path, stats
						.value()

	getAccountInfo: =>
		@client.getAccountInfoAsync()
			.spread (user) => user
			.catch => throw "Error retrieving the user info."

	_makeStats: (path, stats) =>
		_.assign _.pick(
			stats
			"path", "name"
			"size", "clientModifiedAt"
		), path: stats.path.replace path, ""
