/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.Util.perfbypage Extends %ZEN.Component.page [ System = 4 ]
{

Parameter PAGETIMING = 1;

Parameter TIMINGSLOTS = 48;

Parameter ENCODED = 1;

Parameter RESOURCE = "%Development";

Property page As %String(MAXLEN = 256);

Property date As %String(MAXLEN = 256) [ InitialExpression = {$zdate($h,3)} ];

/// 
/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

h2 {
	color: darkblue;
	border-top: 1px solid darkblue;
	font-weight: bold;
	font-size: 1.2em;
}

table.DetailTable {
	border: 1px solid black;
	/* make tables with few columns, small */
	width: 10%;
}

table.DetailTable th {
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	padding-left: 2px;
	padding-right: 8px;
	font-weight: bold;
	text-align: left;
	color: yellow;
}

table.DetailTable td {
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	padding-left: 2px;
	padding-right: 2px;
}

.button{
	color: blue;
	height: 19px;
	width: 22px;
}

.label{
	font-size: 1.2em;
}
</style>
}

/// 
/// This XML block defines the contents of this page.
XData Contents
{
<page xmlns="http://www.intersystems.com/zen"  title="Web Performance By Page">



<hgroup>

<vgroup  width="100%" valign="top">

<html id="title"><h2><b>Web Performance by Page </b></h2> </html>



<hgroup>

<html id="l1"><font size="+1"><b>Page:  </b></font> </html><spacer width="5"/>

<label id="page"  value="#( %url.page )#" />

</hgroup>

<hgroup>

<html id="l2"><font size="+1"><b>Date:  </b></font> </html><spacer width="5"/>



<button id="backoneday" caption=" &lt; " onclick="zenPage.backoneday();" />

<spacer width="3"/><label id="date"  value="" /><spacer width="3"/>

<button id="forwardoneday" caption=" &gt; " onclick="zenPage.forwardoneday();"></button>



</hgroup>

<hgroup>

<svgFrame id="myFrame1" height="300" width="400">

  		<lineChart height="300" width="400" id="Hits" title="Page Hits"

           ongetData="return zenPage.getgraph1(series, zenThis.seriesSize );"

           backgroundStyle="fill: url(#glow-blue);"

           seriesCount="1" seriesColors="red" seriesSize="48"

            />

            </svgFrame> 

<svgFrame id="myFrame2" height="300" width="400">             

         	<lineChart height="300" width="400" id="globals" title="Globals Per Hit"

            ongetData="return zenPage.getgraph2(series, zenThis.seriesSize);"

            backgroundStyle="fill: url(#glow-blue);"

            seriesCount="1" seriesColors="blue" seriesSize="48"

             />

              </svgFrame>

<svgFrame id="myFrame3" height="300" width="400">             

         	<lineChart height="300" width="400" id="lines" title="Lines Per Hit"

            ongetData="return zenPage.getgraph3(series, zenThis.seriesSize);"

            backgroundStyle="fill: url(#glow-blue);"

            seriesCount="1" seriesColors="green" seriesSize="48"

             />

              </svgFrame>       

</hgroup>

<hgroup>                  

<svgFrame id="myFrame4" height="300" width="400">              

             <lineChart height="300" width="400" id="TotalTime" title="TotalTime"

            ongetData="return zenPage.getgraph4(series, zenThis.seriesSize);"

            backgroundStyle="fill: url(#glow-blue);"

            seriesCount="1" seriesColors="green" seriesSize="48"

             />

           	  </svgFrame>    

<svgFrame id="myFrame5" height="300" width="400">              

             <lineChart height="300" width="400" id="MinTime" title="MinTime"

            ongetData="return zenPage.getgraph5(series, zenThis.seriesSize);"

            backgroundStyle="fill: url(#glow-blue);"

            seriesCount="1" seriesColors="red" seriesSize="48"

             />

           	  </svgFrame>

<svgFrame id="myFrame6" height="300" width="400">              

             <lineChart height="300" width="400" id="MaxTime" title="MaxTime"

            ongetData="return zenPage.getgraph6(series, zenThis.seriesSize);"

            backgroundStyle="fill: url(#glow-blue);"

            seriesCount="1" seriesColors="blue" seriesSize="48"

             />

           	  </svgFrame>

</hgroup>



</vgroup>

</hgroup>

</page>
}

