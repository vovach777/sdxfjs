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


 function Reader() {
	 this.buff = new Buffer(0);
	 this.objects = [];
 }
 
 Reader.prototype.sync = function() {
	 this.buff = new Buffer(0);
 }
 
 Reader.prototype.flush = function() {
	 this.buff = new Buffer(0);
	 this.objects = [];
 }
 
 
 Reader.prototype.append = function(data) {
	 this.buff = Buffer.concat([this.buff,data]);
	 var offset = 0;
	while (this.buff.length >= 6) {
	   	   
		//var chunkID =  this.buff.readUInt16LE(0);
		var flag =    this.buff.readUInt8(2);
		var type = (flag & 0xE0) >> 5; 	
		var length = (flag & SDXF_FLAG_SHORTCHUNK) ? 0  : this.buff.readUIntLE(3,3);
		if (this.buff.length < length+6)
		   break;
		
		if (type === SDXF_TYPE_STRUCTURE) {
			 objects.push(
				 parseSDXF(this.buff.slice(0,6+length))
			 );  
		}
	    this.buff=this.buff.slice(6+length);		 	
	}
	return this;	 
 };
 
function parseSDXF(buff) {	
	var res = {};
	var offset = 0;	
	try{		 
		while (buff.length-offset >= 6)  {
			var chunkID =  buff.readUInt16LE(offset);
			offset +=2;
			var flag = buff.readUInt8(offset);
			offset +=1;
			var type = (flag & 0xE0) >> 5; 	
			var length = buff.readUIntLE(offset,3);
			offset +=3;
			var content = null, value;
			if ((flag & SDXF_FLAG_SHORTCHUNK)===0) {
			   content =  buff.slice(offset,offset+length);
			   if (content.length !== length)
						return res;
			   offset += length;
			}
			value = content;														   				
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
		}		
	}
	catch(e) {
		console.log(e);
	}
  	return res;  	
}

function Writer() {
	
}


 
module.exports.parseSDXF = parseSDXF;
module.exports.Reader = Reader;
