/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syQRPNG, %callout)

/// This class contains methods which will allow you to generate a QR Code, and either store it
/// in a file, or return an image of it. The following QR Code image was created by this class,
/// and then embedded in this web page:<br><br>
/// <image id="InterSystemsWebPage" width="200" height="200" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAyAAAAMgAQMAAADhvpQrAAAABlBMVEX///8AAABVwtN+AAACxUlEQVR4nO3bMXYbMQwFQN6A978lb8AUsVYAgV07qfyehoVMgcAflGo8hvPrztzNWa+nFRpWqKw82BbDKwQCgUAgEAjk6/H4JXYNHb/NaliVuzQIBAKBQCAQyDdDozg7d+7S1qVBIBAIBAKBQJ6Q3WXsXJ/lKwQCgUAgEAjk/5Aj9Up6uEAgEAgEAoFA7pB4YuM1usvXu6cuDQKBQCAQCATy7opnBepfP7s0CAQCgUAgEMh4PncBK/+Umz8Kg0AgEAgEAoGc7TsPzVCZ4bJywi67ZBkCgUAgEAjk05GZI++Cdz/93nHmp/wVAoFAIBAIBPLVMnJY19icY5cVVp7hEwKBQCAQCAQSkZFfZsmO6zynHk8QCAQCgUAgkGt6h4CdHlOlvcfK6raGQCAQCAQCgRyR8yZpnWudws7xM1UgEAgEAoFAICl4lccoVOQAV4mCQCAQCAQCgRzI7oTraeeGyI6bdQ4cAoFAIBAIBJKvKfXIm9nZZWqVSxiHQCAQCAQCgZwZ1+fDdNtT77ENAoFAIBAIBHLM1cZ6Zuk/nH3uAoFAIBAIBAJpklonFlvzcV8IBAKBQCCQT0f+/r1OfF8ho8bX1e7rEAgEAoFAIJAGXEGuWpWP1Jk3LdtBIBAIBAKBfChSsZlHa8bOW7ar5TQIBAKBQCAQyBg3hToR1zk62y2OOwQCgUAgEMiHI1dtvj6L3Qs17DgLAoFAIBAIBPKQllOj35rtajPjEAgEAoFAIJBd/p8xBu/Q2+bNEjzLUhMCgUAgEAgE8kKuwl377Px9I4/w9XWBQCAQCAQCgZwx19zIxeoflePkBggEAoFAIBDIEzIKVf06coCrWQUCgUAgEAgE8p6YZ2PqufLqUlfnel8gEAgEAoFAIH1LW4ns7ip1o/VNJAQCgUAgEMhnIQ+Nx8RxqeDKmesrBAKBQCAQCAQynF93/gByMOulZqnGzwAAAABJRU5ErkJggg==">
/// <br><br>
/// See the Wikipedia article at http://en.wikipedia.org/wiki/QR_code for more information
/// about QR Codes.<br><br>
/// See also the Wikipedia article at http://en.wikipedia.org/wiki/URI_scheme for more information
/// about URI QR encoding schemes.<br>
/// <br>
/// This method is not supported on VMS platforms and will return an error if called.<br>
/// <br>
/// <br>
Class %SYS.QRCode Extends %SYSTEM.Help [ Abstract, System = 4 ]
{

/// Describes the mime type of the file the .dll/.so returns.
/// f.e. data:image/png
Parameter QRMIMETYPE = "data:image/png";

/// Generate a QR Code image in a file.<br>
/// Given a string, this method will generate a QR Code from the string, 
/// and write the image of it to the passed in file name in PNG format.<br>
/// <br>
/// Parameters:<br>
/// <br>
/// QRString - String from which to generate the QR Code image from.<br>
/// Filename - (by ref) File where the image is written.<br>
/// If filename is passed as a null string, then a temporary file is created with the QR Code
/// image written to it, and the name of the file is returned in Filename. If a Filename is 
/// passed in, and the file already exists, the file will be overwritten.<br>
/// Dimension - (default 200) Size in pixels of how large the image should be. If 100 is passed in, an image
/// 100 x 100 pixels is generated. If the image will not fit in the Dimension specified, then the
/// dimension will be increased to an appropriate size.<br>
/// CorrectionLevel - (default "H") One of the following levels of correction (image quality).<br>
/// "L" - Low           7% of codewords can be restored.<br>
/// "M" - Medium       15% of codewords can be restored.<br>
/// "Q" - Quartile     25% of codewords can be restored.<br>
/// "H" - High         30% of codewords can be restored.<br>
/// <br>
/// Notes:<br>
/// This method requires the %System_CallOut:USE resource to run.<br>
/// <br>
/// The string is encoded in UTF-8 before the image is generated.<br>
/// <br>
/// The CorrectionLevel specified partially determines the maximum length of the QRString which can be
/// encoded. The second factor is the encoding tier. There are 4 encoding tiers. "A" is part of the alphanumeric tier while
/// "a" is not. The following is a table of the maximum length for the "alphanumeric" encoding tier
/// for each Correction Level:<br>
/// L - 4,296<br>
/// M - 3,391<br>
/// Q - 2,420<br>
/// H - 1,852<br>
/// <br>
/// String size limits for UTF8 encode  https://www.qrcode.com/en/about/version.html:<br>
/// H quality:  Numeric 3057 Alpha numeric 1852 UTF8 1273 Kanji 784<br>
/// Q quality: Numeric 3993 Alpha numeric 2420 UTF8 1663 Kanji 1024<br>
/// M quality: Numeric 5596 Alpha numeric 3391 UTF8 2331 Kanji 1435<br>
/// L quality: Numeric 7089 Alpha numeric 4296 UTF8 2953 Kanji 1817<br>
/// Examples:<br>
/// <br>
/// Generate a QR Code image in a file which when read directs your browser
/// to the InterSystems web site.<br><br>
/// Set x=##Class(%SYS.QRCode).GenerateFile("http://www.intersystems.com","intersystems.png")
/// <br><br>
/// <image id="InterSystemsWebPage1" width="200" height="200" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAyAAAAMgAQMAAADhvpQrAAAABlBMVEX///8AAABVwtN+AAACxUlEQVR4nO3bMXYbMQwFQN6A978lb8AUsVYAgV07qfyehoVMgcAflGo8hvPrztzNWa+nFRpWqKw82BbDKwQCgUAgEAjk6/H4JXYNHb/NaliVuzQIBAKBQCAQyDdDozg7d+7S1qVBIBAIBAKBQJ6Q3WXsXJ/lKwQCgUAgEAjk/5Aj9Up6uEAgEAgEAoFA7pB4YuM1usvXu6cuDQKBQCAQCATy7opnBepfP7s0CAQCgUAgEMh4PncBK/+Umz8Kg0AgEAgEAoGc7TsPzVCZ4bJywi67ZBkCgUAgEAjk05GZI++Cdz/93nHmp/wVAoFAIBAIBPLVMnJY19icY5cVVp7hEwKBQCAQCAQSkZFfZsmO6zynHk8QCAQCgUAgkGt6h4CdHlOlvcfK6raGQCAQCAQCgRyR8yZpnWudws7xM1UgEAgEAoFAICl4lccoVOQAV4mCQCAQCAQCgRzI7oTraeeGyI6bdQ4cAoFAIBAIBJKvKfXIm9nZZWqVSxiHQCAQCAQCgZwZ1+fDdNtT77ENAoFAIBAIBHLM1cZ6Zuk/nH3uAoFAIBAIBAJpklonFlvzcV8IBAKBQCCQT0f+/r1OfF8ho8bX1e7rEAgEAoFAIJAGXEGuWpWP1Jk3LdtBIBAIBAKBfChSsZlHa8bOW7ar5TQIBAKBQCAQyBg3hToR1zk62y2OOwQCgUAgEMiHI1dtvj6L3Qs17DgLAoFAIBAIBPKQllOj35rtajPjEAgEAoFAIJBd/p8xBu/Q2+bNEjzLUhMCgUAgEAgE8kKuwl377Px9I4/w9XWBQCAQCAQCgZwx19zIxeoflePkBggEAoFAIBDIEzIKVf06coCrWQUCgUAgEAgE8p6YZ2PqufLqUlfnel8gEAgEAoFAIH1LW4ns7ip1o/VNJAQCgUAgEMhnIQ+Nx8RxqeDKmesrBAKBQCAQCAQynF93/gByMOulZqnGzwAAAABJRU5ErkJggg==">
/// <br><br>
/// Generate a QRCode Image in a file which when read generates an e-mail to the
/// InterSystems support team:<br>
/// <br>
/// Set x=##Class(%SYS.QRCode).GenerateFile("mailto:support@intersystems.com?subject=A%20QR%20Code%20Test&body=This%20is%20a%20QR%20Code%20Test.%20%0A","support.png")<br><br>
/// <image id="InterSystemsMailto" width="200" height="200" src="data:image/png;base64,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">
ClassMethod GenerateFile(QRString As %String, ByRef Filename As %SysPath = "", Dimension As %Integer = 200, CorrectionLevel As %String = "H") As %Status
{
 s $zt="Error"
 s Status=..Generate(QRString,.Filename,Dimension,CorrectionLevel)
 q Status
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Generate a QR Code image in a binary string.<br>
/// Given a string, this method will generate a QR Code from the string, 
/// and store the binary representation of it in a string.<br>
/// <br>
/// Parameters:<br>
/// <br>
/// QRString - String from which to generate the QR Code image from.<br>
/// QRImage (by ref) - Returned binary representation of the created image in PNG format.<br>
/// QRDataURI (by ref) - Encoded representation of the created image, suitable to be displayed
/// in an HTML Data URI control.<br>
/// Dimension - (default 200) Size in pixels of how large the image should be. If 100 is passed in, an image
/// 100 x 100 pixels is generated.<br>
/// CorrectionLevel - (default "H") One of the following levels of correction (image quality).<br>
/// "L" - Low,           7% of codewords can be restored.<br>
/// "M" - Medium,        15% of codewords can be restored.<br>
/// "Q" - Quartile,      25% of codewords can be restored.<br>
/// "H" - High,          30% of codewords can be restored.<br>
/// <br>
/// Notes:<br>
/// This method requires the %System_CallOut:USE resource to run.<br>
/// <br>
/// The string is encoded in UTF-8 before the image is generated.<br>
/// <br>
/// The CorrectionLevel specified partially determines the maximum length of the QRString which can be
/// encoded. The second factor is the encoding tier. There are 4 encoding tiers. "A" is part of the alphanumeric tier while
/// "a" is not. The following is a table of the maximum length for the "alphanumeric" encoding tier
/// for each Correction Level:<br>
/// L - 4,296<br>
/// M - 3,391<br>
/// Q - 2,420<br>
/// H - 1,852<br>
/// <br>
/// String size limits for UTF8 encode https://www.qrcode.com/en/about/version.html:<br>
/// H quality: Numeric 3057 Alpha numeric 1852 UTF8 1273 Kanji 784<br>
/// Q quality: Numeric 3993 Alpha numeric 2420 UTF8 1663 Kanji 1024<br>
/// M quality: Numeric 5596 Alpha numeric 3391 UTF8 2331 Kanji 1435<br>
/// L quality: Numeric 7089 Alpha numeric 4296 UTF8 2953 Kanji 1817<br><br><br>
/// The QRDataURI value returned is in the format:<br><br>
/// "data:image/png;base64,"_Base64Encode(QRImage)<br><br>
/// It can be displayed as an image in a ZEN page with the following ZEN control:<br><br>
/// image id="QRCode" width="200" height="200" src=""  <br><br>
/// and then setting the src parameter as follows:<br><br>
/// s Status=##Class(%SYS.QRCode).GenerateImage(String,,.DataURI)<br>
/// Set ..%GetComponentById("QRCode").src = DataURI<br>
/// <br>
ClassMethod GenerateImage(QRString As %String, ByRef QRImage As %Binary, ByRef QRDataURI As %String, Dimension As %Integer = 800, CorrectionLevel As %String = "H") As %Status
{
 s $zt="Error"
 k QRImage 
 k QRDataURI
 s Status=..Generate(QRString,.Filename,Dimension,CorrectionLevel)
 i '$$$ISOK(Status) q Status
 o Filename:"RUDK\RAW\":5
 i '$t q $$$ERROR($$$QRCodeFileCanNotOpen,Filename)
 Try {
	s Image=""
 	f  {
		u Filename r Record q:$zeof
		s Image=Image_Record
 	}
 } catch {
 	i $ZE'["ENDOFFILE" ztrap $ZE
 }
 c Filename
 s QRImage=Image
 s QRDataURI=..#QRMIMETYPE_";base64,"_$SYSTEM.Encryption.Base64Encode(QRImage,1)
 q $$$OK
Error s $zt=""
 i $d(Filename) c Filename
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Generate a QR Code image in a file. See the other methods for documentation.<br>
ClassMethod Generate(QRString As %String, ByRef Filename As %String = "", Dimension As %Integer, CorrectionLevel As %String) As %Status [ Internal ]
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$SystemCallOutResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$SystemCallOutResourceName_":"_$$$PermUseName)
#;If we pass in a "" string for Filename, generate a temp one
 i Filename="" s Filename=##Class(%File).TempFilename("png")
#;Validate the passed in parameters
 s Status=..Validate(QRString,Filename,Dimension,CorrectionLevel)
 i '$$$ISOK(Status) q Status
#;We no longer use $ZF(-1) so we don't want quotes from NormalizeFilenameWithSpaces(Filename)
 s OutFile=Filename
 s QRString=$zcvt(QRString,"o","UTF8")
#; w "Encoding ",QRString," in: ",OutFile," Opts:",Dimension,"_",CorrectionLevel,$l(QRString)!
 s compression=1
 s osStatus=$zf(-6,$$$IrisQRPNGLibrary,$$$QRPNGGENERATEIMAGE,QRString,OutFile,Dimension,CorrectionLevel,compression)
 i osStatus'=$$$IRISQRPNGSTATUSOK {
#;	d $system.OBJ.DisplayError(osStatus)
	i osStatus=$$$IRISQRPNGSTATUSFILEPERMISSIONS q $$$ADDSC(Status,$$$ERROR($$$QRCodeFileCanNotOpen,OutFile))
	i osStatus=$$$IRISQRPNGSTATUSPROBLEMENCODINGNUMERICSTRING q $$$ADDSC(Status,$$$ERROR($$$QRCodeSanityCheckArgsNumeric,$l(QRString)))
	i osStatus=$$$IRISQRPNGSTATUSPROBLEMENCODINGALPHANUMERICSTRING q $$$ADDSC(Status,$$$ERROR($$$QRCodeSanityCheckArgsAlphaNumeric,$l(QRString)))
	i osStatus=$$$IRISQRPNGSTATUSPROBLEMENCODINGBYTESTRING q $$$ADDSC(Status,$$$ERROR($$$QRCodeSanityCheckArgsByte,$l(QRString)))
	i osStatus=$$$IRISQRPNGSTATUSPROBLEMENCODINGKANJISTRING q $$$ADDSC(Status,$$$ERROR($$$QRCodeSanityCheckArgsKanji,$l(QRString)))
	i osStatus=$$$IRISQRPNGSTATUSPROBLEMENCODINGUNKNOWNMODESTRING q $$$ADDSC(Status,$$$ERROR($$$QRCodeSanityCheckArgsUnknownType,$l(QRString)))
	i osStatus=$$$IRISQRPNGSTATUSNULLPTRARGS q $$$ADDSC(Status,$$$ERROR($$$QRCodeNullPtrs,QRString,OutFile))
	i osStatus=$$$IRISQRPNGSTATUSUNKNOWNEXCEPTION q $$$ADDSC(Status,$$$ERROR($$$QRCodeExceptionDuringFileCreation,OutFile))
#;Default
	s Status=$$$ERROR($$$QRCodeFileNotCreated,OutFile,osStatus)
 }
#;If here the QRCode file should have been created with non zero size
 i '##Class(%File).Exists(OutFile) {
	 s Status=$$$ERROR($$$QRCodeFileNotCreated,OutFile,osStatus)
	 q Status
 }
 q $$$OK
