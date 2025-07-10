/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, EnsUtil, EnsErrors)

Class Ens.Util.XML.Reader [ Abstract, ClassType = "", ProcedureBlock, System = 3 ]
{

ClassMethod ObjectFromFile(Output pObject As %RegisteredObject, pFilename As %String, pClassnames As %String, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,pObject=$$$NULLOREF
	do {
		#; Obtain a stream from the specified file
		Set tSC = ##Class(Ens.Util.File).LinkFileStream(pFilename,.tStream)  If $$$ISERR(tSC) Quit
		#; Create the object from the stream
		Set tSC = ##Class(Ens.Util.XML.Reader).ObjectFromStream(.pObject,tStream,pClassnames,pResolver)
	} while (0)
Exit
	Quit tSC
Trap
	Set tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Goto Exit
}

ClassMethod ObjectsFromFile(Output pObjects As %ListOfObjects, pFilename As %String, pClassnames As %String, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set:'$$$IsdefObject(pObjects)||'pObjects.%Extends("%Collection.AbstractListOfObj") pObjects=$$$NULLOREF
		#; Obtain a stream from the specified file
		Set tSC = ##Class(Ens.Util.File).LinkFileStream(pFilename,.tStream)  If $$$ISERR(tSC) Quit
		#; Create the object from the stream
		Set tSC = ##Class(Ens.Util.XML.Reader).ObjectsFromStream(.pObjects,tStream,pClassnames,pResolver)
	} while (0)
Exit
	Quit tSC
Trap
	Set tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Goto Exit
}

ClassMethod ObjectFromXData(Output pObject As %RegisteredObject, pXDataHolderClassname As %String, pXDataName As %String, pClassnames As %String, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,pObject=$$$NULLOREF
	do {
		#; Open the compiled class definition for this class
		If $IsObject(pXDataHolderClassname) && (pXDataHolderClassname.%IsA("%Dictionary.CompiledClass") || pXDataHolderClassname.%IsA("%Dictionary.ClassDefinition")) {
			Set tCC=pXDataHolderClassname, pXDataHolderClassname=tCC.Name
		} Else {
			Set tCC = ##class(%Dictionary.CompiledClass).%OpenId(pXDataHolderClassname,0,.tSC)  Quit:$$$ISERR(tSC)
			$$$ASSERTNOLOG($IsObject(tCC))
		}
		#; Find the named XDATA block
		If tCC.%IsA("%Dictionary.CompiledClass") {
			If '##class(%Dictionary.CompiledXData).%ExistsId(pXDataHolderClassname_"||"_pXDataName) Set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,pXDataHolderClassname,pXDataName) Quit
		} Else {
			If '##class(%Dictionary.XDataDefinition).%ExistsId(pXDataHolderClassname_"||"_pXDataName) Set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,pXDataHolderClassname,pXDataName) Quit
		}
		Set tIndex = tCC.XDatas.FindObjectId(pXDataHolderClassname_"||"_pXDataName)
		
		#; Get the XDATA as stream
		Set tStream = tCC.XDatas.GetAt(tIndex).Data
		$$$ASSERTNOLOG($IsObject(tStream))
		Do tStream.Rewind()
		
		#; Instantiate the object from the stream
		Set tSC=..ObjectFromStream(.pObject,tStream,pClassnames,pResolver)
	} while (0)
Exit
	Quit tSC
Trap
	Set tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Goto Exit
}

