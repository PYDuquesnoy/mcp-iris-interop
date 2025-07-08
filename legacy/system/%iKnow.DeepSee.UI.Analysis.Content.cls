/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.DeepSee.UI.Analysis.Content Extends %iKnow.DeepSee.UI.Analysis.AbstractAnalysis [ Deprecated, System = 4 ]
{

/// This parameter specifies the name of the Listing that will be selected by default for
/// displaying facts in the tables on this page if the user didn't select any other listing
/// explicitly.
Parameter DEFAULTLISTINGNAME = "ShortListing";

/// The name of the listing currently selected by the user.
Property listingName As %ZEN.Datatype.string(ZENURL = "LISTING");

/// The name of the cube to which the selected measure actually belongs
Property baseCube As %ZEN.Datatype.string(ZENURL = "BASECUBE");

/// The name of the measure, without any relationship prefixes
Property baseMeasure As %ZEN.Datatype.string(ZENURL = "BASEMEASURE");

Property backgroundTimerInterval As %ZEN.Datatype.integer [ InitialExpression = 500 ];

ClassMethod %GetAnalysisInfo(Output pInfo) As %Status
{
	Set pInfo("caption") = $$$Text("Content Analysis")
	Set pInfo("tooltip") = $$$Text("Display the iKnow Content Analysis page")
	Set pInfo("icon") = "portal/logo_48x48.png"
	Set pInfo("rank") = ""
	Quit $$$OK
}

///  Contents of the dialog body.
XData dialogBodyContent [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup width="100%" height="100%">
<hgroup id="grpControls" labelPosition="left" >
<pane paneName="paneSelMeasure" />
<spacer width="20" />
<select id="selListing" onchange="zenPage.changeListingClient();" showEmpty="true" label="Display listing" />
</hgroup>
<spacer height="20" />
<titleBox title="Most typical facts" width="100%" />
<spacer height="10" />
<html id="htmlTypical" OnDrawContent="DrawFactList" seed="typical" />
<spacer height="20" />
<titleBox title="Most breaking facts" width="100%" />
<spacer height="10" />
<html id="htmlBreaking" OnDrawContent="DrawFactList" seed="breaking" />
</vgroup>
</pane>
}

Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("iKnow Content Analysis")
}

Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Analyze the unstructured data for a cell with iKnow.")
}

ClassMethod BuildOverlaps(pDomainId As %Integer, pFilter As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		do ..%SetBackgroundMethodStatus("loading...")
		
		set tFilter = ##class(%iKnow.Filters.Filter).RestoreFilterFromString(pFilter)
		set tSC = ##class(%iKnow.Semantics.DominanceAPI).BuildOverlap(pDomainId, pFilter)
		quit:$$$ISERR(tSC)
		
		kill ^IRIS.Temp.IKT.Bgr(+$j)
		
		job ..BuildFactList(pDomainId, pFilter, "breaking", +$j)::10
		quit:'$test  // throw error?
		
		job ..BuildFactList(pDomainId, pFilter, "typical", +$j)::10
		quit:'$test // throw error?
		
		for {
			if '$d(^IRIS.Temp.IKT.Bgr(+$j,"breaking"),tBreaking)
					|| '$d(^IRIS.Temp.IKT.Bgr(+$j,"typical"),tTypical) {
				hang 1
				continue
			}
			
			if $$$ISERR(tBreaking) { set tSC = tBreaking }
			elseif $$$ISERR(tTypical) { set tSC = tTypical }
			
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	do ..%EndBackgroundMethod()
	quit tSC
}

