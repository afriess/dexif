// unit dEXIF - Copyright 2001-2006, Gerry McGuire
//--------------------------------------------------------------------------
// Program to pull the information out of various types of EXIF digital
// camera files and show it in a reasonably consistent way
//                                                                                  UNDEFINED
// This module parses the very complicated exif structures.
//
// Matthias Wandel,  Dec 1999 - August 2000  (most of the comments)
//
// Translated to Delphi:
//         Gerry McGuire, March - April 2001 - Currently - read only
//                        May 2001 - add EXIF to jpeg output files
//                        September 2001 - read TIF files, IPTC data
//                        June 2003 - First (non-beta) Release
//--------------------------------------------------------------------------
//   In addition to the basic information provided by Matthias, the
//   following web page contains reference informtion regarding the
//   exif standard: http://www.pima.net/standards/iso/tc42/wg18/WG18_POW.htm
//   (the documents themselves are PDF).
//--------------------------------------------------------------------------
//  17.05.2002 MS Corrections/additions M. Schwaiger
//  19.10.2013 Adaption to Lazarus
//  13.07.2016 Some Modifications my Mitja Stachowiak (mitjastachowiak.de) - search for comment msta
//--------------------------------------------------------------------------
Unit dEXIF;

{$IFDEF LCL}
  {$mode DELPHI}{$H+}
{$ENDIF}

interface

uses
  sysutils, classes, math,
 {$IFDEF DELPHI}
  {$IFNDEF dExifNoJpeg} jpeg, {$ENDIF}
 {$ELSE}
  fpimage, fpreadjpeg,
 {$ENDIF}
  dIPTC;

Const
   DexifVersion = '1.03d';
   ExifTag = 1;  // default tag Types
   GpsTag = 2;
   ThumbTag = 4;
   GenericEXIF = 0;
   CustomEXIF = 1;
   AllEXIF = -1;
   crlf = #13#10;
   GenNone = 0;
   GenAll = 255;
   GenString = 2;
   GenList = 4;
   VLMin = 0;
   VLMax = 1;

type
   tEndInd = class
      MotorolaOrder: boolean;
      function Get16u(oset: integer): word;
      function Get32s(oset: integer): Longint;
      function Get32u(oset: integer): Longword;
      function Put32s(data: Integer): string;
      procedure WriteInt16(var buff:string;int,posn:integer);
      procedure WriteInt32(var buff:string;int,posn:longint);
      function GetDataBuff: string;
      procedure SetDataBuff(const Value: string);
      property DataBuff:string read GetDataBuff write SetDataBuff;
   private
      llData: string;
   public
      destructor destroy; override;
   end;

  TimgData = class;

  TImageInfo = class(tEndind)
  private
    function ReadComments : String;       // msta
    function ReadImageDescription : AnsiString;
    function ReadArtist : AnsiString;
    procedure WriteComments (v : String);
    procedure WriteImageDescription (v : AnsiString);
    procedure WriteArtist (v : AnsiString);

    function GetTagElement(TagID: integer): TTagEntry;
    procedure SetTagElement(TagID: integer; const Value: TTagEntry);
    function GetTagByName(TagName: string): TTagEntry;
    procedure SetTagByName(TagName: string; const Value: TTagEntry);
    procedure TagWriteThru16(te: ttagentry; NewVal16: word);
    procedure TagWriteThru32(te: ttagentry; NewVal32: longint);
    procedure pushDirStack(dirStart, offsetbase: Integer);
    function testDirStack(dirStart, offsetbase: Integer): boolean;
    procedure clearDirStack;
    function CreateExifBuf (parentID:word=0; offsetbase:Integer=0) : String;  // msta
    procedure removeTag(TagID:integer; parentID:word=0);
    function getTag(TagID:integer; forceCreate:Boolean=false; parentID:word=0; TagType:word=65535; forceID:Boolean=false) : PTagEntry; // msta
  public
    FITagArray: array of tTagEntry;
    FITagCount: integer;
    MaxTag: integer;
    parent: timgdata;
    exifVersion : string[6];
    CameraMake: string[32];
    CameraModel: string[40];
    DateTime: string[20];
    Height,Width,HPosn,WPosn: integer;
    FlashUsed: integer;
    BuildList: integer;
    MakerNote: string;
    TiffFmt: boolean;
    //CommentPosn: integer;
    //CommentSize: integer;
// DateTime tag locations
    dt_oset:integer;
    dt_orig_oset:integer;
    dt_digi_oset:integer;
// Add support for thumbnail
    ThumbTrace:string;
    ThumbStart: integer;
    ThumbLength: integer;
    ThumbType: integer;
    FIThumbArray: array of tTagEntry;
    FIThumbCount: integer;
    MaxThumbTag: integer;
//  Added the following elements to make the
//  structure a little more code-friendly
    TraceLevel: integer;
    TraceStr: string;
    msTraceStr: string;
    msAvailable: boolean;
    msName:string;
    MakerOffset : integer;
    property ITagArray[TagID:integer]: TTagEntry
        read GetTagElement write SetTagElement; default;
    property Data[TagName:string]: TTagEntry
        read GetTagByName write SetTagByName;
    property Comments : String read ReadComments write WriteComments;
    property ImageDescription : AnsiString read ReadImageDescription write WriteImageDescription;
    property Artist : AnsiString read ReadArtist write WriteArtist;

    Constructor Create( p:timgdata; buildCode:integer =GenAll);
    procedure Assign(source:TImageInfo);
//  The following functions format this structure into a string
    function  toString:string;   //  Summerizes in a single line
    function  toLongString:string;
    procedure SetExifComment(newComment: string);
//  The following functions manage the date
    function  GetImgDateTime: TDateTime;
    function  ExtrDateTime(oset: integer): TDateTime;
    function  ExifDateToDateTime(dstr: string): TDateTime;
    procedure SetDateTimeStr(oset: integer; TimeIn: TDateTime);
    procedure AdjDateTime(days, hours, mins, secs: integer);
    procedure OverwriteDateTime(InTime: tdatetime);   //  Contains embedded CR/LFs
    procedure ProcessHWSpecific(MakerBuff:string;
                  TagTbl:Array of TTagEntry;
                  DirStart:longint;
                  AMakerOffset:Longint;
                  spOffset:integer = 0);
    Procedure ProcessThumbnail;
    Procedure AddMSTag(fname,fstr:string;fType:word);
    Procedure ProcessExifDir(DirStart, OffsetBase, ExifLength: longint;
             tagType:integer = ExifTag; prefix:string=''; parentID:word=0);
    function CvtInt(buff: string): longint;
    Function FormatNumber(buffer: string; fmt: integer; fmtStr:string;
      decodeStr: string=''): string;
    Function GetNumber(buffer: string; fmt: integer): double;
    procedure removeThumbnail;
    procedure AdjExifSize(nh,nw:longint);
    Function LookupTag(SearchStr:string):integer; virtual;
    Function LookupTagVal(SearchStr:string):string; virtual;
    Function LookupTagDefn(item: string): integer;
    Function LookupTagByDesc(SearchStr: string): integer;
    function AddTagToArray(nextTag: iTag): integer;
    function AddTagToThumbArray(nextTag: iTag): integer;
    Procedure ResetIterator;
    Function IterateFoundTags(TagId:integer; var retVal:TTagEntry):boolean;
    Function GetTagByDesc(SearchStr: string): TTagEntry;
    Function HasThumbnail:boolean;
    function IterateFoundThumbTags(TagId: integer;
      var retVal: TTagEntry): boolean;
    procedure ResetThumbIterator;
    procedure Calc35Equiv;
    function EXIFArrayToXML: tstringlist;
    function LookupTagInt(SearchStr: string): integer;
    function GetRawFloat(tagName: string): double;
    function GetRawInt(tagName: string): integer;
    function LookupRatio: double;
    destructor Destroy; override;
    function WriteThruInt(tname: string; value: Integer): boolean;
    function WriteThruString(tname, value: String): boolean;
  private
    iterator:integer;
    iterThumb:integer;
  end; // TInfoData

  tSection = record
    data: string;
    dtype:integer;
    size:longint;
    base:longint;
  end;
  pSection = ^tSection;

 // TTagTableArray = array of TTagEntry;
  TGpsFormat = (gf_DD,gf_DM,gf_DMS);

    TImgData = class(tEndInd) // One per image object
        sections: array [1..21] of tSection;
        TiffFmt: boolean;
        BuildList: integer;
        SectionCnt : integer;
        ExifSegment: pSection;
        IPTCSegment: pSection;
        CommentSegment: pSection;
        HeaderSegment : pSection;
        Filename: string;
        FileDateTime: tDateTime;
        FileSize: longint;
        ErrStr: string;
        ExifObj: TImageInfo;
        IptcObj: TIPTCData;
        TraceLevel: integer;
        procedure reset;
        procedure SetFileInfo(fname:string);
        constructor Create(buildCode: integer = GenAll);
        function SaveExif(jfs2:tstream; EnabledMeta : Byte = $FF; freshExifBlock : Boolean = false):longint;
        function ReadExifInfo(fname:string):boolean;
        Procedure MakeIPTCSegment(buff:string);
        Procedure MakeCommentSegment(buff:string);
        function  GetCommentStr:string;
        Function  GetCommentSegment:string;
        function ProcessFile(const AFileName:string):boolean;
        function ReadJpegSections (f: TStream):boolean;
        function ReadJpegFile(const AFileName:string):boolean;
        function ReadTiffSections (f: tstream):boolean;
        function ReadTiffFile(const AFileName:string):boolean;
        procedure ClearSections;
        procedure ClearEXIF;
        procedure ClearIPTC;
        procedure ClearComments;
        procedure ProcessEXIF;
        procedure CreateIPTCObj;
        function  HasMetaData:boolean;
        function HasEXIF: boolean;
        function HasIPTC: boolean;
        function HasComment: boolean;
        function HasThumbnail: boolean;
        function ReadIPTCStrings(fname: string):tstringlist;
        function ExtractThumbnailBuffer: String;
        procedure MergeToStream(Input, Output: TStream; EnabledMeta: Byte = $FF;
          freshExifBlock: Boolean = false);
        {$IFDEF DELPHI}
        {$IFNDEF dExifNoJpeg}
        function ExtractThumbnailJpeg: TJpegImage;
        procedure WriteEXIFJpeg(j:tjpegimage;fname:ansistring;origName:ansistring;
                  adjSize:boolean = true);  overload;
        procedure WriteEXIFJpeg(fname:ansistring); overload;
        procedure WriteEXIFJpeg(j:tjpegimage;fname:ansistring; adjSize:boolean = true);  overload;
        {$ENDIF}
        {$ENDIF}
        destructor Destroy; override;
  end; // TImgData

  // these function variables can be overridden to
  // alter the default formatting for various data types
  tfmtInt  = function (inInt:integer):string;
  tfmtReal = function (inReal:double):string;
  tfmtFrac = function (inNum,inDen:integer):string;

  // These formatting functions can be used elsewhere
  function defIntFmt (inInt:integer):string;
  function defRealFmt(inReal:double):string;
  function defFracFmt(inNum,inDen:integer):string;
  function fmtRational( num,den:integer):string;

  function getbyte( var f : tstream) : byte;
  function DecodeField(DecodeStr, idx: string): string;
  function CvtTime(instr: string): string;

Var
   DexifDataSep   : string = ', ';
   DexifDecodeSep : string = ',';
   DexifDelim     : string = ' = ';
   DexifDecode    : boolean = true;
   estimateValues : boolean = false;
   TiffReadLimit  : longint = 256000;
   curTagArray    : TImageInfo = nil;
   fmtInt: tfmtInt = @defIntFmt;
   fmtReal: tfmtReal = @defRealFmt;
   fmtFrac: tfmtFrac = @defFracFmt;

Const
   GpsFormat = gf_DMS;
   validHeader: string = 'Exif'#0;

{ object declared in dIPTC unit
  TTagEntry = record
    TID: integer;        // TagTableID - EXIF use
    TType: word;         // tag type
    ICode: Word;         // iptc code
    Tag: word;           // primary key
    Name: string;        // searchable
    Desc: string;        // translatable
    Code: string;        // decode capability
    Data:String;         // display value
    Raw:string;          // unprocessed value
    Fmt:string;          // Format string
    Size: integer;       // used by ITPC module
    CallBack: StrFunct;  // formatting string
  end;
}
   EmptyEntry: ttagEntry = ( TID:0; TType:0; ICode:0; Tag:0; Name: '';
       Desc: ''; Code:''; Data:''; Raw:''; PRaw:0; FormatS:''; Size:0);

//--------------------------------------------------------------------------
// JPEG markers consist of one or more= $FF bytes, followed by a marker
// code byte (which is not an FF).  Here are the marker codes of interest
// in this program.
//--------------------------------------------------------------------------

     M_SOF0 = $C0;            // Start Of Frame N
     M_SOF1 = $C1;            // N indicates which compression process
     M_SOF2 = $C2;            // Only SOF0-SOF2 are now in common use
     M_SOF3 = $C3;
     M_DHT  = $C4;            // Define Huffman Table
     M_SOF5 = $C5;            // NB: codes C4 and CC are NOT SOF markers
     M_SOF6 = $C6;
     M_SOF7 = $C7;
     M_SOF9 = $C9;
     M_SOF10= $CA;
     M_SOF11= $CB;
     M_SOF13= $CD;                              M_DAC  = $CC;            // Define arithmetic coding conditioning
     M_SOF14= $CE;
     M_SOF15= $CF;
     M_SOI  = $D8;            // Start Of Image (beginning of datastream)
     M_EOI  = $D9;            // End Of Image (end of datastream)
     M_SOS  = $DA;            // Start Of Scan (begins compressed data)
     M_DQT  = $DB;            // Define Quantization table
     M_DNL  = $DC;            // Define number of lines
     M_DRI  = $DD;            // Restart interoperability definition
     M_DHP  = $DE;            // Define hierarchical progression
     M_EXP  = $DF;            // Expand reference component
     M_JFIF = $E0;            // Jfif marker
     M_EXIF = $E1;            // Exif marker
  M_EXIFEXT = $E2;            // Exif extended marker
     //  M_KODAK = $E3;           // Kodak marker  ???
     M_IPTC = $ED;            // IPTC - Photoshop
    M_APP14 = $EE;            // Photoshop data:  App14
     M_COM  = $FE;            // Comment

    ProcessTable : array [0..29] of TTagEntry =
    (( TID:0;TType:0;ICode: 0;Tag: M_SOF0;   Name:'SKIP';Desc: 'Baseline'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF1;   Name:'';Desc: 'Extended sequential'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF2;   Name:'';Desc: 'Progressive'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF3;   Name:'';Desc: 'Lossless'),
     ( TID:0;TType:0;ICode: 0;Tag: M_DHT;    Name:'';Desc: 'Define Huffman table'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF5;   Name:'';Desc: 'Differential sequential'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF6;   Name:'';Desc: 'Differential progressive'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF7;   Name:'';Desc: 'Differential lossless'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF9;   Name:'';Desc: 'Extended sequential, arithmetic coding'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF10;  Name:'';Desc: 'Progressive, arithmetic coding'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF11;  Name:'';Desc: 'Lossless, arithmetic coding'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF13;  Name:'';Desc: 'Differential sequential, arithmetic coding'),
     ( TID:0;TType:0;ICode: 0;Tag: M_DAC;    Name:'';Desc: 'Define arithmetic coding conditioning'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF14;  Name:'';Desc: 'Differential progressive, arithmetic coding'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOF15;  Name:'';Desc: 'Differential lossless, arithmetic coding'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOI;    Name:'';Desc: 'Start of Image'),
     ( TID:0;TType:0;ICode: 0;Tag: M_EOI;    Name:'';Desc: 'End of Image'),
     ( TID:0;TType:0;ICode: 0;Tag: M_SOS;    Name:'';Desc: 'Start of Scan'),
     ( TID:0;TType:0;ICode: 0;Tag: M_DQT;    Name:'';Desc: 'Define quantization table'),
     ( TID:0;TType:0;ICode: 0;Tag: M_DNL;    Name:'';Desc: 'Define number of lines'),
     ( TID:0;TType:0;ICode: 0;Tag: M_DRI;    Name:'';Desc: 'Restart interoperability definition'),
     ( TID:0;TType:0;ICode: 0;Tag: M_DHP;    Name:'';Desc: 'Define hierarchical progression'),
     ( TID:0;TType:0;ICode: 0;Tag: M_EXP;    Name:'';Desc: 'Expand reference component'),
     ( TID:0;TType:0;ICode: 0;Tag: M_JFIF;   Name:'';Desc: 'JPG marker'),
     ( TID:0;TType:0;ICode: 0;Tag: M_EXIF;   Name:'';Desc: 'Exif Data'),
     ( TID:0;TType:0;ICode: 0;Tag: M_EXIFEXT; Name:'';Desc: 'Exif Extended Data'),
     ( TID:0;TType:0;ICode: 0;Tag: M_COM;    Name:'';Desc: 'Comment'),
     ( TID:0;TType:0;ICode: 0;Tag: M_IPTC;   Name:'';Desc: 'IPTC data'),
     ( TID:0;TType:0;ICode: 0;Tag: M_APP14;  Name:'';Desc: 'Photoshop data'),
     ( TID:0;TType:0;ICode: 0;Tag: 0;        Name:'';Desc: 'Unknown')
    );

   Function CvtIrrational( instr:string ):double;
   Function LookupType(idx:integer):string;

   Function MakePrintable(s:string):string;

   //  Formatting callbacks
   Function GpsPosn(instr:string) :string;
   Function GenCompConfig(instr:string): string;
   Function ExposCallBack(instr: string): string;
   Function FlashCallBack(instr: string): string;
   Function ExtractComment(instr: string): string;
   Function SSpeedCallBack(instr: string): string;
   Function xpTranslate(instr: string): string;

