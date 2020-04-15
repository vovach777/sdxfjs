# sdxfjs
  Structured Data Exchange Format (SDXF)
  RFC 3072 http://www.ietf.org/rfc/rfc3072.txt

```node

var SDXF = require("sdxfjs");
var $ = {
	get_data: 1,
	info_str: 2
};

var s = {
  get_data : {   info_str: "Information" }
}
var ser = new SDXF.Serialize($);
var des = new SDXF.Deserialize($);
ser.pipe(des);
ser.write(s);
ser.end();
des.on('data',_chunk);
function _chunk(data) {
    console.log(data);
}
```