ClassMethod ObjectsFromXData(Output pObjects As %ListOfObjects, pXDataHolderClassname As %String, pXDataName As %String, pClassnames As %String, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set:'$$$IsdefObject(pObjects)||'pObjects.%Extends("%Collection.AbstractListOfObj") pObjects=$$$NULLOREF
		#; Open the compiled class definition for this class
		If $IsObject(pXDataHolderClassname) && (pXDataHolderClassname.%IsA("%Dictionary.CompiledClass") || pXDataHolderClassname.%IsA("%Dictionary.ClassDefinition")) {
			Set tCC=pXDataHolderClassname, pXDataHolderClassname=tCC.Name
		} Else {
			Set tCC = ##class(%Dictionary.CompiledClass).%OpenId(pXDataHolderClassname,0,.tSC)  Quit:$$$ISERR(tSC)
			$$$ASSERTNOLOG($IsObject(tCC))
		}
		#; Find the named XDATA block
		If tCC.%IsA("%Dictionary.CompiledClass") {
			If '##class(%Dictionary.CompiledXData).%ExistsId(pXDataHolderClassname_"||"_pXDataName) Set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,pXDataHolderClassname,pXDataName) Quit
		} Else {
			If '##class(%Dictionary.XDataDefinition).%ExistsId(pXDataHolderClassname_"||"_pXDataName) Set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,pXDataHolderClassname,pXDataName) Quit
		}
		Set tIndex = tCC.XDatas.FindObjectId(pXDataHolderClassname_"||"_pXDataName)
		
		#; Get the XDATA as stream
		Set tStream = tCC.XDatas.GetAt(tIndex).Data
		$$$ASSERTNOLOG($IsObject(tStream))
		Do tStream.Rewind()
		
		#; Instantiate the object from the stream
		Set tSC=..ObjectsFromStream(.pObjects,tStream,pClassnames,pResolver)
	} while (0)
Exit
	Quit tSC
Trap
	Set tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Goto Exit
}

ClassMethod ObjectFromStream(Output pObject As %RegisteredObject, pStream As %BinaryStream, pClassnames As %String, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}) As %Status
{
	Set pObject=$$$NULLOREF
	
	#; Create an instance of %XML.Reader
	Set tReader=##class(%XML.Reader).%New()  $$$ASSERTNOLOG($IsObject(tReader))

	#; Set the EntityResolver
	If $IsObject(pResolver) Set tReader.EntityResolver=pResolver

	#; Begin processing of the file
	Set tSC=tReader.OpenStream(pStream)  Quit:$$$ISERR(tSC) tSC

	#; Associate class names with the XML element names
	For iClass=1:1:$L(pClassnames,",") { Set tClassname=$ZStrip($P(pClassnames,",",iClass),"<>W")  Continue:""=tClassname
		Set tHeadTag = $$$GetClassParameter(tClassname,"XMLNAME")
		Set:""=tHeadTag tHeadTag=$P(tClassname,".",$L(tClassname,"."))
		Do tReader.Correlate(tHeadTag,tClassname)
	}
	#; Read objects from xml file
	Set tFound = tReader.Next(.pObject,.tSC)  Quit:$$$ISERR(tSC) tSC
	If 'tFound Do pStream.Rewind() Quit $$$ERROR($$$EnsErrNoObjFromStream,tHeadTag,pClassnames,pStream.Read(1000)) 
	Quit tSC
}

ClassMethod ObjectsFromStream(Output pObjects As %ListOfObjects, pStream As %BinaryStream, pClassnames As %String, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}) As %Status
{
	Set:'$$$IsdefObject(pObjects)||'pObjects.%Extends("%Collection.AbstractListOfObj") pObjects=$$$NULLOREF

	#; Create an instance of %XML.Reader
	Set tReader=##class(%XML.Reader).%New()  $$$ASSERTNOLOG($IsObject(tReader))

	#; Set the EntityResolver
	If $IsObject(pResolver) Set tReader.EntityResolver=pResolver

	#; Begin processing of the file
	Set tSC=tReader.OpenStream(pStream)  Quit:$$$ISERR(tSC) tSC

	#; Associate class names with the XML element names
	For iClass=1:1:$L(pClassnames,",") { Set tClassname=$ZStrip($P(pClassnames,",",iClass),"<>W")  Continue:""=tClassname
		Set tHeadTag = $$$GetClassParameter(tClassname,"XMLNAME")
		Set:""=tHeadTag tHeadTag=$P(tClassname,".",$L(tClassname,"."))
		Do tReader.Correlate(tHeadTag,tClassname)
	}
	#; Read objects from xml stream
	Set tFound=0  For { Quit:'tReader.Next(.tObject,.tSC)  Quit:$$$ISERR(tSC)  Set tFound=1
		Set:'$IsObject(pObjects) pObjects=##class(%Library.ListOfObjects).%New()
		Do pObjects.Insert(tObject)
	}
	Quit:$$$ISERR(tSC) tSC
	Quit:'tFound $$$ERROR($$$EnsErrNoObjFromStream,$G(tHeadTag),pClassnames,pStream.Read(1000))
	Quit tSC
}

