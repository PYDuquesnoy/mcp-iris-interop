/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.UserLibrary.TermList Extends (%RegisteredObject, %DeepSee.UserLibrary.UserData)
{

Parameter XMLNAME = "termlist";

Property FullName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute") [ SqlComputeCode = { Set {FullName} = {name}_"."_$$$DSTLExt }, SqlComputed, Transient ];

Property name As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property caption As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property description As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property pattern As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property modDate As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property subjectArea As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property fieldListString As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property hideValue As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property keyList As list Of %String;

Property fieldList As list Of %String;

Property valueList As array Of %String;

Method %Save() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.TermList).%FromObj($this)
	}
	Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

ClassMethod %ExistsId(pID As %String = "") As %Boolean
{
	Quit ##class(%DeepSee.TermList).%TermListExists(pID)
}

ClassMethod %OpenId(pID As %String = "") As %DeepSee.UserLibrary.TermList
{
	Quit ##class(%DeepSee.TermList).%ToObj(pID)
}

ClassMethod %DeleteId(pID As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.TermList).%DeleteTermList(pID)
	}
	Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

Method getIdentifier() As %String
{
	Quit $$$UPPER(..name)
}

}
