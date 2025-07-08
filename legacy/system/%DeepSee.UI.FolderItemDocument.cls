/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract Document used to load a folder item (e.g. dashboard) definition into Studio.
Class %DeepSee.UI.FolderItemDocument Extends %Studio.AbstractDocument [ ClassType = "", ProcedureBlock, System = 4 ]
{

Projection RegisterExtension As %Projection.StudioDocument(DocumentExtension = "DFI", DocumentNew = 0, DocumentType = "xml", XMLNamespace = "http://www.intersystems.com/DeepSee/FolderItem");

Parameter EXTENSION = ".DFI";

/// Load the folder item definition into the stream Code<br>
Method Load() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set name=..Name
		If ".DFI"'=$ZCVT($E(name,*-3,*),"U") Set tSC=$$$ERROR($$$GeneralError,"Invalid folder item filename '"_name_"'")  Quit
		Set name=##class(%DeepSee.UserLibrary.FolderItem).fullNameFromDocumentName(name) ; restore slashes that were removed to placate %RoutineMgr
		Set tEncoding=$S(..Code.%Extends("%IO.IParts.CharacterIO"):..Code.CharEncoding,
						..Code.%Extends("%FileCharacterStream"):$$MapExtCharset^%NLS(..Code.TranslateTable),
						1:"")
		Set tSC = ..Code.WriteLine("<?xml version=""1.0"""_$S(""=tEncoding:"",1:" encoding="""_tEncoding_"""")_"?>")  Quit:$$$ISERR(tSC)
		Set tSC = ..Code.WriteLine("")  Quit:$$$ISERR(tSC)
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%Export(name,..Code,0)
	} While(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Goto Exit
}

/// Save the folder item definition document.
Method Save() As %Status
{
	Quit ..ImportStream(..Name,..Code)
}

/// Save the folder item definition document from stream to global.
ClassMethod ImportStream(pName As %String, pStream As %GlobalCharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Find old tItemName name in pStream
		Do pStream.Rewind()
		Set (tLine,tFolder,tName)="" While tLine'[" folderName=" { Set tLine=pStream.ReadLine(,.tSC) Quit:pStream.AtEnd }
		Set f=$F(tLine,"folderName=") Set:f tFolder=$P($E(tLine,f+1,*),$E(tLine,f))
		Set f=$F(tLine,"name=") Set:f tName=$P($E(tLine,f+1,*),$E(tLine,f))
		Set tOldItem=tFolder_$S(""=tFolder:"",1:"/")_tName
		Do pStream.Rewind()
		;Set tStream=##class(Ens.Util.XML.Reader).ChangeXMLStreamEncoding(pStream,"") Do tStream.Rewind()
		Set tStream=..ChangeXMLStreamEncoding(pStream,"") Do tStream.Rewind()
		If ".DFI"'=$ZCVT($E(pName,*-3,*),"U") Set tSC=$$$ERROR($$$GeneralError,pName_" is not a folder item")  Quit
		Set tItemName=##class(%DeepSee.UserLibrary.FolderItem).fullNameFromDocumentName(pName) ; restore slashes that were removed to placate %RoutineMgr
		tstart
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%Import(tStream,1,0,,tItemName)
		If $$$ISOK(tSC) {
			#; Schema loaded ok, let's commit it - but first fix name if needed
			Do:tOldItem'=tItemName pStream.Clear(), ##class(%DeepSee.UserLibrary.Utils).%Export(tItemName,pStream,0)
			tcommit
		} Else {
			#; Rollback the schema update			
			trollback
		}
	} While(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Goto Exit
}

/// Delete the folder item definition <var>name</var>.
ClassMethod Delete(name As %String) As %Status
{
	Quit:".DFI"'=$ZCVT($E(name,*-3,*),"U") $$$ERROR($$$GeneralError,"Invalid folder item filename")
	Set name=##class(%DeepSee.UserLibrary.FolderItem).fullNameFromDocumentName(name) ; restore slashes that were removed to placate %RoutineMgr
	Quit ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(name)
}

/// 
/// Return the timestamp of folder item 'name' in %TimeStamp format, i.e. $zdatetime($horolog,3).
/// This is used to determine if the folder item has been updated on the server and so needs reloading into Studio.
/// So the format should be $zdatetime($horolog,3), or "" if the folder item does not exist.
ClassMethod TimeStamp(name As %String) As %TimeStamp
{
#define timeUTCtoUTCH(%utc)  $zdatetimeh(%utc,3,,,,,,,,0)
#define timeUTCHtoUTC(%utch) $zdatetime(%utch,3,,3)
	Quit:".DFI"'=$ZCVT($E(name,*-3,*),"U") ""
	Set name=##class(%DeepSee.UserLibrary.FolderItem).fullNameFromDocumentName(name) ; restore slashes that were removed to placate %RoutineMgr
	Quit:'##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(name,.tID) ""
	&sql(SELECT timeModified INTO :tTimestamp FROM %DeepSee_UserLibrary.FolderItem WHERE ID=:tID)
	Quit:SQLCODE ""
	#; Quit ##class(Ens.DataType.UTC).LogicalToOdbc($S(""=tTimestamp:"",1:tTimestamp))
	Quit $S(""=tTimestamp:"",1:$$$timeUTCHtoUTC($zu(193,$$$timeUTCtoUTCH(tTimestamp),0)))
}

/// Return the compile time of routine 'name' in %TimeStamp format. The format should be $zdatetime($horolog,3),
/// or "" if the routine does not exist.
ClassMethod CompileTime(name As %String) As %TimeStamp [ CodeMode = expression ]
{
..TimeStamp(.name)
}

/// Return 1 if the given folder item document exists and 0 if it does not.
ClassMethod Exists(name As %String) As %Boolean
{
	Quit:".DFI"'=$ZCVT($E(name,*-3,*),"U") 0
	Set name=##class(%DeepSee.UserLibrary.FolderItem).fullNameFromDocumentName(name) ; restore slashes that were removed to placate %RoutineMgr
	Quit ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(name)
}

Query List(Directory As %String, Flat As %Boolean, System As %Boolean, pShowAll As %Boolean, pFolderClass As %String) As %Query(ROWSPEC = "name:%String,modified:%TimeStamp,size:%Integer,directory:%String")
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Directory As %String = "", Flat As %Boolean = "", System As %Boolean = "", pShowAll As %Boolean = 1, pFolderClass As %String = "") As %Status
{
	If $G(Directory)'="" Set qHandle="" Quit $$$OK
	Set tSC=##class(%DeepSee.UserLibrary.Utils).%GetFolderItemList(.qHandle, Directory, pShowAll, pFolderClass)
	Set qHandle=""
	Quit tSC
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ListExecute ]
{
#define timeUTCtoLocal(%utc) $zdatetime($zu(193,$zdatetimeh(%utc,3,,,,,,,,0),0),3,,3)
	Set Row="",AtEnd=0
	Set qHandle=$O(qHandle($G(qHandle)),1,tItemId)
	If qHandle="" Set AtEnd=1  Quit $$$OK
	Set tItem=##class(%DeepSee.UserLibrary.FolderItem).%OpenId(tItemId,,.tSC)  Quit:$$$ISERR(tSC) tSC
	Set Row=$LB(tItem.documentName,$S(""=tItem.timeModified:"",1:$$$timeUTCtoLocal(tItem.timeModified)),0,"") ; use documentName property with slashes removed because they would make %RoutineMgr think this is a CSP
	Set:""=$O(qHandle(qHandle)) AtEnd=1
	Quit $$$OK
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ListFetch ]
{
	Kill qHandle  Set qHandle=""
	Quit $$$OK
}

/// Export this document to the current device in XML format
Method ExportToXML(flags As %String) As %Status
{
	Set ..Code.LineTerminator=$C(10)
	Do ..Code.Rewind()
	Do ..Code.ReadLine()  // omit xml header
	While '(..Code.AtEnd) {
		Write ..Code.Read(16000)
	}
	Quit $$$OK
}

/// Import from the stream in XML format
Method ImportFromXML(stream As %RegisteredObject, flags As %String) As %Status
{
	Do ..Code.Clear()
	Do ..Code.CopyFrom(stream)
	Quit $$$OK
}

/// Copied from Ens.Util.XML.Reader
ClassMethod ChangeXMLStreamEncoding(pSource As %CharacterStream, pEncoding As %String = "", ByRef pTarget As %CharacterStream = "", Output pStatus) As %CharacterStream [ Internal ]
{
	Set tHeader = $S(pSource.%Extends("%IO.I.Stream"):pSource.Read(400,,.pStatus), 1: pSource.Read(400,.pStatus))  Quit:$$$ISERR(pStatus) $$$NULLOREF
	Set tNewHeader = ..ChangeXMLEncoding(tHeader, pEncoding)

	If '$IsObject(pTarget) {
		If tNewHeader=tHeader { Do pSource.Rewind()  Quit pSource }
		Set pTarget = $classmethod($S(""'=pTarget:pTarget, 1:pSource.%ClassName(1)),"%New","")
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

/// Copied from Ens.Util.XML.Reader
ClassMethod ChangeXMLEncoding(pString As %String, pEncoding As %String = "") As %String [ Internal ]
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
