(*

  SDXF.pas ver 1.3
  Structured Data Exchange Format (SDXF)
  RFC 3072 http://www.ietf.org/rfc/rfc3072.txt
  Copyright (c) 2008 PERCo, Vlad Rubtsov
  Contact: axentry@gmail.com
  Копирайты, варнинги, ахтунги и дислаймеры ....
  last mod: 17.08.08
*)



unit tcsSDXF;

{$ASSERTIONS ON}

interface
uses
  SysUtils,
  Windows,
  Classes,
  Contnrs;

const
{(*}
{
     +----------+-----+-------+-----------------------------------+
     | Name     | Pos.| Length| Description                       |
     +----------+-----+-------+-----------------------------------+
     | chunk-ID |  1  |   2   | ID of the chunk (unsigned short)  |
     | flags    |  3  |   1   | type and properties of this chunk |
     | length   |  4  |   3   | length  of the following data     |
     | content  |  7  |   *)  | net data or a list of of chunks   |
     +----------+-----+-------+-----------------------------------+

     +-+-+-+-+-+-+-+-+
     |7|6|5|4|3|2|1|0|
     +-+-+-+-+-+-+-+-+
      | | | | | | | |
      | | | | | | | +-- reserved
      | | | | | | +---- array
      | | | | | +------ short chunk
      | | | | +-------- encrypted chunk
      | | | +---------- compressed chunk
      | | |
      +-+-+------------ data type (0..7)
}

  ///////////////////////////
  //  Типы данных SDXF
  ///////////////////////////

  SDXF_TYPE_PENDING    = 0; // 0 -- pending structure (chunk is inconsistent, see also 11.1)
  SDXF_TYPE_STRUCTURE  = 1; // 1 -- structure
  SDXF_TYPE_BIT_STRING = 2; // 2 -- bit string (binary data)
  SDXF_TYPE_NUMERIC    = 3; // 3 -- numeric
  SDXF_TYPE_CHARACTER  = 4; // 4 -- character
  SDXF_TYPE_FLOAT      = 5; // 5 -- float (ANSI/IEEE 754-1985)
  SDXF_TYPE_UTF8       = 6; // 6 -- UTF-8
  SDXF_TYPE_RESERVED   = 7; // 7 -- reserved

  ///////////////////////////
  //  Флаги SDXF
  ///////////////////////////

  SDXF_FLAG_RESERVED   = $1;
  SDXF_FLAG_ARRAY      = $2;
  SDXF_FLAG_SHORTCHUNK = $4;
  SDXF_FLAG_ENCRYPTED  = $8;
  SDXF_FLAG_COMPRESSED = $10;

  OpRead : Pointer = Pointer(0);
  OpWrite: Pointer = Pointer(1);



{*)}
type

  ESDXF = class(Exception);

  PChunk = ^TChunk;
  TChunk = packed record
    chunkID: WORD;
    flags: Byte;
    length: array[0..2] of Byte;
  end;

  TSDXF = class
  private
    FBufferHead: PByte;  // Голова буфера
    FBufferSize: NativeUInt;  // Размер буфера
    FBufferTail: PByte;  // Хвост буфера

    FCurrPos: PByte;     // Текущая позиция
    FCurrTail: PByte;    // Хвост данных в буфере

    FStack: TStack;
    FOpStack: TStack;

    function  GetChunkDataLen: DWord; overload; inline;
    procedure SetChunkDataLen(ALength: DWord); overload; inline;
    procedure SetChunkDataLen(AChunk: PByte; ALength: DWord); overload;
    function  GetChunkSize: DWord; overload; inline;
    procedure SetChunkHeader(AID: Word; AChunkType: Byte; AFlags: Byte = 0);
    procedure SkeepChunkHeader(ALength: DWord = 0);

    procedure CheckExpand(AID: Word; ASize: DWord);