ClassMethod ObjectFromString(Output pObject As %RegisteredObject, pString As %String, pClassnames As %String, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}) As %Status
{
	Set pObject=$$$NULLOREF

	#; Create an instance of %XML.Reader
	Set tReader=##class(%XML.Reader).%New()  $$$ASSERTNOLOG($IsObject(tReader))

	#; Set the EntityResolver
	If $IsObject(pResolver) Set tReader.EntityResolver=pResolver

	#; Begin processing of the file
	Set tSC=tReader.OpenString(pString)  Quit:$$$ISERR(tSC) tSC

	#; Associate class names with the XML element names
	For iClass=1:1:$L(pClassnames,",") { Set tClassname=$ZStrip($P(pClassnames,",",iClass),"<>W")  Continue:""=tClassname
		Set tHeadTag = $$$GetClassParameter(tClassname,"XMLNAME")
		Set:""=tHeadTag tHeadTag=$P(tClassname,".",$L(tClassname,"."))
		Do tReader.Correlate(tHeadTag,tClassname)
	}
	#; Read objects from xml file
	Set tFound = tReader.Next(.pObject,.tSC)  Quit:$$$ISERR(tSC) tSC
	If 'tFound Quit $$$ERROR($$$EnsErrNoObjFromString,tHeadTag,pClassnames,pString) 
	Quit tSC
}

ClassMethod ObjectsFromString(Output pObjects As %ListOfObjects, pString As %String, pClassnames As %String, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}) As %Status
{
	Set:'$$$IsdefObject(pObjects)||'pObjects.%Extends("%Collection.AbstractListOfObj") pObjects=$$$NULLOREF

	#; Create an instance of %XML.Reader
	Set tReader=##class(%XML.Reader).%New()  $$$ASSERTNOLOG($IsObject(tReader))

	#; Set the EntityResolver
	If $IsObject(pResolver) Set tReader.EntityResolver=pResolver

	#; Begin processing of the file
	Set tSC=tReader.OpenString(pString)  Quit:$$$ISERR(tSC) tSC

	#; Associate class names with the XML element names
	For iClass=1:1:$L(pClassnames,",") { Set tClassname=$ZStrip($P(pClassnames,",",iClass),"<>W")  Continue:""=tClassname
		Set tHeadTag = $$$GetClassParameter(tClassname,"XMLNAME")
		Set:""=tHeadTag tHeadTag=$P(tClassname,".",$L(tClassname,"."))
		Do tReader.Correlate(tHeadTag,tClassname)
	}
	#; Read objects from xml string
	Set tFound=0  For { Quit:'tReader.Next(.tObject,.tSC)  Quit:$$$ISERR(tSC)  Set tFound=1
		Set:'$IsObject(pObjects) pObjects=##class(%Library.ListOfObjects).%New()
		Do pObjects.Insert(tObject)
	}
	Quit:$$$ISERR(tSC) tSC
	Quit:'tFound $$$ERROR($$$EnsErrNoObjFromString,tHeadTag,pClassnames,pString)
	Quit tSC
}

