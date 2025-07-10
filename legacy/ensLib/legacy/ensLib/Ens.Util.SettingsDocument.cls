/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Used to load deployable settings documents into Studio.
/// See Ens.Config.DefaultSettings for one use.
Class Ens.Util.SettingsDocument Extends %Studio.AbstractDocument [ ClassType = "", ProcedureBlock, System = 4 ]
{

Projection RegisterExtension As %Projection.StudioDocument(DocumentDescription = "Deployable Settings Document", DocumentExtension = "ESD", DocumentNew = 0, DocumentType = "xml", XMLNamespace = "http://www.intersystems.com/Ensemble/DataSettings");

/* Deployable Settings Document */
Parameter EXTENSION = ".ESD";

/// Load the Deployable Default Settings into the stream Code irrespective of ProductionName set<br>
Method Load() As %Status
{
	Set tSC=$$$OK
	Try {
		Set tSC = ..getDataTableName(..Name,.tDataTableName)
		Quit:$$$ISERR(tSC)
		Set tSC = $CLASSMETHOD(tDataTableName,"%ExportStudioDocuments",..Code)
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
		Set tSC=..getDataTableName(pName,.tDataTableName)
		Quit:$$$ISERR(tSC)
		Do pStream.Rewind()
		Set (tLine,tOldItem,tName)="" While tLine'[" table=" { Set tLine=pStream.ReadLine(,.tSC) Quit:pStream.AtEnd }
		Set f=$F(tLine,"table=") Set:f tOldItem=$P($E(tLine,f+1,*),$E(tLine,f))
		Do pStream.Rewind()
		Set tStream=##class(Ens.Util.XML.Reader).ChangeXMLStreamEncoding(pStream,"") Do tStream.Rewind()
		tstart
		#; Guard against transactions being be closed 
		#dim tLevel = $TLevel
		Set tSC = $Classmethod(tDataTableName,"%ImportStudioDocuments",tStream)
		If ($TLevel>0) && ($TLevel=tLevel) {
			If $$$ISOK(tSC) {
				tcommit
			} Else {
				trollback
			}
		}
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Delete the Default Settings.
ClassMethod Delete(pName As %String) As %Status
{
	Set tSC=..getDataTableName(pName,.tDataTableName)
	Quit:$$$ISERR(tSC) tSC
	Quit $Classmethod(tDataTableName,"%ClearStudioDocuments")
}

/// 
/// Return the timestamp of text document 'pName' in %TimeStamp format, i.e. $zdatetime($horolog,3).
/// This is used to determine if the document has been updated on the server and so needs reloading into Studio.
/// So the format should be $zdatetime($horolog,3), or "" if the category does not exist.
ClassMethod TimeStamp(pName As %String) As %TimeStamp
{
	Set tSC=..getDataTableName(pName,.tDataTableName)
	If $$$ISERR(tSC) Quit ""
	Set ts=$G(^Ens.Configuration("esd",tDataTableName,"time"))
	Quit ##class(Ens.DataType.UTC).LogicalToOdbc($S(""=ts:ts,1:$ZDT(ts,3,,3)))
}

/// Return the compile time of routine 'pName' in %TimeStamp format. The format should be $zdatetime($horolog,3),
/// or "" if the routine does not exist.
ClassMethod CompileTime(pName As %String) As %TimeStamp [ CodeMode = expression ]
{
..TimeStamp(.pName)
}

/// Return 1 if time is defined for the class (e.g. Ens.Config.DefaultSettings).
ClassMethod Exists(pName As %String) As %Boolean
{
	Set tSC=..getDataTableName(pName,.tDataTableName)
	Quit:$$$ISERR(tSC) 0
	Quit ''$data(^Ens.Configuration("esd",tDataTableName,"time"))
}

Query List(Directory As %String, Flat As %Boolean, System As %Boolean) As %Query(ROWSPEC = "name:%String,modified:%TimeStamp,size:%Integer,directory:%String")
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Directory As %String = "", Flat As %Boolean = "", System As %Boolean = "") As %Status
{
	If $G(Directory)'="" Set qHandle="", qHandle("BadDir")=1 Quit $$$OK
	set index=$I(^IRIS.Temp.EnsConfiguration)
	set cat="" for  set cat=$O(^Ens.Configuration("esd",cat)) quit:cat=""  set ^IRIS.Temp.EnsConfiguration(index,cat)=""
	set qHandle=$LB(index,"")
	quit $$$OK
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ListExecute ]
{
	If $G(qHandle("BadDir")) Set Row="", AtEnd=1  Quit $$$OK
	Set tempnode=$LG(qHandle,1),cat=$LG(qHandle,2)
	If (tempnode="") set Row="",AtEnd=1 quit $$$OK
	Set cat=$O(^IRIS.Temp.EnsConfiguration(tempnode,cat))
	Set $LI(qHandle,2)=cat
	If cat="" Set AtEnd=1 Quit $$$OK
	Set Row=$LB(cat_".esd",$G(^IRIS.Temp.EnsConfiguration(tempnode,cat,"time")),0,"")
	If $O(^IRIS.Temp.EnsConfiguration(tempnode,cat))="" set AtEnd=1
	Quit $$$OK
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ListFetch ]
{
	Set tempnode=$LG(qHandle,1)
	If tempnode'="" kill ^IRIS.Temp.EnsConfiguration(tempnode)
	Set qHandle=""
	Quit $$$OK
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
	Set tSC=..getDataTableName(..Name,.tDataTableName)
	Quit:$$$ISERR(tSC) tSC
	Lock +^Ens.Configuration("esd",tDataTableName):0 Else  Quit $$$ERROR($$$CanNotLockRoutine,..Name)
	Set ..Locked=1
	Quit $$$OK
}

/// Lock a document by name.
ClassMethod LockName(name As %String) As %Status
{
	Set tSC=..getDataTableName(name,.tDataTableName)
	Quit:$$$ISERR(tSC) tSC
	Lock +^Ens.Configuration("esd",tDataTableName):0 Else  Quit $$$ERROR($$$CanNotLockRoutine,name)
	Quit $$$OK
}

/// Unlock the current document.
Method Unlock(flags As %String) As %Status
{
	If '..Locked Quit $$$OK
	If ..Locked>1 Set ..Locked=..Locked-1 Quit $$$OK
	Set tSC=..getDataTableName(..Name,.tDataTableName)
	Quit:$$$ISERR(tSC) tSC
	Lock -^Ens.Configuration("esd",tDataTableName)
	Set ..Locked=0
	Quit $$$OK
}

/// Unlock a document by name.
ClassMethod UnlockName(name As %String) As %Status
{
	Set tSC=..getDataTableName(name,.tDataTableName)
	Quit:$$$ISERR(tSC) tSC
	Lock -^Ens.Configuration("esd",tDataTableName)
	Quit $$$OK
}

ClassMethod getDataTableName(name As %String, Output pDataTableName As %String) As %Status [ Private ]
{
	Set pDataTableName = ""
	If $zconvert($extract(name,*-3,*),"U") '= ".ESD" {
		Quit $$$ERROR($$$GeneralError,"Invalid data table filename '"_name_"'")
	}
	Set pDataTableName = $extract(name,1,*-4)
	Quit $$$OK
}

ClassMethod LocalizeDescription(ext As %String, ByRef Description As %String(MAXLEN=500)) As %Status
{
	Set Description = $$$Text("Deployable Settings Document","Ensemble")
	Quit $$$OK
}

/// Return true if this is mapped from a database other than the default routine database and zero otherwise.
/// Also set the source database in <var>sourcedb</var>.
ClassMethod IsMapped(name As %String, ByRef sourcedb As %String) As %Boolean
{
	/*
		The time stamp is stored in ^Ens.Configuration("esd",$e(name,1,*-4))
		but the actual data that is exported/imported is the default global
		for the class e.g. Ens.Util.Schedule or Ens.Config.DefaultSettings
	*/
	Set tGlobal = $$storageGbl^%qarmac($e(name,1,*-4))
	Return ..IsMappedGlobal(tGlobal,.sourcedb)
}

}