//    procedure Reallocate(ASize: DWord);deprecated;
    procedure CheckType(AType: DWord);
    procedure CheckNoFlags(AFlags: DWord);

    function  GetChunkID: WORD; overload; inline;
    function  GetChunkType: Byte; overload; inline;
    function  GetChunkFlags
	: Byte; overload; inline;
    function  GetOffset: Integer;
    function  GetPackageSize: DWord;
  public
    constructor Create(ABuffer: PByte; ASize: DWord);
    destructor  Destroy; override;

    function  IsEntireChunk(AChunkHead: PByte; ALength: DWord): Boolean;  //PVV: Why not static?
    function  TypeDescr(AType: DWord): String;
    function  FlagsDescr(AFlags: DWord): String;
    procedure SetBuffer(ABuffer: PByte; ASize: DWord);
    function  GetChunkID(AChunk: PByte): Word; overload;
    function  GetChunkType(AChunk: PByte): Byte; overload;
    function  GetChunkFlags(AChunk: PByte): Byte; overload;
    class function  GetChunkSize(AChunk: PByte): DWord; overload; static;
    class function  GetChunkDataLen(AChunk: PByte): DWord; overload; static;

    procedure Reset;

    procedure CreateBegin(AID: WORD);
    procedure CreateChunk(AID: WORD); overload; deprecated 'Use CreateBegin';
    procedure CreateChunk(AID: WORD; AValue: Double); overload;
    procedure CreateChunk(AID: WORD; AValue: Int64); overload;
    procedure CreateChunk(AID: WORD; AValue: String); overload;
    procedure CreateChunk(AID: WORD; ABuffer: PByte; ALength: DWord); overload;
    procedure CreateChunk(AID: WORD; AStream: TStream); overload;
    procedure CreateChunk(AID: WORD; AStream: TStream; BlockSize: Cardinal); overload;

    procedure Leave; deprecated 'Use CreateEnd or ExtractEnd';
    procedure CreateEnd;

    function  ExtractBegin: Word;
    procedure Enter; deprecated 'Use ExtractBegin';
    procedure Extract(var AValue: Double); overload;
    procedure Extract(var AValue: Integer); overload;
    procedure Extract(var AValue: Int64); overload;
    function  Extract: String; overload;
    procedure Extract(out ABuffer: PByte; out ALength: DWord); overload;
    function  Next: Boolean;
    procedure ExtractEnd;

    procedure SaveToFile(const AFileName: String);
//    function  LoadFromFile(const AFileName: String): Boolean; deprecated;

    property  Buffer: PByte       read FBufferHead;
    property  Position: PByte     read FCurrPos   write FCurrPos;
    property  Offset: Integer     read GetOffset;
    property  ChunkID: Word       read GetChunkID;
    property  ChunkType: Byte     read GetChunkType;
    property  ChunkFlags: Byte    read GetChunkFlags;
    property  ChunkSize: DWord    read GetChunkSize;    // SizeOf(TChunk) + SizeOf(Data...)
    property  ChunkDataLen:DWord  read GetChunkDataLen; // SizeOf(Data...)
    property  PackageSize: DWord  read GetPackageSize;  // FullSize
  end;


implementation
uses
  SysConst;

{ TSDXF }

constructor TSDXF.Create(ABuffer: PByte; ASize: DWord);
begin
  inherited Create;

  FStack      := TStack.Create;
  FOpStack    := TStack.Create;

  SetBuffer(ABuffer, ASize);
end;

destructor TSDXF.Destroy;
begin
  inherited Destroy;

  FreeAndNil(FStack);
  FreeAndNil(FOpStack);
end;

procedure TSDXF.SetBuffer(ABuffer: PByte; ASize: DWord);
begin
  FBufferHead := ABuffer;
  FBufferSize := ASize;
  FBufferTail := FBufferHead + FBufferSize;
  Reset;
end;

procedure TSDXF.Reset;
begin
  FCurrPos := FBufferHead;

  while FStack.Count > 0 do
    FStack.Pop;

  while FOpStack.Count > 0 do
    FOpStack.Pop;
end;

procedure TSDXF.CheckExpand(AID: Word; ASize: DWord);
begin
  if FCurrPos + ASize > FBufferTail then
    raise ESDXF.CreateFmt('SDXF: Элемент ID:%d. Переполнение внешнего буфера (%d, %d)',
      [AID, FBufferSize, NativeUint(FCurrPos + ASize - FBufferTail)]);
