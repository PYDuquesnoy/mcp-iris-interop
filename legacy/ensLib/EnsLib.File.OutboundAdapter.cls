/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// An Outbound Adapter class providing methods used to write data to files and do other OS level file manipulations.
Class EnsLib.File.OutboundAdapter Extends (Ens.OutboundAdapter, EnsLib.File.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Overwrite file if it exists, instead of appending
Property Overwrite As %Boolean [ InitialExpression = 0 ];

/// Number of seconds to wait on each attempt to open the output file.
Property OpenTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

Parameter SETTINGS = "RegistryID:Basic:selector?context={Ens.ServiceRegistry.External.ContextSearch/Services?Protocols_1=File},FilePath:Basic:directorySelector,Overwrite,Charset::selector?context={Ens.ContextSearch/CharacterSets},OpenTimeout";

Property OldIO As %String(MAXLEN = 1000);

Property Device As %String(MAXLEN = 1000);

Property LineTerminator As %String(MAXLEN = 10) [ InitialExpression = {$C(13,10)} ];

Method OnInit() As %Status
{
	Set ..OldIO = $IO  Do ##class(Ens.Util.Trace).SetTraceDevice($S($IO?1"|TCP|".e:"",1:$IO))
	Quit $$$OK
}

/// Combine base Filename with Directory and filename Spec that may contain timestamp and counter templates.
/// Parameters are then passed to CreateTimestamp() which is inherited from Ens.Util.File.
/// 
Method CreateFilename(pFilename As %String, pSpec As %String, pIsVMS As %Boolean, pDirectory As %String, pLocal As %Boolean, ByRef pCharactersToRemove As %String) As %String
{
	#; Override to use FilePath as pDirectory in case %+ file existence-checking is called for
	Set:'($D(pDirectory)#2) pDirectory=..fixPath(..FilePath)
	Quit ##Class(%File).GetFilename(..CreateTimestamp(.pFilename,.pSpec,.pIsVMS,pDirectory,.pLocal,.pCharactersToRemove))
}

Method open(pFilename As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		$$$ASSERT(""=..Device)
		If ""=..FilePath Set tSC=$$$ERROR($$$EnsErrGeneral,"No file path specified; can't access file")  Quit

		Set ..Device = ..fixPath(..FilePath)_pFilename
		If $Case($ZCVT(..Charset,"L"),"":0,"!":0,"default":0,"native":0,:1) {
			Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable($S("!"=$E(..Charset):$E(..Charset,2,*),1:..Charset))
			Set tMode = $S(..Overwrite:"NWUK\",1:"AWUK\")_tTable_"\"
		} Else {
			Set tMode = $S(..Overwrite:"NWU",1:"AWU")
		}
		$$$catTRACE("file","Trying to open for "_$S(..Overwrite:"(over)write",1:"append")_" '"_..Device_"' with timeout="_..OpenTimeout)
		Open ..Device:(tMode):..OpenTimeout  Set:'$Test tSC=$$$ERROR($$$FileCanNotOpen,..Device)

		If $$$ISERR(tSC) Set ..Device = ""
		Else  $$$catTRACE("file","Opened for "_$S(..Overwrite:"(over)write",1:"append")_" '"_..Device_"'")

	} While 0
	If $$$ISERR(tSC) If $$$StatusEquals(tSC,$$$FileCanNotOpen) { Set ..BusinessHost.Retry = 1 } else { $$$LOGSTATUS(tSC) }
Exit
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<NOTOPEN>" { Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to open for "_$S(..Overwrite:"(over)write",1:"append")_" '"_..Device_" : "_$ZE) }
	Else {
		Set tSC=$$$SystemError
		Close:..Device'="" ..Device
	}
	Set ..Device = ""
	Goto Exit
}

Method openRead(pFilename As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		$$$ASSERT(""=..Device)

		Set ..Device = ..fixPath(..FilePath)_pFilename
		If ""'=..Charset&&("default"'=$ZCVT(..Charset,"L")) {
			Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(..Charset)
			Set tMode = "RUK\"_tTable_"\"
		} Else {
			Set tMode ="RU"
		}
		$$$catTRACE("file","Trying to open for read '"_..Device_"' with timeout="_..OpenTimeout)
		Open ..Device:(tMode):..OpenTimeout  Set:'$Test tSC=$$$ERROR($$$FileCanNotOpen,..Device)

		If $$$ISERR(tSC) Set ..Device = ""
		Else  $$$catTRACE("file","Opened for read '"_..Device_"'")

	} While 0
	If $$$ISERR(tSC) If $$$StatusEquals(tSC,$$$FileCanNotOpen) { Set ..BusinessHost.Retry = 1 } else { $$$LOGSTATUS(tSC) }
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Close:..Device'="" ..Device
	Set ..Device = ""
	Goto Exit
}

Method close() As %Status
{
	If ""'=..Device {
		If $IO=..Device Use ..OldIO
		Close ..Device
		Set ..Device = ""
	}
	Quit $$$OK
}

Method Exists(pFilename As %String) As %Boolean
{
	$$$ASSERT(""=..Device)
	Set tFullname =..fixPath(..FilePath)_pFilename
	Quit ##class(%File).Exists(tFullname)
}

