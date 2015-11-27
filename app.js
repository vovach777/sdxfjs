var fs = require('fs');
var SDXF = require('./sdxf');

var sample1 = fs.readFileSync('sample4.sdxf');
var opt = {};
var res = new SDXF.Reader();
    res.append( sample1 ).append( sample1 );
	

var wrt = new SDXF.Writer();
wrt.write(res.objects.shift());
wrt.end();

var rd = new SDXF.Reader();

wrt.on('data', function(chunk){
    rd.append( chunk );
   //console.log(chunk); 
});

wrt.on('end', function() {
 //  console.dir(rd.objects);
 console.log(JSON.stringify( res, null,4 ));    
});


//console.log(sample1.length);