ClientMethod backoneday() [ Language = javascript ]
{

	var url = "%25CSP.Util.perfbypage.cls?";

	// param 1 = PAGE

	url = url + "page=" + encodeURIComponent(zenPage.getComponentById("page").value);

	// param 2 = DATE

	var date = zenPage.getComponentById("date").value;

	var Today = new Date(date.substring(0,4), date.substring(5,7)-1, date.substring(8,10));

	// 24 hours = 86400000 milliseconds

	var Yesterday = new Date(Today.getTime() - 86400000 );

	url = url + "&date=" + Yesterday.getYear() + "-";

	if (Yesterday.getMonth() < 9) {

		url = url + "0";

	}

	url = url + (Yesterday.getMonth()+1) + "-";

	if (Yesterday.getDate() < 10){

		url = url + "0";

	}

	url = url + Yesterday.getDate();

	zenPage.gotoPage(url);
}

ClientMethod forwardoneday() [ Language = javascript ]
{

	var url = "%25CSP.Util.perfbypage.cls?";

	// param 1 = PAGE

	url = url + "page=" + encodeURIComponent(zenPage.getComponentById("page").value);

	// param 2 = DATE

	var date = zenPage.getComponentById("date").value;

	var Today = new Date(date.substring(0,4), date.substring(5,7)-1, date.substring(8,10));

	// 24 hours = 86400000 milliseconds

	var Yesterday = new Date(Today.getTime() + 86400000 );

	url = url + "&date=" + Yesterday.getYear() + "-";

	if (Yesterday.getMonth() < 9) {

		url = url + "0";

	}

	url = url + (Yesterday.getMonth()+1) + "-";

	if (Yesterday.getDate() < 10){

		url = url + "0";

	}

	url = url + Yesterday.getDate()

	zenPage.gotoPage(url);
}

ClientMethod getgraph1(serie As %Integer, size As %Integer) [ Language = javascript ]
{

	var page = zenPage.getComponentById('page').value;

	var date = zenPage.getComponentById('date').value;

	var data = zenPage.GetGraph("Hits", page, date);

	/* for debugging

	for (i=0;i<48;i++) {

		alert("data["+i+"]="+data[i]);

	}

	*/

    return data;
}

ClientMethod getgraph2(serie As %Integer, size As %Integer) [ Language = javascript ]
{

	var p = zenPage.getComponentById('page').value;

	var d = zenPage.getComponentById('date').value;

	

	var data = zenPage.GetGraph("GlobalsPerHit", p, d);

	return data;
}

ClientMethod getgraph3(serie As %Integer, size As %Integer) [ Language = javascript ]
{

	var p = zenPage.getComponentById('page').value;

	var d = zenPage.getComponentById('date').value;

	

	var data = zenPage.GetGraph("LinesPerHit", p, d);

    return data;
}

ClientMethod getgraph4(serie As %Integer, size As %Integer) [ Language = javascript ]
{

	var p = zenPage.getComponentById('page').value;

	var d = zenPage.getComponentById('date').value;

	

	var data = zenPage.GetGraph("TotalTime", p, d);

    return data;
}

ClientMethod getgraph5(serie As %Integer, size As %Integer) [ Language = javascript ]
{

	var p = zenPage.getComponentById('page').value;

	var d = zenPage.getComponentById('date').value;

	

	var data = zenPage.GetGraph("MinTime", p, d);

    return data;
}

ClientMethod getgraph6(serie As %Integer, size As %Integer) [ Language = javascript ]
{

	var p = zenPage.getComponentById('page').value;

	var d = zenPage.getComponentById('date').value;

	

	var data = zenPage.GetGraph("MaxTime", p, d);

    return data;
}

ClassMethod GetGraph(measure As %String, pagename As %String, date As %String) As %ListOfDataTypes [ ZenMethod ]
{

	set Hits = ##class(%ListOfDataTypes).%New()

	

	Set rset = ##class(%ResultSet).%New()

 	Set rset.ClassName = "%CSP.Util.Performance"

	Set rset.QueryName = "PageAndDay"

	Do rset.Execute(pagename, date)

	

	set start = 1

 	while (rset.Next()) 

    {

	    for i = start:1:rset.Data("Slot")-1 {

	    	do Hits.Insert(0)

	    }

	    do Hits.Insert(rset.Data(measure))

	    set start = rset.Data("Slot") + 1

    }

    

    for i=start:1:48  do Hits.Insert( 0 )

    

    quit Hits
}

/// 
/// This callback is called after the server-side page 
/// 
/// object and all of its children are created.<br>
/// 
/// Subclasses can override this to add, remove, or modify 
/// 
/// items within the page object model, or to provide values
/// 
/// for controls.
Method %OnAfterCreatePage() As %Status
{

	// Set Page

	set c = %page.%GetComponentById("page")

	set c.value = %request.Get("page")

	

	// Set Date

	set c = %page.%GetComponentById("date")

	if %request.Get("date") '= ""{

		set c.value = %request.Get("date")

	}else{

		set c.value = $zdate($h,3)

	}

	Quit $$$OK
}

}
