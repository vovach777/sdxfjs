var fs = require('fs');
var SDXF = require('./sdxf');

var sample1 = fs.readFileSync('sample4.sdxf');
var opt = {};
var res = new SDXF.Reader();
    res.append( sample1 );
	

var wrt = new SDXF.Writer();
wrt.write(res.objects[0]);
wrt.end();

var rd = new SDXF.Reader();

wrt.on('data', function(chunk){
    rd.append( chunk );
});

wrt.on('end', function() {
   if (JSON.stringify(rd.objects, null,4)===JSON.stringify(res.objects, null,4))
      console.log('passed');    
    else
      console.log('fail');
});