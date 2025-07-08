/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

IncludeGenerator (%occUtility, %DeepSee)

/// Utility class that provides an API for testing
/// DeepSee queries.
Class %DeepSee.QueryTest Extends %RegisteredObject [ System = 3 ]
{

/// Return list of test queries defined within this class.
ClassMethod %ListQueries(Output pInfo) [ CodeMode = objectgenerator, Final, Internal ]
{
	Set tSC = $$$OK
	If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition")) { // !!!
		Do %code.WriteLine(" Quit """"")
		Quit tSC
	}

	// find all XData blocks
	For n = 1:1:%compiledclass.XDatas.Count() {
		Set tXData = %compiledclass.XDatas.GetAt(n)
		Do %code.WriteLine(" Set pInfo("_$$$quote(tXData.Name)_") = " _ n)
	}
	Quit tSC
}

/// Return the test specification object with given (XData) name.
ClassMethod %GetTestSpec(pName As %String, Output tSC As %Status) As %DeepSee.TestSpec
{
	Set tSC = $$$OK
	Set tSpec = ""

	Do ..%ListQueries(.tList)
	Set n = $G(tList(pName))
	If (n = "") {
		Set tSC = $$$ERROR($$$GeneralError,"Test not found: "_pName)
		Quit ""
	}
	Else {
		Set cdef = ##class(%Dictionary.CompiledClass).%OpenId(..%ClassName(1))
		Set tXData = cdef.XDatas.GetAt(n)
		Set tStream = tXData.Data
		Do tStream.Rewind()
		If (tStream.Size > 0) {

			Set tReader = ##class(%XML.Reader).%New()

			Set tSC = tReader.OpenStream(tStream)
			If $$$ISERR(tSC) Quit

			Do tReader.Correlate("test","%DeepSee.TestSpec")

			Do tReader.Next(.tSpec,.tSC)
			If $$$ISERR(tSC) Quit
		}
	}
	Quit tSpec
}

/// Run all the test queries.
ClassMethod %Run(pUseCache As %Boolean = 0, pTrace As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Set tCount = 0
	Set tErrCount = 0
	Do ..%ListQueries(.tQueries)
	Set tName = $O(tQueries(""))
	While (tName '= "") {
		Set tCount = tCount + 1
		Write "Running query ",tName,!
		Set tSC = ..%RunQuery(tName,pUseCache,pTrace)
		If $$$ISERR(tSC) {
			Set tErrCount = tErrCount + 1
			Set tErrors(tErrCount,"name") = tName
			Set tErrors(tErrCount,"sc") = tSC
			Set tSC = $$$OK
		}
		Set tName = $O(tQueries(tName))
	}

	Write !,"TEST COMPLETE: "
	Write tCount," queries run with ",tErrCount," error(s)",!

	For n = 1:1:tErrCount {
		Write !,"ERROR EXECUTING QUERY '",tErrors(n,"name"),"':"
		Do $System.Status.DisplayError(tErrors(n,"sc"))
	}

	Quit tSC
}

/// Run the specified test query.
ClassMethod %RunQuery(pName As %String, pUseCache As %Boolean = 0, pTrace As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSpec = ..%GetTestSpec(pName,.tSC)
		If $$$ISERR(tSC) Quit

		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tRS.%UseCache = pUseCache
		Set tRS.%Trace = pTrace

		Set tSC = tRS.%PrepareMDX(tSpec.query)
		If $$$ISERR(tSC) Quit

		Set tSC = tRS.%Execute()
		If $$$ISERR(tSC) Quit

		Do tRS.%Print(.tPrintStats)

		Set tFacts = ##class(%DeepSee.Utils).%GetCubeFactCount(tRS.%Cube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tCellWidth = 20
		Write "Cells: ",?15,$J($FN($G(tPrintStats("cells")),","),tCellWidth),!
		Write "Empty Cells: ",?15,$J($FN($G(tPrintStats("empty")),","),tCellWidth),!
		Write "Total: ",?15,$J($FN($G(tPrintStats("total")),","),tCellWidth),!
		Write "Facts: ",?15,$J($FN(tFacts,","),tCellWidth),!
		Write !

		Do tRS.%PrintStatistics()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(tSC)
	}


	Quit tSC
}

}
