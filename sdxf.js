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


 function Parser($) {
	 this.$ = $;
	 this.buff = new Buffer(0);
	 this.objects = [];
 }
 
 Parser.prototype.sync = function() {
	 this.buff = new Buffer(0);
 };
 
 Parser.prototype.flush = function() {
	 this.buff = new Buffer(0);
	 this.objects = [];
 };
 
 
 function s4( num ) {	 
	 return ('0000000' +(num||0).toString(16)).slice(-8);
 }
 function s6( num ) {	 
	 return ('00000000000' +(num||0).toString(16)).slice(-12);
 }
function s2( num ) {
	 return ('000' + (num||0).toString(16)).slice(-4);
 }
  
 Parser.prototype.append = function(data) {
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
			 this.objects.push(
				 parseSDXF(this.buff.slice(0,6+length),this.$)
			 );  
		}
	    this.buff=this.buff.slice(6+length);		 	
	}
	return this;	 
 };
 
function parseSDXF(buff,$) {	
	var res = {};
	var offset = 0;
	if ($) index($);	
	try{		 
		while (buff.length-offset >= 6)  {
			var chunkID =  buff.readUInt16LE(offset);
			if ($ && $.$ && $.$.hasOwnProperty(chunkID))
			 	chunkID = $.$[chunkID]; 			
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
						value = content ? parseSDXF( content,$ ) : {};
						break;
				case SDXF_TYPE_UTF8:
						if (content) {
							if (flag & SDXF_FLAG_COMPRESSED) {
								value = '{'+	
										s4(content.readUInt32LE(0,true))+'-'+ //D1
										s2(content.readUInt16LE(4,true))+'-'+ //D2
										s2(content.readUInt16LE(6,true))+'-'+ //D3
										s2(content.readUInt16LE(8,true))+'-'+ //D4:2
										s6(content.readUIntBE(10,6,true))+ //D4:6
										'}';
							}
							else
							  value = content.toString();
						}
						else 
						  value = '';				
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
			if (res.hasOwnProperty(chunkID)) {
				if (Array.isArray(res[chunkID])) {
					res[chunkID].push(value); 
				} else {
					res[chunkID] = [res[chunkID],value];
				}				
			} else
			  res[chunkID] = value;  					
		}		
	}
	catch(e) {
		console.log(e);
	}
  	return res;  	
}

var Transform = require('stream').Transform;
var Writable  = require('stream').Writable;
var inherits  = require("util").inherits;
inherits(Serialize, Transform);
inherits(Deserialize, Transform);
inherits(LogObject, Writable);


function Serialize($) {
	this.$ = $;
	Transform.call(this,{ objectMode: true, decodeStrings: false });
}

Serialize.prototype._transform = function (chunk, encoding, callback) {
	var data = new Buffer( getBufferFor(chunk, this.$) );
	if (data.length > 0) {
		objectToSDXF(chunk, data, this.$);
		callback(null,data);	 
	}
};

function getBufferFor(obj,$) {
	var res=0;
	Object.keys(obj).forEach(_k);
	function _k(key) {
		var	value = obj[key];
		if ($ && $.hasOwnProperty(key)) {
			key = $[key];//map key 
		} else {
			key = Number(key);
			if (!(Number.isInteger(key) && (key >= 0) && (key <= 0xffff)))
			return; //ignore	
		}
		kv(key,value);		
	}
    function kv(key,value) {
		var tmp
		if (value == null)
		   return;		
	 	if (Buffer.isBuffer(value)) {			 
			tmp = (value.length > 0xffffff) ? 0xffffff : value.length; 
			res += 6+tmp;
		 } 
		else if (typeof value === 'string') {
			tmp = Buffer.byteLength(value);
			if (tmp > 0xffffff)
			     tmp = 0xffffff;			    			
			res += 6+tmp;
		}
		else if (typeof value === 'object') {
			if (Array.isArray(value)) {
			    value.forEach(function(element) {
					kv(key, element);
				});  	
			} else {
			tmp = getBufferFor(value,$);
			if (tmp > 0)
		       res += 6+tmp;
			}
		}
		else if (typeof value === 'number') {
			if ( Number.isInteger(value)) {
				if ( (value >= 0) && (value <= 0xffffff) ) 
			    	res += 6;
				else
				if ((value >= -2147483648) && (value <= 2147483647) ) 
					res += 6+4;
				else
					res += 6+8;
			} else
			 res += 6+8;
		}
		else if (value === true) 
				res += 6;
		else if (value === false)
				res += 6;				 
	}
	return res;
}


