var http = require('http');

var server = http.createServer(function(req, res) {
	console.log('---');
	console.log(req.headers);
	console.log('---\n\n');
	res.statusCode = 200;  // OK
    res.end('cheers man');
});


server.listen(8081, function() { console.log("No Auth Server Listening on http://localhost:8081/"); });