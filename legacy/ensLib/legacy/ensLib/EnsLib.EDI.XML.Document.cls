/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsEDIXML, %soap)

/// This class encapsulates an XML document stream and provides methods to interrogate and update it
/// Two types of path strings can be used to identify a document node: a 'Property path' that is based in
/// a particular XML schema definition (xsd), irrespective of any particular document instance, and a 'DOM path' that is based in the structure of a particular
/// document irrespective of any XML schema. The DOM Path uses XPATH conventions; it always starts with '/' while a Property Path never does.
Class EnsLib.EDI.XML.Document Extends (%Persistent, EnsLib.EDI.XML.Prop, %XML.SAX.EntityResolver, %XML.Adaptor) [ System = 4 ]
{

Parameter DOCCLASSNAME = "XML Document";

Parameter DOCCLASSFULLNAME = "XML Virtual Document";

Parameter DOCSHORTNAME = "XML";

/// Name of the default SearchTable indexing class used in UI choices and MessageBank submissions 
Parameter DEFSEARCHCLASS = "EnsLib.EDI.XML.SearchTable";

/// Name of the associated schema class and, after a colon, the schema class code that represents a DocType
Parameter SCHEMACLASS = "EnsLib.EDI.XML.Schema:DS";

Index Extent [ Extent, Type = bitmap ];

Index OriginalDocId On OriginalDocId;

Property %EntityResolverSchemaDir As %String(MAXLEN = "") [ Internal, Transient ];

Property %EntityResolverHttpTimeout As %Numeric [ Internal, Transient ];

Property %EntityResolverSSLConfigName As %String(MAXLEN = "") [ Internal, Transient ];

/// The raw text content of the document. Note that this is a truncated version suitable for use in SQL results and visual inspection,
/// but not a complete or definitive representation of the document.
Property RawContent As %String(MAXLEN = 10000) [ Calculated, ReadOnly, SqlComputeCode = { Set {RawContent}=##class({%%CLASSNAME}).getContentAsString({ID}) }, SqlComputed, Transient ];

/// When setting 'raw' XML to a Property path (as opposed to a DOM path)
/// this flag allows setting the data directly to the internal DOM storage.<br/>
/// Whilst this might improve performance the output may have nodes in a different order
/// than desired when combining with single property path sets.<br/>
/// This setting is provided for backwards compatibility. <br/>
/// The default is to set to the internal intermediary Property storage.<br/>
Property ByPassPropCacheForMixed As %Boolean [ InitialExpression = 0, Transient ];

Method RawContentGet() As %String
{
	Quit ..OutputToString()
}

/// This method is for use from the RawContent property's SQL Compute invocation
ClassMethod getContentAsString(pId As %String, pMaxLen As %Integer = 10000, pStartOffset As %Integer = 1) As %String [ Internal ]
{
	Set tDoc=..%OpenId(pId,,.tSC)  Quit:$$$ISERR(tSC) ""	
	Quit $E(tDoc.OutputToString(),1,pMaxLen)
}

/* override with new SqlComputed code */
Property Name As %String(MAXLEN = "") [ Calculated, ReadOnly, SqlComputeCode = { Set {Name}=$S(""={%storedContentRef}:##class({%%CLASSNAME}).getName({ID}),1:$$$xmlGetNodeValue({%storedContentRef},$$$xmlGetDocumentElement({%storedContentRef}))) }, SqlComputed, Transient ];

Method NameGet() As %String [ CodeMode = expression ]
{
..GetValueAt("/1/name()")
}

ClassMethod getName(pId As %String) As %String [ Internal ]
{
	#dim tName As %String = ""
	#dim tSC As %Status = $$$OK
	Set tDoc=..%OpenId(pId,,.tSC)
	If $$$ISOK(tSC) Set tName=tDoc.Name
	Quit tName
}

/* override with new SqlComputed code */
Property TypeVersion As %String(MAXLEN = "") [ Calculated, ReadOnly, SqlComputeCode = { Set {TypeVersion}=##class({%%CLASSNAME}).getTypeVersion({ID}) }, SqlComputed, Transient ];

Method TypeVersionGet() As %String [ CodeMode = expression ]
{
..GetValueAt(":/1/@schemaLocation")
}

ClassMethod getTypeVersion(pId As %String) As %String [ Internal ]
{
	/* Always open object even if stored content in case TypeVersion modified */
	#dim tTypeVersion As %String = ""
	#dim tSC As %Status = $$$OK
	Set tDoc=..%OpenId(pId,,.tSC)
	If $$$ISOK(tSC) Set tTypeVersion=tDoc.TypeVersion
	Quit tTypeVersion
}

/* override with new SqlComputed code */
Property Identifier As %String(MAXLEN = "") [ Calculated, ReadOnly, SqlComputeCode = { Set {Identifier}=##class({%%CLASSNAME}).getIdentifier({ID},{DocType}) }, SqlComputed, Transient ];

Method IdentifierGet() As %String
{
	Set tIdentifier=""
	If (""'=..DocTypeCategory)&&(""'=..DocTypeName) {
		Set tIdentifierPath=$G($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"idPath"))
		Set:""'=tIdentifierPath tIdentifier=..GetValueAt(tIdentifierPath)
	}
	Quit tIdentifier
}

ClassMethod getIdentifier(pId, pDocType) As %String [ Internal ]
{
	Set tIdentifier=""
	If (""'=$P(pDocType,":",1))&&(""'=$P(pDocType,":",2)) {
		Set tIdentifierPath=$G($$$vaSchemaGbl($P(pDocType,":",1),"DS",$P(pDocType,":",2),"idPath"))
		If ""'=tIdentifierPath { Set tObj=..%OpenId(pId) Set:$IsObject(tObj) tIdentifier=tObj.GetValueAt(tIdentifierPath) }
	}
	Quit tIdentifier
}

/* Override properties from %XML.SAX.ContentHandler as [ Transient ] because we are persistent */
Property HandlerType As %Integer [ InitialExpression = {$$$ClsHandler}, Internal, Transient ];

Property KeepWhitespace As %Boolean [ InitialExpression = 0, Internal, Transient ];

Property GlobalName As %String(MAXLEN = "") [ InitialExpression = "||%xmlTemp", Internal, Transient ];

/*
	We maintain 3 layers of content: Stored DOM Content, extra DOMCache that modifies it, and PropCache that modifies that.
	DOMCache and PropCache can coexist so long as they are in sync or one of them has priority.
	- DOM  Get : first convert PropCache to DOMCache so they are in sync, then get from DOMCache looking through to stored DOM
	- DOM  Set : first convert PropCache to DOMCache and kill PropCache, then set to DOMCache looking through to stored DOM
	- Prop Get : get from PropCache looking through to DOMCache looking through to stored DOM
	- Prop Set : set into PropCache; no need to convert because PropPath is content-independent
	- DocType Set : first convert PropCache to DOMCache, kill PropCache
	Note that a Set with action=Append means an implied Get must be done first.
	
	Also note that each of these 3 content layers may be either process-local or stored persistently
*/
/// Retrieve the content value of the XML element or attribute identified by <var>pPropertyPath</var>.
/// This path may be either a "DOM Path" or a "Property Path".<p/>
///  A DOM path is schema independent and starts from the document root with a '/' character and is delimited by the '/' character at each
/// level of descent, and by square brackets '[' and ']' for repeating elements.<p/>
/// A Property path is based on a simplified projection of the XML schema applied to the current document by way of its DocType property.  It starts from the root element (one level down
/// from the XML document root) and is delimited by the "." character and by parentheses '(' and ')' for repeating elements.<p/>
/// The <var>pFormat</var> argument is an optional string comprised of a collection of single-character flag codes:<ul>
/// <li>1-9 : indent with this number of spaces (4 is the default with the 'i' format specifier)</li>
/// <li>a : attributes alphabetical</li>
/// <li>c : canonical ; ignores 'eintw'</li>
/// <li>e : close elements even when empty</li>
/// <li>f : full top element not just its contents</li>
/// <li>g : suppress output of empty elements</li>
/// <li>i : indent with 4 spaces unless 't' or 1-9</li>
/// <li>l : output schema information, schema uri and schema location, based on property stored in ..schemaLocation</li>
/// <li>n : newline (lf) after every text-free element</li>
/// <li>o : output unescaped - for instance don't change &lt; to &amp;lt;</li>
/// <li>p : suppress output of namespace prefixes</li>
/// <li>q : use double quotes to set off attribute values if possible</li>
/// <li>s : use stored indentation whitespace (ignores 'it1-9')</li>
/// <li>r : use stored returns / newlines (ignores 'nw')</li>
/// <li>t : indent with tab</li>
/// <li>u : declare prefixes as well as using them</li>
/// <li>w : Windows-style cr/lf newline after every text-free element</li>
/// <li>x : omit namespaces in output</li>
/// </ul>
Method GetValueAt(pPropertyPath As %String = "", pFormat As %String, Output pStatus As %Status, pDummy As %Boolean) As %String
{
  #;w:1 !,"<br>GetValueAt pPropertyPath="_pPropertyPath
	If $Case($E(pPropertyPath),"/":1,"*":(":/"=$E(pPropertyPath,2,3)),":":("/"=$E(pPropertyPath,2)),"":1,:0) {
		Set:""=pPropertyPath pPropertyPath="/1"
		Set tIgnoreNamespaces=("/"'=$E(pPropertyPath)&&$L(pPropertyPath))
		If $D(@..%PropCacheRef) {
			#; DOM  Get : first convert PropCache to DOMCache so they are in sync, then get from DOMCache looking through to stored DOM
			Set:tIgnoreNamespaces $E(pPropertyPath,1,$F(pPropertyPath,"/")-2)=""
			Set tDOMPath=pPropertyPath
			Set:tIgnoreNamespaces tNSContext("ign")=tIgnoreNamespaces
			Quit:..propGetDOMPathValue(.tDOMPath,.tPropPath,.tValue,.tDSubs,.tPSubs,.tSchemaRef,.tNSContext,.pStatus) tValue  Quit:$$$ISERR(pStatus) ""
			Set pStatus=..syncToDOMCache(0,tPropPath,tDOMPath,tDSubs,tPSubs,tSchemaRef,.tNSContext)  Quit:$$$ISERR(pStatus) ""
		} Else {
			Set:tIgnoreNamespaces $E(pPropertyPath,1,$F(pPropertyPath,"/")-2)=""
		}
		Set pStatus=..domGetValueAt(.tValue,pPropertyPath,.pFormat,tIgnoreNamespaces)
	} Else {
		Quit:$E(pPropertyPath,1,2)[":" $$$ERROR($$$EnsErrGeneral,"Can't get property path '"_pPropertyPath_"' because ignoring namespace prefixes is only possible for DOM paths")
		Set pStatus=..propGetValueAt(.tValue,pPropertyPath,.pFormat)
	}
	Quit tValue
}

Method GetValuesArray(pPropertyPath As %String, pFormat As %String, ByRef pArray As %String, Output pStatus As %Status, ByRef pLongArray As %String)
{
	Set pStatus=$$$OK  Kill pArray,pLongArray
	Do ..getValsArray(pPropertyPath,.pFormat,.pArray,.pStatus,.pLongArray)
}

/// Finds all values matching a SegPath:PropertyPath string that contains zero or more () implicit iterators
Method getValsArray(pPropertyPath As %String = "", pFormat As %String, ByRef pArray As %String, Output pStatus As %Status, ByRef pLongArray As %String) [ Internal ]
{
	Set $ZT="Trap"
	Set f=$F(pPropertyPath,"()")
	If 'f {
		Set tVal=..GetValueAt(pPropertyPath,.pFormat,.pStatus)
		If tVal '= "" {
			If $L(tVal) >= $$$MAXEDIARRAYSUBSCRIPT {
				Set pLongArray($I(pLongArray)) = tVal
			}
			Set pArray($E(tVal,1,$$$MAXEDIARRAYSUBSCRIPT))=""
		}
		Quit
	}
	Set tHead=$E(pPropertyPath,1,f-3)
	Set tTail=$E(pPropertyPath,f,*)

	Set i="" For { Set i=..GetNextIndex(tHead_"()",i,.pStatus)  Quit:i=""
		Set tNewPath=tHead_"("_(i)_")"_tTail
		Do ..getValsArray(tNewPath,.pFormat,.pArray,.tSC,.pLongArray)
		Set:$$$ISERR(tSC) pStatus=$$$ADDSC(pStatus,tSC)
	}
	Quit
Trap
	Set $ZT="", pStatus=$$$SystemError
	Quit
}

/// Finds all values matching a PropertyPath string that contains zero or more () implicit iterators
/// Supports PropertyPath values with (), (n) to choose a specific one of the given type, or just plain (same as path().
Method GetValues(pPropertyPath As %String = "", pFormat As %String, pValSepString As %String = "<>", Output pStatus As %Status) As %String
{
}

/// <p>Retrieve an XML virtual document constructed from the tree identified by <var>pPropertyPath</var>.
/// This path may be either a "DOM Path" or a "Property Path". The <class>Document</class> instance is created
/// using the supplied <var>pPropertyPath</var> as the root of the tree -- this is equivalent to calling the 
/// <method>GetValueAt</method>() with the "f" format flag specified.</p>
/// <p>A "DOM Path" is schema independent and starts from the document root with a '/' character and is delimited by the '/'
/// character at each level of descent, and by square brackets '[' and ']' for repeating elements.</p>
/// <p>A "Property Path" is based on a simplified projection of the XML schema applied to the current document 
/// by way of its <property>DocType</property> property. It starts from the root element (one level down
/// from the XML document root) and is delimited by the "." character and by parentheses '(' and ')' for repeating elements.</p>
/// The third <parameter>pFormat</parameter> defaults to f if not supplied. <br>
/// Pass in d in the pFormat string parameter to include namespace declarations from the top of source document.
/// The f format parameter will be added if not inluded in the parameter. 
Method GetSubDocumentAt(pPropertyPath As %String = "", Output pStatus As %Status, pFormat As %String = "f") As EnsLib.EDI.XML.Document
{
	Set pStatus = $$$OK
	Set tSubDocument = ""
	Try {
		#; Use "f" for the format to ensure that we build the XML from the actual path that was specified, as opposed to any child nodes
		#dim tFormat = pFormat
		If tFormat'["f" Set tFormat= tFormat_"f"
		Set tValue = ..GetValueAt(pPropertyPath,tFormat,.pStatus)
		If $$$ISERR(pStatus) {
			Quit
		}
		Set tSubDocument = ..ImportFromString(tValue,.pStatus)
		If $$$ISERR(pStatus) {
			Quit
		}
		If '$IsObject(tSubDocument) {
			Set pStatus = $$$ERROR($$$EnsErrGeneral,"Unable to create XML subdocument for path '" _ pPropertyPath _ "'")
			Quit
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	Quit tSubDocument
}

/// Insert the XML representation of <var>pSubDocument</var> into this document at the path specified by
/// <var>pPropertyPath</var>. <br>
/// The XML representation is the GetValueAt using "/1" as the property path except if the target Property Path
/// where the sub document is to be set is of type "any" then the XML representation of pSubDocument retrieved 
/// will be the full document including top element i.e. path "/"
Method SetSubDocumentAt(pSubDocument As EnsLib.EDI.XML.Document = "", pPropertyPath As %String = "") As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tPath = pPropertyPath
		Set tTargetIsanyElement = 0
		Set tNodeType = ""
		// Check for property path
		If $case($extract(pPropertyPath),
			"/":	0,
			"*":	(":/" '= $extract(pPropertyPath,2,3)),
			":":	("/" '= $extract(pPropertyPath,2)),
			"":		0,
					:1) {
			// Convert to DOM path using "set" as the nodes may not exist yet
			Set tStatus = ..propParsePath(pPropertyPath,"set",.tPath,,,,,.tNodeType)
			#; take first 4 chars since could be repeating
			Set tTargetIsanyElement = ($E(tNodeType,1,4)=">any")
			If $$$ISERR(tStatus) {
				Quit
			}
		}

		Set tRemove = 1
		Set tPosition = ..GetValueAt(tPath _ "/position()",,.tStatus)
		If $$$ISERR(tStatus) {
			// Ignore errors if the node doesn't exist yet
			Set tErrorText = $system.Status.GetErrorText(tStatus)
			If (tErrorText [ "Can't evaluate DOM path") && (tErrorText [ "this node is a 'unknown' node") {
				Set tStatus = $$$OK
				Set tRemove = 0
				// Use supplied path as position
				Set tPosition = $piece(tPath,"/",*)
			}
			Else {
				Quit
			}
		}
		Set tPosRoot = $piece(tPath,"/",1,*-1) _ "/"
		If tTargetIsanyElement && (tRemove) {
			Set tPosPath = tPosRoot _ "any"
		} Else {
			Set tPosPath = tPosRoot _ tPosition
		}
		If tRemove {
			// Clear content
			Set tStatus = ..SetValueAt("",tPosPath,"remove")
			If $$$ISERR(tStatus) {
				Quit
			}
			Set tStatus = ..SetValueAt("",tPosRoot _ $piece($piece(tPath,"/",*),"[")_"[~" _ tPosition_"]")
			If $$$ISERR(tStatus) {
				Quit
			}
		}
		Else {
			Set tStatus = ..SetValueAt("",tPosPath)
			If $$$ISERR(tStatus) {
				Quit
			}
		}
		If $IsObject(pSubDocument) {
			If tTargetIsanyElement {
				#; get the whole document
				Set tGetPath = "/"
			} Else {
				Set tGetPath = "/1"
			}
			Set tValue = pSubDocument.GetValueAt(tGetPath,"",.tStatus)
			If $$$ISERR(tStatus) {
				Quit
			}
			Set tStatus = ..SetValueAt(tValue,tPosPath)
			If $$$ISERR(tStatus) {
				Quit
			}
			/*	if not getting the full document we do not 
				include attributes in the top node so we need to add in.
			*/
			If 'tTargetIsanyElement {
				Set tAttribCount = pSubDocument.GetValueAt("/1/@[*]")
				For i=1:1:tAttribCount {
					Set tAttribPath = "/1/@[" _ i _ "]"
					Set tAttribName = pSubDocument.GetValueAt(tAttribPath _ "/name()")
					If (tAttribName '= "") {
						Set tAttribValue = pSubDocument.GetValueAt(tAttribPath,,.tStatus)
						If $$$ISERR(tStatus) {
							Quit
						}
						Set tStatus = ..SetValueAt(tAttribValue,tPosPath _ "/@" _ tAttribName)
						If $$$ISERR(tStatus) {
							Quit
						}
					}
				}
				If $$$ISERR(tStatus) {
					Quit
				}
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

Method SetValueAt(pValue As %String = "", pPropertyPath As %String = "", pAction As %String = "set", pKey As %String = "") As %Status
{
	If $Case($E(pPropertyPath),"/":1,"*":(":/"=$E(pPropertyPath,2,3)),":":("/"=$E(pPropertyPath,2)),"":1,:0) {
		Set:""=pPropertyPath pPropertyPath="/1"
		Quit:"/"'=$E(pPropertyPath) $$$ERROR($$$EnsErrGeneral,"Can't set to DOM path '"_pPropertyPath_"' because ignoring namespace prefixes is only supported for Get, not for Set")
		#; DOM  Set : first convert PropCache to DOMCache and kill PropCache, then set to DOMCache looking through to stored DOM
		If ""'=..DocType {
			Set tDOMPath=pPropertyPath
			Set tLastElem=$P(tDOMPath,"/",$L(tDOMPath)-1)
			Quit:(tLastElem="[$~]")||(tLastElem="[~$]") 
			Set tInsertPos=$F(tDOMPath,"[~")-2  ;Set:-2=tInsertPos tInsertPos=$F(tDOMPath,"[$~")-3 ;; Prodlog 105088 a final tag of $~ is legitimate since it says insert content at last node
			Set:tInsertPos>=0 $E(tDOMPath,tInsertPos,$L(tDOMPath))=""
			Quit:$E(tDOMPath,tInsertPos-1)="/" $$$ERROR($$$EnsErrGeneral,"Can't set to DOM path '"_pPropertyPath_"' because final element "_$e(pPropertyPath,tInsertPos,$L(pPropertyPath))_" lacks element designator")
			Do ..propGetDOMPathValue(.tDOMPath,.tPropPath,.tOldVal,.tDSubs,.tPSubs,.tSchemaRef,.tNSContext,.tSC)  Quit:$$$ISERR(tSC) tSC
			Set tSC=..syncToDOMCache(1,.tPropPath,tDOMPath,tDSubs,tPSubs,tSchemaRef,.tNSContext)  Quit:$$$ISERR(tSC) tSC
			#; If root element not named, get root element name from DOM sync result
			Set:""'=tDOMPath&&$Case($E(pPropertyPath,1,3), "/1":1, "/1/":1, :0) $P(pPropertyPath,"/",2)=$P(tDOMPath,"/",2)
		}
		Quit ..domSetValueAt(.pValue,pPropertyPath,.pAction,.pKey) //,tCSubs,tDSubs,tPSubs,.tNSContext)
	} elseif (pValue["<") {
		If ..isMixedContent(pValue) {
			/*	Carried out the quicker test first before more detailed check
				Mixed content and property path is *not* a DOM Path
			*/
			Quit:""=..DocType $$$ERROR($$$EnsErrGeneral,"Can't set to DOM path '"_pPropertyPath_"' because setting mixed content only supported for DOM Paths or for documents with a DocType")
			If ..ByPassPropCacheForMixed || ($zcvt(pAction,"L")'="set") {
				#; Go direct to DOM Cache
				Set tSC=..propParsePath(pPropertyPath,"set",.tDOMPath,.tCSubs,.tDSubs,.tPSubs,.tRef,.tType,.tIndex,.tValue,.tNSContext,.tDone)  Quit:$$$ISERR(tSC) tSC
				Set tSC=..initNSContext(tDSubs,.tNSContext)  Quit:$$$ISERR(tSC) tSC
				Set tSC=..syncToDOMCache(0,pPropertyPath,tDOMPath,tDSubs,tPSubs,tRef,.tNSContext)  Quit:$$$ISERR(tSC) tSC
				Quit ..domSetValueAt(.pValue,tDOMPath,.pAction,.pKey) //,tCSubs,tDSubs,tPSubs,.tNSContext)
			} Else {
				#; setting 'any' raw xml to a property path
				Set pAction = "setany"
			}
		} Else {
			#; Escape < s ready for the property set call below
			Set pValue = $Replace(pValue,"<","&lt;")
		}
	}
	Quit:$E(pPropertyPath,1,2)[":" $$$ERROR($$$EnsErrGeneral,"Can't set to property path '"_pPropertyPath_"' because ignoring namespace prefixes is only supported for get, not for set")
	Quit ..propSetValueAt(.pValue,pPropertyPath,.pAction,.pKey)
}

Method CopyValues(pSource As EnsLib.EDI.XML.Document, pSourcePath As %String, pTargetPath As %String, pAction As %String, pKey As %String, pEmptyFieldAsNull As %Boolean = 0, pIgnoreMissingSource As %Boolean = 0, pGenerateEmptySegments As %Boolean = 0) As %Status
{
	Set tSC=$$$OK
	Set tSourceWild=$F(pSourcePath,"()"), tTargetWild=$F(pTargetPath,"()")
	If tSourceWild||tTargetWild {
		Set tSourceHead=$E(pSourcePath,1,tSourceWild-3), tSourceTail=$E(pSourcePath,tSourceWild,*)
		Set tTargetHead=$E(pTargetPath,1,tTargetWild-3), tTargetTail=$E(pTargetPath,tTargetWild,*)
		If tSourceWild {
			If pEmptyFieldAsNull {
				If (tTargetWild)&&(tSourceHead [ ":")&&(tTargetHead [ ":") {
					Quit:(pSource.GetValueAt(tSourceHead)="") $$$OK
				}
			}
			Set i="" For { Set i=pSource.GetNextIndex(tSourceHead_"()",i,.tSC)  Quit:""=i
				Set tSourceNewPath=tSourceHead_"("_(i)_")"_tSourceTail
				Set tTargetNewPath=$S(tTargetWild:tTargetHead_"("_(i)_")"_tTargetTail,1:pTargetPath)
				Set tSC2=..CopyValues(pSource,tSourceNewPath,tTargetNewPath,pAction,pKey,pEmptyFieldAsNull,pIgnoreMissingSource)
				If $$$ISERR(tSC2)&&('pIgnoreMissingSource||(($$$StatusText(tSC2)'["No segment found")&&($$$StatusText(tSC2)'["is not an element, instead this node"))) {
					Set tSC=tSC2
					Quit
				}
			}
		} Else {
			Set i="" For { Set i=..GetNextIndex(tTargetHead_"()",i,.tSC)  Quit:""=i
				Set tTargetNewPath=tTargetHead_"("_(i)_")"_tTargetTail
				Set tSC=..CopyValues(pSource,pSourcePath,tTargetNewPath,pAction,pKey)  Quit:$$$ISERR(tSC)
			}
		}
	} Else {
		#; source and target not wild; no more iterating to be done; just set target subtree = source subtree (pFormat=u means declare namespace prefixes)
 ;w:1 !,"<br/>Get/Set("_pSourcePath_","_pTargetPath_","_pAction_","_pKey_")"
		#dim tSourceValue As %String = pSource.GetValueAt(pSourcePath,"u",.tSC2)
		If $$$ISERR(tSC2),(tSourceValue="") Quit tSC2
		Set tSC=..SetValueAt(tSourceValue,pTargetPath,pAction,pKey)  Set:$$$ISERR(tSC2) tSC=$$$ADDSC(tSC,tSC2)
	}
	Quit tSC
}

/// deprecated - never did anything
Method CommitNode(pPropertyPath As %String = "", pDeep As %Boolean = 0) As %Status [ Internal ]
{
	Quit $$$OK
}

Method SetMaxCalcCache(size As %Integer)
{
	Set i%%MaxCalcCache=size
}

/// Switch from keeping changes in memory to keeping them in storage.  Allows for unlimited changes to a document without running out of memory. This mode is automatically in effect when the object is created by loading from a stored Id
Method CommittedMode(pMode As %Boolean = 1) As %Status
{
	If pMode {
		Set tSC=..%Save()  Quit:$$$ISERR(tSC) tSC
		Set tId=..%Id()
		Set i%%DOMCacheRef=$Name($$$vaExtentGbl(tId,"domcache"))  Kill ..%PropCache
		Set i%%PropCacheRef=$Name($$$vaExtentGbl(tId,"propcache"))  Kill ..%DOMCache
		Set ..InCommittedMode = 1
	} Else {
		Set ..InCommittedMode = 0
		Set tId=..%Id()  Quit:""=tId $$$OK
		Quit:$$$vaIsLocalRef(..%DOMCacheRef)&&$$$vaIsLocalRef(..%PropCacheRef) $$$OK
		If '$$$vaIsLocalRef(..%DOMCacheRef)  Kill ..%DOMCache   Merge ..%DOMCache=$$$vaExtentGbl(tId,"domcache")    Set i%%DOMCacheRef="..%DOMCache"
		If '$$$vaIsLocalRef(..%PropCacheRef) Kill ..%PropCache  Merge ..%PropCache=$$$vaExtentGbl(tId,"propcache")  Set i%%PropCacheRef="..%PropCache"
	}
	Quit $$$OK
}

Method %OnConstructClone(object As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	#; note it is really only safe to clone objects that have already been saved. Otherwise if the original gets deleted the clone's content may go away.
	If ..%ContentRef'=..%storedContentRef && $D(@..%ContentRef) {
		// if the content ref refers to the other guy's temp global, reference-count it for both them and us
		$$$ASSERT($$$vaIsLocalRef(..%ContentRef))
		Set @$$$xmlUserNodeName(..%ContentRef)@("refs",$this)=""
		#;Remove possible refs pointer to oref in clone from source before updating
		Kill @$$$xmlUserNodeName(object.%ContentRef)@("refs")
		Set @$$$xmlUserNodeName(object.%ContentRef)@("refs",$this)=""
	}
	Merge:'$$$vaIsPropRef(..%DOMCacheRef) ..%DOMCache=@object.%DOMCacheRef
	Set i%%DOMCacheRef="..%DOMCache"

	Merge:'$$$vaIsPropRef(..%PropCacheRef) ..%PropCache=@object.%PropCacheRef
	Set i%%PropCacheRef="..%PropCache"
	Set i%%CalcCacheRef="..%CalcCache"
	Set i%%FindCacheRef="..%FindCache"
	$$$vaKillCalcCache ; abandon source object's cache if any

	Set i%IsMutable=1 ; mark our new self mutable
	Quit $$$OK
}

/// create an object based on id=initvalue but editable
Method %OnNew(initvalue As %RawString = {$$$NULLOREF}) As %Status [ Private ]
{
	// This method uses the whole stream, whereas the ImportFrom() methods start at the current stream position
	Set tSC=$$$OK, (tFilename,tString,tStream)=""
	If '$IsObject(initvalue) {
		Try {
			Set tString=$LG(initvalue,1), ..Format=$LG(initvalue,2), ..Source=$LG(initvalue,3)
		} Catch {
			If $E(initvalue,1,4) [ "<" {
				Set tString=initvalue, ..Source="String"
			} Else {
				Set tFilename=initvalue, ..Source=tFilename
			}
		}
	} ElseIf initvalue.%Extends("%IO.I.Stream") {
		Set ..Source=initvalue.Name
		Do initvalue.Rewind()
		Set tStream=##class(%Library.GlobalCharacterStream).%New()
		Do ##class(Ens.Util.XML.Reader).ChangeXMLStreamEncoding(initvalue,"",tStream,.tSC)
	} ElseIf initvalue.%Extends("%Stream.Object") {
		Set tStream=initvalue
		Do tStream.Rewind()
		If tStream.%Extends("%Library.FileStreamAdaptor") || tStream.%Extends("%Stream.FileBinary") {
			Set ..Source=tStream.Filename
		}
		Set:""=..Source&&tStream.%Extends("%Library.AbstractStream") ..Source=$G(tStream.Attributes("Source"),$G(tStream.Attributes("Name"),$G(tStream.Attributes("Filename"))))
		Set tStream=##class(Ens.Util.XML.Reader).ChangeXMLStreamEncoding(tStream,"",,.tSC)
	} ElseIf initvalue.%Extends("%XML.Document") {
		Set r%%XMLDoc=initvalue, initvalue=$$$NULLOREF, tString=""
	} Else {
		Quit $$$ERROR($$$EnsErrGeneral,"Can't initialize XML document from non-stream object "_initvalue)  Quit
	}
	If $$$ISOK(tSC) && $S($IsObject(initvalue):initvalue.Size, 1:$L(tString)||$L(tFilename)) {
		Set:'$IsObject(..%XMLDoc) r%%XMLDoc=##class(%XML.Document).%New()
		Set ..%XMLDoc.KeepWhitespace=0
		Set tEntityResolver = $$$NULLOREF
		Set tSAXFlags = $$$SAXFULLDEFAULT
		Set tSAXSchemaSpec = ""
		If $IsObject(initvalue) {
			Set tSC=##class(%XML.SAX.Parser).ParseStream(tStream,..%XMLDoc,tEntityResolver,tSAXFlags,,tSAXSchemaSpec)
		} ElseIf ""=tFilename {
			Set tSC=##class(%XML.SAX.Parser).ParseString(tString,..%XMLDoc,tEntityResolver,tSAXFlags,,tSAXSchemaSpec)
		} Else {
			Set tSC=##class(%XML.SAX.Parser).ParseFile(tFilename,..%XMLDoc,tEntityResolver,tSAXFlags,,tSAXSchemaSpec)
		}
	}
	If $$$ISOK(tSC) && $IsObject(..%XMLDoc) {
		$$$ASSERT(""'=..%XMLDoc.DocumentId)
		Set i%%ContentRef=..%XMLDoc.DocumentId
		Set @$$$xmlUserNodeName(..%ContentRef)@("refs",$this)=""
	} Else {
		Set i%%ContentRef="%null(0)"
	}
	Set i%%DOMCacheRef="..%DOMCache"
	Set i%%PropCacheRef="..%PropCache"
	Set i%%CalcCacheRef="..%CalcCache"
	Set i%%FindCacheRef="..%FindCache"
	Set i%%ParseCache=$i(^||ISC.XML.VDOC.ParseCache)
	Quit tSC
}

Method %OnClose() As %Status [ Private ]
{
	Set r%%XMLDoc=$$$NULLOREF
	If ..%ContentRef'=..%storedContentRef {
		Kill @$$$xmlUserNodeName(..%ContentRef)@("refs",$this)
		Kill:'$D(@$$$xmlUserNodeName(..%ContentRef)@("refs")) @..%ContentRef
	}
	If i%%PurgeIndex {
	   Kill ^||%XML.VDoc.CalcCache(i%%PurgeIndex)
	}
	If i%%ParseCache {
		Kill ^||ISC.XML.VDOC.ParseCache(i%%ParseCache)
	}
	Quit $$$OK
}

Method %OnOpen() As %Status [ Private ]
{
	Set tId=..%Id()
	Do ..DocTypeSet(i%DocType)
	Set i%%DOMCacheRef=$Name($$$vaExtentGbl(tId,"domcache"))
	Set i%%PropCacheRef=$Name($$$vaExtentGbl(tId,"propcache"))
	#; No automatic merge of arrays here - allow cheap instantiation for routing etc
	//	Merge ..%DOMCache=@..%DOMCacheRef    Set i%%DOMCacheRef="..%DOMCache"
	//	Merge ..%PropCache=@..%PropCacheRef  Set i%%PropCacheRef="..%PropCache"
	Set i%%ContentRef=..%storedContentRef
	Set i%%CalcCacheRef="..%CalcCache"
	Set i%%FindCacheRef="..%FindCache"
	Set updateFlag=1
	Set:""=..%ContentRef i%%ContentRef="%null(0)",updateFlag=0
	if updateFlag=1 Set:($g(@i%%ContentRef@(0,"e"))'=1) updateFlag=0
	if (updateFlag) {
		do ##class(EnsLib.EDI.XML.DOMUpgrader).UpgradeDOM(i%%ContentRef,i%%DOMCacheRef,.tXMLDocument)
		if ($g(tXMLDocument)'="") {
			kill @i%%ContentRef
			merge @i%%ContentRef=@tXMLDocument.DocumentId
		}
	}
	Set i%%ParseCache=$i(^||ISC.XML.VDOC.ParseCache)
	Quit $$$OK
}

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	If ""=..%storedContentRef&&$$$vaIsLocalRef(..%ContentRef)&&$D(@..%ContentRef) {
		#; Store the name of the storage node
		Set i%%storedContentRef=$Name($$$vaContentGbl($$$JobKey,$I($$$vaContentGbl($$$JobKey))))
	}
	Quit $$$OK
}

/// %Save() calls this method internally.
/// As a result %Save() saves a copy of the cache arrays to storage but keeps them in memory as well for further changes.
Method %OnAfterSave(insert As %Boolean) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim tNSContext, tId As %String
	#dim e As %Exception.AbstractException
	
	Try {
		If $D(@..%PropCacheRef) {
			Set tSC=..initNSContext(","">/"",1",.tNSContext)
			If $$$ISERR(tSC) Quit
			Set tSC=..syncToDOMCache(1,"",,,,,.tNSContext)
			If $$$ISERR(tSC) Quit
		}
		Set tId=..%Id()
		If ..%DOMCacheRef'=$Name($$$vaExtentGbl(tId,"domcache")) Kill $$$vaExtentGbl(tId,"domcache")  Merge $$$vaExtentGbl(tId,"domcache")=@..%DOMCacheRef
		If ..%PropCacheRef'=$Name($$$vaExtentGbl(tId,"propcache")) Kill $$$vaExtentGbl(tId,"propcache")  Merge $$$vaExtentGbl(tId,"propcache")=@..%PropCacheRef
		If ""'=..%storedContentRef&&$$$vaIsLocalRef(..%ContentRef) {
			#; Store to the named storage node
			Merge @..%storedContentRef=@..%ContentRef
			Set @$$$xmlUserNodeName(..%storedContentRef)@("refs",tId)="" ; claim storage with our Id
			Kill @$$$xmlUserNodeName(..%storedContentRef)@("refs",$this) ; remove oref pointer from stored data that was included with merge
		}
	} Catch e {Set tSC=e.AsStatus()}
	Quit tSC
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private ]
{
	New %tID, %tCRef  Set %tID=$$$oidPrimary(oid)
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	&sql(Select %storedContentRef Into :%tCRef From EnsLib_EDI_XML.Document Where Id=:%tID)
	If 'SQLCODE && (""'=%tCRef) {
		Kill @$$$xmlUserNodeName(%tCRef)@("refs",%tID)  Kill:'$D(@$$$xmlUserNodeName(%tCRef)@("refs")) @$Name(@(%tCRef))
	}

	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	New %tID,index,segid, %tCRef  Set %tID={%%ID}, %tCRef={%storedContentRef}
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	If (""'=%tCRef) {
		Kill @$$$xmlUserNodeName(%tCRef)@("refs",%tID)  Kill:'$D(@$$$xmlUserNodeName(%tCRef)@("refs")) @$Name(@(%tCRef))
	}
	Quit
}

/// Deprecated - see CommittedMode()
Method UseProcessContent() [ Internal ]
{
	Quit:""=..%ContentRef||'$D(@..%ContentRef) $$$OK
	If '$$$vaIsLocalRef(..%ContentRef) {
		$$$ASSERT(..%ContentRef=..%storedContentRef)
		Set i%%ContentRef="^||tmpVdocXML("_$I(^||tmpVdocXML)_")"
		Merge @..%ContentRef=@..%storedContentRef
	}
	Quit $$$OK
}

/// Deprecated - see CommittedMode()
Method UseGlobalContent() As %Status [ Internal ]
{
	Quit:""=..%ContentRef||'$D(@..%ContentRef) $$$OK
	If ""=..%storedContentRef Set tSC=..%Save()  Quit:$$$ISERR(tSC) tSC
	$$$ASSERT(""'=..%storedContentRef)
	If $$$vaIsLocalRef(..%ContentRef) {
		Kill @$$$xmlUserNodeName(..%ContentRef)@("refs",$this)
		If '$D(@$$$xmlUserNodeName(..%ContentRef)@("refs")) Set r%%XMLDoc=$$$NULLOREF  Kill @..%ContentRef
		Set i%%ContentRef=..%storedContentRef
	}
	Quit $$$OK
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pDummy As %Boolean = 0) As %Status
{
	If 0=pDaysToKeep Do ..KillGlobals(.pDeletedCount,1,0)  Quit $$$OK

	New %tDoNotDeleteDate,%tID,%tTime  Set %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	Set SQLCODE=0, pDeletedCount=0
	&sql(Declare C1 Cursor for
		Select ID,TimeCreated Into :%tID,:%tTime From EnsLib_EDI_XML.Document Order By ID)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		If $$$timeCmp(%tTime,%tDoNotDeleteDate)<0 {
			&sql(Delete From EnsLib_EDI_XML.Document Where ID=:%tID)
			Set pDeletedCount=pDeletedCount+%ROWCOUNT
		}
	} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	Quit:SQLCODE&&(SQLCODE'=100) $$$ERROR($$$EnsErrGeneral,"Purge error at ID "_%tID_"; SQLCODE = "_SQLCODE)
	Quit $$$OK
}

ClassMethod KillGlobals(Output pDeletedCount, pKeepExtentCount = 0, pDisplayLog = 1)
{
	&sql(SELECT COUNT(*) INTO :pDeletedCount From EnsLib_EDI_XML.Document)
	Set tExtentCount=$G($$$vaExtentGbl)
	Write:pDisplayLog !,"Killing ",$classname()," extent ("_pDeletedCount_"/"_tExtentCount_")"
	Do ..%KillExtent()
	Set:pKeepExtentCount $$$vaExtentGbl=tExtentCount

	Do ##class(EnsLib.EDI.XML.SearchTable).%KillExtent()

	Set globals($Name($$$vaContentGbl))=""

	Set global="" For { Set global=$O(globals(global))  Quit:""=global
		Kill tExtentCount  Set:pKeepExtentCount tExtentCount=$S($D(@global)#2:@global,1:$$topNodesSum(global))
		Write:pDisplayLog !,"Killing ",global,"("_$G(tExtentCount)_")"
		Kill @global
		If $D(tExtentCount) Set @global=tExtentCount
	}
	Quit
topNodesSum(global)
	Set tSum=0,cnt=0,sub="" For { Set sub=$O(@global@(sub),1,cnt)  Quit:""=sub  Set tSum=tSum+cnt }
	Quit tSum
}

ClassMethod TotalCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From EnsLib_EDI_XML.Document)
	Quit tCount
}

ClassMethod ImportFromFile(pFilename As %String, pDocNum As %Integer = 1, Output pStatus As %Status, pConfigItem As %String) As EnsLib.EDI.XML.Document
{
	Set pStatus=$$$OK
	Kill %objlasterror
	Set tDoc=..%New(pFilename)
	Set:'$IsObject(tDoc) pStatus=$$$ERROR($$$EnsErrGeneral,"Failed to create document from file '"_pFilename_"': "_$$$StatusDisplayString(%objlasterror))
	Quit tDoc
}

ClassMethod ImportFromDevice(Output pStatus As %Status, ByRef pConfigItem As %String) As EnsLib.EDI.XML.Document
{
	Set tDeviceStream=##class(%IO.DeviceStream).AttachNew(,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ..ImportFromIOStream(tDeviceStream,.pStatus,.pConfigItem)
}

ClassMethod ImportFromLibraryStream(pLibStream As %Stream.Object, Output pStatus As %Status, ByRef pConfigItem As %String) As EnsLib.EDI.XML.Document
{
	Set pStatus=$$$OK
	If pLibStream.%Extends("%Library.FileStreamAdaptor") || pLibStream.%Extends("%Stream.FileBinary") {
		Set tSource=pLibStream.Filename
	} ElseIf pLibStream.%Extends("%Library.AbstractStream") {
		Set tSource=$G(pLibStream.Attributes("Source"),$G(pLibStream.Attributes("Name"),$G(pLibStream.Attributes("Filename"))))
	} Else {
		Set tSource=""
	}
	If pLibStream.AtEnd Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't create new document from stream '"_tSource_"' at end")  Quit $$$NULLOREF
	Set tXMLDoc=##class(%XML.Document).%New()
	Set tXMLDoc.KeepWhitespace=0
	Set tEntityResolver = $$$NULLOREF
	Set tSAXFlags = $$$SAXFULLDEFAULT
	Set tSAXSchemaSpec = ""
	Set pStatus=##class(%XML.SAX.Parser).ParseStream(pLibStream,tXMLDoc,tEntityResolver,tSAXFlags,,tSAXSchemaSpec)  Quit:$$$ISERR(pStatus) $$$NULLOREF
	Kill %objlasterror
	Set tDoc=..%New(tXMLDoc)
	If '$IsObject(tDoc) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Could not create new document"_$S(""=$G(%objlasterror):"",1:" "_$$$StatusDisplayString(%objlasterror)))  Quit $$$NULLOREF
	Set tDoc.Source=tSource
	Quit tDoc
}

ClassMethod ImportFromString(pString As %String, Output pStatus As %Status, ByRef pConfigItem As %String) As EnsLib.EDI.XML.Document
{
	Set pStatus=$$$OK
	Kill %objlasterror
	Set tDoc=..%New(pString)
	Set:'$IsObject(tDoc) pStatus=$$$ERROR($$$EnsErrGeneral,"Failed to create document from string: "_$$$StatusDisplayString(%objlasterror))
	Quit tDoc
}

ClassMethod ImportFromIOStream(pIOStream As %IO.I.CharacterStream, Output pStatus As %Status = {$$$OK}, ByRef pConfigItem As %String = "") As EnsLib.EDI.XML.Document
{
	Set tLibStream=##class(%IO.LibraryStream).%New(pIOStream)
	Quit ..ImportFromLibraryStream(tLibStream,.pStatus,.pConfigItem)
}

Method OutputToFile(pFilename As %String, pOverwrite As %Boolean, pFormat As %String) As %Status
{
	Set tIOStream=##Class(%IO.FileStream).%New()
	Do tIOStream.Open(pFilename,$S($G(pOverwrite):"NEW",1:"AEW"),5,,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ..OutputToIOStream(tIOStream, .pFormat)
}

Method OutputToDevice(pFormat As %String) As %Status
{
	Set tDeviceStream=##class(%IO.DeviceStream).AttachNew(,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ..OutputToIOStream(tDeviceStream, .pFormat)
}

Method OutputToLibraryStream(pLibStream As %Stream.Object, pFormat As %String) As %Status
{
	Set tIOStream=$S(pLibStream.%Extends("%IO.I.CharacterStream"):pLibStream, 1:##Class(%IO.MetaCharacterStream).%New(pLibStream))
	Quit ..OutputToIOStream(tIOStream, .pFormat)
}

Method OutputToString(pFormat As %String, Output pStatus As %Status) As %String
{
	Set tIOStream=##Class(%IO.StringStream).%New()
	If $Get(pFormat) [ "C(!" {
		Set tCharEncoding = "binary"
	} Else {
		Set tCharEncoding = "unicode"
	}
	Set tIOStream.CharEncoding=tCharEncoding ; not "Native"
	Set pStatus = ..OutputToIOStream(tIOStream, .pFormat)
	Do tIOStream.Rewind()
	Set tIOStream.CharEncoding=tCharEncoding ; show the translated content
	Quit tIOStream.Read()
}

/// If pFormat contains a string of the form: C(encoding) then an XML charset declaration line will be output.
/// If encoding is empty the IOStream's encoding will be used.
/// If encoding starts with ! then the IOStream's encoding will be set to the given encoding.
Method OutputToIOStream(pIOStream As %IO.I.CharacterStream, pFormat As %String, pFlush As %Boolean = 1) As %Status
{
	Quit:'$$$IsdefObject(pIOStream) $$$ERROR($$$EnsErrGeneral,"No Stream object provided")
	Set tFormat=$G(pFormat,..Format)
	#; Apply the C(e) part of pFormat
	Set cp=$F(tFormat,"C(") If cp {
		Set ce=$F(tFormat,")",cp)
		If ce {
			Set tCharEncoding=$ZStrip($E(tFormat,cp,ce-2),"<>WC"), $E(tFormat,cp-2,ce-1)=""
			Set tForce=("!"=$E(tCharEncoding))  Set:tForce $E(tCharEncoding,1)=""
			If ""=tCharEncoding { Set tCharEncoding=pIOStream.CharEncoding }
			ElseIf tForce { Set pIOStream.CharEncoding=tCharEncoding }
			Set:$Case($ZCVT(tCharEncoding,"L"),"":1,"native":1,"local":1,"default":1,:"@"=$E(tCharEncoding)) tCharEncoding=$S(pIOStream.%Extends("%IO.I.TranslationDevice"):##class(%IO.I.TranslationDevice).GetTableCharEncoding(pIOStream.TranslationTable),1:"")
			If tCharEncoding'="" {
				// Will be writing file character streams RAW since we will do the translation in %IO.MetaCharacterStream
				If pIOStream.%Extends("%Library.FileCharacterStream") ||
				   pIOStream.%Extends("%Stream.FileCharacter") {
					Set translateTable=pIOStream.TranslateTable
					Set pIOStream.TranslateTable="RAW"
				}
				Do pIOStream.Write("<?xml version=""1.0"" encoding="""_tCharEncoding_""" ?>"_$S(tFormat["w":$C(13,10), tFormat["n":$C(10), tFormat["r":$C(10), tFormat["c":$C(10), 1:""))
			}
		}
	}
	If $D(@..%PropCacheRef) {
		Set tSC=..initNSContext(","">/"",1",.tNSContext)  Quit:$$$ISERR(tSC) tSC
		Set tSC=..syncToDOMCache(0,"",,,,,.tNSContext)  Quit:$$$ISERR(tSC) tSC
	}
	Set tSC=..domGetValueAt(.pIOStream,"/",tFormat)
	If pFlush&&pIOStream.%Extends("%IO.SocketCommon") Do pIOStream.Flush(.tSC1)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
	// Restore file character stream translate table
	If $data(translateTable) Set pIOStream.TranslateTable=translateTable
	Quit tSC
}

/// Display Document as HTML
Method OutputHTMLZen() As %Status
{
	Set tXMLStream=##class(%Stream.TmpCharacter).%New()
	Set tSC=..OutputToLibraryStream(tXMLStream,"wt")
	If $$$ISOK(tSC),$IsObject(tXMLStream) {
		Do tXMLStream.Rewind()
		Write "<pre style=""white-space:pre-wrap"">"
		Set tSC=$$WriteEscapedCharStream^%occXMLInternal(tXMLStream,"HTML")
		Write "</pre>"
	}
	Quit tSC
}

/// No DTD available for XML VDoc
ClassMethod XMLDTD(top As %String, format As %String, input As %Boolean, ByRef dtdlist) As %Status [ Internal, ServerOnly = 1 ]
{
	Quit $$$ERROR($$$EnsErrGeneral,"No DTD available for XML VDoc class '"_$classname()_"'")
}

/// Suppress normal XML meta data
Parameter XMLNOMETADATA [ Internal ] = 1;

/// Suppress normal XML meta data<p>
ClassMethod %XMLGenerate() [ Internal, ServerOnly = 1 ]
{
}

/// Export XML VDoc data
Method XMLExportInternal() As %Status [ Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	New myFormat,myIndent
	Set:'($D(top)#2) top=..Name
	
	// Convert XMLExport/%XML.Writer style indent code to GetValueAt format code.
	If indentFlag {
		If indentChars=$c(9) {
			Set myFormat="t"
		} Else {
			Set myIndent=$translate(indentChars," ","")
			If (myIndent'="") || ($length(indentChars)>9) {
				Set myFormat="i"
			} Else {
				Set myFormat=$length(indentChars)
			}
		}
	} Else {
		Set myFormat=""
	}
	
	// Add the XML VDoc object to the oupput
	If $$$XMLIsWrite {
		// Normal XMLExport using write command
		Write currentIndent
		Set sc=..OutputToDevice("w"_myFormat_indentChars)
	} Else {
		// XMLExport as used within SOAP
		Set stream = ##class(%Stream.TmpCharacter).%New()
		Set sc=..OutputToLibraryStream(stream,"w"_myFormat_indentChars)
		If $$$ISOK(sc) {
			$$$XMLSetBuffer(currentIndent)
			$$$XMLWrite
			$$$XMLUseNext
			$$$XMLSetStream(stream)
		}
	}
	Quit sc
}

/// No XMLImport available for XML VDoc
Method XMLImportInternal() As %Status [ Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	Quit $$$ERROR($$$EnsErrGeneral,"No XMLImport available for XML VDoc class '"_$classname()_"'")
}

/// No XMLSchema available for XML VDoc
ClassMethod XMLSchema(top As %String, format As %String, namespacePrefix As %String = "", input As %Boolean, refOnly As %Boolean, ByRef schema) As %Status [ Internal, ServerOnly = 1 ]
{
	Quit $$$ERROR($$$EnsErrGeneral,"No XMLSchema available for XML VDoc class '"_$classname()_"'")
}

Method DumpMaps(pWhich As %String = "") As %Status
{
	Set DocType=..DocType w ! zw DocType
	w:""'=DocType !,"DocTypeCategory, DocTypeName = "_..DocTypeCategory_", "_..DocTypeName
	If ""'=..DocTypeCategory&&(""'=..DocTypeName) {
		If '$L(pWhich)||(pWhich["m") {
			w !,"Schema top level metadata:",!
			zw $$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"meta")
		}
		If '$L(pWhich)||(pWhich["a") {
			w !,"Schema top level properties array:",!
			zw $$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"array")
		}
	}
	If '$L(pWhich)||(pWhich["c") w ! Merge Content=@..%ContentRef w ! zw Content k Content
	If '$L(pWhich)||(pWhich["d") w ! Merge DOMCache=@..%DOMCacheRef w ! zw DOMCache k DOMCache
	If '$L(pWhich)||(pWhich["i") w ! Merge CalcCache=@..%CalcCacheRef w ! zw CalcCache k CalcCache
	If '$L(pWhich)||(pWhich["i") w ! Merge FindCache=@..%FindCacheRef w ! zw FindCache k FindCache
	If '$L(pWhich)||(pWhich["p") w ! Merge PropCache=@..%PropCacheRef w ! zw PropCache k PropCache
	If '$L(pWhich)||(pWhich["n") w ! Merge nsMap=..namespaceMapping w ! zw nsMap k nsMap
	Quit $$$OK
}

ClassMethod GetContentArray(Output pContents, pMode As %String, pDocType As %String, pLevel As %Integer, pIncludeBase As %Boolean, pElem, pNodeAddr) As %Status [ CodeMode = expression ]
{
##class(EnsLib.EDI.XML.Schema).GetContentArray(.pContents,.pMode,.pDocType,.pLevel,.pIncludeBase,,.pNodeAddr)
}

/// Returns a list of available DocTypes for this document class. <br/>
/// The DocType is returned as the first column in the result set. <br/>
/// The <var>Category</var> parameter can be used to restrict the list. <br/>
/// If <var>Category</var> is: <br/>
///  0 - return only DocTypes in standard categories <br/>
///  + - return only DocTypes in user-defined categories <br/>
///  empty - return DocTypes from all categories <br/>
///  a category name - return only DocTypes in the named category <br/>
///  a partial name suffixed with '%' - return only DocTypes in categories matching the partial category name <br/>
///  other - return nothing <br/>
/// If <var>IncludeBase</var> is: <br/>
///  0 - return only DocTypes defined in the current schema category itself <br/>
///  1 - return all DocTypes in the current schema category's base category in addition to those defined in the current category itself <br/>
Query EnumerateDocTypes(Category As %String = "", IncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "Type:%String")
{
}

ClassMethod EnumerateDocTypesExecute(ByRef qHandle As %Binary, Category As %String, IncludeBase As %Boolean) As %Status [ CodeMode = expression ]
{
##class(EnsLib.EDI.XML.Schema).DocStructuresExecute(.qHandle,.Category,.IncludeBase)
}

ClassMethod EnumerateDocTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ PlaceAfter = EnumerateDocTypesExecute ]
{
	Set tSC=##class(EnsLib.EDI.XML.Schema).DocStructuresFetch(.qHandle,.Row,.AtEnd)
	Set:""'=$G(Row) Row=$LB($LG(Row))
	Quit tSC
}

ClassMethod EnumerateDocTypesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateDocTypesExecute ]
{
##class(EnsLib.EDI.XML.Schema).DocStructuresClose(.qHandle)
}

/// Returns a list of document type schema categories for the document class.<br>
/// The Standard parameter can be used to restrict the list.<br>
/// If Standard is:
///  0 - return only standard categories
///  + - return only user-defined categories
///  empty - return all categories
///  a category name - return only the named category
///  a partial name suffixed with '%' - return only categories matching the partial category name
///  other - return nothing
Query EnumerateTypeCategories(Standard As %String = "") As %Query(CONTAINID = 0, ROWSPEC = "Category:%String,Description:%String,IsStandard:%Boolean,Base:%String")
{
}

ClassMethod EnumerateTypeCategoriesExecute(ByRef qHandle As %Binary, Standard As %String = "") As %Status [ CodeMode = expression ]
{
##class(EnsLib.EDI.XML.Schema).TypeCategoriesExecute(.qHandle, Standard)
}

ClassMethod EnumerateTypeCategoriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ PlaceAfter = EnumerateTypeCategoriesExecute ]
{
	Set tSC=##class(EnsLib.EDI.XML.Schema).TypeCategoriesFetch(.qHandle,.Row,.AtEnd)
	Quit tSC
}

ClassMethod EnumerateTypeCategoriesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateTypeCategoriesExecute ]
{
##class(EnsLib.EDI.XML.Schema).TypeCategoriesClose(.qHandle)
}

/// Returns an array of links to manager pages for this type of VDoc; item 0 is the family description
ClassMethod GetManagerLinks(Output pColumns) As %Boolean [ Internal ]
{
	/* Do not show these options - they are not fully working in CSP and are confusing to QD - see new Zen interface
	Set iCol=0
	Set pColumns(iCol,"page")="http://www.w3c.org/XML/"
	Set pColumns(iCol,"name")=$$$Text("XML document messaging")
	Set pColumns(iCol,"desc")=$$$Text("eXtensible Markup Language documents")

	Set iCol=iCol+1
	Set pColumns(iCol,"page")=##class(%CSP.Page).Link("XML/XMLSchemaMain.csp")
	Set pColumns(iCol,"name")=$$$Text("Schema Structures")
	Set pColumns(iCol,"desc")=$$$Text("View schema definitions for XML document types")

	Set iCol=iCol+1
	Set pColumns(iCol,"page")=##class(%CSP.Page).Link("EDIDocumentView.csp?NAME="_$ZCVT("X12 Document","O","URL")_"&CLASS=EnsLib.EDI.XML.Document")
	Set pColumns(iCol,"name")=$$$Text("Document Viewer")
	Set pColumns(iCol,"desc")=$$$Text("View XML documents from a variety of sources and test them with various DocType schema definitions and Data Transformations")
	*/
	Quit 1
}

/// Validates the XML VDoc against the schema that is referenced in its DocType property.
/// If the schema URL specifies https then you must provide an SSL configuration name in <var>pSSLConfig</var> that will work with the URL target server.
Method Validate(pValidationSpec As %String = "", pSSLConfig As %String = "", pHttpTimeout As %Numeric = "") As %Status
{
	If ..DocType="" {
		Set pSchema=""
	} Else {
		Set systemId=$G($$$vaSchemaGbl($P(..DocType,":"),"src",1))
		// We are using our global schema to set the schemaLocation or noNamespaceSchemaLocation for validation
		// count the namespaces.  If only one,
		// then in ..OutputToIOStream we are using xsi:noNamespaceSchemaLocation
		Set namespaceCount=0
		Set i="" For { Set i=$O($$$vaSchemaGbl($P(..DocType,":"),"ns","list",i))  Quit:i=""
			Set namespaceCount=namespaceCount+1
		}
		If namespaceCount > 1 {
			Set uri=$G($$$vaSchemaGbl($P(..DocType,":"),"ns","targ"))
		} Else {
			Set uri=""
		}
		If systemId'="",uri'="" {
			Set pSchema=uri_" "_systemId
		} Else {
			Set pSchema=systemId
		}
	}
	Set tStream=##class(%Stream.GlobalCharacter).%New()
	Set tStream1=##class(%IO.MetaCharacterStream).%New(tStream)
	Set tSC=..OutputToIOStream(.tStream1,$$$OUTPUTSCHEMAINFO) Quit:$$$ISERR(tSC) tSC
	If pSchema'="" {
		Set ..%EntityResolverSchemaDir=##class(%File).GetDirectory($replace(systemId,"%20"," ")), ..%EntityResolverHttpTimeout=pHttpTimeout, ..%EntityResolverSSLConfigName=pSSLConfig
		Set tRetVal=##class(Ens.Util.XML.Validator).ValidateStream(tStream,$this,pSchema)
	} Else {
		// search for schema in content
		Set schemaPresent=0
		For i=1:1:..GetValueAt("/1/@.*") {
			Set propName=..GetValueAt("/1/@["_i_"]/local-name()")
			Set uri=..GetValueAt("/1/@["_i_"]/namespace-uri()")
			If uri="http://www.w3.org/2001/XMLSchema-instance" {
				If propName="schemaLocation" {
					Set schemaPresent = 1
					Set systemId=$P(..GetValueAt("/1/@["_i_"]")," ",2)
					Quit
				} ElseIf propName="noNamespaceSchemaLocation" {
					Set schemaPresent = 1
					Set systemId=..GetValueAt("/1/@["_i_"]")
					Quit
				}
			}
		}
		If schemaPresent {
			Set ..%EntityResolverSchemaDir=##class(%File).GetDirectory($replace(systemId,"%20"," ")), ..%EntityResolverHttpTimeout=pHttpTimeout, ..%EntityResolverSSLConfigName=pSSLConfig
			Set tRetVal=##class(Ens.Util.XML.Validator).ValidateStream(tStream,$this,pSchema)
		} Else {
			Set tRetVal=$$$ERROR($$$EnsErrGeneral,"Validation failed because no schema is present in either the DocType or the document content")
		}
	}
	Quit tRetVal
}

Method resolveEntity(publicID As %Library.String, systemID As %Library.String) As %Library.Integer [ Internal ]
{
	Set $ZT="Trap",tSC=$$$OK,tStream=$$$NULLOREF
	do {
		#; Parse the Id into its components
		Set tId=$S(""'=systemID:systemID,1:publicID)
		Do ##Class(%Net.URLParser).Parse(tId,.tComponents)

		#; Extract the scheme
		Set tScheme=$ZConvert($Get(tComponents("scheme")),"L")
 
 		If tScheme="http"||(tScheme="https") {
			#; Do an http request and assign the response stream
			Set tHttpRequest=##class(%Net.HttpRequest).%New() 
			If '$IsObject(tHttpRequest) Set tSC=%objlasterror Quit

			#; Need to set raw mode to preserve character set
			Set tHttpRequest.ReadRawMode=1

			#; If https, copy across the SSLConfiguration
			If tScheme="https" {
				Set tHttpRequest.Https=1
				Set tHttpRequest.SSLConfiguration=..%EntityResolverSSLConfigName
			}
			Set:""'=..%EntityResolverHttpTimeout tHttpRequest.Timeout=..%EntityResolverHttpTimeout
			Set tHttpRequest.Server=tComponents("host")
			If $Get(tComponents("port"))]"" {
				Set tHttpRequest.Port=tComponents("port")
			}
			Set tRequest=tComponents("path")
			If ($Get(tComponents("path"))'="") {
				Set tRequest=tRequest_"?"_tComponents("query")
			}
			Set tSC=tHttpRequest.Get(tRequest)
			If '$$$ISERR(tSC) Set tStream=tHttpRequest.HttpResponse.Data
		} ElseIf (tScheme="file") {
			#; Open the file and assign the binary stream
			Set tFile=##class(%FileBinaryStream).%New()
			If '$IsObject(tFile) Set tSC=%objlasterror Quit
			
			Set tSC=tFile.LinkToFile(tComponents("path"))
			Set:'$$$ISERR(tSC) tStream=tFile
		} Else {
			#; Assume the Id is a file name, open and assign the binary stream
			Set tFile=##class(%FileBinaryStream).%New()
			If '$IsObject(tFile) Set tSC=%objlasterror Quit
			Set tId=##class(%File).NormalizeFilename($replace(tId,"%20"," "),..%EntityResolverSchemaDir)
			Set tSC=tFile.LinkToFile(tId) 
			Set:'$$$ISERR(tSC) tStream=tFile
		}
	} while 0
Exit
	If tStream'=$$$NULLOREF && $$$ISOK(tSC) {
		#; Create a Stream Adapter
		Set tStream=##class(%XML.SAX.StreamAdapter).%New(tStream)
		If '$IsObject(tStream) Set tSC=%objlasterror
	}
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	Quit tStream
Trap
	Set $ZT="",tStream=$$$NULLOREF,tSC=$$$SystemError
	Goto Exit
}

/// Internal method to do a few checks to see if mixed content rather than just rely on presence of < 
/// Used when setting mixed content using Property path syntax and not DOM syntax.
/// Does not check if valid mixed content but aims to help identify < that code will automatically escape. <br>
/// Does not prevent user XML escaping value.
Method isMixedContent(pValue As %String) As %Boolean [ Internal, Private ]
{
	#; Mixed content must contain a > if it contains a <
	If '$Find(pValue,">") Return 0

	#dim tPositionFirstLessThan = $Find(pValue,"<")

	#; Simple checks err on side of mixed content. Include safety check that does contain a <
	If tPositionFirstLessThan && (tPositionFirstLessThan < $Find(pValue,"</")) Return 1

	#; Could be self terminating. Include safety check that does contain a <
	If tPositionFirstLessThan && (tPositionFirstLessThan < $Find(pValue,"/>")) Return 1

	Return 0
}

Storage Default
{
<Data name="DocumentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%storedContentRef</Value>
</Value>
<Value name="3">
<Value>DocType</Value>
</Value>
<Value name="4">
<Value>TimeCreated</Value>
</Value>
<Value name="5">
<Value>Source</Value>
</Value>
<Value name="6">
<Value>IsMutable</Value>
</Value>
<Value name="7">
<Value>OriginalDocId</Value>
</Value>
</Data>
<Data name="UserValues">
<Attribute>UserValues</Attribute>
<Structure>subnode</Structure>
<Subscript>"UserValues"</Subscript>
</Data>
<DataLocation>^EnsLib.EDI.XML.DocumentD</DataLocation>
<DefaultData>DocumentDefaultData</DefaultData>
<ExtentSize>2000000</ExtentSize>
<IdLocation>^EnsLib.EDI.XML.DocumentD</IdLocation>
<IndexLocation>^EnsLib.EDI.XML.DocumentI</IndexLocation>
<StreamLocation>^EnsLib.EDI.XML.DocumentS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
