var fs = require('fs');
var SDXF = require('./sdxf');

var sample1 = fs.readFileSync('sample3.sdxf');
var opt = {};
var res = new SDXF.Reader();
    res.append( sample1 );
	

//console.log(JSON.stringify( res, null,4 ));
console.dir(res.objects);