end;

procedure TSDXF.CreateBegin(AID: WORD);
begin
  CheckExpand(AID, SizeOf(TChunk));

  SetChunkHeader(AID, SDXF_TYPE_STRUCTURE);
  SetChunkDataLen(0);

  FStack.Push(FCurrPos);
  FOpStack.Push(OpWrite);

  SkeepChunkHeader;
end;

procedure TSDXF.CreateChunk(AID: WORD);
begin
  CheckExpand(AID, SizeOf(TChunk));

  SetChunkHeader(AID, SDXF_TYPE_STRUCTURE);
  SetChunkDataLen(0);

  FStack.Push(FCurrPos);
  FOpStack.Push(OpWrite);

  SkeepChunkHeader;
end;

procedure TSDXF.CreateChunk(AID: WORD; AValue: Double);
begin
  CheckExpand(AID, SizeOf(TChunk) + SizeOf(Double));

  SetChunkHeader(AID, SDXF_TYPE_FLOAT);
  SetChunkDataLen(SizeOf(Double));
  SkeepChunkHeader;

  PDouble(FCurrPos)^ := AValue;

  Inc(FCurrPos, SizeOf(Double));
  FCurrTail := FCurrPos;
end;

procedure TSDXF.CreateChunk(AID: WORD; AValue: Int64);
begin
  if (AValue >= 0) and (AValue <= $FFF) then
  begin
    // Пытаемся использовать короткий вариант.
    // Данные храняться в дескрипторе длины чанка.
    CheckExpand(AID, SizeOf(TChunk));

    SetChunkHeader(AID, SDXF_TYPE_NUMERIC, SDXF_FLAG_SHORTCHUNK);
    SetChunkDataLen(DWord(AValue));
    SkeepChunkHeader;
  end
  else
  begin
    if (AValue >= 0) and (AValue <= High(DWord)) then
    begin
      // Влезем в DWord
      CheckExpand(AID, SizeOf(TChunk) + SizeOf(DWord));

      SetChunkHeader(AID, SDXF_TYPE_NUMERIC);
      SetChunkDataLen(SizeOf(DWord));
      SkeepChunkHeader;

      PDWord(FCurrPos)^ := DWord(AValue);
      Inc(FCurrPos, SizeOf(DWord));
    end
    else
    begin
      // Влезем в QWord
      CheckExpand(AID, SizeOf(TChunk) + SizeOf(Int64));

      SetChunkHeader(AID, SDXF_TYPE_NUMERIC);
      SetChunkDataLen(SizeOf(Int64));
      SkeepChunkHeader;

      PInt64(FCurrPos)^ := AValue;
      Inc(FCurrPos, SizeOf(Int64));
    end;

    FCurrTail := FCurrPos;
  end;
end;

function CLSIDFromString(psz: PWideChar; out clsid: TGUID): HResult; stdcall;
  external 'ole32.dll' name 'CLSIDFromString';

procedure TSDXF.CreateChunk(AID: WORD; AValue: String);
const
  SimpleGUID: String = '{CCEF0784-7D0C-446B-A51C-8E994E53626C}';
var
  Len: Integer;
  WS: UTF8String;
  Guid: TGUID;
begin
  WS   := UTF8Encode(AValue);
  Len  := Length(WS);

  CheckExpand(AID, SizeOf(TChunk) + Len);

  if (Length(AValue) = Length(SimpleGUID)) and
     (Succeeded(CLSIDFromString(PWideChar(WideString(AValue)), Guid)))
  then
  begin
    // Специальное сжатие текстового Guid
    SetChunkHeader(AID, SDXF_TYPE_UTF8, SDXF_FLAG_COMPRESSED);
    SetChunkDataLen(SizeOf(TGUID));
    SkeepChunkHeader;

    PGUID(FCurrPos)^ := Guid;
    Inc(FCurrPos, SizeOf(TGUID));
  end
  else
  begin
    SetChunkHeader(AID, SDXF_TYPE_UTF8);
    SetChunkDataLen(Len);
    SkeepChunkHeader;

    CopyMemory(FCurrPos, Pointer(WS), Len);
    Inc(FCurrPos, Len);
  end;

  FCurrTail := FCurrPos;
