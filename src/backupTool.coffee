DropboxApi = require("./dropboxApi")
Promise = require("bluebird")
fsWalker = require("./fsWalker")
_ = require("lodash")
require("colors")

module.exports =

class BackupTool
	constructor: (@options) ->
		@dropboxApi = new DropboxApi(@options.token)

	sync: =>
		@dropboxApi.getAccountInfo().then ({ usedQuota }) =>
			onRead = (size) => @showReadingState size, usedQuota
			@dropboxApi.on "reading", onRead

			Promise.props
				local: fsWalker @options.from
				remote: @dropboxApi.readDir @options.to
			.then ({ local, remote }) =>
				console.log local
				console.log remote
			.finally =>
				@dropboxApi.removeListener "reading", onRead

	showInfo: =>
		@dropboxApi.getAccountInfo().then (user) =>
			toGiB = (n) => (n / Math.pow(1024, 3)).toFixed 2
			console.log(
				"User information:\n\n".cyan +
				"User ID: #{user.uid}\n" +
				"Name: #{user.name}\n" +
				"Email: #{user.email}\n" +
				"Quota: #{toGiB(user.usedQuota)} GiB / #{toGiB(user.quota)} GiB"
			)

	showReadingState: (size, total) =>
		console.log(
			"Reading remote files:".cyan
			((size / total) * 100).toFixed(2).green + "%".cyan
		)