const
//--------------------------------------------------------------------------
// Describes format descriptor
   BytesPerFormat: array [0..12] of integer = (0,1,1,2,4,8,1,1,2,4,8,4,8);
   NUM_FORMATS   = 12;
   FMT_BYTE      =  1;
   FMT_STRING    =  2;
   FMT_USHORT    =  3;
   FMT_ULONG     =  4;
   FMT_URATIONAL =  5;
   FMT_SBYTE     =  6;
   FMT_UNDEFINED =  7;
   FMT_SSHORT    =  8;
   FMT_SLONG     =  9;
   FMT_SRATIONAL = 10;
   FMT_SINGLE    = 11;
   FMT_DOUBLE    = 12;

var
  ExifNonThumbnailLength : integer;
  ShowTags: integer;
  ExifTrace: integer = 0;
{$IFDEF dEXIFpredeclare}
  ImgData:timgData;
{$ENDIF}

implementation

uses msData;

const
// Compression Type Constants
   JPEG_COMP_TYPE = 6;
   TIFF_COMP_TYPE = 1;

//-------------------------------------------------------
// Describes only tag values needed for physical access
// all others are found in tag array.
//-------------------------------------------------------

   TAG_EXIF_OFFSET        = $8769;
   TAG_GPS_OFFSET         = $8825;
   TAG_INTEROP_OFFSET     = $A005;
   TAG_SUBIFD_OFFSET      = $014A;

   TAG_IMAGEWIDTH         = $0100;
   TAG_IMAGELENGTH        = $0101;
   TAG_THUMBTYPE          = $0103;
   TAG_IMAGEDESCRIPTION   = $010E;     // msta
   TAG_MAKE               = $010F;
   TAG_MODEL              = $0110;
   TAG_DATETIME_MODIFY    = $0132;
   TAG_ARTIST             = $013B;     // msta

   TAG_EXPOSURETIME       = $829A;
   TAG_FNUMBER            = $829D;

   TAG_EXIFVER            = $9000;
   TAG_DATETIME_ORIGINAL  = $9003;
   TAG_DATETIME_DIGITIZED = $9004;
   TAG_SHUTTERSPEED       = $9201;
   TAG_APERTURE           = $9202;
   TAG_MAXAPERTUREVALUE   = $9205;
   TAG_SUBJECT_DISTANCE   = $9206;
   TAG_LIGHT_SOURCE       = $9208;
   TAG_FLASH              = $9209;
   TAG_FOCALLENGTH        = $920A;
   TAG_MAKERNOTE          = $927C;
   TAG_USERCOMMENT        = $9286;

   TAG_EXIF_IMAGEWIDTH    = $A002;
   TAG_EXIF_IMAGELENGTH   = $A003;
   TAG_FOCALPLANEXRES     = $A20E;
   TAG_FOCALPLANEYRES     = $A20F;             // added by M. Schwaiger
   TAG_FOCALPLANEUNITS    = $A210;
   TAG_FOCALLENGTH35MM    = $A405;             // added by M. Schwaiger


   GPSCnt = 31 - 4;
   ExifTagCnt = 251 - 6;  // NOTE: was 250 before, but "count" is 251
   TotalTagCnt = GPSCnt + ExifTagCnt;

var whitelist : array [0..37] of Word = ($8769, $100, $101, $102, $103, $106, $10E, $10F, $110, $132, $13B, $13E, $301, $304, $5010, $5011, $8298, $829A, $882A, $9003, $9004, $9201, $9202, $9203, $9204, $9205, $9206, $9208, $9209, $920A, $920B, $920D, $9286, $9C9B, $9C9C, $9C9D, $9C9E, $9C9F);

{   Many tags added based on Php4 source...
http://lxr.php.net/source/php4/ext/exif/exif.c
}
var
 TagTable : array [0..ExifTagCnt-1] of TTagEntry =