end;


procedure TSDXF.CreateChunk(AID: WORD; ABuffer: PByte; ALength: DWord);
begin
  ASSERT(Assigned(ABuffer));

  CheckExpand(AID, SizeOf(TChunk) + ALength);

  SetChunkHeader(AID, SDXF_TYPE_BIT_STRING);
  SetChunkDataLen(ALength);
  SkeepChunkHeader;

  CopyMemory(FCurrPos, ABuffer, ALength);
  Inc(FCurrPos, ALength);
  FCurrTail := FCurrPos;
end;

procedure TSDXF.CreateChunk(AID: WORD; AStream: TStream);
var
  lPos: PByte;
  lMaxLen, lReaded: Integer;
begin
  assert(assigned(FBufferTail));
  lMaxLen := (FBufferTail - FCurrPos) - SizeOf(TChunk) - 64;

  if lMaxLen <= 0 then
   raise Exception.Create('Out of memory for stream');

  SetChunkHeader(AID, SDXF_TYPE_BIT_STRING);

  lPos := FCurrPos;
  Inc(lPos, SizeOf(TChunk));

  lReaded := AStream.Read(lPos^, lMaxLen);
  assert( lReaded <= lMaxLen);

  SetChunkDataLen(lReaded);

  Inc(FCurrPos, lReaded + SizeOf(TChunk));
  FCurrTail := FCurrPos;

end;


procedure TSDXF.CreateChunk(AID: WORD; AStream: TStream; BlockSize: Cardinal);
var
  lPos: PByte;
  lReaded: Integer;
begin
  CheckExpand(AID, SizeOf(TChunk) + BlockSize);
  lPos := FCurrPos;
  SetChunkHeader(AID, SDXF_TYPE_BIT_STRING);
  SetChunkDataLen(0);
  SkeepChunkHeader;
  lReaded := AStream.Read(FCurrPos^,BlockSize);
  Inc(FCurrPos, lReaded);
  FCurrTail := FCurrPos;
  SetChunkDataLen(lpos,lReaded);
end;


procedure TSDXF.Leave;
var
  lPos: PByte;
  lDelta: DWord;
begin
  ASSERT(FOpStack.Count > 0, 'FOpStack.Count > 0');

  if FOpStack.Pop = OpWrite then
  begin
    lPos   := FStack.Pop;
    lDelta := FCurrPos - (lPos + SizeOf(TChunk));

    ASSERT(lDelta <= $FFFFFF, 'lDelta <= $FFFFFF');

    SetChunkDataLen(lPos, LDelta);
  end
  else
    FCurrPos := FStack.Pop;
end;

procedure TSDXF.CreateEnd;
var
  lPos: PByte;
  lDelta: DWord;
begin
  ASSERT(FOpStack.Count > 0, 'FOpStack.Count > 0');
  ASSERT(FOpStack.Pop = OpWrite, 'FOpStack.Pop = OpWrite');

  lPos   := FStack.Pop;
  lDelta := FCurrPos - (lPos + SizeOf(TChunk));

  ASSERT(lDelta <= $FFFFFF, 'lDelta <= $FFFFFF');

  SetChunkDataLen(lPos, lDelta);
end;

function TSDXF.ExtractBegin: Word;
var
  lPos: PByte;
begin
  CheckType(SDXF_TYPE_STRUCTURE);

  lPos := FCurrPos;
  FStack.Push(FCurrPos);
  FOpStack.Push(OpRead);

  Inc(FCurrPos, SizeOf(TChunk));
  Result := GetChunkID(lPos);
end;

procedure TSDXF.Enter;
begin
  CheckType(SDXF_TYPE_STRUCTURE);

  FStack.Push(FCurrPos);
  FOpStack.Push(OpRead);

  Inc(FCurrPos, SizeOf(TChunk));
end;

