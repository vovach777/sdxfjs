var fs = require('fs');
var Writable = require('stream').Writable;
var SDXF = require('./sdxf');
require("util").inherits(LogObject, Writable);

function LogObject(stream, colors) {
      this.console = new console.Console(stream);
      this.colors = colors||false;
      Writable.call(this,{ objectMode: true, decodeStrings: false });      
} 
LogObject.prototype._write = function (chunk, encoding, callback) {
   this.console.dir( chunk, { depth : null, colors : this.colors} );
   callback();   
};


var sample4 = fs.createReadStream('sample5.sdxf');
var deserialize = new SDXF.Deserialize();
var serialize   = new SDXF.Serialize();
var out   =  fs.createWriteStream('sample5.out.sdxf');
var out_js = new LogObject( fs.createWriteStream('sample5.out.sdxf.js') );


sample4.pipe(deserialize).pipe(serialize).pipe(out);
deserialize.pipe(out_js);