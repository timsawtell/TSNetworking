//to get this module: npm install formidable@latest


var formidable = require('formidable'),
http = require('http'),
util = require('util');


var server = http.createServer(function(req, res) {
    res.writeHead(200, {'content-type': 'application/JSON; charset=ISO-8859-1'});
    res.end('{ "item": { "subitem": "some value", } }');
});


server.listen(8083, function() { console.log("JSON listening on http://localhost:8083/"); });