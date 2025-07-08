/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is class is used to add support for the DataModel interface to a persistent class.
Class %ZEN.DataModel.Adaptor Extends %ZEN.DataModel.ObjectDataModel [ Abstract, Deprecated, System = 4 ]
{

/// Set this false so that dynamic properties do not inadvertently
/// interfere with the user's persistent object.
Parameter DYNAMICPROPERTIES = 0;

/// Create an instance of this DataModel object.<br>
/// Subclasses may override this for special behavior.
ClassMethod %CreateModelInstance(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject [ CodeMode = objectgenerator ]
{
	Set %code.CodeMode = "expression"
	Set tType = $$$getClassType(%compiledclass.Name)
	If (tType = "persistent") {
		Do %code.Write("$S(pID="""":..%New(),1:..%OpenId(pID,pConcurrency,.pSC))")
	}
	Else {
		Do %code.Write("..%New()")
	}
	Quit $$$OK
}

/// This callback method is invoked when a DataModel is opened.
/// If implemented, it opens an instance of the data source object
/// used by the DataModel.
Method %OnOpenSource(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject [ CodeMode = expression ]
{
$this
}

/// This callback method is called when the DataModel is saved. If
/// implemented, it is responsible for saving changes to the data source.
Method %OnSaveSource(pSource As %RegisteredObject) As %Status [ CodeMode = objectgenerator ]
{
	Set tType = $$$getClassType(%compiledclass.Name)
	If (tType = "persistent") {
		Do %code.Write(" Set tSC = ..%Save()")
		Do %code.Write(" Set:$$$ISOK(tSC) ..%id = ..%Id()")
		Do %code.Write(" Quit tSC")
	}
	Else {
		Do %code.Write(" Quit $$$OK")
	}
	Quit $$$OK
}

/// This callback method is called when the DataModel is deleted.
ClassMethod %OnDeleteSource(pID As %String) As %Status [ CodeMode = objectgenerator ]
{
	Set %code.CodeMode = "expression"
	Set tType = $$$getClassType(%compiledclass.Name)
	If (tType = "persistent") {
		Do %code.Write("..%DeleteId(pID)")
	}
	Else {
		Do %code.Write("$$$OK")
	}
	Quit $$$OK
}

}