Method Delete(pFilename As %String) As %Status
{
	$$$ASSERT(""=..Device)
	Set tFullname =..fixPath(..FilePath)_pFilename
	Set tOK = ##class(%File).Delete(tFullname)
	if 'tOK Quit $$$EnsError($$$FileCanNotDelete,tFullname)
	Quit $$$OK
}

Method Rename(pFilename As %String, pNewFilename As %String, pNewPath As %String = "") As %Status
{
	$$$ASSERT(""=..Device)
	Set tFullname =..fixPath(..FilePath)_pFilename
	Set tNewFullname =$S(""=pNewPath:..fixPath(..FilePath)_pNewFilename,1:..fixPath(pNewPath)_pNewFilename)
	Set tOK = ##class(%File).Rename(tFullname, tNewFullname)
	if 'tOK Quit $$$EnsError($$$FileCanNotRename,tFullname_" -> "_tNewFullname)
	Quit $$$OK
}

Method PutLine(pFilename As %String, pLine As %String) As %Status [ CodeMode = expression ]
{
..PutString(pFilename, $G(pLine)_..LineTerminator)
}

Method PutString(pFilename As %String, pData As %String) As %Status
{
	Set tSC = ..open(pFilename) Quit:$$$ISERR(tSC) tSC
	Set $ZT="Trap",tSC=$$$OK
	Use ..Device write pData Use ..OldIO
Exit
	Quit ..close()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

Method PutStream(pFilename As %String, pStream As %Stream, ByRef pLen As %Integer = -1) As %Status
{
	#; If a raw temp stream, just rename rather than copying.
	If pStream.%Extends("%Library.FileStreamAdaptor")&&..Overwrite&&..isTemp(pStream) {
		Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable($S("!"=$E(..Charset):$E(..Charset,2,*),1:..Charset))
		If $S(pStream.%IsA("%Library.FileCharacterStream")&&(0'=pStream.TranslateTable):(tTable=pStream.TranslateTable), 1:("RAW"=tTable)) {
			Set tSC=pStream.SaveStream()  Quit:$$$ISERR(tSC) tSC
			Set tFilename=pStream.Filename
			Set tPath=..fixPath(..FilePath)_pFilename
			Set pStream.Filename=tPath
			$$$catTRACE("adapter","Optimization: Renaming file stream from '"_tFilename_"' to '"_tPath_"'")
			Do ##class(%File).Delete(tPath)
			Set tOK=##class(%File).Rename(tFilename,tPath)
			Set:tOK'=1 tSC=$$$ERROR($$$EnsErrGeneral,"PutStream() Rename failed with code "_tOK)
			Quit tSC
		}
	}
	Set tSC = ..open(pFilename) Quit:$$$ISERR(tSC) tSC
	Set $ZT="Trap",tSC=$$$OK
	Use ..Device Set tSC=pStream.OutputToDevice(.pLen) Use ..OldIO
Exit
	Set tSC1=..close() Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

ClassMethod isTemp(pStream) [ CodeMode = expression ]
{
($$$SYSTempDir=$E(pStream.Filename,1,$L($$$SYSTempDir)))
}

Method GetStream(pFilename As %String, ByRef pStream As %Stream.Object = {$$$NULLOREF}) As %Status
{
	If '$IsObject(pStream) {
		If "binary"'=$ZCVT(..Charset,"L") { Set pStream=##class(%GlobalCharacterStream).%New() } Else { Set pStream=##class(%GlobalBinaryStream).%New() }
	}
	Set tSC = ..openRead(pFilename) Quit:$$$ISERR(tSC) tSC
	Set $ZT="Trap",tSC=$$$OK
	Use ..Device Set pLen=##class(%File).GetFileSize(..fixPath(..FilePath)_pFilename), tSC=pStream.InputFromDevice(.pLen) Use ..OldIO
	$$$catTRACE("file","Read "_pStream.Size_" characters from '"_..fixPath(..FilePath)_pFilename_"'")
Exit
	Quit ..close()
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

/// Get a list of files in the directory configured by FilePath.
/// The filenames are returned in a %ListOfDataTypes object. Each entry in the list is
/// a semicolon-separated string containing: Filename;Type;Size;DateCreated;DateModified;FullPathName
Method NameList(Output pFileList As %ListOfDataTypes, pWildcards As %String = "*", pIncludeDirs As %Boolean = 0) As %Status
{
	#; ={$Select($$$isVMS:"*.*",1:"*")}
	Set $ZT="Trap",tSC=$$$OK
	do {
		Kill pFileList Set pFileList=##class(%ListOfDataTypes).%New()
		$$$catTRACE("file","Getting list of filenames for "_..fixPath(..FilePath))
		Set tResultSet=##class(%ResultSet).%New("%File:FileSet")
		Set tSC=tResultSet.Execute(..FilePath,pWildcards,"Type",pIncludeDirs)  Quit:$$$ISERR(tSC)
		While 0'=tResultSet.Next() {
			#; PathName;Type;Size;DateCreated;DateModified;Name
			Set tSC = pFileList.Insert(tResultSet.GetData(6)_";="_tResultSet.GetData(2)_";"_tResultSet.GetData(3)_";created="_tResultSet.GetData(4)_";modified="_tResultSet.GetData(5)_";"_tResultSet.GetData(1))  Quit:$$$ISERR(tSC)
		}
	} while (0)
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

}
