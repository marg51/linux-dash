restify = require('restify')
config = require('./config').config

spawn = require('child_process').spawn
fs = require('fs')

cache = {cores:1}

server = restify.createServer 
	name: config.name
	version: config.version

server.use restify.acceptParser(server.acceptable)
server.use restify.queryParser()
server.use restify.bodyParser()

server.get '/hostname.php', (req, res, next) ->
	spawned = spawn('hostname')
	spawned.stdout.on 'data', (data) ->
		res.send data.toString()
	next()

server.get '/issue.php', (req, res, next) ->
	spawned = spawn('/bin/uname', ['-r'])
	spawned.stdout.on 'data', (data) ->
		res.send data.toString()
	next()

spawned = spawn('grep', ['-c','^processor','/proc/cpuinfo'])
spawned.stdout.on 'data', (data) ->
	cache.cores = data.toString()

server.get '/numberofcores.php', (req, res, next) ->
	res.send cache.cores
	next()

server.get '/mem.php', (req, res, next) ->
	spawned = spawn('/usr/bin/free', ['-tmo'])
	awk = spawn('/usr/bin/awk',['{print $1","$2","$3-$6-$7","$4+$6+$7}'])
	spawned.stdout.on 'data', (data) ->
		awk.stdin.write(data)
		awk.stdin.end()
		awk.stdout.on 'data', (awk) ->
			res.send(awk.toString().split('\n')[1])
	next()

server.get '/online.php', (req, res, next) ->
	spawned = spawn('/usr/bin/w', ['-h'])
	awk = spawn('/usr/bin/awk',['{print $1","$3","$4","$5}'])
	spawned.stdout.on 'data', (data) ->
		awk.stdin.write(data)
		awk.stdin.end()
		awk.stdout.on 'data', (awk) ->
			res.send(awk.toString().split('\n').map((el)->el.split(',')))
	next()


server.get '/ps.php', (req, res, next) ->
	spawned = spawn('ps', ['aux'])
	awk = spawn('/usr/bin/awk',['NR>1{print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10","$11}'])
	spawned.stdout.on 'data', (data) ->
		awk.stdin.write(data)
	spawned.stdout.on 'end', ->
		awk.stdin.end()
		awk.stdout.on 'data', (awk) ->
			res.send(awk.toString().split('\n').map((el)->el.split(',')))
	next()


server.get '/speed.php', (req, res, next) ->
	res.send 0
	next()

server.get '/uptime.php', (req, res, next) ->
	spawned = spawn('uptime', [])
	awk = spawn('/usr/bin/awk',['{print $3 $4 $5}'])
	spawned.stdout.on 'data', (data) ->
		awk.stdin.write(data)
		awk.stdin.end()
		awk.stdout.on 'data', (awk) ->
			res.send(awk.toString())
	next()


server.get '/users.php', (req, res, next) ->
	res.send []
	next()

server.get '/whereis.php', (req, res, next) ->
	res.send []
	next()

server.get '/ip.php', (req, res, next) ->
	res.send ""
	next()

server.get '/loadavg.php', (req, res, next) ->
	spawned = spawn('uptime', [])
	spawned.stdout.on 'data', (data) ->
		res.send(data.toString().split(':')[4].trim().replace(/,/g,'').split(' ').map((el)->[el,Math.ceil(el*100/cache.cores)]))

	next()
	
server.get '/df.php', (req, res, next) ->
	spawned = spawn('df', ['-h'])
	awk = spawn('/usr/bin/awk',['{print $1","$2","$3","$4","$5","$6}'])
	spawned.stdout.on 'data', (data) ->
		awk.stdin.write(data)
		awk.stdin.end()
		awk.stdout.on 'data', (awk) ->
			res.send(awk.toString().split('\n').splice(1).map((el)->el.split(',')))
	next()

server.listen config.port, ->
	console.log("serveur démaré sur :#{config.port}")
	