// TagTable : array of TTagEntry =
// TagTable : TTagDefArray [0..ExifTagCnt] =
// TagTable: TTagDefArray =
 ((TID:0;TType:0;ICode: 2;Tag: $001;   Name:'InteroperabilityIndex'  ),         {0}
  (TID:0;TType:0;ICode: 2;Tag: $002;   Name:'InteroperabilityVersion'),
  (TID:0;TType:0;ICode: 2;Tag: $00B;   Name:'ACDComment'             ),
  (TID:0;TType:0;ICode: 2;Tag: $0FE;   Name:'NewSubfileType'         ),
  (TID:0;TType:0;ICode: 2;Tag: $0FF;   Name:'SubfileType'            ),
  (TID:0;TType:0;ICode: 2;Tag: $100;   Name:'ImageWidth'             ),
  (TID:0;TType:0;ICode: 2;Tag: $101;   Name:'ImageLength'            ),
  (TID:0;TType:0;ICode: 2;Tag: $102;   Name:'BitsPerSample'          ),
  (TID:0;TType:0;ICode: 2;Tag: $103;   Name:'Compression'            ;Desc:'';Code:'6:Jpeg,3:Uncompressed,1:TIFF'),
  (TID:0;TType:0;ICode: 2;Tag: $106;   Name:'PhotometricInterpretation';Desc:''; Code:'1:Monochrome, 2:RGB, 6:YCbCr'),
  (TID:0;TType:0;ICode: 2;Tag: $10A;   Name:'FillOrder'              ),         {10}
  (TID:0;TType:0;ICode: 2;Tag: $10D;   Name:'DocumentName'           ),
  (TID:0;TType:0;ICode: 2;Tag: $10E;   Name:'ImageDescription'       ),
  (TID:0;TType:0;ICode: 2;Tag: $10F;   Name:'Make'                   ),
  (TID:0;TType:0;ICode: 2;Tag: $110;   Name:'Model'                  ),
  (TID:0;TType:0;ICode: 2;Tag: $111;   Name:'StripOffsets'           ),
  (TID:0;TType:0;ICode: 2;Tag: $112;   Name:'Orientation'            ; Desc:''; Code:'1:Normal,3:Rotated 180°,6:CounterClockwise 90°,8:Clockwise 90°'),
  (TID:0;TType:0;ICode: 2;Tag: $115;   Name:'SamplesPerPixel'        ),
  (TID:0;TType:0;ICode: 2;Tag: $116;   Name:'RowsPerStrip'           ),
  (TID:0;TType:0;ICode: 2;Tag: $117;   Name:'StripByteCounts'        ),
  (TID:0;TType:0;ICode: 2;Tag: $118;   Name:'MinSampleValue'         ),         {20}
  (TID:0;TType:0;ICode: 2;Tag: $119;   Name:'MaxSampleValue'         ),
  (TID:0;TType:0;ICode: 2;Tag: $11A;   Name:'XResolution'            ; Desc:''; Code:''; Data:''; Raw:''; PRaw:0; FormatS:'%5.2f'),
  (TID:0;TType:0;ICode: 2;Tag: $11B;   Name:'YResolution'            ; Desc:''; Code:''; Data:''; Raw:''; PRaw:0; FormatS:'%5.2f'),
  (TID:0;TType:0;ICode: 2;Tag: $11C;   Name:'PlanarConfiguration'    ),
  (TID:0;TType:0;ICode: 2;Tag: $11D;   Name:'PageName'               ),
  (TID:0;TType:0;ICode: 2;Tag: $11E;   Name:'XPosition'              ),
  (TID:0;TType:0;ICode: 2;Tag: $11F;   Name:'YPosition'              ),
  (TID:0;TType:0;ICode: 2;Tag: $120;   Name:'FreeOffsets'            ),
  (TID:0;TType:0;ICode: 2;Tag: $121;   Name:'FreeByteCounts'         ),
  (TID:0;TType:0;ICode: 2;Tag: $122;   Name:'GrayReponseUnit'        ),         {30}
  (TID:0;TType:0;ICode: 2;Tag: $123;   Name:'GrayReponseCurve'       ),
  (TID:0;TType:0;ICode: 2;Tag: $124;   Name:'T4Options'              ),
  (TID:0;TType:0;ICode: 2;Tag: $125;   Name:'T6Options'              ),
  (TID:0;TType:0;ICode: 2;Tag: $128;   Name:'ResolutionUnit'         ;Desc:''; Code:'1:None Specified,2:Inch,3:Centimeter'),
  (TID:0;TType:0;ICode: 2;Tag: $129;   Name:'PageNumber'             ),
  (TID:0;TType:0;ICode: 2;Tag: $12D;   Name:'TransferFunction'       ),
  (TID:0;TType:0;ICode: 2;Tag: $131;   Name:'Software'               ),
  (TID:0;TType:0;ICode: 2;Tag: $132;   Name:'DateTimeModify'         ),
  (TID:0;TType:0;ICode: 2;Tag: $13B;   Name:'Artist'                 ),
  (TID:0;TType:0;ICode: 2;Tag: $13C;   Name:'HostComputer'           ),         {40}
  (TID:0;TType:0;ICode: 2;Tag: $13D;   Name:'Predictor'              ),
  (TID:0;TType:0;ICode: 2;Tag: $13E;   Name:'WhitePoint'             ),
  (TID:0;TType:0;ICode: 2;Tag: $13F;   Name:'PrimaryChromaticities'  ),
  (TID:0;TType:0;ICode: 2;Tag: $140;   Name:'ColorMap'               ),
  (TID:0;TType:0;ICode: 2;Tag: $141;   Name:'HalfToneHints'          ),
  (TID:0;TType:0;ICode: 2;Tag: $142;   Name:'TileWidth'              ),
  (TID:0;TType:0;ICode: 2;Tag: $143;   Name:'TileLength'             ),
  (TID:0;TType:0;ICode: 2;Tag: $144;   Name:'TileOffsets'            ),
  (TID:0;TType:0;ICode: 2;Tag: $145;   Name:'TileByteCounts'         ),
  (TID:0;TType:0;ICode: 2;Tag: $14A;   Name:'SubIFDs'                ),         {50}
  (TID:0;TType:0;ICode: 2;Tag: $14C;   Name:'InkSet'                 ),
  (TID:0;TType:0;ICode: 2;Tag: $14D;   Name:'InkNames'               ),
  (TID:0;TType:0;ICode: 2;Tag: $14E;   Name:'NumberOfInks'           ),
  (TID:0;TType:0;ICode: 2;Tag: $150;   Name:'DotRange'               ),
  (TID:0;TType:0;ICode: 2;Tag: $151;   Name:'TargetPrinter'          ),
  (TID:0;TType:0;ICode: 2;Tag: $152;   Name:'ExtraSample'            ),
  (TID:0;TType:0;ICode: 2;Tag: $153;   Name:'SampleFormat'           ),
  (TID:0;TType:0;ICode: 2;Tag: $154;   Name:'SMinSampleValue'        ),
  (TID:0;TType:0;ICode: 2;Tag: $155;   Name:'SMaxSampleValue'        ),
  (TID:0;TType:0;ICode: 2;Tag: $156;   Name:'TransferRange'          ),         {60}
  (TID:0;TType:0;ICode: 2;Tag: $157;   Name:'ClipPath'               ),
  (TID:0;TType:0;ICode: 2;Tag: $158;   Name:'XClipPathUnits'         ),
  (TID:0;TType:0;ICode: 2;Tag: $159;   Name:'YClipPathUnits'         ),
  (TID:0;TType:0;ICode: 2;Tag: $15A;   Name:'Indexed'                ),
  (TID:0;TType:0;ICode: 2;Tag: $15B;   Name:'JPEGTables'             ),
  (TID:0;TType:0;ICode: 2;Tag: $15F;   Name:'OPIProxy'               ),
  (TID:0;TType:0;ICode: 2;Tag: $200;   Name:'JPEGProc'               ),
  (TID:0;TType:0;ICode: 2;Tag: $201;   Name:'JPEGInterchangeFormat'  ),
  (TID:0;TType:0;ICode: 2;Tag: $202;   Name:'JPEGInterchangeFormatLength'),
  (TID:0;TType:0;ICode: 2;Tag: $203;   Name:'JPEGRestartInterval'    ),         {70}
  (TID:0;TType:0;ICode: 2;Tag: $205;   Name:'JPEGLosslessPredictors' ),
  (TID:0;TType:0;ICode: 2;Tag: $206;   Name:'JPEGPointTransforms'    ),
  (TID:0;TType:0;ICode: 2;Tag: $207;   Name:'JPEGQTables'            ),
  (TID:0;TType:0;ICode: 2;Tag: $208;   Name:'JPEGDCTables'           ),
  (TID:0;TType:0;ICode: 2;Tag: $209;   Name:'JPEGACTables'           ),
  (TID:0;TType:0;ICode: 2;Tag: $211;   Name:'YCbCrCoefficients'      ),
  (TID:0;TType:0;ICode: 2;Tag: $212;   Name:'YCbCrSubSampling'       ),
  (TID:0;TType:0;ICode: 2;Tag: $213;   Name:'YCbCrPositioning'       ; Desc:'';Code:'1:Centered,2:Co-sited'),
  (TID:0;TType:0;ICode: 2;Tag: $214;   Name:'ReferenceBlackWhite'    ),
  (TID:0;TType:0;ICode: 2;Tag: $2BC;   Name:'ExtensibleMetadataPlatform' ),     {80}
  (TID:0;TType:0;ICode: 2;Tag: $301;   Name:'Gamma'                     ),
  (TID:0;TType:0;ICode: 2;Tag: $302;   Name:'ICCProfileDescriptor'      ),
  (TID:0;TType:0;ICode: 2;Tag: $303;   Name:'SRGBRenderingIntent'       ),
  (TID:0;TType:0;ICode: 2;Tag: $304;   Name:'ImageTitle'                ),
  (TID:0;TType:0;ICode: 2;Tag: $1000;  Name:'RelatedImageFileFormat' ),
  (TID:0;TType:0;ICode: 2;Tag: $1001;  Name:'RelatedImageWidth'      ),
  (TID:0;TType:0;ICode: 2;Tag: $1002;  Name:'RelatedImageHeight'     ),
  (TID:0;TType:0;ICode: 2;Tag: $5001;  Name:'ResolutionXUnit'        ),
  (TID:0;TType:0;ICode: 2;Tag: $5002;  Name:'ResolutionYUnit'        ),
  (TID:0;TType:0;ICode: 2;Tag: $5003;  Name:'ResolutionXLengthUnit'  ),         {90}
  (TID:0;TType:0;ICode: 2;Tag: $5004;  Name:'ResolutionYLengthUnit'  ),
  (TID:0;TType:0;ICode: 2;Tag: $5005;  Name:'PrintFlags'             ),
  (TID:0;TType:0;ICode: 2;Tag: $5006;  Name:'PrintFlagsVersion'      ),
  (TID:0;TType:0;ICode: 2;Tag: $5007;  Name:'PrintFlagsCrop'         ),
  (TID:0;TType:0;ICode: 2;Tag: $5008;  Name:'PrintFlagsBleedWidth'   ),
  (TID:0;TType:0;ICode: 2;Tag: $5009;  Name:'PrintFlagsBleedWidthScale'),
  (TID:0;TType:0;ICode: 2;Tag: $500A;  Name:'HalftoneLPI'            ),
  (TID:0;TType:0;ICode: 2;Tag: $500B;  Name:'HalftoneLPIUnit'        ),
  (TID:0;TType:0;ICode: 2;Tag: $500C;  Name:'HalftoneDegree'         ),
  (TID:0;TType:0;ICode: 2;Tag: $500D;  Name:'HalftoneShape'          ),         {100}
  (TID:0;TType:0;ICode: 2;Tag: $500E;  Name:'HalftoneMisc'           ),
  (TID:0;TType:0;ICode: 2;Tag: $500F;  Name:'HalftoneScreen'         ),
  (TID:0;TType:0;ICode: 2;Tag: $5010;  Name:'JPEGQuality'            ),
  (TID:0;TType:0;ICode: 2;Tag: $5011;  Name:'GridSize'               ),
  (TID:0;TType:0;ICode: 2;Tag: $5012;  Name:'ThumbnailFormat'        ),
  (TID:0;TType:0;ICode: 2;Tag: $5013;  Name:'ThumbnailWidth'         ),
  (TID:0;TType:0;ICode: 2;Tag: $5014;  Name:'ThumbnailHeight'        ),
  (TID:0;TType:0;ICode: 2;Tag: $5015;  Name:'ThumbnailColorDepth'    ),
  (TID:0;TType:0;ICode: 2;Tag: $5016;  Name:'ThumbnailPlanes'        ),
  (TID:0;TType:0;ICode: 2;Tag: $5017;  Name:'ThumbnailRawBytes'      ),         {110}
  (TID:0;TType:0;ICode: 2;Tag: $5018;  Name:'ThumbnailSize'          ),
  (TID:0;TType:0;ICode: 2;Tag: $5019;  Name:'ThumbnailCompressedSize'),
  (TID:0;TType:0;ICode: 2;Tag: $501A;  Name:'ColorTransferFunction'  ),
  (TID:0;TType:0;ICode: 2;Tag: $501B;  Name:'ThumbnailData'          ),
  (TID:0;TType:0;ICode: 2;Tag: $5020;  Name:'ThumbnailImageWidth'    ),
  (TID:0;TType:0;ICode: 2;Tag: $5021;  Name:'ThumbnailImageHeight'   ),
  (TID:0;TType:0;ICode: 2;Tag: $5022;  Name:'ThumbnailBitsPerSample' ),
  (TID:0;TType:0;ICode: 2;Tag: $5023;  Name:'ThumbnailCompression'   ),
  (TID:0;TType:0;ICode: 2;Tag: $5024;  Name:'ThumbnailPhotometricInterp'),
  (TID:0;TType:0;ICode: 2;Tag: $5025;  Name:'ThumbnailImageDescription' ),      {120}
  (TID:0;TType:0;ICode: 2;Tag: $5026;  Name:'ThumbnailEquipMake'     ),
  (TID:0;TType:0;ICode: 2;Tag: $5027;  Name:'ThumbnailEquipModel'    ),
  (TID:0;TType:0;ICode: 2;Tag: $5028;  Name:'ThumbnailStripOffsets'  ),
  (TID:0;TType:0;ICode: 2;Tag: $5029;  Name:'ThumbnailOrientation'   ),
  (TID:0;TType:0;ICode: 2;Tag: $502A;  Name:'ThumbnailSamplesPerPixel'),
  (TID:0;TType:0;ICode: 2;Tag: $502B;  Name:'ThumbnailRowsPerStrip'  ),
  (TID:0;TType:0;ICode: 2;Tag: $502C;  Name:'ThumbnailStripBytesCount'),
  (TID:0;TType:0;ICode: 2;Tag: $502D;  Name:'ThumbnailResolutionX'   ),
  (TID:0;TType:0;ICode: 2;Tag: $502E;  Name:'ThumbnailResolutionY'   ),
  (TID:0;TType:0;ICode: 2;Tag: $502F;  Name:'ThumbnailPlanarConfig'  ),         {130}
  (TID:0;TType:0;ICode: 2;Tag: $5030;  Name:'ThumbnailResolutionUnit'),
  (TID:0;TType:0;ICode: 2;Tag: $5031;  Name:'ThumbnailTransferFunction'),
  (TID:0;TType:0;ICode: 2;Tag: $5032;  Name:'ThumbnailSoftwareUsed'  ),
  (TID:0;TType:0;ICode: 2;Tag: $5033;  Name:'ThumbnailDateTime'      ),
  (TID:0;TType:0;ICode: 2;Tag: $5034;  Name:'ThumbnailArtist'        ),
  (TID:0;TType:0;ICode: 2;Tag: $5035;  Name:'ThumbnailWhitePoint'    ),
  (TID:0;TType:0;ICode: 2;Tag: $5036;  Name:'ThumbnailPrimaryChromaticities'),
  (TID:0;TType:0;ICode: 2;Tag: $5037;  Name:'ThumbnailYCbCrCoefficients'    ),
  (TID:0;TType:0;ICode: 2;Tag: $5038;  Name:'ThumbnailYCbCrSubsampling'     ),
  (TID:0;TType:0;ICode: 2;Tag: $5039;  Name:'ThumbnailYCbCrPositioning'     ),  {140}
  (TID:0;TType:0;ICode: 2;Tag: $503A;  Name:'ThumbnailRefBlackWhite' ),
  (TID:0;TType:0;ICode: 2;Tag: $503B;  Name:'ThumbnailCopyRight'     ),
  (TID:0;TType:0;ICode: 2;Tag: $5090;  Name:'LuminanceTable'         ),
  (TID:0;TType:0;ICode: 2;Tag: $5091;  Name:'ChrominanceTable'       ),
  (TID:0;TType:0;ICode: 2;Tag: $5100;  Name:'FrameDelay'             ),
  (TID:0;TType:0;ICode: 2;Tag: $5101;  Name:'LoopCount'              ),
  (TID:0;TType:0;ICode: 2;Tag: $5110;  Name:'PixelUnit'              ),
  (TID:0;TType:0;ICode: 2;Tag: $5111;  Name:'PixelPerUnitX'          ),
  (TID:0;TType:0;ICode: 2;Tag: $5112;  Name:'PixelPerUnitY'          ),
  (TID:0;TType:0;ICode: 2;Tag: $5113;  Name:'PaletteHistogram'       ),         {150}
  (TID:0;TType:0;ICode: 2;Tag: $800D;  Name:'ImageID'                ),
  (TID:0;TType:0;ICode: 2;Tag: $80E3;  Name:'Matteing'               ),   //* obsoleted by ExtraSamples */
  (TID:0;TType:0;ICode: 2;Tag: $80E4;  Name:'DataType'               ),   //* obsoleted by SampleFormat */
  (TID:0;TType:0;ICode: 2;Tag: $80E5;  Name:'ImageDepth'             ),
  (TID:0;TType:0;ICode: 2;Tag: $80E6;  Name:'TileDepth'              ),
  (TID:0;TType:0;ICode: 2;Tag: $828D;  Name:'CFARepeatPatternDim'    ),
  (TID:0;TType:0;ICode: 2;Tag: $828E;  Name:'CFAPattern'             ),
  (TID:0;TType:0;ICode: 2;Tag: $828F;  Name:'BatteryLevel'           ),
  (TID:0;TType:0;ICode: 2;Tag: $8298;  Name:'Copyright'              ),
  (TID:0;TType:0;ICode: 2;Tag: $829A;  Name:'ExposureTime'             ; Desc:'Exposure time'; Code:''; Data:''; Raw:''; PRaw:0; FormatS:'%s sec'),   {160}
  (TID:0;TType:0;ICode: 2;Tag: $829D;  Name:'FNumber'                  ; Desc:''; Code:''; Data:''; Raw:''; PRaw:0; FormatS:'F%0.1f'),
  (TID:0;TType:0;ICode: 2;Tag: $83BB;  Name:'IPTC/NAA'                 ; Desc:'IPTC/NAA'),
  (TID:0;TType:0;ICode: 2;Tag: $84E3;  Name:'IT8RasterPadding'         ),
  (TID:0;TType:0;ICode: 2;Tag: $84E5;  Name:'IT8ColorTable'            ),
  (TID:0;TType:0;ICode: 2;Tag: $8649;  Name:'ImageResourceInformation' ),
  (TID:0;TType:0;ICode: 2;Tag: $8769;  Name:'ExifOffset'               ),
  (TID:0;TType:0;ICode: 2;Tag: $8773;  Name:'InterColorProfile'        ),
  (TID:0;TType:0;ICode: 2;Tag: $8822;  Name:'ExposureProgram'          ; Desc:'';Code:
        '0:Unidentified,1:Manual,2:Normal,3:Aperture priority,'+
        '4:Shutter priority,5:Creative(slow),'+
        '6:Action(high-speed),7:Portrait mode,8:Landscape mode'),
  (TID:0;TType:0;ICode: 2;Tag: $8824;  Name:'SpectralSensitivity'    ),
  (TID:0;TType:0;ICode: 2;Tag: $8825;  Name:'GPSInfo'                ),         {170}
  (TID:0;TType:0;ICode: 2;Tag: $8827;  Name:'ISOSpeedRatings'        ),
  (TID:0;TType:0;ICode: 2;Tag: $8828;  Name:'OECF'                   ),
  (TID:0;TType:0;ICode: 2;Tag: $8829;  Name:'Interlace'              ),
  (TID:0;TType:0;ICode: 2;Tag: $882A;  Name:'TimeZoneOffset'         ),
  (TID:0;TType:0;ICode: 2;Tag: $882B;  Name:'SelfTimerMode'          ),
  (TID:0;TType:0;ICode: 2;Tag: $9000;  Name:'ExifVersion'            ),
  (TID:0;TType:0;ICode: 2;Tag: $9003;  Name:'DateTimeOriginal'       ),
  (TID:0;TType:0;ICode: 2;Tag: $9004;  Name:'DateTimeDigitized'      ),
//  (TID:0;TType:0;ICode: 2;Tag: $9101;  Name:'ComponentsConfiguration'; Callback: GenCompConfig),
  (TID:0;TType:0;ICode: 2;Tag: $9102;  Name:'CompressedBitsPerPixel' ),         {180}
  (TID:0;TType:0;ICode: 2;Tag: $9201;  Name:'ShutterSpeedValue'      ; Desc:''; Code:''; Data:''; Raw:''; PRaw:0; FormatS:''; Size:0; Callback:@SSpeedCallBack),
  (TID:0;TType:0;ICode: 2;Tag: $9202;  Name:'ApertureValue'          ; Desc:'Aperture value'; Code:''; Data:''; Raw:''; PRaw:0; FormatS:'F%0.1f'),
  (TID:0;TType:0;ICode: 2;Tag: $9203;  Name:'BrightnessValue'        ),
  (TID:0;TType:0;ICode: 2;Tag: $9204;  Name:'ExposureBiasValue'      ),
  (TID:0;TType:0;ICode: 2;Tag: $9205;  Name:'MaxApertureValue'       ; Desc:''; Code:''; Data:''; Raw:''; PRaw:0; FormatS:'F%0.1f'),
  (TID:0;TType:0;ICode: 2;Tag: $9206;  Name:'SubjectDistance'        ),
  (TID:0;TType:0;ICode: 2;Tag: $9207;  Name:'MeteringMode'           ; Desc:'';Code:'0:Unknown,1:Average,2:Center,3:Spot,4:MultiSpot,5:MultiSegment,6:Partial'),
  (TID:0;TType:0;ICode: 2;Tag: $9208;  Name:'LightSource'            ; Desc:'';Code:'0:Unidentified,1:Daylight,2:Fluorescent,3:Tungsten,10:Flash,17:Std A,18:Std B,19:Std C'),
  (TID:0;TType:0;ICode: 2;Tag: $9209;  Name:'Flash'                  ; Desc:'';Code:''; Data:''; Raw:''; PRaw:0; FormatS:''; Size:0; CallBack:@FlashCallBack),
  (TID:0;TType:0;ICode: 2;Tag: $920A;  Name:'FocalLength'            ; Desc:'Focal length'; Code:''; Data:''; Raw:''; PRaw:0; FormatS:'%5.2f mm'), {190}
  (TID:0;TType:0;ICode: 2;Tag: $920B;  Name:'FlashEnergy'             ),
  (TID:0;TType:0;ICode: 2;Tag: $920C;  Name:'SpatialFrequencyResponse'),
  (TID:0;TType:0;ICode: 2;Tag: $920D;  Name:'Noise'                   ),
  (TID:0;TType:0;ICode: 2;Tag: $920E;  Name:'FocalPlaneXResolution'   ),      // TID:0;TType:0;ICode: 2;Tag: $920E    -  -
  (TID:0;TType:0;ICode: 2;Tag: $920F;  Name:'FocalPlaneYResolution'   ),	    // TID:0;TType:0;ICode: 2;Tag: $920F    -  -
  (TID:0;TType:0;ICode: 2;Tag: $9210;  Name:'FocalPlaneResolutionUnit';  Desc:'';Code:'1:None Specified,2:Inch,3:Centimeter'),      // TID:0;TType:0;ICode: 2;Tag: $9210    -  -
  (TID:0;TType:0;ICode: 2;Tag: $9211;  Name:'ImageNumber'            ),
  (TID:0;TType:0;ICode: 2;Tag: $9212;  Name:'SecurityClassification' ),
  (TID:0;TType:0;ICode: 2;Tag: $9213;  Name:'ImageHistory'           ),
  (TID:0;TType:0;ICode: 2;Tag: $9214;  Name:'SubjectLocation'        ),         {200}
  (TID:0;TType:0;ICode: 2;Tag: $9215;  Name:'ExposureIndex'          ),
  (TID:0;TType:0;ICode: 2;Tag: $9216;  Name:'TIFF/EPStandardID'      ),
  (TID:0;TType:0;ICode: 2;Tag: $9217;  Name:'SensingMethod'          ),
  (TID:0;TType:0;ICode: 2;Tag: $923F;  Name:'StoNits'                ),
  (TID:0;TType:0;ICode: 2;Tag: $927C;  Name:'MakerNote'              ),
  (TID:0;TType:0;ICode: 2;Tag: $9286;  Name:'UserComment'            ; Desc:''; Code:''; Data:''; Raw:''; PRaw:0; FormatS:''; Size:0; Callback: @ExtractComment),
  (TID:0;TType:0;ICode: 2;Tag: $9290;  Name:'SubSecTime'             ),
  (TID:0;TType:0;ICode: 2;Tag: $9291;  Name:'SubSecTimeOriginal'     ),
  (TID:0;TType:0;ICode: 2;Tag: $9292;  Name:'SubSecTimeDigitized'    ),
  (TID:0;TType:0;ICode: 2;Tag: $953C;  Name:'ImageSourceData'        ),  // "Adobe Photoshop Document Data Block": 8BIM...  {210}
//  (TID:0;TType:0;ICode: 2;Tag: $9C9B;  Name:'Title'                  ;  Callback: xpTranslate),  // Win XP specific, Unicode
//  (TID:0;TType:0;ICode: 2;Tag: $9C9C;  Name:'Comments'               ;  Callback: xpTranslate),  // Win XP specific, Unicode
//  (TID:0;TType:0;ICode: 2;Tag: $9C9D;  Name:'Author'                 ;  Callback: xpTranslate),  // Win XP specific, Unicode
//  (TID:0;TType:0;ICode: 2;Tag: $9C9E;  Name:'Keywords'               ;  Callback: xpTranslate),  // Win XP specific, Unicode
//  (TID:0;TType:0;ICode: 2;Tag: $9C9F;  Name:'Subject'                ;  Callback: xpTranslate),  // Win XP specific, Unicode
  (TID:0;TType:0;ICode: 2;Tag: $A000;  Name:'FlashPixVersion'        ),
  (TID:0;TType:0;ICode: 2;Tag: $A001;  Name:'ColorSpace'             ; Desc:''; Code:'0:sBW,1:sRGB'),
  (TID:0;TType:0;ICode: 2;Tag: $A002;  Name:'ExifImageWidth'         ),
  (TID:0;TType:0;ICode: 2;Tag: $A003;  Name:'ExifImageLength'        ),
  (TID:0;TType:0;ICode: 2;Tag: $A004;  Name:'RelatedSoundFile'       ),         {220}
  (TID:0;TType:0;ICode: 2;Tag: $A005;  Name:'InteroperabilityOffset' ),
  (TID:0;TType:0;ICode: 2;Tag: $A20B;  Name:'FlashEnergy'            ),    // TID:0;TType:0;ICode: 2;Tag: $920B in TIFF/EP
  (TID:0;TType:0;ICode: 2;Tag: $A20C;  Name:'SpatialFrequencyResponse'),   // TID:0;TType:0;ICode: 2;Tag: $920C    -  -
  (TID:0;TType:0;ICode: 2;Tag: $A20E;  Name:'FocalPlaneXResolution'   ),      // TID:0;TType:0;ICode: 2;Tag: $920E    -  -
  (TID:0;TType:0;ICode: 2;Tag: $A20F;  Name:'FocalPlaneYResolution'   ),	    // TID:0;TType:0;ICode: 2;Tag: $920F    -  -
  (TID:0;TType:0;ICode: 2;Tag: $A210;  Name:'FocalPlaneResolutionUnit'; Desc:'';Code:'1:None Specified,2:Inch,3:Centimeter'),      // TID:0;TType:0;ICode: 2;Tag: $9210    -  -
  (TID:0;TType:0;ICode: 2;Tag: $A211;  Name:'ImageNumber'             ),
  (TID:0;TType:0;ICode: 2;Tag: $A212;  Name:'SecurityClassification'  ),
  (TID:0;TType:0;ICode: 2;Tag: $A213;  Name:'ImageHistory'            ),
  (TID:0;TType:0;ICode: 2;Tag: $A214;  Name:'SubjectLocation'         ),        {230}
  (TID:0;TType:0;ICode: 2;Tag: $A215;  Name:'ExposureIndex'           ),
  (TID:0;TType:0;ICode: 2;Tag: $A216;  Name:'TIFF/EPStandardID'       ;   Desc:'TIFF/EPStandardID' ),
  (TID:0;TType:0;ICode: 2;Tag: $A217;  Name:'SensingMethod'           ;   Desc:'';Code:'0:Unknown,1:MonochromeArea,'+
    '2:OneChipColorArea,3:TwoChipColorArea,4:ThreeChipColorArea,'+
    '5:ColorSequentialArea,6:MonochromeLinear,7:TriLinear,'+
    '8:ColorSequentialLinear'),	       	           // TID:0;TType:0;ICode: 2;Tag: $9217    -  -
  (TID:0;TType:0;ICode: 2;Tag: $A300;  Name:'FileSource'              ;  Desc:'';Code:'0:Unknown,1:Film scanner,2:Reflection print scanner,3:Digital camera'),
  (TID:0;TType:0;ICode: 2;Tag: $A301;  Name:'SceneType'               ;  Desc:'';Code:'0:Unknown,1:Directly Photographed'),
  (TID:0;TType:0;ICode: 2;Tag: $A302;  Name:'CFAPattern'              ),
  (TID:0;TType:0;ICode: 2;Tag: $A401;  Name:'CustomRendered'          ;  Desc:'';Code:'0:Normal process,1:Custom process'),
  (TID:0;TType:0;ICode: 2;Tag: $A402;  Name:'ExposureMode'            ;  Desc:'';Code:'0:Auto,1:Manual,2:Auto bracket'),
  (TID:0;TType:0;ICode: 2;Tag: $A403;  Name:'WhiteBalance'            ;  Desc:'';Code:'0:Auto,1:Manual'),
  (TID:0;TType:0;ICode: 2;Tag: $A404;  Name:'DigitalZoomRatio'        ),        {240}
  (TID:0;TType:0;ICode: 2;Tag: $A405;  Name:'FocalLengthIn35mmFilm'   ;  Desc:'Focal Length in 35mm Film'; Code:''; Data:''; Raw:''; PRaw:0; FormatS:'%5.2f mm'),
  (TID:0;TType:0;ICode: 2;Tag: $A406;  Name:'SceneCaptureType'        ;  Desc:'';Code:'0:Standard,1:Landscape,2:Portrait,3:Night scene'),
  (TID:0;TType:0;ICode: 2;Tag: $A407;  Name:'GainControl'             ; Desc:''; Code:'0:None,1:Low gain up,2:High gain up,3:Low gain down,4:High gain down'),
  (TID:0;TType:0;ICode: 2;Tag: $A408;  Name:'Contrast'                ; Desc:''; Code:'0:Normal,1:Soft,2:Hard'),
  (TID:0;TType:0;ICode: 2;Tag: $A409;  Name:'Saturation'              ; Desc:''; Code:'0:Normal,1:Low,2:High'),
  (TID:0;TType:0;ICode: 2;Tag: $A40A;  Name:'Sharpness'               ; Desc:''; Code:'0:Normal,1:Soft,2:Hard'),
  (TID:0;TType:0;ICode: 2;Tag: $A40B;  Name:'DeviceSettingDescription'),
  (TID:0;TType:0;ICode: 2;Tag: $A40C;  Name:'SubjectDistanceRange'    ; Desc:''; Code:'0:Unknown,1:Macro,2:Close view,3:Distant view'),  {250}
  (TID:0;TType:0;ICode: 2;Tag: $A420;  Name:'ImageUniqueID'           ; Desc:''; Code:'0:Close view,1:Distant view'),  {250}
  (TID:0;TType:0;ICode: 2;Tag: 0;      Name:'Unknown'));                        {250}


 GPSTable : array [0..GPSCnt-1] of TTagEntry =
 ((TID:0;TType:0;ICode: 2;Tag: $000;   Name:'GPSVersionID'           ),
  (TID:0;TType:0;ICode: 2;Tag: $001;   Name:'GPSLatitudeRef'         ),
  (TID:0;TType:0;ICode: 2;Tag: $002;   Name:'GPSLatitude'            ; Desc:''; Code:''; Data:''; Raw:''; PRaw:0; FormatS:''; Size:0; CallBack:@GpsPosn),
  (TID:0;TType:0;ICode: 2;Tag: $003;   Name:'GPSLongitudeRef'        ),
  (TID:0;TType:0;ICode: 2;Tag: $004;   Name:'GPSLongitude'           ; Desc:''; Code:''; Data:''; Raw:''; PRaw:0; FormatS:''; Size:0; CallBack:@GpsPosn),
  (TID:0;TType:0;ICode: 2;Tag: $005;   Name:'GPSAltitudeRef'         ;  Desc:''; Code:'0:Above Sealevel,1:Below Sealevel'),
//  (TID:0;TType:0;ICode: 2;Tag: $006;   Name:'GPSAltitude'            ;   CallBack:GpsAltitude),
//  (TID:0;TType:0;ICode: 2;Tag: $007;   Name:'GPSTimeStamp'           ;   CallBack:CvtTime),
  (TID:0;TType:0;ICode: 2;Tag: $008;   Name:'GPSSatellites'          ),
  (TID:0;TType:0;ICode: 2;Tag: $009;   Name:'GPSStatus'              ),
  (TID:0;TType:0;ICode: 2;Tag: $00A;   Name:'GPSMeasureMode'         ),
  (TID:0;TType:0;ICode: 2;Tag: $00B;   Name:'GPSDOP'                 ),
  (TID:0;TType:0;ICode: 2;Tag: $00C;   Name:'GPSSpeedRef'            ),
  (TID:0;TType:0;ICode: 2;Tag: $00D;   Name:'GPSSpeed'               ),
  (TID:0;TType:0;ICode: 2;Tag: $00E;   Name:'GPSTrackRef'            ),
  (TID:0;TType:0;ICode: 2;Tag: $00F;   Name:'GPSTrack'               ),
  (TID:0;TType:0;ICode: 2;Tag: $010;   Name:'GPSImageDirectionRef'   ),
  (TID:0;TType:0;ICode: 2;Tag: $011;   Name:'GPSImageDirection'      ),
  (TID:0;TType:0;ICode: 2;Tag: $012;   Name:'GPSMapDatum'            ),
  (TID:0;TType:0;ICode: 2;Tag: $013;   Name:'GPSDestLatitudeRef'     ),
//  (TID:0;TType:0;ICode: 2;Tag: $014;   Name:'GPSDestLatitude'        ;   CallBack:GpsPosn),
  (TID:0;TType:0;ICode: 2;Tag: $015;   Name:'GPSDestLongitudeRef'    ),
//  (TID:0;TType:0;ICode: 2;Tag: $016;   Name:'GPSDestLongitude'       ;   CallBack:GpsPosn),
  (TID:0;TType:0;ICode: 2;Tag: $017;   Name:'GPSDestBearingkRef'     ),
  (TID:0;TType:0;ICode: 2;Tag: $018;   Name:'GPSDestBearing'         ),
  (TID:0;TType:0;ICode: 2;Tag: $019;   Name:'GPSDestDistanceRef'     ),
  (TID:0;TType:0;ICode: 2;Tag: $01A;   Name:'GPSDestDistance'        ),
  (TID:0;TType:0;ICode: 2;Tag: $01B;   Name:'GPSProcessingMode'      ),
  (TID:0;TType:0;ICode: 2;Tag: $01C;   Name:'GPSAreaInformation'     ),
  (TID:0;TType:0;ICode: 2;Tag: $01D;   Name:'GPSDateStamp'           ),
  (TID:0;TType:0;ICode: 2;Tag: $01E;   Name:'GPSDifferential'        )
  );

  tagInit : boolean = false;

