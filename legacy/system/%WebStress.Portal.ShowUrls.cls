/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.ShowUrls Extends %ZEN.Component.page [ DependsOn = %ZEN.Component.tableNavigator, System = 4 ]
{

Parameter APPLICATION = "%WebStress.Portal.Application";

Parameter DOMAIN = "%WebStress";

Parameter RESOURCE As STRING = "%Development";

/// Name of this page.
Parameter PAGENAME = "Webstress Portal";

Property Script As %String(ZENURL = "Script");

Property Row As %String(ZENURL = "Row");

XData Style
{
<style type="text/css">

body {
	background: #C0C0C0;
	font-family: arial;
	overflow: hidden;
}

#body {
	background: #C0C0C0;
	padding: 0px;
	overflow: hidden;
}

/* do not show standard header */
#header {
	display: none;
}

#footer {
	color: black;
	background: #C0C0C0;
	background-image: none;
	width: 100%;
	padding: 0px;
	border-top: 1px solid gray;
}


/* tool ribbon */
.toolRibbon {
	height: 48px;
	background: white;
	border: 1px solid black;
	vertical-align: middle;
}

.ribbonTitle {
	font-size: 20px;
	color: white;
	background: rgb(53,107,141);
	border-left: 1px solid black;
}

.ribbonLabel {
	vertical-align: middle;
	color: #404040;
	font-weight: bold;
	font-size: 10pt;
}

.ribbonSortOption:hover,.ribbonSortOptionSelected:hover {
	color: darkred;
}

.ribbonSortOption {
	text-decoration: none;
	color: blue;
	font-weight: normal;
}

.ribbonSortOptionSelected {
	text-decoration: none;
	color: #404040;
	background: #FFEEAA;
	font-weight: normal;
}

.viewIconBar {
	vertical-align: bottom;
}

.viewIcon,.viewIconSelected,.viewIconDis {
	vertical-align: bottom;
	padding: 2px;
}

.viewIconSelected {
	padding: 0px;
	border: 2px solid darkred;
	background:#FFEEAA;
}

.viewIcon:hover,.viewIconSelected:hover {
	padding: 1px;
	border: 1px dotted gray;
}



</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page>
<tableNavigator tablePaneId="urls" />
<tablePane id="urls" useSnapshot="true" pageSize="25" maxRows="1000" queryClass="%WebStress.Scripts.URLS" queryName="ShowURL" >
<parameter name="script" value="#(%page.Script)#"/>
   <column colName="ID" link="javascript:zenPage.triggerAction('#(%query.ID)#');" />
</tablePane>
</page>
}

ClientMethod triggerAction(url) [ Language = javascript ]
{
	zenPage.firePopupAction(zenPage.Row,url,true);
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	// default: make *this* page the complete list
	Set tPageName = $$$ZENVAL(..title)
	Set tPageName = $P(tPageName," ",$L(tPageName," "))
	Set pLink(1) = $LB(tPageName,..Link($ZCVT(..%ClassName(1),"O","URL")_".zen?CSPSHARE=1"))
	Quit $$$OK
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()

	Quit tSC
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("WebStress Portal")
}

}
