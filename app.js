var fs = require('fs');
var parseSDXF = require('./sdxf').parseSDXF;

var sample1 = fs.readFileSync('sample2.sdxf');
var opt = {};
var res = parseSDXF(sample1, opt);

//console.log(JSON.stringify( res, null,4 ));
console.dir(res);
console.dir(opt)
console.log(sample1.length);