/// Copy from a stream containing an XML header to another stream with the XML header encoding label changed to the value given in pEncoding.
/// Returns the output stream which if not supplied is created using the same stream class as the input stream.
/// If no change to the encoding label results and if no output stream is supplied then the original input stream is returned as the output stream without copying.
ClassMethod ChangeXMLStreamEncoding(pSource As %CharacterStream, pEncoding As %String = "", ByRef pTarget As %CharacterStream = "", Output pStatus) As %CharacterStream
{
	Set tHeader = $S(pSource.%Extends("%IO.I.Stream"):pSource.Read(400,,.pStatus), 1: pSource.Read(400,.pStatus))  Quit:$$$ISERR(pStatus) $$$NULLOREF
	Set tNewHeader = ..ChangeXMLEncoding(tHeader, pEncoding)

	If '$IsObject(pTarget) {
		If tNewHeader=tHeader { Do pSource.Rewind()  Quit pSource }
		Set pTarget = $classmethod($S(""'=pTarget:pTarget, 1:$classname(pSource)),"%New","") $$$ASSERTNOLOG($IsObject(pTarget))
	}
	If pTarget.%Extends("%IO.I.Stream") {
		Do pTarget.Write(tNewHeader,,.pStatus)  Quit:$$$ISERR(pStatus) $$$NULLOREF
		If pSource.%Extends("%IO.I.Stream") {
			While 'pSource.AtEnd { Set tChunk=pSource.Read(32000,,.pStatus)  Quit:$$$ISERR(pStatus)  Do pTarget.Write(tChunk,,.pStatus)  Quit:$$$ISERR(pStatus) }
		} Else {
			While 'pSource.AtEnd { Set tChunk=pSource.Read(32000,.pStatus)  Quit:$$$ISERR(pStatus)  Do pTarget.Write(tChunk,,.pStatus)  Quit:$$$ISERR(pStatus) }
		}
	} Else {
		Set pStatus = pTarget.Write(tNewHeader)  Quit:$$$ISERR(pStatus) $$$NULLOREF
		If pSource.%Extends("%IO.I.Stream") {
			While 'pSource.AtEnd { Set tChunk=pSource.Read(32000,,.pStatus)  Quit:$$$ISERR(pStatus)  Set pStatus = pTarget.Write(tChunk)  Quit:$$$ISERR(pStatus) }
		} Else {
			While 'pSource.AtEnd { Set tChunk=pSource.Read(32000,.pStatus)  Quit:$$$ISERR(pStatus)  Set pStatus = pTarget.Write(tChunk)  Quit:$$$ISERR(pStatus) }
		}
	}
	Do pSource.Rewind()
	Quit:$$$ISERR(pStatus) $$$NULLOREF
	Do pTarget.Rewind()
	Quit pTarget
}

ClassMethod ChangeXMLEncoding(pString As %String, pEncoding As %String = "") As %String
{
	Set tEncodingPos = $F(pString,"encoding")
	Set tEncoding=$Translate($Piece($Piece(pString,"?>"),"encoding",2),"""","'")
	Set tEncodingValpos = $F(tEncoding,"'")
	Set:"="'=$ZSTRIP($E(tEncoding,1,tEncodingValpos-2),"*W") tEncodingPos=0
	Set tEncoding=$Piece(tEncoding,"'",2)
	If 0=tEncodingPos {
		If pEncoding'="" { ; Insert the encoding tag
			Set tEncodingPos = $F(pString,"?>")
			If tEncodingPos Set $E(pString,tEncodingPos-2,tEncodingPos-1)=" encoding='"_pEncoding_"'?>"
		}
	} Else {
		If pEncoding="" { ; Remove the encoding tag
			Set $E(pString,tEncodingPos-$L("encoding"),$F(pString,tEncoding,tEncodingPos)) = ""
		}
		Else { ; Change the encoding tag
			If $ZCVT(tEncoding,"L")'=$ZCVT(tEncodingPos,"L") {
				Set tEncodingValpos = tEncodingPos+tEncodingValpos-1
				Set $E(pString,tEncodingValpos,tEncodingValpos+$L(tEncoding)-1)=pEncoding
			}
		}
	}
	Quit pString
}

}
