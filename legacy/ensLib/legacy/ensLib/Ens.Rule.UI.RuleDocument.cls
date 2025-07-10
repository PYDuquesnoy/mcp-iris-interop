/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Abstract Document used to load Business Rules into Studio.
Class Ens.Rule.UI.RuleDocument Extends %Studio.AbstractDocument [ ClassType = "", ProcedureBlock, System = 4 ]
{

Projection RegisterExtension As %Projection.StudioDocument(DocumentDescription = "Legacy Rule Document", DocumentExtension = "RUL", DocumentNew = 0, DocumentType = "xml");

Parameter EXTENSION = ".rul";

/// Return 1 if the given Rule document exists and 0 if it does not.
ClassMethod Exists(name As %String) As %Boolean
{
	try {
		set tExists=$classmethod($piece(name,".",1,$length(name,".")-1),"%Extends","Ens.Rule.Definition")
	} catch {
		set tExists=0
	}
	quit tExists
}

/// Delete the Business Rule <var>name</var>.
ClassMethod Delete(name As %String) As %Status
{
	quit $system.OBJ.Delete($piece(name,".",1,$length(name,".")-1))
}

/// Make the XML export export the class instead of this studio document which is only the XData.
ClassMethod TranslateExportName(name As %String, ByRef items As %String) As %Status
{
	Kill items(name)
	Set items($piece(name,".",1,$length(name,".")-1)_".cls")=""
	Quit $$$OK
}

Method ImportFromXML(stream As %RegisteredObject, flags As %String) As %Status
{
	Do ..Code.Clear()
	Do ..Code.CopyFrom(stream)
	Quit $$$OK
}

/// Save the rule document.
Method Save() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Write !!,"Saving Business Rule ",..Name,"...",!
	Do {
		Do ..Code.Rewind()
		Set tFullName = $P(..Name,".",1,$L(..Name,".")-1)
		Set tHost = $P(tFullName,".",1,$L(tFullName,".")-1)
		Set tName = $P(tFullName,".",$L(tFullName,"."))
		Set tSC = ##class(Ens.Rule.RuleDefinition).Load("stream",..Code,1,,tHost,tName)
		If $$$ISERR(tSC) Quit
		if '+$g(^EnsPortal.Settings("UseOldRule")) {
			Write "Upgrading Business Rule ",..Name,"...",!
			Set tSC = ##class(Ens.Rule.Upgrade).ConvertOne(tHost,tName,.tClassname,"/nocompile/delete")
			If $$$ISERR(tSC) Quit
			Write "Converted rule to class ",tClassname,!
		}
		Write "Saved successfully."
	} While(0)
Exit
	Write !
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// CompileDocument is called when the document is to be compiled
Method CompileDocument(ByRef qstruct As %String) As %Status
{
	Set tFullName = $P(..Name,".",1,$L(..Name,".")-1)
	Set tHost = $P(tFullName,".",1,$L(tFullName,".")-1)
	Set tName = $P(tFullName,".",$L(tFullName,"."))
	Set tClassname=##class(Ens.Rule.Upgrade).ConvertRulenameToClassname(tHost,tName)
	Quit $system.OBJ.Compile(tClassname,$get(qstruct))
}

ClassMethod LocalizeDescription(ext As %String, ByRef Description As %String(MAXLEN=500)) As %Status
{
	Set Description = $$$Text("Legacy Rule Document","Ensemble")
	Quit $$$OK
}

}
