/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// A SAX content handler that processes XML Schema files.<BR>
/// This class is used by the XML Schema Wizard; it is not
/// for direct use within applications.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %XML.Utils.SchemaHandler Extends %XML.SAX.ContentHandler [ System = 3 ]
{

/// Integer tree id within ^IRIS.Temp
Property Tree As %Integer;

/// Are we in a schema?
Property InSchema As %Boolean [ InitialExpression = 0 ];

/// Stack level
Property Level As %Integer [ InitialExpression = 0 ];

/// Stack of parsed elements.<BR>
/// Each entry contains: $LB(local, elno)
/// 
Property ElStack As %String [ MultiDimensional ];

/// The <class>SchemaReader</class> that invoked us.
Property Reader As SchemaReader;

/// The file we are parsing
Property SourceName As %String;

/// List of namespace prefixes and their mappings<BR>
/// PrefixMap(prefix) = uri<BR>
/// PrefixMap(prefix,#) = uri (for "stacked" prefixes)
Property PrefixMap As %String [ MultiDimensional ];

/// current target namespace for this schema
Property TargetNS As %String;

/// Save original target namespace when starting processing of schema
Property SaveTargetNS As %String [ Private ];

/// included or imported schema being processed
Property Included As %Boolean;

/// Parse an XML Schema file
ClassMethod ParseFile(filename As %String, reader As SchemaReader, target As %String = "", bInclude As %Boolean = 0) As %Status
{
	Set handler = ..%New()
	Set handler.Reader = reader
	Set handler.Tree=reader.Tree  // so we can use $$$ElTree macro
	Set handler.SourceName = filename
	Set handler.TargetNS = target // pre-set for include files
	Set handler.Included = bInclude

	// parse and build tree
	Set sc = ##class(%XML.SAX.Parser).ParseFile(filename,handler,reader.EntityResolver,reader.SAXFlags)
	If ($$$ISERR(sc)) {
		Quit sc
	}
	
	Quit $$$OK
}

/// Parse an XML Schema stream
ClassMethod ParseStream(stream As %AbstractStream, reader As SchemaReader) As %Status
{
	Set handler = ..%New()
	Set handler.Reader = reader
	Set handler.Tree=reader.Tree  // so we can use $$$ElTree macro
	Set handler.SourceName = ""

	// parse and build tree
	Set sc = ##class(%XML.SAX.Parser).ParseStream(stream,handler,reader.EntityResolver,reader.SAXFlags)
	If ($$$ISERR(sc)) {
		Quit sc
	}
	
	Quit $$$OK
}

/// Parse an XML Schema from a URL
ClassMethod ParseURL(url As %String, reader As SchemaReader, target As %String = "", bInclude As %Boolean = 0) As %Status
{
	If $$$isWINDOWS && ($E($ZCVT(url,"L"),1,7)="file://") {
		// Compensate for SAX ParseURL not supporting file:// syntax on Windows
		Set url=$ZCVT($E(url,8,*),"L")
		Set:"/"=$E(url)&&(url[":"||(url["//")) url=$E(url,2,*)
		Quit ..ParseFile($TR(url,"/","\"), reader, target, bInclude)
	}
	Set handler = ..%New()
	Set handler.Reader = reader
	Set handler.Tree=reader.Tree  // so we can use $$$ElTree macro
	Set handler.SourceName = url
	Set handler.TargetNS = target // pre-set for include files
	Set handler.Included = bInclude
	
	If reader.HttpRequest="" Set reader.HttpRequest = ##class(%Net.HttpRequest).%New()
	Set reader.HttpRequest.SSLConfiguration=reader.SSLConfiguration
	If reader.SSLCheckServerIdentity'="" Set reader.HttpRequest.SSLCheckServerIdentity=reader.SSLCheckServerIdentity

	// parse and build tree
	Set sc = ##class(%XML.SAX.Parser).ParseURL(url,handler,reader.EntityResolver,reader.SAXFlags,,,reader.HttpRequest)
	If ($$$ISERR(sc)) {
		Quit sc
	}
	
	Quit $$$OK
}

/// Converts list of attrs into an array keyed by attr name
Method UnpackAttrs(attrs As %List, ByRef array As %String)
{
	For i = 1:5:$LL(attrs) {
		If ($LG(attrs,i+1) '= "") {
			Set name=$LG(attrs,i+1)
			Set array(name) = $LG(attrs,i+4)
			Set array(name,"u")=$LG(attrs,i)
		}
	}
}

ClassMethod GetFullPath(base As %String, file As %String) As %String
{
	// Normalize to work with / separator
	Set base = $tr(base,"\","/")
	Set file = $tr(file,"\","/")
	If file="" Quit base 
	If $extract(file)="/" Quit file
	If $case($ZConvert($piece(file,"://"),"L"),"http":1,"https":1,"file":1,:0) Quit file

	If $$$isVMS,$case($zcvt($piece(base,"://"),"L"),"http":0,"https":0,:1) {
		If (base="") || (file [ "[") Quit file

		// file portion is in Unix format.  
		// Separate base directory and filename.
		Set base=$piece(base,"]",1)
		Set filename=$piece(file,"/",$length(file,"/"))

		// Remove any ./ pieces and replace ../ with $c(1) for later processing
		Set dir = ""
		For i=$length(file,"/")-1:-1:1 {
			Set p = $piece(file,"/",i)
			If p'="." {
				If p=".." Set p=$c(1)
				Set dir = p _ "/" _ dir
			}
		}
		Set dir=base_"."_$tr(dir,"/",".")
		
		// Normalize directory by removing $c(1) which stands for ..
		Set skip=0
		Set normalizedDir = ""
		For i=$length(dir,"."):-1:1 {
			Set p = $piece(dir,".",i)
			if p'="" {
				If (p=$c(1)) && ($piece(dir,".",i-1)'="") {
					Set skip=skip+1
				} Else {
					If skip>0 {
						Set skip=skip-1
					} Else {
						Set normalizedDir = p _ "." _ normalizedDir
					}
				}
			}
		}
		If $extract(normalizedDir,*)="." Set $extract(normalizedDir,$length(normalizedDir))=""
		
		Quit normalizedDir _ "]" _ filename

	} Else {
		// Append filename to the path from the original base file
		If base'="" Set file = $piece(base,"/",1,$length(base,"/")-1) _ "/" _ file
	
		// Normalize filename by removing . and ..
		Set normalizedFile = $piece(file,"/",$length(file,"/"))
		Set skip=0
		For i=$length(file,"/")-1:-1:1 {
			Set p = $piece(file,"/",i)
			If p'="." {
				If (p="..") && ($piece(file,"/",i-1)'="") {
					Set skip=skip+1
				} Else {
					If skip>0 {
						Set skip=skip-1
					} Else {
						Set normalizedFile = p _ "/" _ normalizedFile
					}
				}
			}
		}
	
		If $$$isWINDOWS && 
		   '$case($zcvt($piece(normalizedFile,"://"),"L"),"http":1,"https":1,:0) {
			Quit $zcvt(normalizedFile,"L")
		}
	
		Quit normalizedFile
	}
}

Method startDocument()
{
	Set ..ElStack(0) = ""
}

Method startPrefixMapping(prefix As %Library.String, uri As %Library.String)
{
	If (prefix = "") { 
		Set prefix = "$defaultNS"
	}
	
	// if we already have seen this prefix, we have to stack the old one
	If ($D(..PrefixMap(prefix))) {
		// find end of list and add 1 to it
		Set i = $O(..PrefixMap(prefix,""),-1) + 1
	
		// stack the current uri	
		Set ..PrefixMap(prefix,i) = ..PrefixMap(prefix)
	}
	
	Set ..PrefixMap(prefix) = uri
	
	// add this NS to the list for the reader
	Do ..Reader.AddNS(uri,prefix,"","")
	
	Quit
}

Method endPrefixMapping(prefix As %Library.String)
{
	If (prefix = "") {
		Set prefix = "$defaultNS"
	}
	
	// see if there is a "stacked" prefix
	Set i = $O(..PrefixMap(prefix,""),-1)
	If (i = "") {
		Kill ..PrefixMap(prefix)
	}
	Else {
		Set ..PrefixMap(prefix) = ..PrefixMap(prefix,i)
		Kill ..PrefixMap(prefix,i)
	}

	Quit
}

Method startElement(uri As %Library.String, local As %Library.String, qname As %Library.String, attrs As %List)
{
	If ('..InSchema) {
		// look for start of schema info
		If (local = "schema") {
			Set ..InSchema = 1
			Set $$$ElTree(..Reader.ElCount) = $LB(local)

			// get attributes for schema
			Do ..UnpackAttrs(attrs,.arr)
			
			// get target namespace for schema
			Set target = $get(arr("targetNamespace"))
			Do ..Reader.AddNS(target,"",($get(arr("elementFormDefault"))="qualified"),($get(arr("attributeFormDefault"))="qualified"))
			If (target'="") || (..TargetNS="") {
				Set ..SaveTargetNS = ..TargetNS
				Set ..TargetNS = target
			}

			If ..Reader.TargetNS '= $c(1) {
				If ..Reader.TargetNS '= ..TargetNS Set ..Reader.MultipleTargetNS=1
			} Else {
				// set the reader target
				Set ..Reader.TargetNS = ..TargetNS
			}
		}
		ElseIf (local = "service") && (..Reader.ClassPrefix="") && '..Reader.NoClassPrefix {
			// name of WSDL service name...

			// get attributes for schema
			Do ..UnpackAttrs(attrs,.arr)

			If ($D(arr("name"))) {
				// set class prefix to use for generated classes...
				Set ..Reader.ClassPrefix = ##class(%SOAP.WebBase).NormalizeName(arr("name"),$$$MAXPACKAGEIDLENGTH) // !!!
			}
		}
		ElseIf (local = "import") && (uri=$$$WSDLns) {
			// get attributes for schema
			Do ..UnpackAttrs(attrs,.arr)

			// an imported file
			Set file = $G(arr("location"))
			If (file '= "") {
				// get path name for current file
				Set file = ..GetFullPath(..SourceName, file)
				Set ns=$get(arr("namespace"))
				If ns="" Set ns=$c(2)
				If '$data(..Reader.Includes(file,ns)) Set ..Reader.Includes(file,ns)=""
			}
		}
	}
	Else {
		
		// get attributes	
		Do ..UnpackAttrs(attrs,.arr)
		
		// find the index no of our target NS
		If (..TargetNS '= "") {
			Set targetNSno = ..Reader.NSIndex(..TargetNS)
		}
		Else {
			// no target; use unqualified name
			Set targetNSno = ""
		}

		If ((local = "include") || (local = "import")) {
			// an include file
			Set file = $G(arr("schemaLocation"))
			If (file '= "") {

				// get path name for current file
				Set file = ..GetFullPath(..SourceName, file)
				If (local = "include") {
					// remember our targetNS for the include
					Set ns=..TargetNS
				} Else {
					Set ns=$get(arr("namespace"))
				}
				If ns="" Set ns=$c(2)
				If '$data(..Reader.Includes(file,ns)) Set ..Reader.Includes(file,ns)=""
			}
		}
		Else {
			// stack xml element
			Set ..Reader.ElCount = ..Reader.ElCount + 1

			Set ..Level = ..Level + 1
			Set ..ElStack(..Level) = $LB(local,..Reader.ElCount)
	
			Set pno = +$LG(..ElStack(..Level - 1),2)
			
			Set name = $G(arr("name"))

			// make a qualified name for this element
			Set qelname = targetNSno _ "^" _ name
			
			// Identify Microsoft dataset elements in included schemas.
			// Only the first dataset in a schema is processed.
			If ..Included && (local="element") && ($get(arr("IsDataSet"))="true") &&
			   ($get(arr("IsDataSet","u"))="urn:schemas-microsoft-com:xml-msdata") {
				Set local="MSDataSet_element_ignore"
				If ..TargetNS'="" {
					Set nsindex=..Reader.NSIndex(..TargetNS)
					If $get(..Reader.NSInfo(nsindex,"msdata"))="" {
						Set local="element"
						Set ..Reader.NSInfo(nsindex,"msdata")=..Reader.ElCount
					}
				}
			}

			// add name to index for resolving ref=
			If (name '= "") && (..Level = 1) &&
			   $case(local,"attribute":1,"attributeGroup":1,"element":1,"group":1,:0) {
				Set ..Reader.ElIndex(qelname) = ..Reader.ElCount
			}
			
			// add to tree
			Set $$$ElTree(..Reader.ElCount,"local") = local

			// remember source file for this element
			Set src=""
			For i=1:1:+$get(..Reader.ElementSrc) {
				If ..Reader.ElementSrc(i)=..SourceName Set src=i Quit
			}
			If src="" {
				Set src=$get(..Reader.ElementSrc)+1
				Set ..Reader.ElementSrc=src
				Set ..Reader.ElementSrc(src)=..SourceName
			}
			Set $$$ElTree(..Reader.ElCount,"src") = src
			
			// remember target NS for this element
			// Set $$$ElTree(..Reader.ElCount,"TargetNS") = targetNSno

			Set $$$ElTree(pno,"ch",..Reader.ElCount) = ""
		
			// add attributes to tree
			// some of these have to be "qualified" by namespace:
			// if not qualified:
			// 	name is in the targetNamespace
			// 	base,ref,type,arrayType are in the default Namespace
			// 	all other values are not qualified

			For i = 1:5:$LL(attrs) {
				If ($LG(attrs,i+1) '= "") {
					Set aname = $LG(attrs,i+1)
					Set aval = $LG(attrs,i+4)
					
					// name is already marked with a namespace above
					If (aname = "name") {
						// name is defined to always be in the target namespace
						Set aval = qelname
					}
					ElseIf (",ref,type,base,arrayType," [ (","_aname_",")) {
						// if unqualified, these values are in the default namespace
						// else they are in their specified namespace
						
						If (aval [ ":") {
							// Keep value of xml:... unchanged.
							If $P(aval,":",1)'="xml" {
								// qualified
								Set ns = $G(..PrefixMap($P(aval,":",1)))
								Set aval = $P(aval,":",2)
	
								// Skip type="." or type=""
								If aname="type",aval="." Continue
						
								If (ns '= "") {
									// replace NS with NS index number
									Set aval = ..Reader.NSIndex(ns) _ "^" _ aval
								}
								Else {
									// this should not happen
									Set aval = "^" _ aval
								}
							}
						} Else {
							// unqualified: use default
							Set ns = $G(..PrefixMap("$defaultNS"))
							// If this schema has been included and no default namespace,
							// then the targetNamespace is the default.
							If (ns="") && ..Included Set ns=..TargetNS

							// Skip type="." or type=""
							If aname="type",aval="." Continue

							If (ns '= "") {
								// replace NS with default NS index number
								Set aval = ..Reader.NSIndex(ns) _ "^" _ aval
							}
							Else {
								Set aval = "^" _ aval
							}
						}
					}
					ElseIf $LG(attrs,i)=$$$ISCSOAPns {
						set aname="isc:"_aname
					}
					Else {
						// leave aval alone
					}

					// place attr in ElTree
					Set $$$ElTree(..Reader.ElCount,"attrs",aname) = aval
				}
			}
		}		
	}
}

Method endElement(uri As %Library.String, local As %Library.String, qname As %Library.String)
{
	If (..InSchema) {
		If (local = "schema") {
			Set ..InSchema = 0
			Set ..TargetNS = ..SaveTargetNS
		}
		Else {
			If ((local '= "include") && (local '= "import")) {
				// unstack xml element
				Kill ..ElStack(..Level)
				Set ..Level = ..Level - 1
			}
		}
	}
}

Method characters(chars As %Library.String, length As %Library.Integer)
{
	Set chars = $ZStrip(chars,"<>W")

	// Test for too many characters
	If (($L(chars) + $L($G($$$ElTree(..Reader.ElCount,"chars")))) < ($$$MaxLocalLength-100)) {
		Set:(chars'="") $$$ElTree(..Reader.ElCount,"chars") = $G($$$ElTree(..Reader.ElCount,"chars")) _ chars
	}
}

}
