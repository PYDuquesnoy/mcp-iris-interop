/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// The <class>%CSP.StreamServer</class> serves any stream data directly from InterSystems IRIS.
/// It derives from %CSP.Page and implements the <method>OnPage()</method> and
/// <method>OnPreHTTP()</method> methods.<br>
/// You can control how the stream is sent using the stream's attributes, these attributes
/// can be accessed via properties in the <class>%CSP.CharacterStream</class> and
/// <class>%CSP.BinaryStream</class>, however you can also set these directly in any stream
/// class. The attributes are:
/// <ol>
/// <li><b>ContentType</b> - Sets the %response.ContentType property</li>
/// <li><b>CharSet</b> - Sets the %response.CharSet property</li>
/// <li><b>Expires</b> - Sets the %response.Expires property</li>
/// <li><b>ContentDisposition</b> - Set the 'Content-Disposition' response header</li>
/// </ol>
/// You can set the default charset to server up character files in using the global
/// ^%SYS("CSP","DefaultFileCharset"), and if you need to define settings per extension (in uppercase)
/// you can use ^%SYS("CSP","MimeFileClassify",$zcvt(ext,"U"))=$listbuild(type,bin,charset) where:
/// <ol>
/// <li>type - Content Type value, e.g. 'text/javascript'</li>
/// <li>bin - 1 if this is binary and 0 if this is a character file</li>
/// <li>charset - For character files the charset to report in the charset header</li></ol>
/// If nothing is defined then for character files we use the default charset associated
/// with the file device in InterSystems IRIS.
Class %CSP.StreamServer Extends %CSP.Page [ System = 3 ]
{

/// Stream serving does not need the session
Parameter UseSession As BOOLEAN = 0;

/// The <method>OnPostHTTP()</method> is called by the CSP dispatcher before the HTTP
/// headers have been sent.  Here, we check that the incoming STREAMOID value is valid,
/// then we set the appropriate content type and content length values into the %response
/// object (see <class>%CSP.Request</class>), in preparation for sending the image data
/// in the <method>OnPage()</method>.
ClassMethod OnPreHTTP() As %Boolean
{
	$$$SysLogSetVar
	Set %stream="",%response.Status="404 Stream Not Found"
	Set file=$get(%request.Data("FILE",1))
	Set file=$zcvt(file,"I","UTF8")
	If file'="" {
		$$$SysLogVar(2,"CSPStream","[OnPreHTTP] Serving file",file)
		Set app=$$getapp^%SYS.cspServer(file,.path)
		Set expires=$$$GetSecurityApplicationsServeFilesTimeout(app) If expires="" Set expires=3600
		Set %response.Expires=expires
		Set servefiles=$$$GetSecurityApplicationsServeFiles(app)
		If expires>0,servefiles=2 {
			Set %response.VaryByParam="FILE"
		}
		If $zconvert($piece(file,".",*),"l")="csp" {
			$$$SysLogVar(2,"CSPStream","[OnPreHTTP] Not allowed to server up a csp file","")
			Quit 0
		}
		#; If we can not serve files from this application leave the stream blank
		If 'servefiles {
			$$$SysLogVar(2,"CSPStream","[OnPreHTTP] CSP application will not allow files to be served","")
			Quit 0
		}
		#; Use standard application mapping to find the file.
		Set file=$$ConvertFilenameToAbsolute^%apiCSP($extract(file,$length(path)+1,*),$$$GetSecurityApplicationsPath(app))
		If $$$FileExists(file)=0 {
			If $piece(path,"/",1,3)="/csp/broker" {
				$$$SysLogVar(2,"CSPStream","[OnPreHTTP] CSP file not found",file)
				Quit 0
			}
			Set tmpfile=%request.Data("FILE",1),len=$length(tmpfile,"/")
			Set commonfile=$$GetFilename^%apiCSP("/csp/broker/"_$extract(tmpfile,$length(path)+1,*))
			If $$$FileExists(commonfile)=0 {
				For i=0,1 {
					If len<3,i=1 Continue
					If $piece(tmpfile,"/",len-i,len)=$extract(tmpfile,$length(path)+1,*) Continue
					Set commonfile=$$GetFilename^%apiCSP("/csp/broker/"_$piece(tmpfile,"/",len-i,len))
					If commonfile'="",$$$FileExists(commonfile) Set file=commonfile,commonfile=-1 Quit
				}
				If commonfile'=-1 {
					$$$SysLogVar(2,"CSPStream","[OnPreHTTP] CSP file not found",file)
					Quit 0
				}
			} Else {
				Set file=commonfile
			}
		}
		#; Can not service up directories
		If ##class(%File).DirectoryExists(file) Quit 0
		Set clientts=$piece($get(%request.CgiEnvs("HTTP_IF_MODIFIED_SINCE")),";")
		Set streamts=$$$FileDateModifiedUTC(file,1)
		If streamts'="" {
			Set httpmodified=..ToHTTPDate(streamts)
			If httpmodified'="" Do %response.SetHeader("Last-Modified",httpmodified)
		}
		#; If we let CSP gateway cache the file then always send full file over as sending '304 Not Modified' will not give it anything to cache
		If %response.VaryByParam'="FILE",clientts'="" {
			Set clientts=..FromHTTPDate(clientts)
			If clientts'="",$select(+streamts<+clientts:1,+streamts>+clientts:0,$piece(streamts,",",2)'>$piece(clientts,",",2):1,1:0) {
				$$$SysLogVar(2,"CSPStream","[OnPreHTTP] File not modified","")
				Set %response.Status="304 Not Modified"
				Quit 0
			}
		}
		
		#; If FileClassify() fails, it classifies the file as application/octet-stream
		Do ..FileClassify($piece(file,".",*),.type,,.charset)
		Set %stream=##class(%FileBinaryStream).%New()
		Set sc=%stream.LinkToFile(file) If $$$ISERR(sc) Quit 0
		If type'="" Set %response.ContentType=type
		Set tmp=$translate(%request.Data("FILE",1),"\","/"),tmp=$piece(tmp,"/",*)
		If tmp?.E1(1" ",1";",1",",1"(",1")",1"<",1">",1"@",1":",1"\",1"""",1"/",1"[",1"]",1"?",1"=",1"{",1"}").E Set tmp=""""_$extract($zutil(144,1,"z"_tmp),3,*)
		If tmp'="" Do %response.SetHeader("Content-Disposition","inline; filename="_tmp)
		Set %response.NoCharSetConvert=1
		If $get(charset)'="" Set %response.CharSet=charset
	} Else {
		Set oid=$get(%request.Data("STREAMOID",1))
		If oid="" Quit 0
		Try {
			Set oid=..Decrypt(oid)
			#; Check if this is a valid $LIST by searching for something that is not in the list
			If $listfind(oid,"xxxStuffxxx")
		} Catch {
			Set oid=""
			$$$SysLogVar(2,"CSPStream","[OnPreHTTP] Invalid oid",$get(%request.Data("STREAMOID",1)))
		}
		If oid="" Quit 0
		Set %stream=##class(%Stream.Object).%Open(oid)
		If %stream=$$$NULLOREF {
			$$$SysLogVar(2,"CSPStream","[OnPreHTTP] Unable to open stream oid",oid)
			Quit 0
		}

		Set %response.ContentType=""
		If $data(%request.Data("EXPIRES",1,"encrypt")) {
			Set expires=$get(%request.Data("EXPIRES",1))
		} Else {
			Set app=$$getapp^%SYS.cspServer(%request.URL)
			Set expires=$$$GetSecurityApplicationsServeFilesTimeout(app)
			#; IE does not handle files it receives that are not cacheable correctly
			If expires="",%request.UserAgent["MSIE" Set expires=60
		}
		If %stream.%Extends("%Library.AbstractStream") {
			Set %response.ContentType=%stream.GetAttribute("ContentType")
			Set %response.CharSet=%stream.GetAttribute("CharSet")
			If %stream.GetAttribute("ContentDisposition")'="" {
				Do %response.SetHeader("Content-Disposition",%stream.GetAttribute("ContentDisposition"))
			}
			If %stream.IsDefinedAttribute("Expires") Set expires=%stream.GetAttribute("Expires")
		}
		If expires'="" Set %response.Expires=expires
		If %response.ContentType="" {
			If $get(%request.Data("CONTENTTYPE",1))'="" {
				Set %response.ContentType=$get(%request.Data("CONTENTTYPE",1))
			} ElseIf %stream.IsCharacter() {
				Set %response.ContentType="text/plain"
			} Else {
				Set %response.ContentType="application/octet-stream"
			}
		}
	}
	
	If %stream.IsCharacter() {
		Do %response.ContentInfo(,.table)
		If table="RAW"||($extract(table,1,$length("Latin"))="Latin")||($extract(table,1,$length("CP"))="CP") {
			Set %response.ContentLength=%stream.Size
		} ElseIf table="UnicodeLittle"||(table="UnicodeBig") {
			Set %response.ContentLength=%stream.Size*2
		} Else {
			#; Gateway will fill in the length for us
			Set %response.ContentLength=""
		}
	} Else {
		Set %response.ContentLength=%stream.Size
	}
	Set %response.Status="200 OK"
	
	#; Now, the OnPage() method will serve up the actual stream data
	
	Quit 1
}

