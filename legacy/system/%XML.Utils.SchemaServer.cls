/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Serves the XML schema for a class via an HTTP request.<BR>
/// The <i>CLASS</i> parameter contains the name of the class 
/// to serve the schema for.
/// The <i>FILE</i> parameter contains the file path for the schema file.
Class %XML.Utils.SchemaServer Extends %CSP.Page [ Not ProcedureBlock, System = 3 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

Parameter CONTENTTYPE = "text/xml";

Parameter CHARSET = "UTF-8";

/// Require USE permissions on the %Development resource for access to this page.
Parameter SECURITYRESOURCE = "%Development:USE";

/// utility used by new Atelier SOAP wizard
ClassMethod fetchWSDL(type, url, sslConfig, ByRef content) As %String [ Internal ]
{
	Set stream="",errorMessage="",isXML=0

	// Use default charset, if not file parameter.
	If type = "URL" {
		//Set contentType = "text/html"
		If (url '= "") {
			//Set url = $zconvert(..Decrypt(url),"I","UTF8")
			Set httpRequest = ##class(%Net.HttpRequest).%New()
			Do ##class(%Net.URLParser).Parse(url,.urlParts)
			If $get(urlParts("scheme")) = "https" {
				Set sslConfig = $get(%request.Data("SSLCONFIG",1))
				If sslConfig '= "" {
					Set httpRequest.Https = 1
					//Set httpRequest.SSLConfiguration = $zconvert(..Decrypt(sslConfig),"I","UTF8")
					Set httpRequest.SSLConfiguration = $zconvert(sslConfig,"I","UTF8")
					Set sslCheckServer = $get(%request.Data("SSLCHECKSERVER",1))
					If sslCheckServer'="" Set httpRequest.SSLCheckServerIdentity=sslCheckServer
				}
				Else {
					Set errorMessage = $$$TextHTML("SSL Configuration required")
				}
			}
			#; Make sure we don't do unnecessary work if no SSL Config
			If (errorMessage = "") {
				Set httpRequest.OpenTimeout = 5
				Set httpRequest.Timeout = 5
				Set httpRequest.Server = $get(urlParts("host"))
				If (+$get(urlParts("port"))) Set httpRequest.Port = urlParts("port")
				Set path = $get(urlParts("path"))
				Set path("query") = ""
				Set path("fragment") = ""
				If (path '= "") && ($extract(path,1) '= "/") Set path = "/" _ path
				If ($get(urlParts("query")) '= "") {
					Set path("query") = urlParts("query")
					If ($extract(path("query"),1) '= "?") Set path("query") = "?" _ path("query")
				}
				If ($get(urlParts("fragment")) '= "") {
					Set path("fragment") = urlParts("fragment")
					If ($extract(path("fragment"),1) '= "#") Set path("fragment") = "#" _ path("fragment")
				}
				Set path = path _ path("query") _ path("fragment")
				Set status = httpRequest.Get(path)
				If $$$ISERR(status) {
					Set errorMessage = $system.Status.GetErrorText(status)
				}
				Else {
					If $IsObject(httpRequest.HttpResponse.Data) {
						Set stream = httpRequest.HttpResponse.Data
					}
					Else {
						Set stream = ##class(%Stream.TmpCharacter).%New()
						Do stream.Write(httpRequest.HttpResponse.Data)
					}
				}
			}
		}
		//Set %response.ContentType = contentType
	}
	elseif type = "FILE"{
		Set stream=##class(%FileBinaryStream).%New()
		Set stream.Filename=url
		Set encoding=..GetEncoding(stream)
	}
	
	Set isXML = 1
		
	///// onPage
	If isXML Set stream = ..AddStyleSheet(stream)
		// For file and URL, stream is already previewed.
	Do stream.Rewind()
	
	set len=32000
	set content = ""
	set sc = $$$OK
	for
	{
		set line=stream.Read(len,.sc)
		quit:line=""
		set content=content_line
	}
	set stream=""
	
	if errorMessage '= "" quit errorMessage
	quit $$$OK
}

ClassMethod OnPreHTTP() As %Boolean
{
	New file,line,encoding,quote,endpos,url,httpRequest,sslConfig,contentType,urlParts,path,status,mimeType
	Set stream="",errorMessage="",isXML=0

	Set file = %request.Get("FILE")
	Set class = %request.Get("CLASS")
	Set url = %request.Get("URL")
	Set local = %request.Get("LOCAL")

	// Use default charset, if not file parameter.
	If (file="") && (class="") && (local="") {
		Set contentType = "text/html"
		If (url '= "") {
			Set url = $zconvert(..Decrypt(url),"I","UTF8")
			Set httpRequest = ##class(%Net.HttpRequest).%New()
			Do ##class(%Net.URLParser).Parse(url,.urlParts)
			If $get(urlParts("scheme")) = "https" {
				Set sslConfig = $get(%request.Data("SSLCONFIG",1))
				If sslConfig '= "" {
					Set httpRequest.Https = 1
					Set httpRequest.SSLConfiguration = $zconvert(..Decrypt(sslConfig),"I","UTF8")
					Set sslCheckServer = $get(%request.Data("SSLCHECKSERVER",1))
					If sslCheckServer'="" Set httpRequest.SSLCheckServerIdentity=..Decrypt(sslCheckServer)
				}
				Else {
					Set errorMessage = $$$TextHTML("SSL Configuration required")
				}
			}
			#; Make sure we don't do unnecessary work if no SSL Config
			If (errorMessage = "") {
				Set username = $get(%request.Data("USERNAME",1))
				If username'="" {
					Set httpRequest.Username = ..Decrypt(username)
					Set httpRequest.Password = ..Decrypt($get(%request.Data("PASSWORD",1)))
				}
				Set httpRequest.OpenTimeout = 5
				Set httpRequest.Timeout = 5
				Set httpRequest.Server = $get(urlParts("host"))
				If (+$get(urlParts("port"))) Set httpRequest.Port = urlParts("port")
				Set path = $get(urlParts("path"))
				Set path("query") = ""
				Set path("fragment") = ""
				If (path '= "") && ($extract(path,1) '= "/") Set path = "/" _ path
				If ($get(urlParts("query")) '= "") {
					Set path("query") = urlParts("query")
					If ($extract(path("query"),1) '= "?") Set path("query") = "?" _ path("query")
				}
				If ($get(urlParts("fragment")) '= "") {
					Set path("fragment") = urlParts("fragment")
					If ($extract(path("fragment"),1) '= "#") Set path("fragment") = "#" _ path("fragment")
				}
				Set path = path _ path("query") _ path("fragment")
				Set status = httpRequest.Get(path)
				If $$$ISERR(status) {
					Set errorMessage = $system.Status.GetErrorText(status)
				}
				Else {
					If $IsObject(httpRequest.HttpResponse.Data) {
						Set stream = httpRequest.HttpResponse.Data
					}
					Else {
						Set stream = ##class(%Stream.TmpCharacter).%New()
						Do stream.Write(httpRequest.HttpResponse.Data)
					}
					Set contentType = httpRequest.HttpResponse.ContentType
					#; Don't translate the output if a character set was specified in the response
					If ($piece(contentType,";",2,99) [ " charset=") Set %response.NoCharSetConvert = 1
					Set mimeType = $extract($zstrip($piece(contentType,";",1),"<>W"),*-3,*)
					Set isXML = (mimeType = "/xml") || (mimeType = "+xml")
				}
			}
		}
		Set %response.ContentType = contentType
	}

	If file="" Quit 1

	// Being called from XML or SOAP Wizard.
	// Filename is encrypted with the session key
	Set $ztrap = "ErrTrap"
	Set file=$zcvt(..Decrypt(file),"I","UTF8")

	// Get first line of file.
	Set stream=##class(%FileBinaryStream).%New()
	Set stream.Filename=file
	Set encoding=..GetEncoding(stream)
	
	// If encoding found then use it for charset.
	If encoding'="" Set %response.CharSet=encoding
	// Assume the file is XML
	Set isXML = 1
	Quit 1
ErrTrap  Set $ztrap="",stream="" 
	Set %response.ContentType="text/html"
	Quit 1
}

ClassMethod GetEncoding(stream As %Stream.Object = "") As %String [ ProcedureBlock = 1 ]
{
	If '$IsObject(stream) Quit ""
	Do stream.Rewind()
	Set line=$tr($piece(stream.Read(1000),$c(10),1),$c(9,13),"  ")
	
	// Use default charset if not XML declaration with encoding attribute.
	If ($extract(line,1,6)'="<?xml ") || (line'["?>") Quit ""
	Set line=$piece(line,"?>",1)
	If line'[" encoding" Quit ""
	Set encoding=$zstrip($piece(line," encoding",2),"<W")
	If $extract(encoding)'="=" Quit ""
	Set encoding=$zstrip($extract(encoding,2,*),"<W")
	Set quote=$extract(encoding)
	If (quote'="""") && (quote'="'") Quit ""
	Set endpos=$find(encoding,quote,2)
	If endpos<0 Quit ""
	Quit $extract(encoding,2,endpos-2)
}

ClassMethod AddStyleSheet(stream As %Stream.Object = "") As %Stream.Object [ ProcedureBlock = 1 ]
{
	If '$IsObject(stream) Quit
	
	Do stream.Rewind()
	Set tStatus = $$$OK
	Set newStream = ##class(%Stream.TmpCharacter).%New()
	Try {
		Set line = stream.Read(200)
			
		If $extract(line,1,10) '[ "<?xml " {
			Do newStream.WriteLine("<?xml version=""1.0"" ?>")
		}
		Else {
			
			Set tXMLDec = $piece(line,"?>",1) _ "?>"
			Set line = $extract(line,$length(tXMLDec)+1,*)
			Do newStream.WriteLine(tXMLDec)
			Set tStyleSheetPos = $find(line,"<?xml-stylesheet ")
			If tStyleSheetPos {
				Do newStream.Write($extract(line,1,tStyleSheetPos-1))
				Set tStyleSheetPos = $find(line,"?>")
				If tStyleSheetPos {
					Set line = $extract(line,tStyleSheetPos,*)
				}
				Else {
					#; Still inside <?xml-stylesheet, so ignore contents of line
					Set line = stream.Read(2000)
					Set tStyleSheetPos = $find(line,"?>")
					If tStyleSheetPos {
						Set line = $extract(line,tStyleSheetPos,*)
					}
					Else {
						Set tStatus = $$$ERROR($$$GeneralError,$$$Text("Unable to replace XML stylesheet"))
						Quit
					}
				}
			}
		}
		Do newStream.WriteLine("<?xml-stylesheet href=""ensemble/Ensemble_XMLDisplay.xsl"" type=""text/xsl"" ?>")
		Do newStream.Write(line)
		
		While 'stream.AtEnd {
			Do newStream.Write(stream.Read())
		}		
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		Do newStream.Clear()
		Do newStream.WriteLine("<?xml version=""1.0"" ?>")
		Do newStream.WriteLine("<error>" _ $zconvert($system.Status.GetErrorText(tStatus),"O","XML") _ "</error>")
	}
	Do newStream.Rewind()
	
	Quit newStream
}

ClassMethod OnPage() As %Status
{
	
	Set class = %request.Get("CLASS")
	Set maxPreview = %request.Get("MAXPREVIEW")

	If stream'="" {
		
		If isXML Set stream = ..AddStyleSheet(stream)
		
		if (maxPreview = "") || (stream.SizeGet() <= ..Decrypt(maxPreview)) {
			// For file and URL, stream is already previewed.
			Do stream.Rewind()
			$$$SETIO("RAW")
			Do stream.OutputToDevice()
		} else {
			write "<div>"_$$$TextHTML("File is too large to be previewed")_"</div>"
		}
		Set stream=""   // to force close

	} ElseIf (class '= "") {
		Write "<?xml version=""1.0"" ?>",!
		Write "<s:schema xmlns:s=""http://www.w3.org/2001/XMLSchema"" >",!
		Do $zobjclassmethod(class,"XMLSchema")
		Write "</s:schema>",!
	} Else {
		&html<Error>
		If $get(errorMessage) '= "" Write errorMessage
	}
	
	Quit $$$OK
}

}