Procedure FixTagTable(var tags:array of TTagEntry);
var i:integer;
begin
  for i := low(tags) to high(tags) do
  begin
    if Length(tags[i].Desc) <= 0 then
      tags[i].Desc := tags[i].Name;
  end;
end;

Function InsertSpaces(instr:string):string;
var i:integer;
  rslt:string;
  tc:char;
  lastUc:boolean;
begin
  LastUC := true;
  rslt := copy(instr,1,1);
  for i := 2 to length(instr) do
  begin
    tc := instr[i];
    if (tc >= 'A') and (tc <= 'Z') then
    begin
      if LastUC then
        rslt := rslt+tc
      else
        rslt := rslt+' '+tc;
      LastUc := true;
    end
    else
    begin
      lastUC := false;
      rslt := rslt+tc;
    end;
  end;
  result := rslt;
end;

Procedure FixTagTableParse(var tags:array of TTagEntry);
var i:integer;
begin
  for i := low(tags) to high(tags) do
  begin
    if Length(tags[i].Desc) <= 0 then
      tags[i].Desc := InsertSpaces(tags[i].Name);
  end;
end;

procedure LoadTagDescs(fancy:boolean = false);
begin
  if tagInit
    then exit
    else tagInit := true;
  if fancy then
  begin
    FixTagTableParse(TagTable);
    FixTagTableParse(GPSTable);
  end
  else
  begin
    FixTagTable(TagTable);
    FixTagTable(GPSTable);
  end;
end;

Function CvtIrrational( instr:string ):double;
var b1,b2:string;
    intMult,op:integer;
begin
  result := 0.0;
  instr := trim(instr);
  try
    op := pos(' ',instr);
    if op > 0 then
    begin
      intMult := StrToint(copy(instr,1,op-1));
      instr := copy(instr,op+1,length(instr));
    end
    else
      intMult := 0;
    op := pos('/',instr);
    b1 := copy(instr,1,op-1);
    b2 := copy(instr,op+1,length(instr));
    result := (intMult*StrToInt(b2)+StrToInt(b1)) / StrToInt(b2);
  except
  end;
end;

function LookupMTagID(idx:integer; ManuTable: array of TTagEntry):integer;
var i:integer;
begin
  result := -1;
  for i := 0 to high(ManuTable) do
    if ManuTable[i].Tag = idx then
    begin
      result := i;
      break;
    end;
end;

function LookupType(idx:integer):string;
var i:integer;
begin
  result := 'Unknown';
  for i := 0 to (sizeof(processTable) div sizeof(TTagEntry))-1 do
    if ProcessTable[i].Tag = idx then
      result := ProcessTable[i].desc;
end;

// These destructors provided by Keith Murray
// of byLight Technologies - Thanks!
Destructor TImageInfo.Destroy;
begin
  SetLength(fITagArray,0);
  inherited;
end;

//  This function returns the index of a tag name
//  in the tag buffer.
Function TImageInfo.LookupTag(SearchStr:string):integer;
var i: integer;
begin
 SearchStr := UpperCase(SearchStr);
 result := -1;
 for i := 0 to fiTagCount-1 do
   if UpperCase(fiTagArray[i].Name) = SearchStr then
   begin
     result := i;
     break;
   end;
end;

//  This function returns the data value for a
//  given tag name.
Function TImageInfo.LookupTagVal(SearchStr:string):string;
var i: integer;
begin
 SearchStr := UpperCase(SearchStr);
 result := '';
 for i := 0 to fiTagCount-1 do
   if UpperCase(fiTagArray[i].Name) = SearchStr then
   begin
     result := fiTagArray[i].Data;
     break;
   end;
end;

//  This function returns the data value for a
//  given tag name.
Function TImageInfo.LookupTagInt(SearchStr:string):integer;
var i: integer;
begin
 SearchStr := UpperCase(SearchStr);
 result := -1;
 for i := 0 to fiTagCount-1 do
   if UpperCase(fiTagArray[i].Name) = SearchStr then
   begin
     result := strtoint(fiTagArray[i].Data);
     break;
   end;
end;

//  This function returns the index of a tag name
//  in the tag buffer. It searches by the description
//  which is most likely to be used as a label
Function TImageInfo.LookupTagByDesc(SearchStr:string):integer;
var i: integer;
begin
 SearchStr := UpperCase(SearchStr);
 result := -1;
 for i := 0 to FITagCount-1 do
   if UpperCase(fiTagArray[i].Desc) = SearchStr then
   begin
     result := i;
     break;
   end;
end;

Function TImageInfo.GetTagByDesc(SearchStr:string):TTagEntry;
var i:integer;
begin
  i := LookupTagByDesc(SearchStr);
  if i >= 0 then
    result := fiTagArray[i]
  else
    result := EmptyEntry;
end;

//  This function returns the index of a tag definition
//  for a given tag name.
function TImageInfo.LookupTagDefn(item: string): integer;
var i:integer;
begin
  result := -1;
  for i := 0 to ExifTagCnt-1 do
  begin
    if lowercase(item) = lowercase(TagTable[i].Name) then
    begin
      result := i;
      break;
    end;
  end;
end;

function LookupTagByID(idx:integer;TagType:integer=ExifTag):integer;
var i:integer;
begin
  result := -1;
  case tagType of
    ThumbTag,
    ExifTag: for i := 0 to ExifTagCnt do
               if TagTable[i].Tag = idx then
                 result := i;
     GpsTag: for i := 0 to GPSCnt do
               if GPSTable[i].Tag = idx then
                 result := i;
  else
  end;
end;

function FetchTagByID(idx:integer;TagType:integer=ExifTag):TTagEntry;
var i:integer;
begin
  result := TagTable[ExifTagCnt-1];
  case tagType of
    ThumbTag,
    ExifTag: for i := 0 to ExifTagCnt-1 do
               if TagTable[i].Tag = idx then
                 result := TagTable[i];
     GpsTag: for i := 0 to GPSCnt-1 do
               if GPSTable[i].Tag = idx then
                 result := GPSTable[i];
  else
  end;
end;

function LookupCode(idx:integer;TagType:integer=ExifTag):string; overload;
var i:integer;
begin
  result := '';
  case tagType of
    ThumbTag,
    ExifTag: for i := 0 to ExifTagCnt do
               if TagTable[i].Tag = idx then
                 result := TagTable[i].Code;
     GpsTag: for i := 0 to GPSCnt do
               if GPSTable[i].Tag = idx then
                 result := GPSTable[i].Code;
  else
  end;
end;

function LookupCode(idx:integer;TagTbl:array of TTagEntry):string; overload;
var i:integer;
begin
  result := '';
  for i := 0 to high(TagTbl) do
    if TagTbl[i].Tag = idx then
      result := TagTbl[i].Code;
end;


// Careful : this function's arguments are always
// evaluated which may have unintended side-effects
// (thanks to Jan Derk for pointing this out)
function siif( const cond:boolean; const s1:string; const s2:string=''):string;
begin
  if cond
    then result := s1
    else result := s2;
end;

procedure TImageInfo.Assign(Source: TImageInfo);
begin
  CameraMake      := Source.CameraMake;
  CameraModel     := Source.CameraModel;
  DateTime        := Source.DateTime;
  Height          := Source.Height;
  Width           := Source.Width;
  FlashUsed       := Source.FlashUsed;
  MakerNote       := Source.MakerNote;
  TraceStr        := Source.TraceStr;
  msTraceStr      := Source.msTraceStr;
  msAvailable     := Source.msAvailable;
  msName          := Source.msName;
end;

const BadVal = -1;

function TImageInfo.ExifDateToDateTime(dstr:string):TDateTime;
type
  TConvert= packed record
     year: Array [1..4] of char; f1:char;
     mon:  Array [1..2] of Char; f2:char;
     day:  Array [1..2] of Char; f3:char;
     hr:   Array [1..2] of Char; f4:char;
     min:  Array [1..2] of Char; f5:char;
     sec:  Array [1..2] of Char;
  end;
  PConvert= ^TConvert;
begin
   try
     with PConvert( @dstr[1] )^ do
       Result := EncodeDate( StrToInt( year ),
                             StrToInt( mon ),
                             StrToInt( day ))
              +  EncodeTime( StrToInt( hr  ),
                             StrToInt( min ),
                             StrToInt( sec ), 0);
   except
     result := 0;
   end;
end;

function TImageInfo.ExtrDateTime(oset:integer):TDateTime;
var tmpStr:string;
begin
  tmpStr := copy(parent.exifSegment^.data,oset,19);
  result := ExifDateToDateTime(tmpStr);
end;

//  2001:01:09 16:17:32
Procedure TImageInfo.SetDateTimeStr(oset:integer; TimeIn:TDateTime);
var tmp:string;
  i:integer;
begin
  tmp := FormatDateTime('yyyy:mm:dd hh:nn:ss',TimeIn);
  for i := 1 to length(tmp) do
    parent.ExifSegment^.data[oset+i-1] := tmp[i];
end;

function TImageInfo.GetImgDateTime:TDateTime;
var x: TDateTime;
begin
  x := 0.0;
  if dt_oset > 0 then
    x := ExtrDateTime(dt_oset)
  else if dt_orig_oset > 0 then
    x := ExtrDateTime(dt_orig_oset)
  else if dt_digi_oset > 0 then
    x := ExtrDateTime(dt_digi_oset);
  result := x;
end;

Procedure TImageInfo.AdjDateTime(days,hours,mins,secs:integer);
var delta:double;
    x: TDateTime;
begin
  //                hrs/day     min/day        sec/day
  delta := days + (hours/24)+ (mins/1440) + (secs/86400);
  if dt_oset > 0 then
  begin
    x := ExtrDateTime(dt_oset);
    SetDateTimeStr(dt_oset,x+delta);
  end;
  if dt_orig_oset > 0 then
  begin
    x := ExtrDateTime(dt_orig_oset);
    SetDateTimeStr(dt_orig_oset,x+delta);
  end;
  if dt_digi_oset > 0 then
  begin
    x := ExtrDateTime(dt_digi_oset);
    SetDateTimeStr(dt_digi_oset,x+delta);
  end;
end;

Procedure TImageInfo.OverwriteDateTime(InTime:tdatetime);
begin
  if dt_oset > 0 then
    SetDateTimeStr(dt_oset,InTime);
  if dt_orig_oset > 0 then
    SetDateTimeStr(dt_orig_oset,InTime);
  if dt_digi_oset > 0 then
    SetDateTimeStr(dt_digi_oset,InTime);
end;

Function CvtTime(instr:string) :string;
var i,sl:integer;
    tb:string;
    tHours,tMin,tSec:double;
begin
   sl := length(DexifDataSep);
   result := instr;                   // if error return input string
   i := pos(DexifDataSep,instr);
   tb    := copy(instr,1,i-1);        // get first irrational number
   tHours := CvtIrrational(tb);       // bottom of lens speed range
   instr := copy(instr,i+sl-1,64);
   i := pos(DexifDataSep,instr);
   tb    := copy(instr,1,i-1);        // get second irrational number
   tMin := CvtIrrational(tb);     // minimum focal length
   instr := copy(instr,i+1,64);
   tSec := CvtIrrational(instr);  // maximum focal length
   // Ok we'll send the result back as Degrees with
   // Decimal Minutes.  Alternatively send back as Degree
   // Minutes, Seconds or Decimal Degrees.
   result := format('%0.0f:%0.0f:%0.0f', [tHours,tMin,tSec]);
end;


Function GenCompConfig(instr:string) :string;
var i,ti:integer;
    ts:string;
