/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.Base [ Abstract, System = 4 ]
{

ClassMethod ClassifierPropName(i As %Integer) As %String
{
	#dim name As %String

	set name = $j(i,3)
	set name = $tr(name," ",0)
	Quit "T"_name
}

ClassMethod ClassifierPCName(i As %Integer) As %String
{
	#dim name As %String

	set name = $j(i,2)
	set name = $tr(name," ",0)
	Quit "cz"_name
}

ClassMethod GetAttributeList(className As %String, Output list As %List) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim name As %String
	
	Try {
		set name = className_"||Attributes"
		set pDef = ##class(%Dictionary.CompiledParameter).%OpenId(name,,.sc)
		Quit:$$$ISERR(sc)
		
		if (pDef = "") {
			set sc = $$$ERROR($$$GeneralError,"Class or paramter not found: "_name)
			Quit
		}
		
		set list = pDef.Default
		if (list = "") {
			set sc = $$$ERROR($$$GeneralError,"Attribute list is not defined: "_name)
			Quit
		}
		
		set list = $lfs(list)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

/// BDB473 - "current" PMML definition. It is up to the operator's apply() method to
/// append relevant sections to this PMML definition based on the action the operator represents.
Property PMML As %DeepSee.PMML.Definition.PMML;

}