/// The <method>OnPage()</method> is called by the CSP dispatcher to generate the
/// page content.  For %CSP.StreamServer, since the content type is actually a stream, not HTML
/// we simply write out the stream data.
ClassMethod OnPage() As %Status
{
	If %stream'=$$$NULLOREF Quit %stream.OutputToDevice()
	Quit $$$OK
}

/// Get oid for file
ClassMethod GetOidForFile(file As %String) As %ObjectIdentity [ Internal ]
{
	Do ..FileClassify($P(file,".",$L(file,".")),.type,.bin,.charset)
	If bin Set oid=##class(%FileBinaryStream).GetStreamIdForFile(file,type,charset)
	If 'bin Set oid=##class(%FileCharacterStream).GetStreamIdForFile(file,type,charset)
	Quit oid
}

/// Classify a file type
ClassMethod FileClassify(ext As %String, ByRef type As %String, ByRef bin As %Boolean, ByRef charset As %String) As %Boolean
{
	Set charset="",bin=1
	If ext="" Set type="application/octet-stream" Quit 0
	Set bin=0,ext="/"_$zconvert(ext,"u")_"/"
	If $data(^%SYS("CSP","MimeFileClassify",$extract(ext,2,*-1)),data) {
		Set type=$list(data),bin=$list(data,2),charset=$listget(data,3)
		Quit 1
	}
	If "/CSS/"=ext Set type="text/css" Goto charset
	If "/HTML/HTM/"[ext Set type="text/html" Goto charset
	If "/JS/"=ext Set type="application/javascript" Goto charset
	If "/TXT/"[ext Set type="text/text" Goto charset
	If "/XML/"[ext Set type="text/xml" Goto charset
	Set bin=1,charset=""
	If "/CLASS/"=ext Set type="" Quit 1
	If "/JPG/JPEG/"[ext Set type="image/jpeg" Quit 1
	If "/GIF/"=ext Set type="image/gif" Quit 1
	If "/TIF/"=ext Set type="image/tiff" Quit 1
	If "/TIFF/"=ext Set type="image/tiff" Quit 1
	If "/BMP/"=ext Set type="image/bmp" Quit 1
	If "/ZIP/"=ext Set type="application/zip" Quit 1
	If "/TAR/"=ext Set type="application/x-tar" Quit 1
	If "/GZ/"=ext Set type="application/x-gzip" Quit 1
	If "/Z/"=ext Set type="application/x-compress" Quit 1
	If "/AI/EPS/PS/"[ext Set type="application/postscript" Quit 1
	If "/PDF/"=ext Set type="application/pdf" Quit 1
	If "/AVI/"=ext Set type="video/x-msvideo" Quit 1
	If "/QT/MOV/"[ext Set type="video/quicktime" Quit 1
	If "/MPEG/MPG/MPE/"[ext Set type="video/mpeg" Quit 1
	If "/WAV/"=ext Set type="audio/wav" Quit 1
	If "/PNG/"=ext Set type="image/png" Quit 1
	If "/SVG/"=ext Set type="image/svg+xml" Quit 1
	If "/ICO/"=ext Set type="image/x-icon" Quit 1
	If "/XLSX/"=ext set type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" Quit 1
	If "/XLTL/"=ext set type="application/vnd.openxmlformats-officedocument.spreadsheetml.template" Quit 1
	If "/POTX/"=ext set type="application/vnd.openxmlformats-officedocument.presentationml.template" Quit 1
	If "/PPSX/"=ext set type="application/vnd.openxmlformats-officedocument.presentationml.slideshow" Quit 1
	If "/PPTX/"=ext set type="application/vnd.openxmlformats-officedocument.presentationml.presentation" Quit 1
	If "/SLDX/"=ext set type="application/vnd.openxmlformats-officedocument.presentationml.slide" Quit 1
	If "/DOCX/"=ext set type="application/vnd.openxmlformats-officedocument.wordprocessingml.document" Quit 1
	If "/DOTX/"=ext set type="application/vnd.openxmlformats-officedocument.wordprocessingml.template" Quit 1
	;
	; Default to application/octet-stream
	Set type="application/octet-stream"
	;
	Quit 0
charset		Set charset=##class(%SYS.NLS.Table).GetCSPTable()
	If charset="" Set charset=$get(^%SYS("CSP","DefaultFileCharset"))
	If charset="" {
		#; Do not use default file translate table for javascript
		If "/JS/"=ext Quit 1
		If $$$IsUnicode {
			#; On a unicode Cache when editing the file in Studio we will use the default file translate table
			#; So this tells us the charset to report when sending the file out
			Set charset=$$MapExtCharset^%SYS.NLS($$GetPDefIO^%SYS.NLS(3))
		} Else {
			#; On an 8bit Cache the file will be read/written in RAW mode so we should default to
			#; using the system default translate table
			Set charset=$$MapExtCharset^%SYS.NLS($$GetCharset^%SYS.NLS())
		}
	}
	Quit 1
}

/// Convert a $H value into an HTTP date format. It assumes that $H is local
/// time and converts it to UTC
ClassMethod ToHTTPDate(h As %String) As %String
{
	Try {
		If h'?1.n1","1.n.1".".n Set h=$ZDTH(h,3,,,,,,,,,1)  ; Convert from YYYY-MM-DD HH:MM:SS format
		Set h=$zdatetime(h,-3)
		Set httpdate=$piece($ZDT(h,11,,,,,,,,,,1)," ")_", "_$ZDT(h,2,,,,4,,,,,,1)_" UTC"
	} Catch {
		Set httpdate=""
	}
	Quit httpdate
}

/// Convert an HTTP date to a $HOROLOG format date, converts from UTC time
/// to the local time.
ClassMethod FromHTTPDate(hd As %String) As %String
{
	Try {
		If (hd?1.e1" "3a)||(hd?1.e1" +"1.n) Set hd=$piece(hd," ",1,*-1)
		Set h=$ZDTH($ZSTRIP($piece(hd,",",2),"<>W"),2,,,,,,,,"0,0",1)
		Set horolog=$zdatetimeh(h,-3)
	} Catch {
		Set horolog=""
	}
	Quit horolog
}

}