function TSDXF.Next: Boolean;
var
  lPos: PByte;
  lEnd: PByte;
begin
  lPos := FCurrPos;
  Inc(lPos, GetChunkSize(FCurrPos));

  if lPos > FBufferTail then
    raise ESDXF.CreateFmt('Элемент ID:%d имеет не правильную длину данных (%d)', [ChunkID, GetChunkSize(FCurrPos)]);

  if FStack.Count > 0 then
  begin
    lEnd   := PByte(FStack.Peek) + GetChunkSize(FStack.Peek);
    Result := lPos < lEnd;
  end
  else
    Result := lPos < FBufferTail;

  if Result then
    FCurrPos := lPos;
end;

procedure TSDXF.Extract(var AValue: Double);
var
  lPos: PByte;
begin
  CheckType(SDXF_TYPE_FLOAT);
  CheckNoFlags(SDXF_FLAG_SHORTCHUNK);

  if (FCurrPos + SizeOf(TChunk) + SizeOf(Double) > FBufferTail) or
     (GetChunkDataLen(FCurrPos) <> SizeOf(Double))
  then
    raise ESDXF.CreateFmt('Элемент ID:%d (число с плавающей точкой) имеет неправильную длину.', [ChunkID]);

  lPos := FCurrPos;
  Inc(lPos, SizeOf(TChunk));
  AValue := PDouble(lPos)^;
end;

procedure TSDXF.Extract(var AValue: Integer);
var
  lDummy: Int64;
begin
  Extract(lDummy);
  if (lDummy < Low(Integer)) or (lDummy > High(Integer)) then
    CheckType(SDXF_TYPE_NUMERIC);

  AValue := Integer(lDummy);
end;

procedure TSDXF.Extract(var AValue: Int64);
var
  lPos: PByte;
  lDummy: Double;
begin
  case ChunkType of
    SDXF_TYPE_FLOAT:
      begin
        Extract(lDummy);
        if Frac(lDummy) <> 0 then
          CheckType(SDXF_TYPE_NUMERIC);
        AValue := Trunc(lDummy);
      end;
    SDXF_TYPE_NUMERIC:
      begin
        // использовалась короткая форма ?
        if ((ChunkFlags and SDXF_FLAG_SHORTCHUNK) <> 0) then
          AValue := ChunkDataLen
        else
        begin
          lPos := FCurrPos;
          Inc(lPos, SizeOf(TChunk));

          case ChunkDataLen of
            SizeOf(DWord): AValue := PDWord(lPos)^;
            SizeOf(Int64): AValue := Pint64(lPos)^;
          else
            raise ESDXF.CreateFmt('Элемент ID:%d (беззнаковое целое) имеет неправильную длину.', [ChunkID]);
          end;
        end;
      end
  else
    CheckType(SDXF_TYPE_NUMERIC);
  end;
end;

function TSDXF.Extract: String;
var
  Buffer: UTF8String;
  lPos: PByte;
  lLen: DWord;
begin
  Result := '';

  CheckType(SDXF_TYPE_UTF8);
  CheckNoFlags(SDXF_FLAG_SHORTCHUNK);

  lLen := GetChunkDataLen(FCurrPos);

  if FCurrPos + SizeOf(TChunk) + lLen > FBufferTail then
    raise ESDXF.CreateFmt('Элемент ID:%d имеет не правильную длину данных (%d)',
                          [ChunkID, lLen]);

  if lLen = 0 then
    Exit;

  lPos := FCurrPos;
  Inc(lPos, SizeOf(TChunk));

  try
    if ((ChunkFlags and SDXF_FLAG_COMPRESSED) <> 0) then
    begin
      if lLen <> SizeOf(TGUID) then
        raise ESDXF.CreateFmt('Элемент ID:%d имеет неподдерживаемую форму сжатия', [ChunkID]);
      Result := GUIDToString(PGUID(lPos)^);
    end
    else
    begin
      SetString(Buffer, PAnsiChar(lPos), Integer(lLen));
      Result := UTF8ToString(Buffer);
    end;
  except
    on E: ESDXF do raise;
    on E: Exception do
      raise ESDXF.CreateFmt('Ошибка распаковки строкового элемента ID:%d (%s)',
                            [ChunkID, e.Message]);
  end;