function objectToSDXF(obj,buff,$) {
	var offset = 0, tmp;
	
    Object.keys(obj).forEach(_k);
	
	function _k(key) {
		var value = obj[key];
		if ($ && $.hasOwnProperty(key)) {
			key = $[key];//map key 
		} else {		
			key = Number(key);
			if (!(Number.isInteger(key) && (key >= 0) && (key <= 0xffff)))
				return; //ignore
		}		
		_kv(key,value);
	}
	
    function _kv(key,value) {
		
		if (value == null)
		  return;
		if (value === true)
		    value = 1;
		else if (value === false)
		    value = 0;  
	 	if (Buffer.isBuffer(value)) {
			tmp =  (value.length > 0xffffff) ? 0xffffff : value.length; 			
			buff.writeUInt16LE(key,offset,2); offset+=2;
			buff.writeUInt8((SDXF_TYPE_BIT_STRING<<5),offset ); offset+=1;
			buff.writeUIntLE(tmp,offset,3); offset+=3;
			value.copy(buff,offset,0,tmp); offset+=tmp;			
		 } 
		else if (typeof value === 'string') {
		//	res += 6+Buffer.byteLength(value);
			buff.writeUInt16LE(key,offset,2); offset+=2;
			buff.writeUInt8((SDXF_TYPE_UTF8<<5),offset ); offset+=1;
			tmp = Buffer.byteLength(value);
			if (tmp > 0xffffff)
			     tmp = 0xffffff;			    						
			buff.writeUIntLE(tmp, offset,3);offset+=3;			
			buff.write(value,offset,tmp); offset+=tmp;			
		}
		else if (typeof value === 'object'){
			if (Array.isArray(value)) {
				value.forEach(function(element) {
				    _kv(key, element);	
				});				
			} else {
				tmp = objectToSDXF(value, buff.slice(offset+6),$);
				if (tmp > 0) {
					buff.writeUInt16LE(key,offset,2); offset+=2;
					buff.writeUInt8(SDXF_TYPE_STRUCTURE<<5, offset); offset+=1;
					buff.writeIntLE(tmp,offset,3); offset+=3;
					offset += tmp;
			}}
		}
		else if (typeof value == 'number') {
			buff.writeUInt16LE(key,offset,2); offset+=2;
			if ( Number.isInteger(value)) {
    							
				if ( (value >= 0) && (value <= 0xffffff) ){
				   buff.writeUInt8((SDXF_TYPE_NUMERIC<<5)|SDXF_FLAG_SHORTCHUNK,offset ); offset+=1;
				   buff.writeUIntLE(value,offset,3); offset+=3;
				} 			    	
				else
				if ((value >= -2147483648) && (value <= 2147483647) ) {
					buff.writeUInt8(SDXF_TYPE_NUMERIC<<5,offset ); offset+=1;
					buff.writeIntLE(4,offset,3); offset+=3;
					buff.writeInt32LE(value,offset); offset+=4; 
				}
				else {
					buff.writeUInt8(SDXF_TYPE_NUMERIC<<5,offset ); offset+=1;
					buff.writeIntLE(8,offset,3); offset+=3;
					buff.writeIntLE(value,offset,8); offset+=8; 					
				}
			} else {			
					buff.writeUInt8(SDXF_TYPE_FLOAT<<5,offset ); offset+=1;
					buff.writeIntLE(8,offset,3); offset+=3;
					buff.writeDoubleLE(value,offset); offset+=8; 								 
			}
		}
	}
	return offset;	  
}

function Deserialize($) {
	Transform.call(this,{ objectMode: true, decodeStrings: false });
	this.parser = new Parser($);
}

Deserialize.prototype._transform = function (chunk, encoding, callback) {
	this.parser.append(chunk);
	var data;
	while (data=this.parser.objects.shift(), data) {
		this.push(data);  	 
	}
	callback();	
};
  
function index($) {
  if ($ && !$.hasOwnProperty('$')) {
	$.$={};  
    Object.keys($).forEach(_get_index);    
  }
  return $;
  
  function _get_index(key) {
    $.$[$[key]] = key;
  }  
}

function LogObject(stream, colors) {
      this.console = new console.Console(stream);
      this.colors = colors||false;
      Writable.call(this,{ objectMode: true, decodeStrings: false });      
} 
LogObject.prototype._write = function (chunk, encoding, callback) {
   this.console.dir( chunk, { depth : null, colors : this.colors} );
   callback();   
};

var LogStream = new LogObject(process.stdout, true); 

//module.exports.parseSDXF = parseSDXF;
module.exports.Parser = Parser;
module.exports.Serialize = Serialize;
module.exports.Deserialize = Deserialize;
module.exports.index = index;
module.exports.LogStream = LogStream;