Error s $zt=""
 q $$$ADDSC($$$ERROR($$$ObjectScriptError,$ze),$g(Status,1))
}

/// Validate the parameters being passed to the QR Encoder.<br>
/// Will assume numeric encoding tier and check the limits based on that.
/// Assumes you don't want pixel dimensions of more than 5000.
/// If you are in the byte tier and go over the length, the .dll/.so (and not this function) 
/// will return an understandable error code.
ClassMethod Validate(QRString As %String, Filename As %String, Dimension As %Integer, CorrectionLevel As %String) As %Status [ Internal ]
{
 s $zt="Error"
#;Dimension must be 0 or higher, and an integer, and < 5001 (5000 was chosen as something larger than what anyone would want)
 i (Dimension<0)||(Dimension\1'=Dimension)||(Dimension>5000) q $$$ERROR($$$QRCodeInvalidDimension,Dimension)
#;The following is a table of the maximum length for the numeric encoding tier for each CorrectionLevel:<br>
#; L - 7089
#; M - 5596
#; Q - 3993
#; H - 3057
#;String size limits for UTF8 encode:<br>
#;H quality: https://www.qrcode.com/en/about/version.html Numeric 3057 Alpha numeric 1852 UTF8 1273 Kanji 784<br>
#;Q quality: Numeric 3993 Alpha numeric 2420 UTF8 1663 Kanji 1024<br>
#;M quality: Numeric 5596 Alpha numeric 3391 UTF8 2331 Kanji 1435<br>
#;L quality: Numeric 7089 Alpha numeric 4296 UTF8 2953 Kanji 1817<br>
#; if your string is in another tier and goes over you will get $$$QRCodeSanityCheckArgsXXX error after you call the .dll/.so<br>
 s MaxLen=$case(CorrectionLevel,"L":7089,"M":5596,"Q":3993,"H":3057,:0)
 i MaxLen=0 q $$$ERROR($$$QRCodeCorrectionLevel,CorrectionLevel)
 s Len=$l(QRString)
 i Len>MaxLen q $$$ERROR($$$QRCodeCorrectionLevelMaxLen,CorrectionLevel,MaxLen,Len) 
 q $$$OK
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

}
