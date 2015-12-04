var SDXF = require("./sdxf");

var  count = 0, from  = Date.now(), $ = {arr:1, root:0}; 
var s = new SDXF.Serialize($);
var d = new SDXF.Deserialize($);
s.pipe(d);
d.on('data',function(data){
    count++;
	setImmediate(_write);	
});

setInterval(_i,1000);
function _i(){	
	console.log( (count / ((Date.now()-from)/1000)) |0);
}

function _write() {   	
   s.write( {root:{arr:[0,1,2,3,4,5,6,7,8,9]}} );
}
setImmediate(_write);
