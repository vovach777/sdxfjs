var SDXF_FLAG_RESERVED   = 0x1;
var SDXF_FLAG_ARRAY      = 0x2;
var SDXF_FLAG_SHORTCHUNK = 0x4;
var SDXF_FLAG_ENCRYPTED  = 0x8;
var SDXF_FLAG_COMPRESSED = 0x10;	

var  SDXF_TYPE_PENDING    = 0; // 0 -- pending structure (chunk is inconsistent, see also 11.1)
var  SDXF_TYPE_STRUCTURE  = 1; // 1 -- structure
var  SDXF_TYPE_BIT_STRING = 2; // 2 -- bit string (binary data)
var  SDXF_TYPE_NUMERIC    = 3; // 3 -- numeric
var  SDXF_TYPE_CHARACTER  = 4; // 4 -- character
var  SDXF_TYPE_FLOAT      = 5; // 5 -- float (ANSI/IEEE 754-1985)
var  SDXF_TYPE_UTF8       = 6; // 6 -- UTF-8
var  SDXF_TYPE_RESERVED   = 7; // 7 -- reserved


 function parseSDXF(buff, options) {
	
	var opt = typeof options === 'object' ? options : {offset : 0, res : {}};
	if (!opt.offset)
	   opt.offset = 0;
	var res = opt.res || {};	
try{
		 
 while (1) {
	if (!Buffer.isBuffer(buff) || (buff.length < 2+1+3))
	   return res;
  	var chunkID =  buff.readUInt16LE(0+opt.offset);
	var flag = buff.readUInt8(2+opt.offset);
	var type = (flag & 0xE0) >> 5; 	
	var length = buff.readUInt(3+opt.offset,3);
	var value = content;
	
		var content = (flag & SDXF_FLAG_SHORTCHUNK) ? null : buff.slice(6+opt.offset,6+opt.offset+length);
		
		if ((content) && (content.length !== length))
				return res;						    
		
		switch (type) {
		case SDXF_TYPE_STRUCTURE:
				value = content ? parseSDXF( content ) : {};
				break;
		case SDXF_TYPE_UTF8:
				value = content ? content.toString() : ''; 
				break;
		case SDXF_TYPE_FLOAT:
				value = content ? content.readDoubleLE(0) : NaN;
				break;
		case SDXF_TYPE_NUMERIC:					
				     value = (content) ? content.readIntLE(0, content.length) : length;  
				break;
		case SDXF_TYPE_BIT_STRING:
				value = content;			  
				break;
		}	
	res[chunkID] = value;
	opt.offset += 6;
	if (content)
	   opt.offset += content.length;
  }
}
catch(e) {
  console.log(e);
}
  return res;  	
} 
module.exports.parseSDXF = parseSDXF;