begin
  ts := '';
  for i := 1+1 to 4+1 do  // skip first char...
  begin
    ti := integer(instr[i]);
    case ti of
      1: ts := ts+'Y';
      2: ts := ts+'Cb';
      3: ts := ts+'Cr';
      4: ts := ts+'R';
      5: ts := ts+'G';
      6: ts := ts+'B';
    else
    end;
  end;
  result := ts;
end;

Function GpsPosn(instr:string) :string;
var i,sl:integer;
    tb:string;
    gDegree,gMin,gSec:double;
begin
   sl := length(DexifDataSep);
   result := instr;                     // if error return input string
   i := pos(DexifDataSep,instr);
   tb    := copy(instr,1,i-1);          // get first irrational number
   gDegree := CvtIrrational(tb);        // degrees
   instr := copy(instr,i+sl-1,64);
   i := pos(DexifDataSep,instr);
   tb    := copy(instr,1,i-1);          // get second irrational number
   gMin := CvtIrrational(tb);           // minutes
   instr := copy(instr,i+sl-1,64);
   gSec := CvtIrrational(instr);        // seconds
   if gSec = 0 then  // camera encoded as decimal minutes
   begin
     gSec := ((gMin-trunc(gMin))*100);  // seconds as a fraction of degrees
     gSec := gSec * 0.6;                // convert to seconds
     gMin := trunc(gMin);               // minutes is whole portion
   end;
   // Ok we'll send the result back as Degrees with
   // Decimal Minutes.  Alternatively send back as Degree
   // Minutes, Seconds or Decimal Degrees.
   case GpsFormat of
      gf_DD: result :=
          format('%1.4f Decimal Degrees',[gDegree + ((gMin + (gSec/60))/60)]);
      gf_DM: result :=
          format('%0.0f Degrees %1.2f Minutes',[gDegree, gMin + (gsec/60)]);
     gf_DMS: result :=
          format('%0.0f Degrees %0.0f Minutes %0.0f Seconds', [gDegree,gMin,gSec]);
   else
   end;
end;

function DecodeField(DecodeStr,idx:string):string;
var stPos:integer;
    ts:string;
begin
   result := '';
   idx := DexifDecodeSep+trim(idx)+':';   // ease parsing
   decodeStr := DexifDecodeSep+decodeStr+DexifDecodeSep;
   stPos := pos(idx,DecodeStr);
   if stPos > 0 then
   begin
     ts := copy(DecodeStr,stPos+length(idx),length(decodeStr));
     result := copy(ts,1,pos(DexifDecodeSep,ts)-1);
   end
end;

function TImageInfo.AddTagToArray(nextTag:iTag):integer;
begin
  if nextTag.tag <> 0 then     // Empty fields are masked out
  begin
    if fITagCount >= MaxTag-1 then
    begin
      inc(MaxTag,TagArrayGrowth);
      SetLength(fITagArray,MaxTag);
    end;
    fITagArray[fITagCount] := nextTag;
    inc(fITagCount);
  end;
  result := fITagCount-1;
end;

function TImageInfo.AddTagToThumbArray(nextTag: iTag): integer;
begin
  if nextTag.tag <> 0 then     // Empty fields are masked out
  begin
    if fIThumbCount >= MaxThumbTag-1 then
    begin
      inc(MaxThumbTag,TagArrayGrowth);
      SetLength(fIThumbArray,MaxThumbTag);
    end;
    fIThumbArray[fIThumbCount] := nextTag;
    inc(fIThumbCount);
  end;
  result := fIThumbCount-1;
end;

function TImageInfo.CvtInt(buff:string):longint;
var i:integer;
    r:Int64;
begin
  r := 0;
  try
  if MotorolaOrder then
    for i := 1 to length(buff) do
      r := r*256+ord(buff[i])
  else
    for i := length(buff) downto 1 do
      r := r*256+ord(buff[i]);
  except
  end;
  result := longint(r);
end;

function TImageInfo.FormatNumber(buffer:string;fmt:integer;
    fmtStr:string;decodeStr:string=''):string;
var buff2,os:string;
    i,vlen:integer;
    tmp,tmp2:longint;
    dv:double;
begin
  os := '';
  vlen := BytesPerFormat[fmt];
  if vlen = 0 then
  begin
    result := '0';
    exit;
  end;
  for i := 0 to min((length(buffer) div vlen), 128)-1 do
  begin
    if os <> '' then
      os := os+DexifDataSep;  // Used for data display
    buff2 := copy(buffer,(i*vlen)+1,vlen);
    case fmt of
      FMT_SBYTE,
      FMT_BYTE,
      FMT_USHORT,
      FMT_ULONG,
      FMT_SSHORT,
      FMT_SLONG:     begin
                       tmp := CvtInt(buff2);
                       if (decodeStr = '') or not DexifDecode then
                         os := os + defIntFmt(tmp) // IntToStr(tmp)
                       else
                         os := os + DecodeField(decodeStr,IntToStr(tmp)); //+
//                           ' ('+IntToStr(tmp)+')';
                     end;
      FMT_URATIONAL,
      FMT_SRATIONAL: begin
                       tmp := CvtInt(copy(buff2,1,4));
                       tmp2 := CvtInt(copy(buff2,5,4));
                       os := os + defFracFmt(tmp,tmp2); //format('%d/%d',[tmp,tmp2]);
                       if (decodeStr <> '') or not DexifDecode then
                         os := os + DecodeField(decodeStr,os); // +' ('+os+')';
                     end;
      FMT_SINGLE,
      FMT_DOUBLE:    begin                       // not used anyway
                       os := os+ '-9999.99';     // not sure how to
                     end;                        // interpret endian issues
    else
      os := os + '?';
    end;
  end;
  if fmtStr <> '' then
  begin
    if pos('%s', fmtStr) > 0 then
    begin
      os := format(fmtStr,[os]);
    end
    else
    begin
      dv := GetNumber(buffer,fmt);
      os := format(fmtStr,[dv]);
    end;
  end;
  result := os;
end;

function TImageInfo.GetNumber(buffer:string;fmt:integer):double;
var os:double;
    tmp:longint;
    dbl:double absolute tmp;
    tmp2:longint;
begin
  try
    case fmt of
      FMT_SBYTE,
      FMT_BYTE,
      FMT_USHORT,
      FMT_ULONG,
      FMT_SSHORT,
      FMT_SLONG:  os := CvtInt(buffer);
      FMT_URATIONAL,
      FMT_SRATIONAL: begin
                       tmp := CvtInt(copy(buffer,1,4));
                       tmp2 := CvtInt(copy(buffer,5,4));
                       os := tmp / tmp2;
                     end;
      FMT_SINGLE: os := dbl;
      FMT_DOUBLE: os := dbl;
    else
      os := 0;
    end;
  except
    os := 0;
  end;
  result := os;
end;

function MakePrintable(s:string):string;
var r:string;
  i:integer;
begin
  for i := 1 to min(length(s),50) do
    if not (ord(s[i]) in [32..255]) then
      r := r+'.'
    else
      r := r+s[i];
  result := r;
end;

function MakeHex(s:string):string;
var r:string;
  i:integer;
begin
  for i := 1 to min(length(s),16) do
    r := r+IntToHex(ord(s[i]),2)+' ';
  if length(s) > 16 then
    r := r+'...';
  result := r;
end;

var dirStack:string = '';

procedure TImageInfo.clearDirStack;
begin
  dirStack := '';
end;

procedure TImageInfo.pushDirStack(dirStart, offsetbase:longint);
var ts:string;
begin
  ts := '['+IntToStr(offsetbase)+':'+IntToStr(dirStart)+']';
  dirStack := dirStack+ts;
end;

function TImageInfo.testDirStack(dirStart, offsetbase:longint):boolean;
var ts:string;
begin
  ts := '['+IntToStr(offsetbase)+':'+IntToStr(dirStart)+']';
  result := pos(ts,dirStack) > 0;
end;

//{$DEFINE CreateExifBufDebug}  // uncomment to see written Exif data
{$ifdef CreateExifBufDebug}var CreateExifBufDebug : String;{$endif}
function TImageInfo.CreateExifBuf (parentID:word=0; offsetBase:integer=0 {offsetBase required, because the pointers of subIFD are referenced from parent IFD (WTF!!)}) : String;  // msta Creates APP1 block with IFD0 only
var
  i, f, n : integer;
  size, pDat, p : Cardinal;
  head : String;

function check (const t : TTagEntry; pid : word) : Boolean; inline;
var i : integer;
begin
 if (t.parentID <> pid) or (t.TType >= Length(BytesPerFormat)) or (BytesPerFormat[t.TType] = 0) then Result := false
 else begin
  Result := Length(whitelist) = 0;
  for i := 0 to Length(whitelist)-1 do if (whitelist[i] = t.Tag) then begin Result := true; break; end;
 end;
end;

function calcSubIFDSize(pid : integer) : integer;
var i : integer;
begin
 Result := 6;
 for i := 0 to Length(fiTagArray)-1 do begin
  if (not check(fiTagArray[i], pid)) then continue;
  Result := Result + 12;
  if (fiTagArray[i].id <> 0) then Result := Result + calcSubIFDSize(fiTagArray[i].id)
  else if (Length(fiTagArray[i].Raw) > 4) then Result := Result + Length(fiTagArray[i].Raw);  // calc size
 end;
end;
begin
 {$ifdef CreateExifBufDebug}if (parentID = 0) then CreateExifBufDebug := '';{$endif}
 if (parentID = 0) then head := #0#0                 // APP1 block size (calculated later)
        + 'Exif' + #$00+#$00                         // Exif Header
        + 'II' + #$2A+#$00 + #$08+#$00+#$00+#$00     // TIFF Header (Intel)
 else head := '';
 n := 0;
 size := 0;
 for i := 0 to Length(fiTagArray)-1 do begin
  if (not check(fiTagArray[i], parentID)) then continue;
  n := n + 1; // calc number of Tags in current IFD
  if (fiTagArray[i].id <> 0) then size := size + calcSubIFDSize(fiTagArray[i].id)
  else if (Length(fiTagArray[i].Raw) > 4) then size := size + Length(fiTagArray[i].Raw);  // calc size
 end;
 pDat := Length(head) + 2 + n*12 + 4; // position of DataArea
 p := pDat;
 size := size + pDat;
 SetLength(Result, size);
 if (parentID = 0) then begin
  head[1] := char(size div 256);
  head[2] := char(size mod 256);
  move(head[1], Result[1], Length(head));             // write header
 end;
 PWord(@Result[1+Length(head)])^ := n;                // write tag count
 PCardinal(@Result[1+Length(head)+2+12*n])^ := 0;     // write offset to next IFD (0, because just IFD0 is included)
 n := 0;
 for f := 0 to 1 do for i := 0 to Length(fiTagArray)-1 do begin          // write tags
  if (not check(fiTagArray[i], parentID)) then continue;
  if (f = 0) and (fiTagArray[i].Tag <> TAG_EXIF_OFFSET) then continue; // Sub-IFD must be first data block... more or less (WTF)
  if (f = 1) and (fiTagArray[i].Tag = TAG_EXIF_OFFSET) then continue;
  PWord(@Result[1+Length(head)+2+12*n+0])^ := fiTagArray[i].Tag;
  if (fiTagArray[i].Tag = TAG_EXIF_OFFSET) then begin
   PWord(@Result[1+Length(head)+2+12*n+2])^ := 4;  // Exif-Pointer is not a real data block but really a pointer (WTF)
   PCardinal(@Result[1+Length(head)+2+12*n+4])^ := 1;
  end else begin
   PWord(@Result[1+Length(head)+2+12*n+2])^ := fiTagArray[i].TType;
   PCardinal(@Result[1+Length(head)+2+12*n+4])^ := Length(fiTagArray[i].Raw) div BytesPerFormat[fiTagArray[i].TType];
  end;
  {$ifdef CreateExifBufDebug}CreateExifBufDebug := CreateExifBufDebug + '  ' + fiTagArray[i].Name;{$endif}
  if (Length(fiTagArray[i].Raw) <= 4) and (fiTagArray[i].id = 0) then begin
   PCardinal(@Result[1+Length(head)+2+12*n+8])^ := 0;
   if (Length(fiTagArray[i].Raw) > 0) then move(fiTagArray[i].Raw[1], Result[1+Length(head)+2+12*n+8], Length(fiTagArray[i].Raw));
  end else begin
   PCardinal(@Result[1+Length(head)+2+12*n+8])^ := p - 8 + offsetBase;
   if (fiTagArray[i].id <> 0) then begin
    {$ifdef CreateExifBufDebug}CreateExifBufDebug := CreateExifBufDebug + ' { ';{$endif}
    fiTagArray[i].Raw := CreateExifBuf(fiTagArray[i].id, p); // create sub IFD
    fiTagArray[i].Size := Length(fiTagArray[i].Raw);
    {$ifdef CreateExifBufDebug}CreateExifBufDebug := CreateExifBufDebug + ' } ';{$endif}
   end;
   move(fiTagArray[i].Raw[1], Result[1+p], Length(fiTagArray[i].Raw));
   p := p + Length(fiTagArray[i].Raw);
  end;
  n := n+1;
 end;
 {$ifdef CreateExifBufDebug}if (parentID = 0) then ShowMessage(CreateExifBufDebug);{$endif}
end;

//--------------------------------------------------------------------------
// Process one of the nested EXIF directories.
//--------------------------------------------------------------------------
var idCnt : Word = 0;
procedure  TImageInfo.ProcessExifDir(DirStart, OffsetBase, ExifLength: longint;
  tagType:integer = ExifTag; prefix:string=''; parentID:word=0);
var ByteCount:integer;
  tag,TFormat,components:integer;
  de,DirEntry,OffsetVal,NumDirEntries,ValuePtr,subDirStart:Longint;
  RawStr,Fstr,transStr:string;
  msInfo: tmsInfo;
  lookupE, newE: TTagEntry;
  tagID : word;
  tmpTR:string;
begin
 if (parentID = 0) then idCnt := 1;
  pushDirStack(dirStart,OffsetBase);
  NumDirEntries := Get16u(DirStart);
  if (ExifTrace > 0) then
    TraceStr := TraceStr +#13#10+
      format('Directory: Start, entries = %d, %d',[DirStart, NumDirEntries]);
  if (DirStart+2+(NumDirEntries*12)) > (DirStart+OffsetBase+ExifLength) then
  begin
    Parent.ErrStr := 'Illegally sized directory';
    exit;
  end;
