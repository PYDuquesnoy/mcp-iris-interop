/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.Util.perfbydate Extends %ZEN.Component.page [ DependsOn = %ZEN.Component.tableNavigator, System = 4 ]
{

Parameter PAGETIMING = 1;

Parameter TIMINGSLOTS = 48;

Parameter RESOURCE = "%Development";

Parameter ENCODED = 1;

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
</style>
}

/// This XML block defines the contents of this page.
XData Contents
{
<page xmlns="http://www.intersystems.com/zen" title="Web Performance by Date">

<hgroup>
<vgroup  width="100%" valign="top">
<html id="description"><h2><b>Web Performance by Date</b></h2> </html>
<form id="MyForm" layout="horizontal" key="" OnLoadForm="">
<vgroup>
<hgroup>
<spacer width="10"/>
<dateText label="From" id="d1"></dateText>
<spacer width="10"/>
<dateText label="Until" id="d2"></dateText>
<spacer width="10"/>
 <vgroup>
  <spacer width="10"/>
 <button id="button" caption=" GO " onclick="zenPage.search();"/>
 </vgroup>
</hgroup>
</vgroup>
</form>

<tableNavigator tablePaneId="Results" />
<tablePane 	id="Results" 
	sql="SELECT     Page AS Event, 
					SUM(Hits) as Hits, 
					SUM(Globals) as Globals, 
					SUM(Lines) as Lines, 
					MIN(MinTime) as MinTime, 
					MAX(MaxTime) as MaxTime, 
					SUM(TotalTime) as TotalTime,
					CAST(AVG(GlobalsPerHit) AS INTEGER) as GPH,
					CAST(AVG(LinesPerHit) AS INTEGER) as LPH
					
		 FROM 	    %CSP_Util.Performance
		 WHERE Day BETWEEN ? AND ?
		 GROUP BY Page
		 ORDER BY Hits DESC"
	pageSize="10" 
	useSnapshot="true" 
	showZebra="true"
	width="100%"
	valueColumn="Event"
	ondblclick="zenPage.gotoByPage(zenThis.value);"
	>
	
	<parameter id="p1" value=''/>
	<parameter id="p2" value=''/>
	
	<column colName="Event"   width="20%" />
	<column colName="Hits"    width="10%" />
	<column colName="Globals" width="10%"/>
	<column colName="Lines"   width="10%" />
	<column colName="Min"     width="10%" />
	<column colName="Max"     width="10%" />
	<column colName="Total"   width="10%" />
	<column colName="GPH"  	  width="10%" />
	<column colName="LPH"     width="10%" />
</tablePane>

</vgroup>
</hgroup>
</page>
}

ClientMethod search() [ Language = javascript ]
{
	try{
		var begin = zenPage.getComponentById('d1').getValue();
		var end   = zenPage.getComponentById('d2').getValue();
		
		var p1 = zenPage.getComponentById('p1');
		p1.setProperty('value',begin);
		var p2 = zenPage.getComponentById('p2');
		p2.setProperty('value',end);
				
		var table = zenPage.getComponentById('Results');
		table.executeQuery();
		}
	catch(ex){
		zenExceptionHandler(ex,arguments);	
	}
}

ClientMethod init() [ Language = javascript ]
{
	try{
		var d = new Date();
		var year = d.getFullYear();
		var month = d.getMonth()+1;
		if (month < 10) month = '0' + month;
		var day = d.getDate();
		if (day < 10) day = '0' + day;
		var todaystr = year + '-' + month + '-' + day;
		
		var p1 = zenPage.getComponentById('d1');
		p1.setProperty('value',todaystr );
		var p2 = zenPage.getComponentById('d2');
		p2.setProperty('value',todaystr );
		
	}	
	catch(ex){
		zenExceptionHandler(ex,arguments);	
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.init();
	zenPage.search();
}

ClientMethod gotoByPage(pagename) [ Language = javascript ]
{
	var page = '%25CSP.Util.perfbypage.cls?page=' + pagename;
	zenPage.gotoPage(page);
}

}