end;

procedure TSDXF.Extract(out ABuffer: PByte; out ALength: DWord);
begin
  if FCurrPos + SizeOf(TChunk) > FBufferTail then
    raise ESDXF.Create('Нет места');

  CheckType(SDXF_TYPE_BIT_STRING);
  CheckNoFlags(SDXF_FLAG_SHORTCHUNK);
//  if ((PChunk(FCurrPos)^.flags and SDXF_FLAG_SHORTCHUNK) <> 0) then
//    raise ESDXF.CreateFmt('Элемент ID:%d имеет неподдерживаемую форму записи', [ChunkID]);
  ALength := GetChunkDataLen;

  if FCurrPos + SizeOf(TChunk) + ALength > FBufferTail then
    raise ESDXF.CreateFmt('Элемент ID:%d имеет не правильную длину данных (%d)',
                          [ChunkID, ALength]);

  ABuffer := FCurrPos;
  Inc(ABuffer, SizeOf(TChunk));
end;

procedure TSDXF.ExtractEnd;
begin
  ASSERT(FOpStack.Count > 0, 'FOpStack.Count > 0');
  ASSERT(FOpStack.Pop = OpRead, 'FOpStack.Pop = OpRead');

  FCurrPos := FStack.Pop;
end;

class function TSDXF.GetChunkDataLen(AChunk: PByte): DWord;
begin
  Result := 0;
{$WARN UNSAFE_CAST OFF}
  LongRec(Result).Bytes[0] := PChunk(AChunk)^.length[0];
  LongRec(Result).Bytes[1] := PChunk(AChunk)^.length[1];
  LongRec(Result).Bytes[2] := PChunk(AChunk)^.length[2];
{$WARN UNSAFE_CAST ON}
end;

procedure TSDXF.SetChunkDataLen(AChunk: PByte; ALength: DWord);
begin
  if (ALength > $FFFFFF) then
    raise ESDXF.CreateFmt('Превышена максимальная длина блока данных (%d)', [ALength]);

  PChunk(AChunk)^.length[0] := LongRec(ALength).Bytes[0];
  PChunk(AChunk)^.length[1] := LongRec(ALength).Bytes[1];
  PChunk(AChunk)^.length[2] := LongRec(ALength).Bytes[2];
end;

procedure TSDXF.SetChunkDataLen(ALength: DWord);
begin
  SetChunkDataLen(FCurrPos, ALength);
end;

function TSDXF.GetChunkID: WORD;
begin
  Result := GetChunkID(FCurrPos);
end;

function TSDXF.GetChunkID(AChunk: PByte): Word;
begin
  Result := PChunk(AChunk)^.chunkID;
end;

function TSDXF.GetChunkDataLen: DWord;
begin
  Result := GetChunkDataLen(FCurrPos);
end;

procedure TSDXF.SetChunkHeader(AID: Word; AChunkType: Byte; AFlags: Byte);
begin
  PChunk(FCurrPos)^.chunkID := AID;
  PChunk(FCurrPos)^.flags   := Byte(AChunkType shl 5) or AFlags;
end;

procedure TSDXF.SkeepChunkHeader(ALength: DWord);
begin
  Inc(FCurrPos, SizeOf(TChunk) + ALength);
  FCurrTail := FCurrPos;
end;

function TSDXF.IsEntireChunk(AChunkHead: PByte; ALength: DWord): Boolean;
begin
  Result := ALength >= SizeOf(TChunk);
  if Result then
    Result := ALength >= GetChunkSize(AChunkHead);
end;

procedure TSDXF.CheckType(AType: DWord);
begin
  if ChunkType <> AType then
    raise ESDXF.CreateFmt('Несоответствие типа элемента с ID:%d. Обнаружен тип %s, ожидался %s',
                          [ChunkID, TypeDescr(ChunkType), TypeDescr(AType)]);
end;

