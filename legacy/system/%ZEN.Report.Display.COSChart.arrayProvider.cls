/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.arrayProvider Extends (%ZEN.Report.Display.node, abstractController) [ Deprecated, System = 4 ]
{

/// The method called has three parameters<br/>
/// ByRef tParameters is parameters passed into the call back <br/>
/// Output tMetaData is a $LB list <br/>
/// Output tData is a $LB list <br/>
Property OnGetArray As %ZEN.Datatype.string;

Property parameters As %ZEN.Datatype.csv;

Method %DrawToHTML(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Set tSC=$$$OK
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	$$$groupNumInc
	Set %context("id")=$$$groupNum
	// fill in abstractController fields from onGetArray	
	do ..GetArray()
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	quit tSC
}

Method %DrawToXSLFO(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Set tSC=$$$OK
	d ..%BeginDrawFo(.context,.XSL,.delay)
	$$$groupNumInc
	Set %context("id")=$$$groupNum
	// fill in abstractController fields from onGetArray
	do ..GetArray()
	d ..%EndDrawFo(.context,.XSL,.delay)
	quit tSC
}

Method GetArray()
{
	if ..OnGetArray'="" {
		if ..parameters'="" {
			for i=1:1:$L(..parameters,",") {
				Set tParameters($P(..parameters,",",i))=""
			}
		}
		//try {
			do $zobjmethod(%report,..OnGetArray,.tParameters,.tMetaData,.tData,$this)
			do ..dataBag.%SetPropertyList($LISTTOSTRING(tMetaData))
			//Set ..dataBag.seriesCount = $LL(tMetaData)
			Set ..dataBag.seriesCount = ##class(scoreCard).length(.tData)
			Set seriesSize = ##class(scoreCard).length(.tData)
			For s = 1:1:seriesSize {

				Set tOff = (s-1) * $LL(tMetaData)

				For n = 1:1:$LL(tMetaData) {

					Set tProp = $LI(tMetaData,n)
#if 0					
					s t=$io u 0 w !,"s="_s_" n="_n_" tProp="_tProp u t
#endif					
					Set ..dataBag.%data(s,tProp) = $LI(tData(s-1),n)

				}

			}
			
		//}
		//catch {
		//}
		do ..dataBag.%SerializeData()
		Set ..dataLoaded=1
	}
}

Method getDimSize(dim) As %Integer
{
	do $zobjmethod(%report,..OnGetArray,.tParameters,.tMetaData,.tData,$this)
	Set length=##class(scoreCard).length(.tData)
	quit $case(dim,1:length, 2:$LL(tMetaData), :0)
}

}
