/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.ClassList.SQLDetails Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter RESOURCE = "%Development";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.ClassList.SQLDetails.zen";

/// Displayed name of this page.
Parameter PAGENAME = "ClassSQLDetails";

/// Display title of this page
Parameter PAGETITLE = "Class SQL Details";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Switch namespace for this page: 
Parameter AUTONS As BOOLEAN = 1;

Property Schema As %String(ZENURL = "SCHEMA");

Property Table As %String(ZENURL = "TABLE");

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="">
<tablePane id="table"
queryClass="%SQL.Manager.Catalog"
queryName="Indices"
dataSource="columns"
maxRows="1000"
showZebra="true"
useSnapshot="true"
>
<column colName="INDEX_NAME" header="Index Name"/>
<column colName="SQL_MAP_NAME" header="SQL Map Name"/>
<column colName="FIELDS" header="Columns"/>
<column colName="TYPE" header="Type"/>
<column colName="BLOCK_COUNT" header="Block Count"/>
<column colName="GLOBAL" header="Global"/>
<column colName="MAP_INHERITED" header="Map Inherited?"/>

<parameter value="#(%page.Schema)#"/>
<parameter value="#(%page.Table)#"/>
</tablePane>
</page>
}

}
