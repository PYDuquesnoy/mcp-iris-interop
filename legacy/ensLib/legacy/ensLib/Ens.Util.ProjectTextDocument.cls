/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occStream)

/// Studio Document used to store arbitrary text documents in a Project file and edit them in Studio.
Class Ens.Util.ProjectTextDocument Extends %Studio.AbstractDocument [ ClassType = "", ProcedureBlock, System = 4 ]
{

Projection RegisterExtension As %Projection.StudioDocument(DocumentExtension = "PTD", DocumentNew = 0, DocumentType = "xml", XMLNamespace = "http://www.intersystems.com/projtxtdoc");

Parameter EXTENSION = ".PTD";

/// Load the PTD text from the global into a Code stream
Method Load() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Quit:".PTD"'=$ZCVT($E(..Name,*-3,*),"U") $$$ERROR($$$GeneralError,"Invalid PTD filename '"_..Name_"'")
	Set tSC=..GblToStream($E(..Name,1,*-4),..Code)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

/// Save the PTD text document into the global
Method Save() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Find old Category name in ..Code
		Do ..Code.Rewind()
		Set (tLine,tOldKey)="" For i=1:5 { Set tLine=..Code.ReadLine(,.tSC) Quit:tLine["<ProjectTextDocument "||..Code.AtEnd }
		If tLine'["<ProjectTextDocument " Set tSC= $$$ERROR($$$GeneralError,"Project Text Document "_..Name_" is not a properly formed PTD document")  Quit
		Set f=$F(tLine,"name=") Set:'f f=$F(tLine,"name =") Set:f tLine=$ZStrip(tLine,"<W"), tOldKey=$P($E(tLine,f+1,*),$E(tLine,f))
		
		Set tKey=$E(..Name,1,*-4)  If ".PTD"'=$ZCVT($E(..Name,*-3,*),"U") Set tSC=$$$ERROR($$$GeneralError,"Project Text Document key "_..Name_" is not a PTD document")  Quit
		TStart
		Set tSC=..StreamToGbl(..Code,,tKey)
		If $$$ISOK(tSC) {
			#; Document loaded ok, let's commit it - but first fix name if needed
			Do:tOldKey'=tKey ..Code.Clear(), ..GblToStream(tKey,..Code)
			TCommit
		} Else {
			#; Rollback the update			
			TRollback
		}
	} While(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

/// Save the PTD text document into the global
ClassMethod GblToStream(pKey As %String, pStream As %String) As %Status [ Internal ]
{
	Set tRef="", tSC=$$$OK
	Quit:'$D(^EnsPTD(pKey),tRef) $$$ERROR($$$GeneralError,"Project Text Document key <"_pKey_"> does not exist in namespace "_$ZNSpace)
	Quit:""=tRef $$$ERROR($$$GeneralError,"Project Text Document stream for <"_pKey_"> does not exist in namespace "_$ZNSpace)

	If '$IsObject(pStream) {
		set tFilename=pStream
		set pStream=##class(%FileCharacterStream).%New()
		//set tSC=pStream.LinkToFile(tFilename)  Quit:$$$ISERR(tSC) tSC
		set pStream.Filename = tFilename
		set pStream.TranslateTable="UTF8"
		Set tEncoding="UTF-8"
	} Else {
		Set tEncoding=$S(pStream.%Extends("%IO.IParts.CharacterIO"):pStream.CharEncoding,
						pStream.%Extends("%FileCharacterStream"):$$MapExtCharset^%NLS(pStream.TranslateTable),
		 				1:"")
	}
	Set tGCS=##class(%Stream.GlobalCharacter).%OpenId(tRef)

	Do pStream.Write("<?xml version=""1.0"""_$S(""=tEncoding:"",1:" encoding="""_tEncoding_"""")_"?>"_$C(13,10))
	Do pStream.Write("<ProjectTextDocument name="""_pKey_"""")
	set desc=$G(^EnsPTD(pKey,"desc"))
	if desc'="" Do pStream.Write(" description="""_desc_"""")
	Do pStream.Write(">"_$C(13,10)_"<![CDATA[")
	#; Quote embedded CDATA close markers
	While $$$ISOK(tSC)&&'tGCS.AtEnd {
		Set tOK=..readUntil(tGCS,pStream,"]]>",.tSC,0)
		Quit:'tOK||$$$ISERR(tSC)
		Set tSC=pStream.Write("]*]>")
	} 
	Quit:$$$ISERR(tSC) tSC
	Do pStream.Write($C(13,10)_"]]></ProjectTextDocument>"_$C(13,10))
	Quit:pStream.%Extends("%Library.FileStreamAdaptor") pStream.SaveStream()
	Quit $$$OK
}

/// Get the content of a PTD document from global storage into a stream object
ClassMethod GetStream(Output pStream, pName As %String, Output pDescription As %String) As %Status
{
	Set:".PTD"=$ZCVT($E(pName,*-3,*),"U") pName=$E(pName,1,*-4)
	Set pDescription=$G(^EnsPTD(pName,"desc"))
	Set pStream=##class(%Stream.GlobalCharacter).%OpenId($G(^EnsPTD(pName)))
	Quit:'$IsObject(pStream) %objlasterror
	Quit $$$OK
}

/// Get the content of a PTD document from global storage and return it as a string
ClassMethod GetString(pName As %String, Output pDescription As %String, Output pStatus As %Status) As %String
{
	Set pStatus=..GetStream(.tGCS,.pName,.pDescription)	 Quit:$$$ISERR(pStatus) ""
	Quit tGCS.Read()
}

/// Save a text document into global storage as a PTD document
ClassMethod Create(pText As %String, pName As %String, pDescription As %String = "") As %Status
{
	Set tSC=$$$OK
	Set:".PTD"'=$ZCVT($E(pName,*-3,*),"U") pName=pName_".PTD"
	Quit:..Exists(pName) $$$ERROR($$$GeneralError,"PTD document '"_pName_"' already exists")
	If '$IsObject(pText) {
		Set tGCS=##class(%Stream.GlobalCharacter).%New()
		Do tGCS.Write(pText)
	} Else {
		Set tGCS=##class(%Stream.GlobalCharacter).%New()
		Set tSC=tGCS.CopyFrom(pText)
	}
	Set:$$$ISOK(tSC) tSC=tGCS.%Save()
	Quit:$$$ISERR(tSC) tSC
	
	Set tKey=$E(pName,1,*-4)
	Set ^EnsPTD(tKey)=tGCS.%Id()
	Set ^EnsPTD(tKey,"time")=$ZTS
	Set:""'=pDescription ^EnsPTD(tKey,"desc")=pDescription
	Quit $$$OK
}

/// Save a PTD document into the PTD global
ClassMethod StreamToGbl(pFile As %String, Output pKeyImported As %String, pForceKey As %String) As %Status [ Internal ]
{
	If '$IsObject(pFile) {
		Quit:'##class(%File).Exists(pFile) $$$ERROR($$$FileDoesNotExist,pFile)
		Set tStream=##class(%IO.FileStream).%New(pFile)  Quit:'tStream.IsOpen $$$ERROR($$$GeneralError,"Unable to open file "_pFile)
	} Else {
		Set tStream=pFile
	}
	Do tStream.Rewind()
	Set (tName,tDesc,tEncoding)=""
	Set tLine="",tLen=0 For i=1:5 {
		Set tLine=$S(tStream.%Extends("%IO.I.Stream"):tStream.ReadLine(,,.tSC), 1:tStream.ReadLine(,.tSC)), tLen=tLen+$L(tLine)+2
		Set tEncPos=$F(tLine," encoding=")  Set:tEncPos tEncoding=$E(tLine,tEncPos+1,$F(tLine,$E(tLine,tEncPos),tEncPos+1)-2)
		Quit:tLine["<ProjectTextDocument "||tStream.AtEnd
	}
	If ""'=tEncoding {
		Set tChanged=0, tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(tEncoding)
		If tStream.%Extends("%IO.IParts.CharacterIO") && (tStream.TranslationTable'=tTable) { Do tStream.Rewind()  Set tStream.CharEncoding=tEncoding, tChanged=1 }
		ElseIf tStream.%Extends("%FileCharacterStream") && (tStream.TranslateTable'=tTable) { Do tStream.Rewind()  Set tStream.TranslateTable=tTable, tChanged=1 }
		If tChanged Set tLine="",tLen=0 For i=1:5 { Set tLine=$S(tStream.%Extends("%IO.I.Stream"):tStream.ReadLine(,,.tSC), 1:tStream.ReadLine(,.tSC)), tLen=tLen+$L(tLine)+2  Quit:tLine["<ProjectTextDocument "||tStream.AtEnd }
	}
	Quit:tLine'["<ProjectTextDocument " $$$ERROR($$$GeneralError,"Project Text Document "_pFile_" is not a properly formed PTD document")
	Set f=$F(tLine,"name=") Set:'f f=$F(tLine,"name =") Set:f tLine=$ZStrip($E(tLine,f,*),"<W"), tName=$ZCVT($P(tLine,$E(tLine,1),2),"I","XML")
	Set f=$F(tLine,"description=") Set:'f f=$F(tLine,"description =") Set:f tLine=$ZStrip($E(tLine,f,*),"<W"), tDesc=$ZCVT($P(tLine,$E(tLine,1),2),"I","XML")

	Set (tKey,tKey0)=$S(""'=pForceKey:pForceKey, ""'=$G(tName):tName, ""'=$G(pKeyImported):pKeyImported, 1:"")
	If ""=tKey {
		Set tKey0=$S(tStream.%Extends("%IO.I.Stream"):tStream.Name, ""'=tStream.GetAttribute("Filename"):tStream.GetAttribute("Filename"), 1:tStream.GetAttribute("Name"))
		#;strip out final filename from file path
		Set:tKey'=$TR(tKey,"/\]") tKey=$P(tKey,"/",$L(tKey,"/")), tKey=$P(tKey,$L(tKey,"\")), tKey=$P($P(tKey,"]",$L(tKey,"]")),";")
		Quit:""=tKey $$$ERROR($$$GeneralError,"Stream "_tStream_$S(""=tKey0:"",1:" / "_tKey0)_" has no name to use as .PTD name")
	}

	#; Another stream PTD validity check - looking for CDATA tag.
	#; tLine here is now from "description =" to the end of the line
	#; Use 10 to account for possible leading line char.
	If '($Find(tLine,"<![CDATA[")||$Find(tStream.Read(10),"<![CDATA[")) {
		Quit $$$ERROR($$$GeneralError,"CDATA start not found in file "_pFile)
	}

	Set:$Case($ZCVT($E(tKey,*-3,*),"U"), ".XML":1, ".PTD":1, :0) tKey=$E(tKey,1,*-4)

	Set tGot1=0 For try=1:1:2 {
		#; Re-read from the beginning to discover what the newline is, so we can use it later on
		Do tStream.Rewind()
		Set tBuf=tStream.Read(tLen+3)
		Set f=$F(tBuf,"<![")
		If 'f Set tSC=$$$ERROR($$$GeneralError,"CDATA not found in file "_pFile)  Quit
		Set:'$D(tNewline) tNewline=$ZStrip($E(tBuf,f-5,f-4),"<E'C")

		#; move up past the CDATA start
		Set tBuf=tStream.Read($L("CDATA[")-(tLen+4-f))
		Set tGCS=##class(%Stream.GlobalCharacter).%New()
	
		#; For all consecutive CDATA's
		For {
			#; read until the CDATA end
			Set tOK=..readUntil(tStream,tGCS,tNewline_"]]>",.tSC,0)
			Quit:'tOK||$$$ISERR(tSC)
			Set tGot1=1
			#; move up past the next CDATA start
			Quit:tStream.AtEnd||("<![CDATA["'= tStream.Read($L("<![CDATA[")))
		}
		Quit:tGot1||$$$ISERR(tSC)||(tNewline="")
		Set tNewline="" ; try again
	}
	Quit:$$$ISERR(tSC) tSC
	Quit:'tGot1 $$$ERROR($$$GeneralError,"CDATA close not found in file "_pFile)

	#; Unquote embedded CDATA close markers
	Do tGCS.Rewind()
	Set tGCS2=##class(%Stream.GlobalCharacter).%New()
	While $$$ISOK(tSC)&&'tGCS.AtEnd {
		Set tOK=..readUntil(tGCS,tGCS2,"]*]>",.tSC,0)
		Quit:'tOK||$$$ISERR(tSC)
		Set tSC=tGCS2.Write("]]>")
	} 
	Quit:$$$ISERR(tSC) tSC
	Set tSC=tGCS2.%Save()  Quit:$$$ISERR(tSC) tSC
	Set tRef=$G(^EnsPTD(tKey))
	Do:""'=tRef ##class(%Stream.GlobalCharacter).%DeleteId(tRef)
	Kill ^EnsPTD(tKey)
	Set ^EnsPTD(tKey)=tGCS2.%Id()
	Set ^EnsPTD(tKey,"time")=$ZTS
	Set:""'=tDesc ^EnsPTD(tKey,"desc")=tDesc
	Set pKeyImported=tKey
	Quit $$$OK
}

/// Read until target found in pStreamIn, copying all data read to pStreamOut
ClassMethod readUntil(pStreamIn, pStreamOut, pTarget, ByRef pSC, pIncludeTarget = 1) As %Boolean [ Internal ]
{
	#; Read in chunks using last char of pTarget as terminator
	Set pSC=$$$OK,tFound=0
	Set tOldTerm=pStreamIn.LineTerminator
	Set tC=$E(pTarget,*)
	Set pStreamIn.LineTerminator=tC
	Set tLine="" While $$$ISOK(pSC) && 'tFound && 'pStreamIn.AtEnd {
		Set tLen=32000-$L(pTarget)
		If pStreamIn.%Extends("%IO.I.Stream") {
			Set tLT=tC, tFresh=pStreamIn.ReadLine(,,.pSC,.tLT), tEOL=(""'=tLT||pStreamIn.AtEnd), tLine=tLine_tFresh
		} Else {
			Set tLine=tLine_pStreamIn.ReadLine(,.pSC,.tEOL)
		}
		Set:tEOL tLine=tLine_tC
		If tEOL && ($L(tLine)>=$L(pTarget)) && (pTarget=$E(tLine,*+1-$L(pTarget),*)) {
			Set tFound=1
			Do pStreamOut.Write($E(tLine,1,$L(tLine)-$L(pTarget))) Set $E(tLine,1,$L(tLine)-$L(pTarget))=""
		} Else {
			If $L(tLine)>$L(pTarget) Do pStreamOut.Write($E(tLine,1,$L(tLine)+1-$L(pTarget))) Set $E(tLine,1,$L(tLine)+1-$L(pTarget))=""
		}
	}
	Do:'tFound||pIncludeTarget pStreamOut.Write(tLine)
	Set pStreamIn.LineTerminator=tOldTerm
	Do:'tFound pStreamIn.Rewind()
	Quit tFound
}

/// Delete the named PTD document <var>pName</var>.
ClassMethod Delete(pName As %String) As %Status
{
	Quit:".PTD"'=$ZCVT($E(pName,*-3,*),"U") $$$ERROR($$$GeneralError,"Invalid PTD filename")
	Set tKey=$E(pName,1,*-4)
	Set tRef=$G(^EnsPTD(tKey))
	Do:""'=tRef ##class(%Stream.GlobalCharacter).%DeleteId(tRef)
	Kill ^EnsPTD(tKey)
	Quit $$$OK
}

/// 
/// Return the timestamp of text document 'pName' in %TimeStamp format, i.e. $zdatetime($horolog,3).
/// This is used to determine if the document has been updated on the server and so needs reloading into Studio.
/// So the format should be $zdatetime($horolog,3), or "" if the category does not exist.
ClassMethod TimeStamp(pName As %String) As %TimeStamp
{
	If ".PTD"'=$ZCVT($E(pName,*-3,*),"U") Set tSC=$$$ERROR($$$GeneralError,"Invalid PTD document filename")  Quit ""
	Set ts=$G(^EnsPTD($E(pName,1,*-4),"time"))
	Quit ##class(Ens.DataType.UTC).LogicalToOdbc($S(""=ts:ts,1:$ZDT(ts,3,,3)))
}

/// Return the compile time of routine 'pName' in %TimeStamp format. The format should be $zdatetime($horolog,3),
/// or "" if the routine does not exist.
ClassMethod CompileTime(pName As %String) As %TimeStamp [ CodeMode = expression ]
{
..TimeStamp(.pName)
}

/// Return 1 if the given project text PTD document exists and 0 if it does not.
ClassMethod Exists(pName As %String) As %Boolean
{
	Quit:".PTD"'=$ZCVT($E(pName,*-3,*),"U") 0
	Set category=$E(pName,1,*-4)
	Quit ''$data(^EnsPTD(category))
}

Query List(Directory As %String, Flat As %Boolean, System As %Boolean) As %Query(ROWSPEC = "name:%String,modified:%TimeStamp,size:%Integer,directory:%String") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Directory As %String, Flat As %Boolean, System As %Boolean) As %Status
{
	if $g(Directory)'="" set qHandle="" quit $$$OK
	set index=$I(^IRIS.Temp)
	set cat="" for  set cat=$O(^EnsPTD(cat)) quit:cat=""  set ^IRIS.Temp(index,cat)=""
	set qHandle=$LB(index,"")
	quit $$$OK
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ListExecute ]
{
	set Row="",AtEnd=0
	set tempnode=$LG(qHandle,1),cat=$LG(qHandle,2)
	if (tempnode="") set Row="",AtEnd=1 quit $$$OK
	set cat=$O(^IRIS.Temp(tempnode,cat))
	set $LI(qHandle,2)=cat
	If cat="" Set AtEnd=1 Quit $$$OK
	set Row=$LB(cat_".PTD",$G(^IRIS.Temp(tempnode,cat,"time")),0,"")
	if $O(^IRIS.Temp(tempnode,cat))="" set AtEnd=1
	Quit $$$OK
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ListExecute ]
{
	set tempnode=$LG(qHandle,1)
	if tempnode'="" kill ^IRIS.Temp(tempnode)
	set qHandle=""
	Quit $$$OK
}

/// Export this document to the current device in XML format
Method ExportToXML(flags As %String) As %Status
{
	Set ..Code.LineTerminator=$c(10)
	Do ..Code.Rewind()
	Do ..Code.ReadLine()  // omit xml header
	While '(..Code.AtEnd) {
		Write ..Code.Read(16000)
	}
	Quit $$$OK
}

/// Import from the stream in XML format.
/// Note that the line endings are normalized to CRLF (i.e. $char(13,10)) to simplify parsing.
Method ImportFromXML(stream As %RegisteredObject, flags As %String) As %Status
{
	Do ..Code.Clear()
	Set tTempStream = ##class(%Stream.TmpCharacter).%New()
	Do tTempStream.CopyFrom(stream)
	Do tTempStream.Rewind()
	Set tTempStream.LineTerminator = $char(10)
	Set tSC = $$$OK
	While 'tTempStream.AtEnd {
		Set tEOL = 0
		Set tLine = tTempStream.ReadLine(,.tSC,.tEOL)
		If $$$ISERR(tSC) Quit
		If tEOL {
			If $extract(tLine,*) = $char(13) Set tLine = $extract(tLine,1,*-1)
			Do ..Code.WriteLine(tLine)
		}
		Else {
			Do ..Code.Write(tLine)
		}
	}
	If $$$ISERR(tSC) Quit tSC
	Quit $$$OK
}

/// Return true if this is mapped from a database other than the default routine database and zero otherwise.
/// Also set the source database in <var>sourcedb</var>.
ClassMethod IsMapped(name As %String, ByRef sourcedb As %String) As %Boolean
{
	/* 2 part mapping required to be truly mapped */
	Set tGlobal = $name(^EnsPTD($e(name,1,*-4)))
	Set tStreamGlobal = $$$streamGlobal
	Return ..IsMappedGlobal(tGlobal,.sourcedb) && ..IsMappedGlobal(tStreamGlobal,.sourcedb)
}

}
