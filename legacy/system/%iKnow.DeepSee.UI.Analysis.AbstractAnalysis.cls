/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %IKInclude)

Class %iKnow.DeepSee.UI.Analysis.AbstractAnalysis Extends %DeepSee.UI.Analysis.AbstractAnalysis [ Abstract, Deprecated, System = 4 ]
{

Property domain As %ZEN.Datatype.integer;

Property filter As %ZEN.Datatype.string;

Property page As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// Whether or not to build cell-level filters as well
Parameter BUILDCELLFILTERS [ Internal ] = 0;

Method BuildIKnowFilters(pIKnowMeasure As %String) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		quit:pIKnowMeasure=""
		
		set tRS = ##class(%DeepSee.ResultSet).%New()
		set tSC = tRS.%PrepareKey(..cubeName,..queryKey)
		quit:$$$ISERR(tSC)

		// create drill through out of current query
		Set r1 = +$P(..selectedRange,",",1)
		Set c1 = +$P(..selectedRange,",",2)
		Set r2 = +$P(..selectedRange,",",3)
		Set c2 = +$P(..selectedRange,",",4)
		Set tAllRows = +$P(..selectedRange,",",5)
		Set tAllCols = +$P(..selectedRange,",",6)
		Set:r1=0 r1=1
		Set:c1=0 c1=1
		Set:r2=0 r2=r1
		Set:c2=0 c2=c1
		
		// first create per-cell filters:
		if ..#BUILDCELLFILTERS {
			kill ^||%IK.CellFilters, ^||%IK.CellFilterHashes
			for r = r1:1:r2 {
				for c = c1:1:c2 {
					set tSC = ..BuildIKnowFilterForCell(pIKnowMeasure, .tRS, r, c, 0, 0, .tFilters, .tCellId)
					quit:$$$ISERR(tSC)
					
					// store filters to build meaningful name
					merge ^||%IK.CellFilters(tCellId) = tFilters
					set i = "" 
					for {
						set i = $order(tFilters(i),1,tFilter)
						quit:i=""
						set x = $i(^||%IK.CellFilterHashes($zcrc(tFilter,7)))
					}
				}
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
			// now add names for all filters that occur < # cells
			set cellCount = $order(^||%IK.CellFilters(""),-1), tCellId=""
			for {
				set tCellId = $order(^||%IK.CellFilters(tCellId))
				quit:tCellId=""
				
				set tFilterId = "", tName=""
				for {
					set tFilterId = $order(^||%IK.CellFilters(tCellId,tFilterId),1,tFilter)
					quit:tFilterId=""
					
					if (^||%IK.CellFilterHashes($zcrc(tFilter,7)) < cellCount) {
						set tName = tName _ ", " _ $e($p(tFilter,".&[",2),1,*-1)
					}
				}
				set $li(%session.Data("_cells", tCellId),3) = $e(tName,3,*)
			}
		}
		
		// and now build a filter to span all selected cells as a whole
		Set tSC = tRS.%GetFiltersForCellRange(.tListingFilters,r1,c1,r2,c2,.tSlicerMeasure,tAllRows,tAllCols,..sortColumn,..sortDir)
		If $$$ISERR(tSC) Quit

		Set tWITH = ""
		Set:..withClause'="" tWITH = " WITH " _ ..withClause _ " "

		Set tMDX = "DRILLFACTS "_tWITH_" SELECT FROM [" _ tRS.%GetCubeName() _"]"
		Set kf = $O(tListingFilters(""))
		While (kf'="") {
			Set tClause = tListingFilters(kf)
			If (tClause'="") {
				Set tMDX = tMDX _ " %FILTER " _ tClause
			}
			Set kf = $O(tListingFilters(kf))
		}

		// create new query
		Set tRS = ##class(%DeepSee.ResultSet).%New()

		Set tSC = tRS.%PrepareMDX(tMDX)
		If $$$ISERR(tSC) Quit
		
		// TODO: work around Listing limitations!
		set tRS.listingPageSize = ##class(%DeepSee.Utils).%GetCubeFactCount(..cubeName)
		
		// DTB316 - If applicable, set the parentQueryKey to allow use of axes locked by the parent query. 
		// Do not assume the %query object exists when this is called.
		If ($G(%query)'="")&&$IsObject(%query)&&%query.%IsA("%DeepSee.Query.query") {
			Set tRS.%Query.parentQueryKey = $S(%query.parentQueryKey'="":%query.parentQueryKey,1:%query.%QueryKey)
		}

		Set tSC = tRS.%Execute()
		If $$$ISERR(tSC) Quit

		// make sure listing is executed
		Set tSC = tRS.%ExecuteListing(1)
		If $$$ISERR(tSC) Quit
		
		set tFilter = ##class(%iKnow.DeepSee.ListingKeyFilter).%New(..cubeName, pIKnowMeasure, tRS.%GetQueryKey())
		set ..filter = tFilter.ToString()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method BuildIKnowFilterForCell(pIKnowMeasure As %String, ByRef pRS As %DeepSee.ResultSet, pRow As %Integer, pCol As %Integer, pAllRows As %Boolean, pAllCols As %Boolean, Output pFilters, Output pCellId As %Integer) As %iKnow.Filters.Filter
{
	set tSC = $$$OK, tFilter=""
	try {
		kill pFilters
		Set tSC = pRS.%GetFiltersForCellRange(.pFilters,pRow,pCol,pRow,pCol,.tSlicerMeasure,pAllRows,pAllCols,..sortColumn,..sortDir)
		If $$$ISERR(tSC) Quit

		Set tWITH = ""
		Set:..withClause'="" tWITH = " WITH " _ ..withClause _ " "

		Set tMDX = "DRILLFACTS "_tWITH_" SELECT FROM [" _ pRS.%GetCubeName() _"]"
		Set kf = $O(pFilters(""))
		While (kf'="") {
			Set tClause = pFilters(kf)
			If (tClause'="") {
				Set tMDX = tMDX _ " %FILTER " _ tClause
			}
			Set kf = $O(pFilters(kf))
		}
		
		// create new query
		Set tRS = ##class(%DeepSee.ResultSet).%New()

		Set tSC = tRS.%PrepareMDX(tMDX)
		If $$$ISERR(tSC) Quit
		
		// DTB316 - If applicable, set the parentQueryKey to allow use of axes locked by the parent query. 
		// Do not assume the %query object exists when this is called.
		If ($G(%query)'="")&&$IsObject(%query)&&%query.%IsA("%DeepSee.Query.query") {
			Set tRS.%Query.parentQueryKey = $S(%query.parentQueryKey'="":%query.parentQueryKey,1:%query.%QueryKey)
		}
		
		Set tSC = tRS.%Execute()
		If $$$ISERR(tSC) Quit
		
		// TODO: work around Listing limitations!
		set tRS.listingPageSize = ##class(%DeepSee.Utils).%GetCubeFactCount(..cubeName)

		// make sure listing is executed
		Set tSC = tRS.%ExecuteListing(1)
		If $$$ISERR(tSC) Quit
		
		set tFilter = ##class(%iKnow.DeepSee.ListingKeyFilter).%New(..cubeName, pIKnowMeasure, tRS.%GetQueryKey())
		set pCellId = $i(%session.Data("_cells"))
		set %session.Data("_cells", pCellId) = $lb(pRow, pCol, tRS.%GetQueryKey(), tFilter.ToString())
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

XData paneSelMeasure [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane labelPosition="left" >
	<select id="selMeasures" label="Measure" showEmpty="false" required="true"
	onchange="zenPage.changeMeasureClient();return;" />
	</pane>
}

ClientMethod changeMeasureClient() [ Language = javascript ]
{
	var sc = zenPage.ChangeMeasure(zen('selMeasures').getValue());
	zenPage.onChangeMeasureClient();
}

ClientMethod onChangeMeasureClient() [ Language = javascript ]
{
}

Method ChangeMeasure(pMeasure As %String) As %Status [ Final, ZenMethod ]
{
	set tSC = $$$OK
	try {
		set ..measureName = pMeasure
		set ..domain = ##class(%iKnow.DeepSee.CubeUtils).GetDomainId(..cubeName, pMeasure)
		
		set ..page = 1, ..filter=""
		kill %session.Data("entities"), %session.Data("_cells"), %session.Data("freqs")
		
		// rebuild filters
		set tSC = ..BuildIKnowFilters(pMeasure)
		quit:$$$ISERR(tSC)
		
		set tSC = ..OnChangeMeasure(pMeasure)
		quit:$$$ISERR(tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method OnChangeMeasure(pMeasure As %String) As %Status [ Private ]
{
	quit $$$OK
}

Method %OnAfterCreatePage() As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		// first build a list of available iKnow measures
		set tSC = ##class(%iKnow.DeepSee.CubeUtils).GetIKnowMeasures(..cubeName,.tMeasures, 1, 1)
		
		if $d(tMeasures) {
			set i="", tMeasures=""
			for {
				set i = $order(tMeasures(i),1,tMeasure)
				quit:i=""
			
				set tMeasures = tMeasures _ $li(tMeasure,1,1)
			}
			set tSelectComp = ..%GetComponentById("selMeasures")
			set tSelectComp.valueList = $lts(tMeasures)
		
			set tSC = ..ChangeMeasure($lg(tMeasures,1))
			quit:$$$ISERR(tSC)
		
			set tSC = ..OnAfterCreatePage()
			quit:$$$ISERR(tSC)
		} else {
			set ..%GetComponentById("panContent").hidden = 1
			set ..%GetComponentById("lblNoMeasures").hidden = 0
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

Method OnAfterCreatePage() As %Status [ Private ]
{
	quit $$$OK
}

///  Add include files to support color schemes.
Method %OnDrawHTMLHead() As %Status
{
	// always use simple for Analyzer
	Set tScheme = "simple"
	/*
	Do ##class(%DeepSee.UserPortal.Utils).%GetPreferences(.tPrefs)
	Set tScheme = $G(tPrefs("Scheme"))

	// check for URL override
	If ($D(%request.Data("SCHEME",1))) {
		Set tScheme = $$$LOWER($G(%request.Data("SCHEME",1)))
	}
	*/

	If (tScheme '= "") {
		// CSS file
		Set tCSSFile = "skin_"_tScheme_".css"
		Write "<link rel=""stylesheet"" type=""text/css"" href="""_tCSSFile_"""/>",!

		// Initializer file for SVG components
		Set tInitFile = "skin_"_tScheme_".js"
		Write "<script type=""text/javascript"" src="""_tInitFile_"""></script>",!
	}

	Quit $$$OK
}

///  Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<label label="This cube has no iKnow measures" id="lblNoMeasures" hidden="true" labelStyle="padding:5px;" />
<pane paneName="dialogBodyContent" width="100%" height="100%" id="panContent" />
</pane>
}

}
