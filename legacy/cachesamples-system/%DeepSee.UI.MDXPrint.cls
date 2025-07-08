/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This page renders an MDX statement in a printer friendly manner.
/// 
Class %DeepSee.UI.MDXPrint Extends %ZEN.Component.page [ System = 4 ]
{

Parameter PAGENAME = "Print-Friendly Output";

/// Domain used for localization.
Parameter DOMAIN = "%DeepSee";

/// All DeepSee pages require %DeepSee_Portal USE.
Parameter RESOURCE = "%DeepSee_Portal";

/// Define the title that will be displayed within subclasses
Property StdTitle As %ZEN.Datatype.string [ InitialExpression = {..#PAGENAME} ];

/// !!!
Property mdx As %ZEN.Datatype.string(ZENURL = "MDX");

/// Name of cube the query is based on (used with queryKey).
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Key for the query.
Property queryKey As %ZEN.Datatype.string(ZENURL = "KEY");

XData Style
{
<style type="text/css">

body {
	font-family: lucida sans unicode;
}

.printTable {
	border: 1px solid black;
}

.printTable th {
	padding-right: 2px;
	padding-left: 2px;
	background: lightgray;
	text-align: left;
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
}

.printTable td {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding-right: 2px;
	padding-left: 2px;
}
.printTable td.number {
	text-align: right;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" 
	title="#(%page.StdTitle)#"
	dropEnabled="true"
	dragAndDrop="true"
	 layout="none"
	>
<html id="html" OnDrawContent="DrawHTML"/>
</page>
}

Method DrawHTML(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If ((..mdx="")&&(..cubeName="")&&(..queryKey)) {
			Write $$$TextHTML("Nothing to display","%DeepSee")
			Quit
		}

		Set tRS = ##class(%DeepSee.ResultSet).%New()
		If (..mdx'="") {
			Set tSC = tRS.%PrepareMDX(..mdx)
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tSC = tRS.%PrepareKey(..cubeName,..queryKey)
			If $$$ISERR(tSC) Quit
		}

		// !!! USE ASYNC and refresh !!!

		// Execute async, refresh page if query not complete
		Set tSC = tRS.%ExecuteAsynch()
		If $$$ISERR(tSC) Quit
		Hang 0.01
		Set tStatus = tRS.%GetStatus(.tComplete)
		If (tStatus<100) {
			Set tMsg = $S(tStatus < 35:"Computing axes...",tStatus < 90:"Computing cells...",1:"Consolidating results...")
			If (tComplete '= "") {
				Set tMsg = tMsg _ $FN(tComplete,",",2)_"% complete"
			}

			Set tParms("CUBE") = tRS.%GetCubeName()
			Set tParms("KEY") = tRS.%GetQueryKey()
			Set tURL = ..%Link($ZCVT($className(),"O","URL")_".cls",.tParms)

			Write $ZCVT(tMsg,"O","HTML")
			Write "<script type=""text/javascript"">",!
			Write "window.setTimeout('self.document.location=\'",$ZCVT(tURL,"O","JS"),"\';',1000);",!
			Write "</script>",!
			Quit
		}

		Set tSC = ..%PrintResults(tRS)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Print out the contents (as HTML) of the given MDX result set.
Method %PrintResults(pRS As %DeepSee.ResultSet) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tAxisCount = pRS.%GetAxisCount()
		Set tKey = pRS.%QueryKey

		If (tAxisCount = 0) {
			// single value answer
			Set tValue = pRS.%GetValue()
			Set tCellWidth = 20
			Write $$$Text("Result","%DeepSee"),":",$$FormatNum(tValue),!
			Quit
		}

		Set tVolume = 0
		For a = 1:1:tAxisCount {
			Set tAxisSize(a) = pRS.%GetAxisSize(a)
			Set tVolume = $S(tVolume=0:tAxisSize(a),1:tVolume*tAxisSize(a))
		}
		If (tVolume = 0) {
			Write $$$Text("No results","%DeepSee"),!
			Quit
		}

		&html<<table border="0" cellspacing="0" cellpadding="1" class="printTable">>


		// Get row and column info
		Set tColCount = +$G(tAxisSize(1))

		// column headers
		For c=1:1:tColCount {
			Set tLabelCount = pRS.%GetOrdinalLabel(.tNames,1,c)
			Set tName = tNames(1)
			Set tColNames(c) = tName
		}

		Set tHasRows = 1
		Set tRowCount = +$G(tAxisSize(2))
		If (tRowCount < 1) {
			Set tHasRows = 0
			Set tRowCount = 1
		}

		If (tColCount > 0) {
			&html<<tr>>
			&html<<th>&nbsp;</th>>
			For c = 1:1:tColCount {
				&html<<th>#($ZCVT(tColNames(c),"O","HTML"))#</th>>
			}
			&html<</tr>>
		}

		For r = 1:1:tRowCount {
			&html<<tr>>
			If (tHasRows) {
				Set tName = ""
				Set tLabelCount = pRS.%GetOrdinalLabel(.tLabels,2,r)
				For n=tLabelCount:-1:1 {
					Set tName = tName _ $S(tName="":"",1:"-&gt;")_ tLabels(n)
				}
			}
			Else {
				Set tName = $$$Text("Results","%DeepSee")
			}
			&html<<th>#($ZCVT(tName,"O","HTML"))#</th>>

			For c = 1:1:tColCount {
				Set tValue = $Case(tAxisCount,
					1:pRS.%GetOrdinalValue(c),
					:pRS.%GetOrdinalValue(c,r))

				Set tCls = $S($IsValidNum(tValue):"number",1:"")
				&html<<td class="#(tCls)#">#($ZCVT($$FormatNum(tValue),"O","HTML"))#</td>>
			}
			&html<</tr>>
		}

		&html<</table>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC

FormatNum(tNum)
	Quit $S(tValue="":"*",tValue'=+tValue:tValue,1:$FN(tValue,","))
}

}
