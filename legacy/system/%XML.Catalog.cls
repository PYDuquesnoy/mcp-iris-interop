/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents an XML catalog. It defines a database of associations 
/// between PUBLIC document identifiers and the URLs for their DTD and/or schema files.
/// 
/// This class is used by the XML.CatalogResolver class when it resolves 
/// DTD and Schema references.
Class %XML.Catalog Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Not ProcedureBlock, SqlTableName = XCatalog, System = 3 ]
{

/// The Keyword for a Catalog entry.
/// Currently only PUBLIC is supported
Property Keyword As %String(MAXLEN = 20) [ Required ];

Index PubIdIDX On PublicId [ Unique ];

/// The Public Identifier string for a Catalog entry.
Property PublicId As %String(MAXLEN = 200) [ Required ];

/// The URL string for a Catalog entry.
Property URL As %String(MAXLEN = 200) [ Required ];

/// Clear the contents of the catalog.
ClassMethod Reset()
{
	Kill ^XML.CatalogD,^XML.CatalogI
}

/// Test if the Catalog is empty
ClassMethod IsEmpty() As %Boolean
{
	Quit '$D(^XML.CatalogD)
}

/// Reset and load the default catalog.
ClassMethod LoadDefault() As %Status
{
	New def,err
	Set def = $$GetFilename^%apiCSP("/csp/docbook/doctypes/CacheXML.cat")
	If ((def = "") || '##class(%File).Exists(def)) {
		Set err = $$$ERROR($$$XMLNoCatalogFile,def)
		Do DisplayError^%apiOBJ(err)
		Quit err
	}

	Write "Resetting catalog"
	Do ..Reset()
	Write ".",!

	// load it	
	Quit ..Load(def)
}

/// Load a Catalog File
ClassMethod Load(filename As %String) As %Status
{
	New parser,el,sc,entry,catfile,path
	
	Set sc = $$$OK

	Set parser = ##class(CatalogParser).%New()
	Set sc = parser.Start(filename)
	If ($$$ISERR(sc)) {
		GOTO Done
	}
	
	Write "Loading XML catalog file: ",filename,!
	
	While (parser.NextElement(.el)) {
		// add an entry to the catalog
		// we only handle PUBLIC at this point
		If ($G(el("KEYWORD")) = "PUBLIC") {
			Write ?5,"PUBLIC ",$G(el("PUBLIC")),!

			Set entry = ##class(Catalog).%New()
			Set entry.Keyword = $G(el("KEYWORD"))
			Set entry.PublicId = $G(el("PUBLIC"))
			Set entry.URL = $G(el("SYSTEM"))
			Do entry.%Save()
		}
		ElseIf ($G(el("KEYWORD")) = "CATALOG") {
			// recursively load another file
			Set catfile = $G(el("CATALOG"))
			Set catfile = $TR(catfile,"\","/")

			// check for relative path
			
			If (($E(catfile,1,1)'="/") && ($E(catfile,2,2)'=":")) {
				Set path = $zu(12,filename)
				Set path = $TR(path,"\","/")
				Set path = $P(path,"/",1,$L(path,"/")-1) _ "/"
				
				Set catfile = path _ catfile
			}
			
			Set sc = ..Load(catfile)
			If ($$$ISERR(sc)) {
				GOTO Done
			}
		}
	}

	Write "Complete: ",$zdt($H,3),!
Done	
	Quit sc
}

/// Return an open Stream object that contains the
/// DTD for a given Public Identifier.<br>
/// The caller is responsible for closing the stream.
ClassMethod ResolvePublic(publicId As %String) As %AbstractStream
{
	New url,stream,components,sc,path,io
	Set stream = ""

	Set url = ..FindURL(publicId)

	If (url '= "") {
		// parse URL into components
		Do ##class(%Net.URLParser).Parse(url,.components)
	
		If ($G(components("scheme")) = "http") {
			New httpRequest
			Set httpRequest = ##class(%Net.HttpRequest).%New()
			If (httpRequest = $$$NULLOREF) ZTrap
			Set httpRequest.Server = components("netloc")
			Do httpRequest.Get(components("path"))
			
			Set stream = httpRequest.HttpResponse.Data
		}
		ElseIf ($G(components("scheme")) = "file") {
		 	Set stream = ##class(%File).%New(components("netloc") _ components("path"))
		 	Set sc = stream.Open("RU")
		 	If ($$$ISERR(sc)) {
			 	Do $system.OBJ.DisplayError(sc)
			 	Write !,"DTD Resolution Error: "
			 	Set stream = ""
		 	}
	 	}
		ElseIf (($G(components("scheme")) = "csp")) {
			// csp: means resolve this using Cache CSP applications
			Set path = $$GetFilename^%apiCSP($G(components("path")))
			If path="" {
				Set sc=$$$ERROR($$$CSPApplicationDoesNotExist,$P($G(components("path")),"/",1,$L($G(components("path"))-1)))
			} ElseIf ##class(%File).Exists(path) {
				Set stream = ##class(%FileBinaryStream).%New()
				Set sc= stream.LinkToFile(path)
			} Else {
				Set sc=$$$ERROR($$$FileNotFound,path)
			}
			If $$$ISERR(sc) {
				Set io = $io
				Use 0
				Do $SYSTEM.Status.DisplayError(sc)
				Write !,"Unable to use file: ",path,!
				Use io
				Set stream = ""
			}
		}
	}
	
	If stream'=$$$NULLOREF {
	
		#; Create a Stream Adapter
 		Set stream=##class(%XML.SAX.StreamAdapter).%New(stream)
 		If '$IsObject(stream) Do $System.Status.DisplayError(%objlasterror)
	}
	Quit stream
}

/// Find the URL for a given Public Identifier.
ClassMethod FindURL(publicId As %String) As %String
{
	New SQLCODE,url
	
	/// Use STARTSWITH; publicId might not be complete
	&sql(SELECT URL 
			INTO :url
			FROM XCatalog 
			WHERE :publicId %STARTSWITH PublicId)
			
	If (SQLCODE '= 0) {
		QUIT ""
	}
	
	Quit url
}

/// Display the contents of the XML Catalog to the console.
ClassMethod DisplayCatalog()
{
	New SQLCODE,id,key,pubid
	
	Write "Current contents of XML Catalog:",!
	
	&sql(DECLARE DC CURSOR FOR SELECT ID,Keyword, PublicId 
			INTO :id,:key,:pubid
			FROM XCatalog )
			
	&sql(OPEN DC)
	&sql(FETCH DC)
	
	While (SQLCODE = 0) {
		Write id,?6,key,?16,pubid,!
		&sql(FETCH DC)
	}
	
	&sql(CLOSE DC)
}

Storage Default
{
<Data name="CatalogClassName">
<Attribute>%%CLASSNAME</Attribute>
<Structure>node</Structure>
<Subscript>0</Subscript>
</Data>
<Data name="CatalogDefaultData">
<Value name="1">
<Value>PublicId</Value>
</Value>
<Value name="2">
<Value>URL</Value>
</Value>
<Value name="3">
<Value>Keyword</Value>
</Value>
</Data>
<DataLocation>^XML.CatalogD</DataLocation>
<DefaultData>CatalogDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^XML.CatalogD</IdLocation>
<IndexLocation>^XML.CatalogI</IndexLocation>
<StreamLocation>^%XML.CatalogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