procedure TSDXF.CheckNoFlags(AFlags: DWord);
begin
  if (ChunkFlags and AFlags) <> 0 then
    raise ESDXF.CreateFmt('Несоответствие признака элемента с ID:%d. Ообнаружен признак %s',
                          [ChunkID, FlagsDescr(AFlags)]);
end;

function TSDXF.TypeDescr(AType: DWord): String;
begin
  case AType of
    SDXF_TYPE_PENDING:    Result := 'SDXF_TYPE_PENDING';
    SDXF_TYPE_STRUCTURE:  Result := 'SDXF_TYPE_STRUCTURE';
    SDXF_TYPE_BIT_STRING: Result := 'SDXF_TYPE_BIT_STRING';
    SDXF_TYPE_NUMERIC:    Result := 'SDXF_TYPE_NUMERIC';
    SDXF_TYPE_CHARACTER:  Result := 'SDXF_TYPE_CHARACTER';
    SDXF_TYPE_FLOAT:      Result := 'SDXF_TYPE_FLOAT';
    SDXF_TYPE_UTF8:       Result := 'SDXF_TYPE_UTF8';
    SDXF_TYPE_RESERVED:   Result := 'SDXF_TYPE_RESERVED';
  else
    Result := 'SDXF_TYPE_UNKNOWN';
  end;
end;

function TSDXF.FlagsDescr(AFlags: DWord): String;
begin
  Result := '';
  if (AFlags and SDXF_FLAG_RESERVED) <> 0 then
    Result := Result + ':SDXF_FLAG_RESERVED';
  if (AFlags and SDXF_FLAG_ARRAY) <> 0 then
    Result := Result + ':SDXF_FLAG_ARRAY';
  if (AFlags and SDXF_FLAG_SHORTCHUNK) <> 0 then
    Result := Result + ':SDXF_FLAG_SHORTCHUNK';
  if (AFlags and SDXF_FLAG_ENCRYPTED) <> 0 then
    Result := Result + ':SDXF_FLAG_ENCRYPTED';
  if (AFlags and SDXF_FLAG_COMPRESSED) <> 0 then
    Result := Result + ':SDXF_FLAG_COMPRESSED';
end;

procedure TSDXF.SaveToFile(const AFileName: String);
var
  s: NativeUInt;
  lHandle: THandle;
  lWritten: DWord;
begin
  if FCurrTail = nil then
    s := FBufferSize
  else
    s := FCurrTail - FBufferHead;
  lHandle := CreateFile(PChar(AFileName), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);

  if lHandle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;

  try
    if not WriteFile(lHandle, FBufferHead^, s, lWritten, nil) then
      RaiseLastOSError;
    if lWritten <> s then
      raise EOSError.CreateFmt('Write file failed: File %s has been truncated. (%d/%d).',
        [AFileName, s, lWritten]);
  finally
    CloseHandle(lHandle);
  end;
end;


class function TSDXF.GetChunkSize(AChunk: PByte): DWord;
begin
  if ((PChunk(AChunk)^.flags and SDXF_FLAG_SHORTCHUNK) <> 0) then
    Result := SizeOf(TChunk)
  else
  begin
    Result := GetChunkDataLen(AChunk);
    Inc(Result, SizeOf(TChunk));
  end;
end;

function TSDXF.GetChunkSize: DWord;
begin
  Result := GetChunkSize(FCurrPos);
end;

function TSDXF.GetOffset: integer;
begin
  Result := Integer(FCurrPos) - Integer(FBufferHead);
end;

function TSDXF.GetPackageSize: DWord;
begin
  Result := GetChunkSize(FBufferHead);
end;

function TSDXF.GetChunkType: Byte;
begin
  Result := GetChunkType(FCurrPos);
end;

function TSDXF.GetChunkType(AChunk: PByte): Byte;
begin
  Result := (PChunk(AChunk)^.flags and $E0) shr 5;
end;

function TSDXF.GetChunkFlags: Byte;
begin
  Result := GetChunkFlags(FCurrPos);
end;

function TSDXF.GetChunkFlags(AChunk: PByte): Byte;
begin
  Result := PChunk(AChunk)^.flags and $1F;
end;

end.