//Parent.ErrStr:=
//format('%d,%d,%d,%d+%s',[DirStart,NumDirEntries,OffsetBase,ExifLength,
//parent.errstr]);
//  Uncomment to trace directory structure
  if (tagType = ExifTag) and (ThumbStart = 0) and not TiffFmt then
  begin
    DirEntry := DirStart+2+12*NumDirEntries;
    ThumbStart := Get32u(DirEntry);
    ThumbLength := OffsetBase+ExifLength-ThumbStart;
  end;

  for de := 0 to NumDirEntries-1 do
  begin
    tagID := 0;
    DirEntry := DirStart+2+12*de;
    Tag := Get16u(DirEntry);
    TFormat := Get16u(DirEntry+2);
    Components := Get32u(DirEntry+4);
    ByteCount := Components * BytesPerFormat[TFormat];
    if ByteCount = 0 then continue;
    If ByteCount > 4 then
    begin
      OffsetVal := Get32u(DirEntry+8);
      ValuePtr := OffsetBase+OffsetVal;
    end
    else ValuePtr := DirEntry+8;

    RawStr := copy(parent.EXIFsegment^.data,ValuePtr,ByteCount);
    fstr := '';

    if BuildList in [GenString,GenAll] then
    begin
      LookUpE := FetchTagByID(tag,tagType);

      with LookUpE do
      begin
        case tformat of
          FMT_UNDEFINED: fStr := '"'+StrBefore(RawStr,#0)+'"';
             FMT_STRING:
             begin
                fStr := copy(parent.EXIFsegment^.data, ValuePtr,ByteCount);
                if fStr[ByteCount] = #0 then
                  fStr := copy(fStr,1,ByteCount-1);
             end;
        else
          fStr := FormatNumber(RawStr, TFormat, FormatS, Code);
        end;
        if (Tag > 0) and assigned(callback) and DexifDecode then
          fstr := Callback(fStr)
        else
          fstr := MakePrintable(fstr);
        transStr := Desc;
      end;

     Case tag of

       TAG_USERCOMMENT:
         begin
           fStr := trim(copy(RawStr,9,ByteCount-8));    // msta - one letter is missing, when using ByteCount-9...    // old one is erroneous

           //CommentPosn := ValuePtr;
           //CommentSize := ByteCount-9;
         end;
     end;

     tmpTR := #13#10+
          siif(ExifTrace > 0,'tag[$'+inttohex(tag,4)+']: ','')+
          transStr+DexifDelim+fstr+
          siif(ExifTrace > 0,' [size: '+inttostr(ByteCount)+']','')+
          siif(ExifTrace > 0,' [start: '+inttostr(ValuePtr)+']','');

      if tagType = ThumbTag then
          Thumbtrace := ThumbTrace + tmpTR
      else
          TraceStr := TraceStr + tmpTR;
      end;
//   Additional processing done here:

     Case tag of
       TAG_SUBIFD_OFFSET,
       TAG_EXIF_OFFSET,
       TAG_INTEROP_OFFSET:
         begin
           try
             SubdirStart := OffsetBase + LongInt(Get32u(ValuePtr));
             // some mal-formed images have recursive references...
             // if (subDirStart <> DirStart) then
             if not testDirStack(SubDirStart,OffsetBase) then begin
               TagID := IDCnt;
               IDCnt := IDCnt+1;
               ProcessExifDir(SubdirStart, OffsetBase, ExifLength, ExifTag, '', tagID);
             end;
           except
           end;
         end;
       TAG_GPS_OFFSET:
         begin
           try
             SubdirStart := OffsetBase + LongInt(Get32u(ValuePtr));
             if not testDirStack(SubDirStart,OffsetBase) then begin
              tagID := idCnt;
              idCnt := idCnt + 1;
              ProcessExifDir(SubdirStart, OffsetBase, ExifLength, GpsTag, '', tagID);
             end;
           except
           end;
         end;
       TAG_MAKE: CameraMake := fstr;
       TAG_MODEL: CameraModel := fstr;
       TAG_EXIFVER: ExifVersion := rawstr;
       TAG_DATETIME_MODIFY:
         begin
           dt_oset := ValuePtr;
           DateTime := fstr;
         end;
       TAG_DATETIME_ORIGINAL:
         begin
           dt_orig_oset := ValuePtr;
           DateTime := fstr;
         end;
       TAG_DATETIME_DIGITIZED:
         begin
           dt_digi_oset := ValuePtr;
         end;
       TAG_MAKERNOTE: begin
            MakerNote := RawStr;
            MakerOffset := ValuePtr;
            Msinfo := tmsinfo.create(TiffFmt,self);
            msAvailable := msInfo.ReadMSData(self);
            FreeAndNil(msinfo);
          end;
       TAG_FLASH:
                FlashUsed := round(getNumber(RawStr, TFormat));
       TAG_IMAGELENGTH,
       TAG_EXIF_IMAGELENGTH:
           begin
             HPosn := DirEntry+8;
             Height := round(getNumber(RawStr, TFormat));
           end;
       TAG_IMAGEWIDTH,
       TAG_EXIF_IMAGEWIDTH:
           begin
             WPosn := DirEntry+8;
             Width := round(getNumber(RawStr, TFormat));
           end;
       TAG_THUMBTYPE:
           if tagType = ThumbTag then
             ThumbType := round(getNumber(RawStr, TFormat));
     else
       // no special processing
     end;

      if BuildList in [GenList,GenAll] then
      begin
        try
          NewE := LookupE;
          NewE.Data := fstr;
          NewE.Raw := RawStr;
          NewE.Size := length(RawStr);
          NewE.PRaw := ValuePtr;
          NewE.TType := tFormat;
          NewE.parentID := parentID;
          NewE.id := tagID;
          if tagType = ThumbTag then
            AddTagToThumbArray(NewE)
          else
            AddTagToArray(NewE);
        except
          // if we're here: unknown tag.
          // item is recorded in trace string
        end;
    end;

  end;
end;

Procedure TImageInfo.AddMSTag(fname,fstr:string;fType:word);
var  newE: TTagEntry;
begin
  if BuildList in [GenList,GenAll] then
  begin
    try
      newE.Name := fname;
      newE.Desc := fname;
      NewE.Data := fstr;
      NewE.Raw := fStr;
      NewE.Size := length(fStr);
      NewE.PRaw := 0;
      NewE.TType := fType;
      NewE.parentID := 0;
      NewE.id := 0;
      NewE.TID := 1; // MsSpecific
      AddTagToArray(NewE);
    except
      // if we're here: unknown tag.
      // item is recorded in trace string
    end;
  end;
end;

Procedure TImageInfo.ProcessThumbnail;
var start:integer;
begin
  start := ThumbStart+9;
  ProcessExifDir(start, 9, ThumbLength-12,ThumbTag,'Thumbnail');
end;

Procedure TImageInfo.removeThumbnail;
var newSize:integer;
begin
  newSize := ThumbStart-6;
  with parent do
  begin
    SetLength(ExifSegment^.data,newSize);
    ExifSegment^.size := newSize;
  // size calculations should really be moved to save routine
    ExifSegment^.data[1] := char(newSize div 256);
    ExifSegment^.data[2] := char(newSize mod 256);
  end;
end;

procedure TImageInfo.ProcessHWSpecific(MakerBuff:string;
                TagTbl:Array of TTagEntry;
                DirStart:longint;
                AMakerOffset:Longint;
                spOffset:integer = 0);
var NumDirEntries:integer;
    de,ByteCount,TagID:integer;
    DirEntry,tag,TFormat,components:integer;
    OffsetVal,ValuePtr:Longint;
    RawStr,Fstr,Fstr2,TagStr,ds:string;
    OffsetBase: longint;
    NewE:TTagEntry;
begin
  DirStart := DirStart+1;
  OffsetBase := DirStart-AMakerOffset+1;
  SetDataBuff(MakerBuff);
  try
    NumDirEntries := Get16u(DirStart);
    for de := 0 to NumDirEntries-1 do
    begin
      DirEntry := DirStart+2+12*de;
      Tag := Get16u(DirEntry);
      TFormat := Get16u(DirEntry+2);
      Components := Get32u(DirEntry+4);
      ByteCount := Components * BytesPerFormat[TFormat];
      OffsetVal := 0;
      If ByteCount > 4 then
      begin
        OffsetVal := Get32u(DirEntry+8);
        ValuePtr := OffsetBase+OffsetVal;
      end
      else
        ValuePtr := DirEntry+8;

      // Adjustment needed by Olympus Cameras
      if ValuePtr+ByteCount > length(MakerBuff) then
        RawStr := copy(parent.DataBuff,OffsetVal+spOffset,ByteCount)
      else
        RawStr := copy(MakerBuff,ValuePtr,ByteCount);

      TagID := LookupMTagID(tag,TagTbl);
      if TagID < 0
        then TagStr := 'Unknown'
        else TagStr := TagTbl[TagID].Desc;
      fstr := '';
      if UpperCase(TagStr) = 'SKIP' then
        continue;

    if BuildList in [GenList,GenAll] then
    begin
       case tformat of
           FMT_STRING: fStr := '"'+strbefore(RawStr,#0)+'"';
        FMT_UNDEFINED: fStr := '"'+RawStr+'"';
//         FMT_STRING: fStr := '"'+copy(MakerBuff,ValuePtr,ByteCount-1)+'"';
      else
        try
          ds := siif(dEXIFdecode, LookupCode(tag,TagTbl),'');
          if TagID < 0
            then fStr := FormatNumber(RawStr, TFormat, '', '')
            else fStr := FormatNumber(RawStr, TFormat, TagTbl[TagID].FormatS, ds);
        except
          fStr := '"'+RawStr+'"';
        end;
      end;

      rawDefered := false;
      if (TagID > 0) and assigned(TagTbl[TagID].CallBack) and DexifDecode then
        fstr2 := TagTbl[TagID].CallBack(fstr)
      else
        fstr2 := MakePrintable(fstr);

      if (ExifTrace > 0) then
      begin
        if not rawDefered then
          msTraceStr := msTraceStr +#13#10+
            'tag[$'+inttohex(tag,4)+']: '+
           TagStr+DexifDelim+fstr2+
           ' [size: '+inttostr(ByteCount)+']'+
           ' [raw: '+MakeHex(RawStr)+']'+
           ' [start: '+inttostr(ValuePtr)+']'
        else
          msTraceStr := msTraceStr +#13#10+
            'tag[$'+inttohex(tag,4)+']: '+
           TagStr+DexifDelim+
           ' [size: '+inttostr(ByteCount)+']'+
           ' [raw: '+MakeHex(RawStr)+']'+
           ' [start: '+inttostr(ValuePtr)+']'+
           fstr2;
      end
      else
      begin
        if not rawDefered then
          msTraceStr := msTraceStr +#13#10+
            TagStr+DexifDelim+fstr2
        else
          msTraceStr := msTraceStr+
            fstr2+ // has cr/lf as first element
            #13#10+TagStr+DexifDelim+fstr;
      end;
      (*
      msTraceStr := msTraceStr +#13#10+
         siif(ExifTrace > 0,'tag[$'+inttohex(tag,4)+']: ','')+
         TagStr+DexifDelim+fstr+
         siif(ExifTrace > 0,' [size: '+inttostr(ByteCount)+']','')+
         siif(ExifTrace > 0,' [raw: '+MakeHex(RawStr)+']','')+
         siif(ExifTrace > 0,' [start: '+inttostr(ValuePtr)+']','');
      *)
    end;

      if (BuildList in [GenList,GenAll]) and (TagID > 0) then
      begin
        try
          NewE := TagTbl[TagID];
          if rawdefered then
            NewE.Data := fstr
          else
            NewE.Data := fstr2;
          NewE.Raw := RawStr;
          NewE.TType := tFormat;
          NewE.TID := 1; // MsSpecific
          AddTagToArray(NewE);
        except
          // if we're here: unknown tag.
          // item is recorded in trace string
        end;
      end;

     end;

  except
     on e:exception do
       Parent.ErrStr := 'Error Detected = '+e.message;
   end;

   SetDataBuff(parent.DataBuff);
end;


Function ExtractComment(instr: string): string;
begin
//  CommentHeader := copy(instr,1,8);  // fixed length string
  result := copy(instr,9,maxint);
end;

Function FlashCallBack(instr: string): string;
var tmp: integer;
    tmpS: string;
begin
  tmp := strToInt(instr);
  tmps :=      siif(tmp and  1 =  1,'On','Off');             // bit0
  tmps := tmps+siif(tmp and  6 =  2,', UNKNOWN');             // bit1
  tmps := tmps+siif(tmp and  6 =  4,', no strobe return');    // bit2
  tmps := tmps+siif(tmp and  6 =  6,', strobe return');       // bit1+2
  tmps := tmps+siif(tmp and 24 =  8,', forced');              // bit3
  tmps := tmps+siif(tmp and 24 = 16,', surpressed');          // bit4
  tmps := tmps+siif(tmp and 24 = 24,', auto mode');           // bit3+4
  tmps := tmps+siif(tmp and 32 = 32,', no flash function');  // bit5
  tmps := tmps+siif(tmp and 64 = 64,', red-eye reduction');  // bit6
  result := tmps;
end;

function ExposCallBack(instr: string):string;
var expoTime:double;
begin
  expoTime := strToFloat(instr);
  result := Format('%4.4f sec',[expoTime])+
    siif(ExpoTime <= 0.5,
      format(' (1/%d)',[round(1/ExpoTime)]),'');
// corrected by M. Schwaiger - adding ".5" is senseless when using "round"!
end;

function SSpeedCallBack(instr: string):string;
var expoTime:double;
begin
  expoTime := CvtIrrational(instr);
  expoTime := (1/exp(expoTime*ln(2)));
  result := Format('%4.4f sec',[expoTime])+
    siif(ExpoTime <= 0.5,
      format(' (1/%d)',[round(1/ExpoTime)]),'');
end;

function xpTranslate(instr: string):string;
var i:integer;
    ts:string;
    cv:char;
begin
  ts := '';
  for i := 1 to StrCount(instr,',') do
    if odd(i) then
    begin
       cv := chr(strtoint(StrNth(instr,',',i)));
       if cv <> #0 then
         ts := ts+cv;
    end;
  result := ts;
end;

function TImageInfo.toLongString: string;
var tmpStr:string;
begin
  if parent.ExifSegment = nil then
    result := ''
  else if Parent.errstr <> '<none>' then
    result := 'File Name: '  + ExtractFileName(parent.Filename) + crlf +
            'Exif Error: '+Parent.errstr
  else
  begin
    result := 'File Name: '   + ExtractFileName(parent.Filename) + crlf +
            'File Size: '   + IntToStr(parent.FileSize div 1024)+ 'k'   + crlf +
            'File Date: '   + dateToStr(parent.FileDateTime)   + crlf +

            'Photo Date: '  + DateTime + crlf +
            'Make (Model): '  + CameraMake + ' ('+CameraModel+')' + crlf +
            'Dimensions: '  + IntToStr(Width) + ' x '+
                              IntToStr(Height);
    if BuildList in [GenString,GenAll] then
    begin

      tmpStr := LookupTagVal('ExposureTime');
      if tmpStr <> '' then
        result := result+crlf+'Exposure Time: '+tmpStr
      else
      begin
        tmpStr := LookupTagVal('ShutterSpeedValue');
        if tmpStr <> '' then
          result := result+crlf+'Exposure Time: '+tmpStr
      end;

      tmpStr := LookupTagVal('FocalLength');
      if tmpStr <> '' then
        result := result+crlf+'Focal Length: '+tmpStr;

      tmpStr := LookupTagVal('FocalLengthin35mm');
      if tmpStr <> '' then
        result := result+crlf+'Focal Length (35mm): '+tmpStr;

      tmpStr := LookupTagVal('FNumber');
      if tmpStr <> '' then
        result := result+crlf+'FNumber: '+tmpStr;

      tmpStr := LookupTagVal('ISOSpeedRatings');
      if tmpStr <> '' then
        result := result+crlf+'ISO: '+tmpStr;
    end;
    result := result + crlf +
      'Flash: ' + siif(odd(FlashUsed),'Yes','No');
  end;
end;

function TImageInfo.toString: string;
begin
  if parent.ExifSegment = nil then
    result := ''
  else if Parent.errstr <> '<none>' then
    result := ExtractFileName(parent.Filename) + ' Exif Error: '+Parent.errstr
  else
    result := ExtractFileName(parent.Filename) + ' ' +
            IntToStr(parent.FileSize div 1024)+'k '+
            Copy(DateTime,1,10) + ' '+
            IntToStr(Width)+'w '+IntToStr(Height)+'h '
            +siif(odd(FlashUsed),' Flash','');
end;

(*************************************************
The following methods write data back into the
EXIF buffer.
*************************************************)

procedure TImageInfo.SetExifComment( newComment:string);
begin
  WriteThruString('UserComment','ASCII'#0#0#0+newComment);
end;

procedure TImageInfo.AdjExifSize(nh,nw:longint);
begin
  if (Height <=0) or (Width <=0) then
    exit;
  if (nw <> Width) or (nh <> Height) then
  begin
    parent.WriteInt32(parent.ExifSegment^.data,nh,hPosn);
    parent.WriteInt32(parent.ExifSegment^.data,nw,wPosn);
  end;
end;

procedure TImageInfo.TagWriteThru16(te:ttagentry;NewVal16:word);
begin
  parent.WriteInt16(parent.ExifSegment^.data,newVal16,te.praw);
end;

procedure TImageInfo.TagWriteThru32(te:ttagentry;NewVal32:longint);
begin
  parent.WriteInt16(parent.ExifSegment^.data,newVal32,te.praw);
end;

function TImageInfo.WriteThruInt(tname:string;value:longint):boolean;
var te:ttagentry;
  vlen:integer;
begin
  result := false;  // failure
  te := Data[tname];
  if te.Tag = 0 then
    exit;
   result := true;   // success
   vlen := BytesPerFormat[te.TType];
   if vlen = 2 then
     TagWriteThru16(te,word(value))
   else
   if vlen = 4 then
     TagWriteThru32(te,value)
   else
     result := false;    // don't recognize the type
end;

function TImageInfo.WriteThruString(tname:string;value:String):boolean;
var
  te:ttagentry;
  i,sPosition:integer;
{procedure SpliceData (p, s : integer); // msta - inserts or removes Bytes from EXIF-Section. p=3, s=2 means data'[3]=new, data'[4]=new, data'[5]=data[3]. Negative s means deleting bytes from data.
var i : integer;
begin
 if (s = 0) then exit;
 for i := 0 to fiTagCount-1 do if UpperCase(fiTagArray[i].PRaw > p) then begin
  fiTagArray[i].PRaw := fiTagArray[i].PRaw + s;

 end;
 with parent.ExifSegment^ do begin
  if (s > 0) then begin
   SetLength(data, Length(data) + s);
   for i := Length(data)-1 downto p+s do data[i] := data[i-s];
  end else begin
   for i := p to Length(data)-1+s do data[i] := data[i-s];
   SetLength(data, Length(data) + s);
  end;
  data[1] := char(Length(data) div 256);
  data[2] := char(Length(data) mod 256);
 end;
end;    }
begin
  result := false;  // failure
  te := Data[tname];
  if te.Tag = 0 then begin
    //Showmessage('exit');
    exit;
  end;
  with parent.ExifSegment^ do begin
    sPosition := te.PRaw;
    for i := 0 to te.Size-2 do
      if i > length(value)-1 then
        data[i+sPosition] := #0
      else
        data[i+sPosition] := value[i+1];
    data[sPosition+te.Size-1] := #0; // strings are null terminated
  end;
  result := true;   // success
end;

//
//   Sample call  -
//        ImgData.ExifObj.WriteThruInt('Orientation',3);
//
//*********************************************

constructor TImageInfo.Create(p: timgdata; buildCode: integer = GenAll);
begin
  inherited create;
  LoadTagDescs(True);  // initialize global structures
  FITagCount := 0;
  buildList := BuildCode;
  clearDirStack;
  parent := p;
end;

constructor TImgData.Create(buildCode: integer = GenAll);
begin
  inherited create;
  buildList := BuildCode;
  reset;
end;

function TImageInfo.GetTagElement(TagID: integer): TTagEntry;
begin
  result := fITagArray[TagID]
end;

procedure TImageInfo.SetTagElement(TagID: integer;
  const Value: TTagEntry);
begin
  fITagArray[TagID] := Value;
end;

function TImageInfo.GetTagByName(TagName: string): TTagEntry;
var i:integer;
begin
  i := LookupTag(TagName);
  if i >= 0 then
    result := fITagArray[i]
  else
    result := EmptyEntry;
end;

procedure TImageInfo.SetTagByName(TagName: string; const Value: TTagEntry);
var i:integer;
begin
  i := LookupTag(TagName);
  if i >= 0 then
    fITagArray[i] := Value
  else
  begin
    AddTagToArray(value);
  end;
end;

procedure TImageInfo.removeTag(TagID:integer; parentID:word=0);
var i,j : integer;
begin
 j := 0;
 for i := 0 to Length(fiTagArray)-1 do begin
  if (j <> 0) then fiTagArray[i-j] := fiTagArray[i];
  if (fiTagArray[i].ParentID = parentID) and (fiTagArray[i].Tag = TagID) then j := j+1;
 end;
 if (j <> 0) then SetLength(fiTagArray, Length(fiTagArray)-j);
end;

function TImageInfo.getTag(TagID:integer; forceCreate:Boolean=false; parentID:word=0; TagType:word=65535; forceID:Boolean=false) : PTagEntry; // msta
var i,j : integer;
begin
 Result := nil;
 for i := 0 to Length(fiTagArray)-1 do if (fiTagArray[i].ParentID = parentID) and (fiTagArray[i].Tag = TagID) then begin
  Result := @fiTagArray[i];
  exit;
 end;
 if (forceCreate) then begin
  i := Length(fiTagArray);
  SetLength(fiTagArray, i+1);
  fiTagArray[i].Tag := TagID;
  for j := 0 to Length(TagTable)-1 do if (TagTable[j].Tag = TagID) then begin fiTagArray[i] := TagTable[j]; break; end;
  if (TagType <> 65535) then fiTagArray[i].TType := TagType;
  fiTagArray[i].ParentID := parentID;
  fiTagArray[i].Id := 0;
  if (forceID) then begin
   j := 1;
   for i := 0 to Length(fiTagArray)-1 do if (fiTagArray[i].id >= j) then j := fiTagArray[i].id+1;
   fiTagArray[i].Id := j;
  end;
  Result := @fiTagArray[i];
 end;
end;

function TImageInfo.ReadComments : String;
var
  p : PTagEntry;
  w : WideString;
begin
 Result := '';
 w := '';
 p := getTag(TAG_EXIF_OFFSET, false, 0, 4);
 if (p = nil) then exit;
 p := getTag(TAG_USERCOMMENT, false, p^.ID, 2);
 if (p = nil) or (Length(p^.Raw) <= 10) then exit;
 if (Pos('ASCII', p^.Raw) = 1) then begin
  setLength(Result, Length(p^.Raw)-9);
  move(p^.Raw[9], Result[1], Length(p^.Raw)-9);
 end else begin
  setLength(w, (Length(p^.Raw)-10) div 2);
  move(p^.Raw[9], w[1], Length(p^.Raw)-10);
  Result := String(w);
 end;
end;

function TImageInfo.ReadImageDescription : AnsiString;
var p : PTagEntry;
begin
 Result := '';
 p := getTag(TAG_IMAGEDESCRIPTION, false, 0, 2);
 if (p = nil) then exit;
 setLength(Result, Length(p^.Raw)-1);
 move(p^.Raw[1], Result[1], Length(p^.Raw)-1);
 Result := trim(Result);
end;

function TImageInfo.ReadArtist : AnsiString;
var p : PTagEntry;
begin
 Result := '';
 p := getTag(TAG_ARTIST, false, 0, 2);
 if (p = nil) then exit;
 setLength(Result, Length(p^.Raw)-1);
 move(p^.Raw[1], Result[1], Length(p^.Raw)-1);
 Result := trim(Result);
end;

procedure TImageInfo.WriteComments (v : String);
var
  p : PTagEntry;
  i : integer;
  w : WideString;
  u : Boolean;
begin
 p := getTag(TAG_EXIF_OFFSET, true, 0, 4, true);
 if (v = '') then begin
  removeTag(TAG_USERCOMMENT, p^.ID);
  exit;
 end;
 p := getTag(TAG_USERCOMMENT, true, p^.ID, 7);
 u := false;
 w := WideString(v);
 for i := 1 to Length(w) do if (Word(w[i]) > 126) then begin u := true; break; end;
 if (u) then begin
  p^.Raw := 'UNICODE ';
  for i := 1 to Length(w) do begin
   p^.Raw := p^.Raw + Char(PByte(@w[i])^) + Char(PByte(@w[i]+1)^);
  end;
  p^.Raw := p^.Raw + #0#0;
 end else begin
  p^.Raw := 'ASCII   ';
  for i := 1 to Length(w) do begin
   p^.Raw := p^.Raw + Char(PByte(@w[i])^);
  end;
  p^.Raw := p^.Raw + #0;
 end;
 p^.Size := Length(p^.Raw);
end;

procedure TImageInfo.WriteImageDescription (v : AnsiString);
var p : PTagEntry;
begin
 if (v = '') then begin
  removeTag(TAG_IMAGEDESCRIPTION, 0);
  exit;
 end;
 p := getTag(TAG_IMAGEDESCRIPTION, true, 0, 2);
 p^.Raw := v + #0;
 p^.Size := Length(p^.Raw);
end;

procedure TImageInfo.WriteArtist (v : String);
var p : PTagEntry;
begin
 if (v = '') then begin
  removeTag(TAG_ARTIST, 0);
  exit;
 end;
 p := getTag(TAG_ARTIST, true, 0, 2);
 p^.Raw := v + #0;
 p^.Size := Length(p^.Raw);
end;

function TImageInfo.IterateFoundTags(TagId: integer;
        var retVal:TTagEntry):boolean;
begin
  FillChar(retVal,sizeof(retVal),0);
  while (iterator < FITagCount) and (FITagArray[iterator].TID <> TagId) do
    inc(iterator);
  if (iterator < FITagCount) then
  begin
    retVal := FITagArray[iterator];
    inc(iterator);
    result := true;
  end
  else
    result := false;
end;

procedure TImageInfo.ResetIterator;
begin
   iterator := 0;
end;

function TImageInfo.IterateFoundThumbTags(TagId: integer;
        var retVal:TTagEntry):boolean;
begin
  FillChar(retVal,sizeof(retVal),0);
  while (iterThumb < FIThumbCount) and (FITagArray[iterThumb].TID <> TagId) do
    inc(iterThumb);
  if (iterThumb < FIThumbCount) then
  begin
    retVal := FIThumbArray[iterThumb];
    inc(iterThumb);
    result := true;
  end
  else
    result := false;
end;

procedure TImageInfo.ResetThumbIterator;
begin
   iterThumb := 0;
end;

function TImageInfo.GetRawFloat( tagName: string ):double;
var tiq :TTagEntry;
begin
  tiq := GetTagByName( tagName );
  if tiq.Tag = 0 // EmptyEntry
    then result := 0.0
    else result := GetNumber(tiq.Raw, tiq.TType);
end;

function TImageInfo.GetRawInt( tagName: string ):integer;
begin
  result := round(GetRawFloat(tagName));
end;

//  Unfortunatly if we're calling this function there isn't
//  enough info in the EXIF to calculate the equivalent 35mm
//  focal length and it needs to be looked up on a camera
//  by camera basis. - next rev - maybe
Function TImageInfo.LookupRatio:double;
var estRatio:double;
  upMake,upModel:string;
begin
  upMake  := copy(uppercase(cameramake),1,5);
  upModel := copy(uppercase(cameramodel),1,5);
  estRatio := 4.5;  // ballpark for *my* camera -
  result := estRatio;
end;

procedure TImageInfo.Calc35Equiv;
const Diag35mm : double = 43.26661531; // sqrt(sqr(24)+sqr(36))
var tmp:integer;
  CCDWidth, CCDHeight,
    fpu, fl, fl35, ratio : double;
  NewE, LookUpE : TTagEntry;
begin
  if LookUpTag('FocalLengthin35mmFilm') >= 0 then
    exit;  // no need to calculate - already have it

  CCDWidth  := 0.0;
  CCDHeight := 0.0;
  tmp := GetRawInt('FocalPlaneResolutionUnit');
  if (tmp <= 0) then
     tmp := GetRawInt('ResolutionUnit');
  case tmp of
    2: fpu := 25.4;   // inch
    3: fpu := 10;     // centimeter
  else
    fpu := 0.0
  end;

  fl := GetRawFloat('FocalLength');
  if (fpu = 0.0) or (fl = 0.0) then
    exit;

  tmp := GetRawInt('FocalPlaneXResolution');
  if (tmp > 0) then
    CCDWidth := Width * fpu / tmp;
  tmp := GetRawInt('FocalPlaneYResolution');
  if (tmp > 0) then
    CCDHeight := Height * fpu / tmp;

  if CCDWidth*CCDHeight <= 0 then  // if either is zero
  begin
    if not estimateValues then
      exit;
    ratio := LookupRatio()
  end
  else
    ratio :=  Diag35mm / sqrt (sqr (CCDWidth) + sqr (CCDHeight));

  fl35 := fl *  ratio;

// now load it into the tag array
    tmp := LookupTagDefn('FocalLengthIn35mmFilm');
    LookUpE := TagTable[tmp];
    NewE := LookupE;
    NewE.Data := Format('%5.2f',[fl35]);
    NewE.Raw := '';
    NewE.FormatS := '%s mm';
    NewE.TType := FMT_SRATIONAL;
    AddTagToArray(NewE);
    TraceStr := TraceStr+#13#10+
          siif(ExifTrace > 0,'tag[$'+inttohex(tmp,4)+']: ','')+
          NewE.Desc+DexifDelim+NewE.Data+
          siif(ExifTrace > 0,' [size: 0]','')+
          siif(ExifTrace > 0,' [start: 0]','');
end;

function TImageInfo.EXIFArrayToXML: tstringlist;
var buff:tstringlist;
  i:integer;
begin
  buff := TStringList.Create;
  buff.add('   <EXIFdata>');
  for i := 0 to fiTagCount-1 do
    with fITagArray[i] do
    begin
      buff.add('   <'+name+'>');
      if tag in [105,120] // headline and image caption
        then buff.add('      <![CDATA['+data+']]>')
        else buff.add('      '+data);
      buff.add('   </'+name+'>');
    end;
  buff.add('   </EXIFdata>');
  result := buff;
end;

function getbyte( var f : tstream) : byte;
var a : byte;
begin
  f.Read(a,1);
  result := a;
end;

//--------------------------------------------------------------------------
// Here we implement the Endian Independent layer.  Outside
// of these methods we don't care about endian issues.
//--------------------------------------------------------------------------
function tEndInd.GetDataBuff: string;
begin
  result := llData;
end;

procedure tEndInd.SetDataBuff(const Value: string);
begin
  llData := Value;
end;

procedure tEndInd.WriteInt16(var buff:string;int,posn:integer);
begin
  if MotorolaOrder then
  begin
    buff[posn+1] := char(int mod 256);
    buff[posn] := char(int div 256);
  end
  else
  begin
    buff[posn] := char(int mod 256);
    buff[posn+1] := char(int div 256);
  end
end;

procedure tEndInd.WriteInt32(var buff:string;int,posn:longint);
begin
  if MotorolaOrder then
  begin
    buff[posn+3] := char(int mod 256);
    buff[posn+2] := char((int shr 8) mod 256);
    buff[posn+1] := char((int shr 16) mod  256);
    buff[posn]   := char((int shr 24) mod 256);
  end
  else
  begin
    buff[posn] := char(int mod 256);
    buff[posn+1] := char((int shr 8) mod 256);
    buff[posn+2] := char((int shr 16) mod  256);
    buff[posn+3] := char((int shr 24) mod 256);
  end
end;

//--------------------------------------------------------------------------
// Convert a 16 bit unsigned value from file's native byte order
//--------------------------------------------------------------------------
function tEndInd.Get16u(oset:integer):word;
// var hibyte,lobyte:byte;
begin
// To help debug, uncomment the following two lines
//  hibyte := byte(llData[oset+1]);
//  lobyte := byte(llData[oset]);
  if MotorolaOrder
    then result := (byte(llData[oset]) shl 8)
           or byte(llData[oset+1])
    else result := (byte(llData[oset+1]) shl 8)
           or byte(llData[oset]);
end;

//--------------------------------------------------------------------------
// Convert a 32 bit signed value from file's native byte order
//--------------------------------------------------------------------------
function tEndInd.Get32s(oset:integer):Longint;
begin
  if MotorolaOrder
    then result := (byte(llData[oset]) shl 24)
           or (byte(llData[oset+1]) shl 16)
           or (byte(llData[oset+2]) shl 8)
           or byte(llData[oset+3])
    else result := (byte(llData[oset+3]) shl 24)
           or (byte(llData[oset+2]) shl 16)
           or (byte(llData[oset+1]) shl 8)
           or byte(llData[oset]);
end;

//--------------------------------------------------------------------------
// Convert a 32 bit unsigned value from file's native byte order
//--------------------------------------------------------------------------
function tEndInd.Put32s(data:Longint):string;
var  data2:integer;
     buffer:string[4] absolute data2;
     bbuff:char;
begin
  data2 := data;
  if MotorolaOrder then
  begin
    bbuff := buffer[1];
    buffer[1] := buffer[4];
    buffer[4] := bbuff;
    bbuff := buffer[2];
    buffer[2] := buffer[3];
    buffer[3] := bbuff;
  end;
  result := buffer;
end;

//--------------------------------------------------------------------------
// Convert a 32 bit unsigned value from file's native byte order
//--------------------------------------------------------------------------
function tEndInd.Get32u(oset:integer):Longword;
begin
  result := Longword(Get32S(oset)) and $FFFFFFFF;
end;

destructor tEndInd.destroy;
begin
 //Log('   tEndInd.Destroy entered.');
 inherited;
 //Log('   tEndInd.Destroy finished.');
end;



//--------------------------------------------------------------------------
// The following methods implement the outer parser which
// decodes the segments.  Further parsing isthen passed on to
// the TImageInfo (for EXIF) and TIPTCData objects
//--------------------------------------------------------------------------
Procedure TImgData.MakeIPTCSegment(buff:string);
var bl:integer;
begin
  bl := length(buff)+2;
  if IPTCSegment = nil then
  begin
    inc(SectionCnt);
    IPTCSegment := @(sections[SectionCnt]);
  end;
  IPTCSegment^.data := char(bl div 256)+char(bl mod 256)+buff;
  IPTCSegment^.size := bl;
  IPTCSegment^.dtype := M_IPTC;
end;

Procedure TImgData.MakeCommentSegment(buff:string);
var bl:integer;
begin
  bl := length(buff)+2;
  if CommentSegment = nil then
  begin
    inc(SectionCnt);
    CommentSegment := @(sections[SectionCnt]);
  end;
  CommentSegment^.data := char(bl div 256)+char(bl mod 256)+buff;
  CommentSegment^.size := bl;
  CommentSegment^.dtype := M_COM;
end;

Function TImgData.GetCommentSegment:string;
begin
  result := '';
  if CommentSegment <> nil then
    result := copy(CommentSegment^.data,2,maxint);
end;

function TImgData.SaveExif(jfs2:tstream; EnabledMeta : Byte = $FF; freshExifBlock : Boolean = false):longint;
var cnt:longint;
    buff:string;
begin
  cnt:=0;
  buff := #$FF#$D8;
  jfs2.Write(pointer(buff)^,length(buff));
  if (EnabledMeta and 1 <> 0) then begin
   if (freshExifBlock) then begin
    buff := #$FF + Chr(M_EXIF);
    cnt := cnt+jfs2.Write(buff[1], length(buff));
    buff := ExifObj.CreateExifBuf;
    cnt := cnt+jfs2.Write(buff[1], length(buff));
    buff := '';
   end else if (ExifSegment <> nil) then with ExifSegment^ do begin
    buff := #$FF+chr(Dtype)+data;
    cnt := cnt+jfs2.Write(pointer(buff)^,length(buff));
   end else if (HeaderSegment <> nil) then with HeaderSegment^ do begin
    buff := chr($FF)+chr(Dtype)+data;
    // buff := #$FF+chr(Dtype)+#$00#$10'JFIF'#$00#$01#$02#$01#$01','#$01','#$00#$00;
    cnt := cnt+jfs2.Write(pointer(buff)^,length(buff));
   end else if (cnt = 0) then begin
    // buff := chr($FF)+chr(Dtype)+data;
    buff := #$FF+chr(M_JFIF)+#$00#$10'JFIF'#$00#$01#$02#$01#$01','#$01','#$00#$00;
    cnt := cnt+jfs2.Write(pointer(buff)^,length(buff));
   end;
  end;
  if (EnabledMeta and 2 <> 0) and (IPTCSegment <> nil) then with IPTCSegment^ do begin
   buff := chr($FF)+chr(Dtype)+data;
   cnt := cnt+jfs2.Write(pointer(buff)^,length(buff));
  end;
  if (EnabledMeta and 4 <> 0) and (CommentSegment <> nil) then with CommentSegment^ do begin
   buff := chr($FF)+chr(Dtype)+data;
   cnt := cnt+jfs2.Write(pointer(buff)^,length(buff));
  end;
  result := cnt;
end;

function TImgData.ExtractThumbnailBuffer: String;
var
  STARTmarker,STOPmarker:integer;
  tb:string;
begin
  result := '';
  if HasThumbnail then
  begin
    try
      tb := copy(DataBuff,ExifObj.ThumbStart,ExifObj.ThumbLength);
      STARTmarker := pos(#$ff#$d8#$ff#$db,tb);
      if Startmarker = 0 then
        STARTmarker := pos(#$ff#$d8#$ff#$c4,tb);
      if STARTmarker <= 0 then
        exit;
      tb := copy(tb,STARTmarker,length(tb));  // strip off thumb data block
      // ok, this is fast and easy - BUT what we really need
      // is to read the length bytes to do the extraction...
      STOPmarker := pos(#$ff#$d9,tb)+2;
      tb := copy(tb,1,STOPmarker);
      result := tb;
    except
    // result will be empty string...
    end;
  end;
end;

{$IFNDEF dExifNoJpeg}

{function TImgData.ExtractThumbnailJpeg: TJpegImage;
var ti:TJPEGImage;
  x:TStringStream;
  tb:string;
begin
  result := nil;
  if HasThumbnail and (ExifObj.ThumbType = JPEG_COMP_TYPE) then
  begin
    tb := ExtractThumbnailBuffer();
    if (tb = '') then
      exit;
    x := TStringStream.Create(tb);
    ti := TJPEGImage.Create;
    x.Seek(0,soFromBeginning);
    ti.LoadFromStream(x);
    x.Free;
    result := ti;
  end;
end;

procedure TImgData.WriteEXIFJpeg(j:tjpegimage;fname:string;origName:string;
  adjSize:boolean = true);
begin
  if origName = '' then
    origName := fname;
  if not ReadExifInfo(origName) then
  begin
    j.SaveToFile(fname);
    exit;
  end;
  WriteEXIFJpeg(j,fname,adjSize);
end;

procedure TImgData.WriteEXIFJpeg(fname:string);
var img:tjpegimage;
begin
  img := TJPEGImage.Create;
  img.LoadFromFile(Filename);
  WriteEXIFJpeg(img,fname,false);
  img.Free;
end;

procedure TImgData.WriteEXIFJpeg(j:tjpegimage;fname:string; adjSize:boolean = true);
var jms:tmemorystream;
    jfs:TFileStream;
begin
  //pslen := 2;
  jms := tmemorystream.Create;
  try // Thanks to Erik Ludden...
    jfs := tfilestream.Create(fname,fmCreate or fmShareExclusive);
    try
      if adjSize and (EXIFobj <> nil) then
        EXIFobj.AdjExifSize(j.height,j.width);
      j.SaveToStream(jms);
      MergeToStream(jms, jfs); // msta
    finally
      jfs.Free;
    end
  finally
    jms.Free;
  end
end;    }

procedure TImgData.MergeToStream(Input, Output : TStream; EnabledMeta : Byte = $FF; freshExifBlock : Boolean = false);   // msta
var pslen:integer;
    tb:array[0..12] of byte;
begin
 pslen := 2;
 SaveExif(tstream(Output), EnabledMeta, freshExifBlock);
 Input.Seek(2,soFromBeginning);
 Input.Read(tb,12);      // a little big to help debug...
 if tb[1] = M_JFIF then                // strip header
   pslen := pslen+(tb[2]*256)+tb[3]+2; // size+id bytes
 Input.Seek(pslen,soFromBeginning);
 Input.Read(tb,12);
 if tb[1] = M_EXIF then                // strip exif
   pslen := pslen+tb[2]*256+tb[3]+2;   // size+id bytes
 Input.Seek(pslen,soFromBeginning);
 Input.Read(tb,12);
 if tb[1] = M_IPTC then                // strip iptc
   pslen := pslen+tb[2]*256+tb[3]+2;   // size+id bytes
 Input.Seek(pslen,soFromBeginning);
 Input.Read(tb,12);
 if tb[1] = M_COM then                 // strip comment
   pslen := pslen+tb[2]*256+tb[3]+2;   // size+id bytes
 Input.Seek(pslen,soFromBeginning);
 Output.Seek(0,soFromEnd);
 Output.CopyFrom(Input,Input.Size-pslen);
end;

{$ENDIF}

procedure TImgData.ClearSections;
begin
  ClearEXIF;
  ClearIPTC;
  ClearComments;
end;

procedure TImgData.ClearEXIF;
begin
  ExifSegment := nil;
  FreeAndNil(ExifObj);
end;

procedure TImgData.ClearIPTC;
begin
  IPTCSegment := nil;
  HeaderSegment := nil;
  FreeAndNil(IptcObj);
end;

procedure TImgData.ClearComments;
begin
  CommentSegment := nil;
  HeaderSegment := nil;
end;

function TImgData.GetCommentStr:string;
var buffer:string;
    bufLen:integer;
begin
  buffer := CommentSegment^.Data;
  bufLen := (byte(buffer[1]) shl 8) or byte(buffer[2]);
  result := copy(buffer,3,bufLen-2);
end;

function TImgData.ReadExifInfo(fname:string):boolean;
begin
  ProcessFile(fname);
  result := HasMetaData();
end;

{function TImgData.FillInIptc:boolean;
begin
  if IPTCSegment = nil then
    CreateIPTCObj
  else
    IPTCObj.ParseIPTCArray(IPTCSegment^.Data);
//    filename := FName;
  result := IPTCObj.HasData();
end;     }


function TImgData.ProcessFile(const AFileName : String):boolean;
var extn:string;
begin
  reset;
  result := false;
  if not FileExists{UTF8}(AFileName) { *Converted from FileExists* } then
    exit;
  SetFileInfo(AFileName);
  try
      errstr := 'Not an EXIF file';
      extn :=  lowercase(ExtractFileExt(AFilename));
      if (extn = '.jpg') or (extn = '.jpeg') or (extn = '.jpe') then
      begin
        if not ReadJpegFile(AFileName) then
          exit;
      end
      else
      if (extn = '.tif') or (extn = '.tiff') or (extn = '.nef') then
      begin
        if not ReadTiffFile(AFileName) then
          exit;
      end
      else
      begin
        exit;
      end;
      errstr := '<none>';
//      msAvailable := ReadMSData(Imageinfo);
//      msName := gblUCMaker;
      result := true;
  except
    errstr := 'Illegal Exif construction';
  end;
end;

procedure TImgData.SetFileInfo(fname:string);
var s:tsearchrec;
    stat:word;
begin
   stat := FindFirst{UTF8}(fname,faAnyFile,s); { *Converted from FindFirst* }
   if stat = 0 then
   begin
     Filename := fname;
     FileDateTime := FileDateToDateTime(s.Time);
     FileSize := s.Size;
   end;
   FindClose{UTF8}(s); { *Converted from FindClose* }
end;

procedure TImgData.CreateIPTCObj;
begin
  MakeIPTCSegment('');
  IPTCobj := TIPTCdata.Create(self);
  // IPTCdata := IPTCobj;  // old style global pointer
end;

//--------------------------------------------------------------------------
// Parse the marker stream until SOS or EOI is seen;
//--------------------------------------------------------------------------
function TImgData.ReadJpegSections (f: tstream):boolean;
var a,b:byte;
    ll,lh,itemlen,marker:integer;
begin
  a := getbyte(f);
  b := getbyte(f);
  if (a <> $ff) or (b <> M_SOI) then
  begin
    result := FALSE;
    exit;
  end;
  SectionCnt := 0;
  while SectionCnt < 20 do  // prevent overruns on bad data
  begin
    repeat
      marker := getByte(f);
    until marker <> $FF;
    Inc(SectionCnt);
    // Read the length of the section.
    lh := getByte(f);
    ll := getByte(f);
    itemlen := (lh shl 8) or ll;
    with Sections[SectionCnt] do
    begin
      DType := marker;
      Size := itemlen;
      setlength(data,itemlen);
      data[1] := chr(lh);
      data[2] := chr(ll);
      try
        F.Read(data[3],itemlen-2);
      except
        continue;
      end;
    end;
    if (SectionCnt = 5) and not HasMetaData() then
      break;  // no exif by 8th - let's not waste time
    case marker of
      M_SOS: begin
               break;
             end;
      M_EOI: begin  // in case it's a tables-only JPEG stream
               break;
             end;
      M_COM: begin // Comment section
               CommentSegment := @sections[SectionCnt];
             end;
      M_IPTC: begin // IPTC section
               if (IPTCSegment = nil) then
               begin
                 IPTCSegment := @sections[SectionCnt];
                 IPTCobj := TIPTCdata.Create(self);
                 // IPTCdata := IPTCobj;  // old style global pointer
               end;
             end;
      M_JFIF: begin
                // Regular jpegs always have this tag, exif images have the exif
                // marker instead, althogh ACDsee will write images with both markers.
                // this program will re-create this marker on absence of exif marker.
               // dec(SectionCnt);
                HeaderSegment := @sections[SectionCnt];
                // break;
              end;
      M_EXIF: begin
                if ((SectionCnt <= 5) and (EXIFsegment = nil) )then
                begin
                    // Seen files from some 'U-lead' software with Vivitar scanner
                    // that uses marker 31 later in the file (no clue what for!)
                    EXIFsegment := @sections[SectionCnt];
                    EXIFobj := TImageInfo.Create(self,BuildList);
                    EXIFobj.TraceLevel := TraceLevel;
                    // ImageInfo := EXIFobj;  // old style global pointer
                    SetDataBuff(EXIFsegment^.data);
                    ProcessEXIF;
                end
                else
                begin
                  // Discard this section.
                  dec(SectionCnt);
                end;
              end;
      M_SOF0..M_SOF15: begin
                 // process_SOFn(Data, marker);
             end;
    else
      // break;
    end;
 end;
 result := HasMetaData();
end;

function TImgData.ReadJpegFile(const AFileName:string):boolean;
var F: tfilestream;
begin
  TiffFmt := false;  // default mode
  F := TFileStream.Create(AFilename,fmOpenRead or fmShareDenyWrite);
  try
    result := ReadJpegSections(tstream(F));
  except
    result := false;
  end;
  F.Free;
end;

function TImgData.ReadTiffSections (f: tstream):boolean;
var // lh,ll,
    itemlen:integer;
    fmt:string;
begin
  result := true;
  fmt := char(getbyte(f))+char(getbyte(f));
  if (fmt <> 'II') and (fmt <> 'MM') then
  begin
    result := FALSE;
    exit;
  end;

  setlength(Sections[1].data,6);
  F.Read(Sections[1].data[1],6);
{
  // length calculations are inconsistant for TIFFs
  lh := byte(Sections[1].data[1]);
  ll := byte(Sections[1].data[2]);

  if MotorolaOrder
    then itemlen := (lh shl 8) or ll
    else itemlen := (ll shl 8) or lh;
}
//  itemlen := (ll shl 8) or lh;

  itemlen := TiffReadLimit;

  setlength(Sections[1].data,itemlen);
  F.Read(Sections[1].data[1],itemlen);

  SectionCnt := 1;
  EXIFsegment := @(sections[1]);

  EXIFobj := TImageInfo.Create(self,BuildList);
  EXIFobj.TraceLevel := TraceLevel;
  ExifObj.TiffFmt := TiffFmt;
  ExifObj.TraceStr := '';
  EXIFsegment := @sections[SectionCnt];
  ExifObj.DataBuff := Sections[1].data;
  ExifObj.parent.DataBuff :=  Sections[1].data;
  ExifObj.MotorolaOrder := fmt = 'MM';
  EXIFobj.ProcessExifDir(1, -7 , itemlen);
  EXIFobj.Calc35Equiv();
end;

function TImgData.ReadTiffFile(const AFileName:string):boolean;
var F: tfilestream;
begin
  TiffFmt := true;
  F := TFileStream.Create(AFileName,fmOpenRead or fmShareDenyWrite);
  try
    result := ReadTiffSections(tstream(F));
  except
    result := false;
  end;
  F.Free;
  TiffFmt := false;
end;

Procedure TImgData.ProcessEXIF;
var hdr:string;
    toset:integer;
begin
  if not assigned(ExifObj) then
    ExifObj := TImageInfo.Create(self,BuildList);
  hdr := copy(EXIFsegment^.Data,3,length(validHeader));
  if  hdr <> validHeader then
  begin
    errStr := 'Incorrect Exif header';
    exit;
  end;
  if copy(EXIFsegment^.Data,9,2) = 'II' then
    MotorolaOrder := false
  else if copy(EXIFsegment^.Data,9,2) = 'MM' then
    MotorolaOrder := true
  else
  begin
    errStr := 'Invalid Exif alignment marker';
    exit;
  end;
  ExifObj.TraceStr := '';
  ExifObj.DataBuff := DataBuff;
  ExifObj.MotorolaOrder := MotorolaOrder;

  toset := Get32u(17-4);
  if toset = 0
    then ExifObj.ProcessExifDir(17, 9, EXIFsegment^.Size-6)
    else ExifObj.ProcessExifDir(9+toset, 9, EXIFsegment^.Size-6);
  if errstr <> '' then
  begin
    EXIFobj.Calc35Equiv();
  end;
end;

procedure TImgData.Reset;
begin
  SectionCnt := 0;
  ExifSegment := nil;
  IPTCSegment := nil;
  CommentSegment := nil;
  HeaderSegment := nil;
  Filename := '';
  FileDateTime := 0;
  FileSize := 0;
  ErrStr := '';
  FreeAndNil(ExifObj);
  FreeAndNil(IptcObj);
  MotorolaOrder := false;
end;

function TImgData.HasMetaData: boolean;
begin
  result := (EXIFsegment <> nil) or (CommentSegment <> nil) or
            (IPTCsegment <> nil);
end;

function TImgData.HasEXIF: boolean;
begin
  result := (EXIFsegment <> nil);
end;

function TImgData.HasThumbnail: boolean;
begin
  result := (EXIFsegment <> nil) and EXIFobj.hasThumbnail;
end;

function TImgData.HasIPTC: boolean;
begin
  result := (IPTCsegment <> nil);
end;

function TImgData.HasComment: boolean;
begin
  result := (Commentsegment <> nil);
end;

function TImgData.ReadIPTCStrings(fname: string): tstringlist;
begin
  if ProcessFile(fname) and HasIPTC then
    result := IPTCObj.ParseIPTCStrings(IPTCSegment^.Data)
  else
    result := nil;
end;

{function TImgData.MetaDataToXML: tstringlist;
var buff,buff2:tstringlist;
  s:tsearchrec;
begin
  if FindFirstUTF8(Filename,faAnyFile,s) <> 0 then
  begin
    FindCloseUTF8(s); //*Converted from FindClose*
    result := nil;
    exit;
  end;
  buff := TStringList.Create;
  buff.add('<dImageFile>');
  buff.add('   <OSdata>');
  buff.add('      <name> '+ExtractFileName(s.Name)+' </name>');
  buff.add('      <path> '+ExtractFilePath(Filename)+' </path>');
  buff.add('      <size> '+inttostr(s.Size)+' </size>');
  buff.add('      <date> '+DateToStr(FileDateToDateTime(s.time))+' </date>');
  buff.add('   </OSdata>');
  if ExifObj <> nil then
  begin
    buff2 := ExifObj.EXIFArrayToXML;
    if buff2 <> nil then
    begin
      buff.AddStrings(buff2);
      buff2.Clear;
      buff2.Free;
    end;
  end;
  if IptcObj <> nil then
  begin
    buff2 := IptcObj.IPTCArrayToXML;
    if buff2 <> nil then
    begin
      buff.AddStrings(buff2);
      buff2.Clear;
      buff2.Free;
    end;
  end;
  buff.add('</dImageFile>');
  result := buff;
end;     }

destructor TImgdata.Destroy;
begin
  if assigned(ExifObj) then begin
   // Log('  ExifObj Free...');
    ExifObj.free;
  end;

  if assigned(IptcObj) then begin
   // Log('  IPTCObj Free...');
    IptcObj.free;
  end;
 // Log('  start TImgData.Destroy:inherited');
  inherited;
 // Log('  finished TImgData.Destroy:inherited');
end;




function TImageInfo.HasThumbnail: boolean;
begin
  // 19 is minimum valid starting position
  result := (ThumbStart > 21) and (ThumbLength > 256);
end;




function defIntFmt (inInt:integer):string;
begin
  result := IntToStr(inInt)
end;

function defRealFmt(inReal:double):string;
begin
  result := FloatToStr(inReal);
end;

function GCD(a, b : integer):integer;
begin
  try
  if (b mod a) = 0 then
    Result := a
  else
    Result := GCD(b, a mod b);
  except
    result := 1
  end;
end;


function fmtRational( num,den:integer):string;
var
  gcdVal,intPart,fracPart,newNum,newDen: integer;
  outStr:String;
begin
  // first, find the values
  gcdVal := GCD(num,den);
  newNum := num div gcdVal;   // reduce the numerator
  newDen := den div gcdVal;    //  reduce the denominator
  intPart := newNum div newDen;
  fracPart := newNum mod newDen;

  // now format the string
  outStr := '';
  if intPart <> 0 then
     outStr := inttostr(intPart)+' ';
  if fracPart <> 0 then
       outStr := outStr + inttostr(fracPart)+'/'+inttostr(newDen);
  result := trim(outstr);  // trim cleans up extra space
end;

function defFracFmt(inNum,inDen:integer):string;
begin
  result := format('%d/%d',[inNum,inDen]);
 // result := fmtRational(inNum,inDen);
 //
 // It turns out this is not a good idea generally
 // because some std. calculation use rational
 // representations internally
end;

{$IFDEF dEXIFpredeclare}

initialization
  ImgData := TImgData.create;
finalization
  ImgData.Free;
{$ENDIF}
end.
























