/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Abstract Document used to load a set of LookupTable values into Studio.
Class Ens.Util.LookupTableDocument Extends %Studio.AbstractDocument [ ClassType = "", ProcedureBlock, System = 4 ]
{

Projection RegisterExtension As %Projection.StudioDocument(DocumentExtension = "LUT", DocumentNew = 0, DocumentType = "xml", XMLNamespace = "http://www.intersystems.com/Ensemble/LookupTable");

Parameter EXTENSION = ".LUT";

/// Load the lookup table definition into the stream Code<br>
Method Load() As %Status
{
	Set tSC=$$$OK
	Try {
		Set tSC = ..getTableName(..Name,.tTableName)
		If $$$ISERR(tSC) Quit
		Set tSC = ##class(Ens.Util.LookupTable).%Export(..Code,tTableName)
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Save the lookup table definition document.
Method Save() As %Status
{
	Quit ..ImportStream(..Name,..Code)
}

/// Save the lookup table definition document from stream to global.
ClassMethod ImportStream(pName As %String, pStream As %GlobalCharacterStream) As %Status
{
	Set tSC=$$$OK
	Try {
		#; Find old tItemName name in pStream
		Do pStream.Rewind()
		Set (tLine,tOldItem,tName)="" While tLine'[" table=" { Set tLine=pStream.ReadLine(,.tSC) Quit:pStream.AtEnd }
		Set f=$F(tLine,"table=") Set:f tOldItem=$P($E(tLine,f+1,*),$E(tLine,f))
		Do pStream.Rewind()
		Set tStream=##class(Ens.Util.XML.Reader).ChangeXMLStreamEncoding(pStream,"") Do tStream.Rewind()
		Set tSC = ..getTableName(pName,.tTableName)
		If $$$ISERR(tSC) Quit
		tstart
		Set tSC = ##class(Ens.Util.LookupTable).%Import(tStream,tTableName)
		If $$$ISOK(tSC) {
			#; Schema loaded ok, let's commit it - but first fix name if needed
			Do:tOldItem'=tTableName pStream.Clear(), ##class(Ens.Util.LookupTable).%Export(pStream,tTableName)
			tcommit
		} Else {
			#; Rollback the schema update			
			trollback
		}
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Delete the lookup table definition <var>name</var>.
ClassMethod Delete(name As %String) As %Status
{
	Set tSC = ..getTableName(name,.tTableName)
	If $$$ISERR(tSC) Quit tSC
	Do ##class(Ens.Util.LookupTable).%ClearTable(tTableName)
	Quit $$$OK
}

/// Return the timestamp of lookup table 'name' in %TimeStamp format, i.e. $zdatetime($horolog,3).
/// This is used to determine if the lookup table has been updated on the server and so needs reloading into Studio.
/// So the format should be $zdatetime($horolog,3), or "" if the lookup table does not exist.
ClassMethod TimeStamp(name As %String) As %TimeStamp
{
	If $$$ISERR(..getTableName(name,.tTableName)) Quit ""
	Set tH = $H
	If tTableName '= "" {
		Set tH = ##class(Ens.Util.LookupTable).getTimestamp(tTableName)
		If (tH = "") {
			Set tH = $H
			// For upgraded lookup tables, initialise the timestamp
			If ##class(Ens.Util.LookupTable).%ExistsTable(tTableName) Do ##class(Ens.Util.LookupTable).updateTimestamp(tTableName)
		}
	}
	Quit $ZDT(tH,3,,3)
}

/// Return the compile time of routine 'name' in %TimeStamp format. The format should be $zdatetime($horolog,3),
/// or "" if the routine does not exist.
ClassMethod CompileTime(name As %String) As %TimeStamp [ CodeMode = expression ]
{
..TimeStamp(.name)
}

/// Return 1 if the given lookup table document exists and 0 if it does not.
ClassMethod Exists(name As %String) As %Boolean
{
	If $$$ISERR(..getTableName(name,.tTableName)) Quit 0
	Quit ##class(Ens.Util.LookupTable).%ExistsTable(tTableName)
}

ClassMethod getTableName(name As %String, Output pTableName As %String) As %Status [ Private ]
{
	Set pTableName = ""
	If $zconvert($extract(name,*-3,*),"U") '= ".LUT" {
		Quit $$$ERROR($$$GeneralError,"Invalid lookup table filename '"_name_"'")
	}
	Set pTableName = $extract(name,1,*-4)
	Quit $$$OK
}

Query List(Directory As %String, Flat As %Boolean, System As %Boolean) As %Query(ROWSPEC = "name:%String,modified:%TimeStamp,size:%Integer,directory:%String")
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Directory As %String = "", Flat As %Boolean = "", System As %Boolean = "") As %Status
{
	If $G(Directory)'="" Set qHandle="", qHandle("BadDir")=1 Quit $$$OK
	Quit ##class(Ens.Util.LookupTable).EnumerateExecute(.qHandle)
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ PlaceAfter = ListExecute ]
{
	If $G(qHandle("BadDir")) Set Row="", AtEnd=1  Quit $$$OK
	Set tSC=##class(Ens.Util.LookupTable).EnumerateFetch(.qHandle,.Row,.AtEnd)  Quit:$$$ISERR(tSC) tSC
	Set:Row'="" Row=$LB($LG(Row)_".LUT","","","")
	Quit tSC
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ListFetch ]
{
	Quit ##class(Ens.Util.LookupTable).EnumerateClose(.qHandle)
}

/// Export this document to the current device in XML format
Method ExportToXML(flags As %String) As %Status
{
	Write $C(10)
	Do ..Code.Rewind()
	Set ..Code.LineTerminator=$C(10)
	Do ..Code.ReadLine() ; skip xml declaration line
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

/// Lock the current document.
/// If it fails then return a status code of the error, otherise return $$$OK
Method Lock(flags As %String) As %Status
{
	If ..Locked Set ..Locked=..Locked+1 Quit $$$OK
	Set tSC = ..getTableName(..Name,.tTableName)
	If $$$ISERR(tSC) Quit tSC
	Lock +^Ens.LookupTable(tTableName):0 Else  Quit $$$ERROR($$$CanNotLockRoutine,..Name)
	Set ..Locked=1
	Quit $$$OK
}

/// Lock a document by name.
ClassMethod LockName(name As %String) As %Status
{
	Set tSC = ..getTableName(name,.tTableName)
	If $$$ISERR(tSC) Quit tSC
	Lock +^Ens.LookupTable(tTableName):0 Else  Quit $$$ERROR($$$CanNotLockRoutine,name)
	Quit $$$OK
}

/// Unlock the current document.
Method Unlock(flags As %String) As %Status
{
	If '..Locked Quit $$$OK
	If ..Locked>1 Set ..Locked=..Locked-1 Quit $$$OK
	Set tSC = ..getTableName(..Name,.tTableName)
	If $$$ISERR(tSC) Quit tSC
	Lock -^Ens.LookupTable(tTableName)
	Set ..Locked=0
	Quit $$$OK
}

/// Unlock a document by name.
ClassMethod UnlockName(name As %String) As %Status
{
	Set tSC = ..getTableName(name,.tTableName)
	If $$$ISERR(tSC) Quit tSC
	Lock -^Ens.LookupTable(tTableName)
	Quit $$$OK
}

/// Return true if this is mapped from a database other than the default routine database and zero otherwise.
/// Also set the source database in <var>sourcedb</var>.
ClassMethod IsMapped(name As %String, ByRef sourcedb As %String) As %Boolean
{
	Do ..getTableName(name,.tTableName)
	Set tGlobal = $name(^Ens.LookupTable(tTableName))
	Return ..IsMappedGlobal(tGlobal,.sourcedb)
}

}