Method OnChangeMeasure() As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		
		// populate selListing
		// BDB323 - find the real cube behind this measure
		set tMeasure = ..measureName, tCube = ..cubeName
		while $find(tMeasure,".") {
			set tRelationship = $piece(tMeasure,".",1), tMeasure = $piece(tMeasure,".",2,999)
			set tCube = ##class(%DeepSee.Utils).%GetRelatedCube(tCube, tRelationship)
		}
		set ..baseMeasure = tMeasure, ..baseCube = tCube
		
		set tSC = ##class(%DeepSee.Utils).%GetCubeListings(..baseCube, .tListings, "table")
		quit:$$$ISERR(tSC)
		
		set i="", tValueList="", tDisplayList=""
		for {
			set i = $order(tListings(i),1,tData)
			quit:i=""
			continue:i="$$$CUSTOM"
			set tValueList = tValueList _ "," _ $replace(i,",","\,")
			set tDisplayList = tDisplayList _ "," _ $replace($li(tData,1),",","\,")
		}
		set tSelListing = ..%GetComponentById("selListing")
		set tSelListing.valueList = $e(tValueList,2,*)
		set tSelListing.displayList = $e(tDisplayList,2,*)
		
		kill %session.Data("_tables")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method PopulateTables() [ ZenMethod ]
{
	set tSC = $$$OK
	try{
		// launch overlap building
		set tSC = ..%RunBackgroundMethod("BuildOverlaps", ..domain, ..filter)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawFactList(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		if '$d(%session.Data("_tables",pSeed)) {
			write "building..."
			quit
		}
		
		// find listing fieldList
		set tCube = ..baseCube
		merge tListingInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCube),"listing")
		set tDefaultListing = $g($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCube),"defaultListing"))
		for tListingName = ..listingName, ..#DEFAULTLISTINGNAME, tDefaultListing, $o(tListingInfo("")) {
			continue:tListingName=""
			continue:$g(tListingInfo(tListingName,"listingType"),"table")="map"
			for tListingType = "fieldList","sql" {
				set tListing = $g(tListingInfo(tListingName,tListingType))
				quit:tListing'=""
			}
			quit:tListing'=""
		}
		
		// error out if we did not find any decent listing
		if (tListing="") {
			set tSC = $$$ERROR($$$GeneralError, "Please select a Listing")
			quit
		}
		
		set tTable = ##class(%DeepSee.Utils).%GetSQLTableName($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCube),"sourceClass"))
		set tTable = ##class(%iFind.Utils).QuoteDelimitedIdentifier(tTable)
		if (tListingType = "fieldList") {
			set tQuery = "SELECT "_tListing_" FROM "_tTable_" WHERE %ID = ?"
		} else {
			// BDB319 - for sql-based listings, replace $$$RESTRICT and $$$SOURCE
			set tQuery = $replace($replace(tListing, "$$$SOURCE", tTable), "$$$RESTRICT", "%ID = ?")
		}
		
		// BDB301: remove $$$IKSUMMARY and $$$IKLINK entries. there's a link to 
		// the full MeasureValue.zen display page so the summary nor link have a purpose
		// of their own
		set tMaxPos = $length(tQuery)
		for tMacro = "$$$IKSUMMARY","$$$IKLINK" {
			set tIKPos = $find(tQuery, tMacro)
			while (tIKPos) {
				set tLoopPos=tIKPos-1
				set tInBrackets = 0, tInQuotes=0
				while $i(tLoopPos)<=tMaxPos {
					set tChar=$e(tQuery,tLoopPos)
					set:(tChar="""") tInQuotes=1-tInQuotes
					continue:tInQuotes
					set:(tChar="[") tInBrackets=1
					set:(tChar="]") tInBrackets=0
					continue:tInBrackets
					quit:(tChar=",")
					quit:$$$UPPER($e(tQuery,tLoopPos,tLoopPos+5))=" FROM "
				}
				
				// BDB334 - track back to erase any spaces before the $$$IK*, right up to the preceding
				// comma or SELECT keyword
				set tBackPos=tIKPos-$l(tMacro)
				while ($e(tQuery,tBackPos)'=",") && (tBackPos>8) { 
					set tBackPos = tBackPos - 1 
				}
				
				set tQuery = $e(tQuery,1,tBackPos-1) _ $e(tQuery,tLoopPos,*)
				set tIKPos = $find(tQuery, tMacro)
			}
		}
		// if we stripped off the first column, we have "SELECT , bla, bla..." !
		if ($f($zstrip(tQuery,"*W"),",")=8) {
			set tQuery = "SELECT "_$p(tQuery,",",2,9999)
		}
		
		set tRS = ##class(%ResultSet).%New()
		set tSC = tRS.Prepare(tQuery)
		quit:$$$ISERR(tSC)
		
		write "<table class=""factList"">"
		
		// loop through rows
		merge tFacts = %session.Data("_tables",pSeed)
		set i="", isFirst=1
		for {
			set i = $order(tFacts(i),1,tData)
			quit:i=""
			
			set tFactId = $li(tData,1), tScore = $li(tData,3)
			set tObjId = ##class(%iKnow.DeepSee.CubeUtils).GetSourceObjectId(tCube, tFactId)
			
			set tSC = tRS.Execute(tObjId)
			quit:$$$ISERR(tSC)
			
			do tRS.Next(.tSC)
			quit:$$$ISERR(tSC)
			
			// print header if first row
			if (isFirst) {
				write "<tr><th>&nbsp;</th>"
				for j = 1:1:tRS.%ResultColumnCount {
					write "<th>"_tRS.GetColumnName(j)_"</th>"
				}
				write "<th>Score</th></tr>"
				set isFirst=0
			}
			
			write "<tr><td><a href=""javascript:zenPage.showIKnowMsrValue('"_tCube_"','"_..baseMeasure_"','"_tObjId_"');""><img style=""height:16px;"" src=""deepsee/ds2_magnify_44.png"" title=""",..baseMeasure,""" /></a></td>"
			
			for j = 1:1:tRS.%ResultColumnCount {
				set tValue = tRS.GetData(j)
				write "<td>"_$e(tValue,1,40)_$s($length(tValue)>40:"...", 1:"")_"</td>"
			}
			
			write "<td class=""colScore"">"_$normalize(tScore,0)_"</td></tr>"
		}
		quit:$$$ISERR(tSC)
		
		write "</table>"
	
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

ClassMethod BuildFactList(pDomainId As %Integer, pFilter As %String, pSeed As %String, pJobId As %Integer) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {	
		set tFilter = ##class(%iKnow.Filters.Filter).RestoreFilterFromString(pFilter)
		
		// gather sources to display
		if (pSeed = "typical") {
			set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetTypicalSources(.tFacts, pDomainId, 1, 5,, tFilter)
		} elseif (pSeed = "breaking") {
			set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetBreakingSources(.tFacts, pDomainId, 1, 5,, tFilter)
		}
		quit:$$$ISERR(tSC)
		
		merge ^IRIS.Temp.IKT.Bgr(pJobId, pSeed) = tFacts
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	set ^IRIS.Temp.IKT.Bgr(pJobId, pSeed) = tSC
	quit tSC
}

/// Perform a showIKnowMsrValue action, if supported.
ClientMethod showIKnowMsrValue(cube, measure, id) [ Language = javascript ]
{
	var parms = {
			CUBE:cube,
			MEASURE:measure,
			OBJIDS:id
			};
			
	zenLaunchPopupWindow('_iKnow.DeepSee.UI.MeasureValue.zen',measure,'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

ClientMethod changeListingClient() [ Language = javascript ]
{
	var sc = zenPage.setProperty('listingName', zen('selListing').getValue());
	zen('htmlTypical').refreshContents();
	zen('htmlBreaking').refreshContents();
}

XData Style
{
<style type="text/css">
table.factList {
	border: 1px solid black;
	font-size: 12px;
	margin: 0px;
}

table.factList th {
	background-color: #356B8D;
	color: white;
	margin: 0px;
	padding: 2px;
}

table.factList td {
	background-color: white;
	margin: 0px;
	padding: 2px;
}

table.factList a {
	color: #356B8D;
}

table.factList td.colScore {
	text-align: right;
}
</style>
}

ClassMethod %OnFinishBackgroundTask(pTaskID As %String)
{
	kill %session.Data("_tables")
	merge %session.Data("_tables") = ^IRIS.Temp.IKT.Bgr(pTaskID)
	kill ^IRIS.Temp.IKT.Bgr(pTaskID)
	&js<
		zen('htmlTypical').refreshContents();
		zen('htmlBreaking').refreshContents();
	>
}

ClientMethod onChangeMeasureClient() [ Language = javascript ]
{
	zenPage.PopulateTables();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.PopulateTables();
}

}
