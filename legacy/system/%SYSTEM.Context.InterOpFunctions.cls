/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %Integration.Context

Class %SYSTEM.Context.InterOpFunctions Extends %Library.SystemBase
{

/// Array using $namespace first subscript - Case sensitive
/// Second subscript is method name uppercase
Property functions As %RawString [ MultiDimensional ];

Method %OnNew(pNamespace = {$namespace}) As %Library.Status
{
	#dim tSC = $$$OK

	Set tSC = ..populateFunctions(pNamespace)

	Quit tSC
}

Method GetFunctionDetails(pFunction As %String, Output pSC As %Status = {$$$OK}, pNamespace As %String = {$namespace}) As %String
{
	#dim tLastBuilt
	If '$Data(..functions(pNamespace),tLastBuilt)#2 || ..outOfDate(tLastBuilt) {
		Set pSC = ..populateFunctions(pNamespace)
		If $$$ISERR(pSC) Quit ""
	}

	Quit $Get(..functions(pNamespace,$ZCVT(pFunction,"U")),"")
}

Method GetFunctionSet(Output pArray, pNamespace As %String = {$namespace}) As %Status
{
	#dim tSC = $$$OK
	Kill pArray

	#dim tLastBuilt

	If '$Data(..functions(pNamespace),tLastBuilt)#2 || ..outOfDate(tLastBuilt) {
		Set tSC = ..populateFunctions(pNamespace)
		If $$$ISERR(tSC) Quit tSC
	}

	Merge pArray = ..functions(pNamespace)
	Quit tSC
}

Method outOfDate(pLastBuilt As %String) As %Boolean
{
	#; When a function set class is compiled it sets one central global - shared by all namespaces.
	#; Must be in a database that is r/w even in mirror failover. No need for journal

	#dim tUpTime

	#; If not defined then take as up to date
	#; If failed over then new processes would have recreated based on empty ..functions array
	#; Chance of being out of date is if central global removed manually after the process has built the list.
	#; If this is the case recompiling a function set class will reset.
	If '$Data($$$interopFunctionSetsRoot,tUpTime)#2 Quit 0

	Quit (tUpTime > pLastBuilt)
}

Method clearContext(pNamespace As %String = {$namespace})
{
	Kill ..functions(pNamespace)
}

Method populateFunctions(pNamespace As %String = {$namespace}) As %Status
{
	#dim tSC = $$$OK
	#dim e As %Exception.AbstractException

	#dim tArray

	Try {

		#; Don't check if interoperability namespace - let call to buildFunctionSet fail

		New $Namespace
		Set $namespace = pNamespace

		Do ..clearContext(pNamespace)

		Set tSC = ##class(Ens.Rule.Utilities).buildFunctionSet(.tArray)
		If $$$ISERR(tSC) Quit

		Merge ..functions(pNamespace) = tArray
		Set ..functions(pNamespace) = $ZH

	} Catch e {

		Set tSC = e.AsStatus()

	}

	Quit tSC
}

}
