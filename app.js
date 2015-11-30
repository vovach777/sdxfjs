var fs = require('fs');
var SDXF = require('./sdxf');

var sample4 = fs.createReadStream('sample5.sdxf');
var deserialize = new SDXF.Deserialize();
var serialize   = new SDXF.Serialize();
var out   = new fs.createWriteStream('sample5.out.sdxf');

sample4.pipe(deserialize).pipe(serialize).pipe(out);
deserialize.on('data', function(chunk) {
      console.dir( chunk, { depth : null, colors : true} );
});