/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Zen page for System Management Portal - Home for SQL 
Class %CSP.UI.Portal.SQL.Home Extends (%CSP.UI.Template.Property, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Switch namespace $NAMESPACE is present
Parameter AUTONS As BOOLEAN = 1;

/// Displayed name of this page.
Parameter PAGENAME = "SQL Home Page";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.Home.zen";

Parameter HELPADDRESS = "Home,SQL";

/// Security requirement
Parameter RESOURCE = "%Development";

/// String user entered to filter the tree.
Property SQLFILTER As %String;

/// Possible values: Tables, Views, Procedures, CQs
Property FILTERTYPE As %String;

/// Possible values: 1, 2, 3, 4, 5 (Functions & Queries, Functions & Queries & Extent, Functions, Queries, Queries & Extent)
Property FILTERPROC As %Integer;

/// User selected schema
Property FILTERSCHEMA As %Integer;

/// Whether to include System items
Property SYSTEMFLAG As %Integer [ InitialExpression = "0" ];

/// Whether to include deprecated items
Property DEPRECATEDFLAG As %Integer [ InitialExpression = "0" ];

/// Maximum items to be loaded in the tree. It is set to 10000 and user cannot modify. 
/// For ISC internal testing, you may set a value in ^|"%SYS"|IRIS.Temp.MgtPortalSettings($Username,"SQLMAXTREELOAD") to override it. 
Property MAXTREELOAD As %Integer [ InitialExpression = 10000, Internal ];

/// Current namespace 
Property NAMESPACE As %String(ZENURL = "$NAMESPACE");

/// current user selected catalog type - updated when user clicked on a tree node. -1=Nothing selected; 0=Table; 1=SystemTable; 2=View; 3=Procedure; 4=Cached Query
Property CurrentCatalog As %Integer;

/// current item (value) selected from the tree
Property CurrentItem As %String;

/// Default is Display Mode
Property RuntimeMode As %ZEN.Datatype.string [ InitialExpression = "2" ];

/// Maximum rows to display in result tables
Property MaxRows As %ZEN.Datatype.string [ InitialExpression = "1000" ];

/// Whether to show row numbers in result tables
Property ShowRowNum As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// SQL dialect used to prepare dynamic SQL statements
Property Dialect As %ZEN.Datatype.string [ InitialExpression = "IRIS" ];

/// Whether to execute the SQL query in the foreground
Property Foreground As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Current Process ID ($JOB)
Property processID As %ZEN.Datatype.string [ InitialExpression = {$JOB} ];

/// Holds the selected redio option on the SQL Statements display
Property StatementRadioSelect As %ZEN.Datatype.string [ InitialExpression = "statementTable0" ];

/// Specify how columns whose type class is a swizzleable class
/// will be defined in the result set class generated from a SELECT statement.
/// Currently it is always set to 0.
Property ObjectSelectMode As %Integer [ InitialExpression = 0 ];

/// icon used for major branch folder at the top level, such as Tables and Views
Property iconFolder As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/broker/deepsee/folder_16.png")} ];

/// Link pages
Property BuilderPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/%25CSP.UI.SQL.QueryBuilderWindow.cls",,1)} ];

Property DocBookPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/docbook/DocBook.UI.Page.zen",,1)} ];

Property DocumaticPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/documatic/%25CSP.Documatic.cls",,1)} ];

Property OpenTablePage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/UtilSqlOpen.csp",,1)} ];

Property OpenViewPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/UtilSqlOpenView.csp",,1)} ];

Property PrintDetailsPage As %ZEN.Datatype.string [ InitialExpression = {..Link("%CSP.UI.Portal.SQL.PrintTable.zen",,1)} ];

Property SQLHomePage As %ZEN.Datatype.string [ InitialExpression = {..Link("%25CSP.UI.Portal.SQL.Home.zen",,1)} ];

Property SQLStatementDetailsPage As %ZEN.Datatype.string [ InitialExpression = {..Link("_CSP.UI.Portal.Dialog.SQLStatementDetails.zen",,1)} ];

Property SQLViewPage As %ZEN.Datatype.string [ InitialExpression = {..Link("%CSP.UI.Portal.Dialog.SQLView.zen",,1)} ];

Property TuneTablePage As %ZEN.Datatype.string [ InitialExpression = {..Link("%CSP.UI.Portal.SQL.TuneTable.zen",,1)} ];

Property OpenRoutinePage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/%25CSP.UI.System.ViewCode.cls",,1)} ];

Property TuneAllTablePage As %ZEN.Datatype.string [ InitialExpression = {..Link("%CSP.UI.Portal.Dialog.SQLTuneTables.zen",,1)} ];

Property SQLParametersPage As %ZEN.Datatype.string [ InitialExpression = {..Link("%CSP.UI.Portal.Dialog.SQLParametersPrompt.zen",,1)} ];

Property CurrentStatementPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/op/%25CSP.UI.Portal.SQL.CurrentStatements.zen",,1)} ];

Property msgDeleteCQNamespace As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to delete ALL cached queries in namespace %1?")} ];

Property msgDeleteCQTable As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to delete all cached queries for table %1?")} ];

Property msgSelectTable As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please select a Table from the tree and try again.")} ];

/// Filter used for Statements table
Property StatementFilter As %ZEN.Datatype.string;

/// Maximum rows to display in Statements table
Property StatementMaxRows As %ZEN.Datatype.integer [ InitialExpression = 1000 ];

/// PageSize used to display in Statements table
Property StatementPageSize As %ZEN.Datatype.integer [ InitialExpression = 100 ];

/// ID of currently executing query so we can support multiple browser windows side by side
Property CurrentQueryID As %ZEN.Datatype.integer [ Internal ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#searchPane {
	border-right: 1px solid #F0F0F0;;
	padding-left: 10px;
	padding-right: 5px;
}
#resultGroup {
	display: none;		
}
#spanArrow {
	color: #356B8D;
}

/* @doc="Input box of data combobox. Changed color for this page." */
.comboboxInput {
	border-top: 1px solid #ABABAB;
	border-bottom: 1px solid #ABABAB;
	border-left: 1px solid #ABABAB;
}
/* @doc="Image button in data combobox. Changed color for this page." */
.comboboxImgButton {
	border-top: 1px solid #ABABAB;
	border-bottom: 1px solid #ABABAB;
	border-right: 1px solid #ABABAB;
	/* attempt to scale button with text */
	width: 1.3em;
	height: 1.4em;
}

/* override menu color */
.menuTable {
	border: 1px solid #F0F0F0;
}
a.menuItem {
	color: #000000;
	font-weight: bold;
}

/* @doc="Mouse over menu item." */
a.menuItem:hover {
	background: white;
	border: 1px white solid;
	text-decoration: underline;
}
/* @doc="Disabled menu item." */
a.menuItemDisabled {
	background: white;
	padding: 4px 4px 4px 4px;
	text-decoration: none;
}
/* active menu item: this is used for top-level items
	when their submenu is displayed.
*/
a.menuItemActive {
	border: 1px solid #F0F0F0;
	color: #28536D;
	font-weight: bold;
	padding: 2px 10px 2px 2px;
	background: #F9EDBE;
}
/* this is for individual links built on this page*/
a.histlink {
	color: #3B84BC;
	text-decoration: none;	
}
a.histlink:hover {
	background: transparent;
	text-decoration: underline;
}
/* override radioSet caption placement */
a.radioSetCaption {
	color: #404040;
	font-weight: bold;
	vertical-align: text-bottom;
}
/* table style for catalog details */
table.DetailTable	{ 
	font-size: 11px;
	margin-left: 2px; margin-right: 10px;
	border: 1px #888888 solid;
}
table.DetailTable TH { 
	font-weight: bold;		
	background:white; 
	color: #888888;
	text-align: center;
}
table.DetailTable td.caption { 
	font-weight: bold;		
	background: #D0D0FF; 
	border-bottom: gray solid 1px;
	border-right: gray solid 1px;
	padding: 3px;
}
table.DetailTable td.value { 		
	background: #FFFFFF; 
	border-bottom: gray solid 1px;
	border-right: gray solid 1px;
	padding: 3px;
}
table.DetailTable tr.OddRow { background: white; }

table.DetailTable tr.EvenRow { background: #F0F0F0; }

/* @doc="Caption above table. Used by Browse"*/
table.tpTable caption { 
	font-weight: bold;
	text-align: left;
	border: 1px solid #F0F0F0;
	background: F1F0E7;
}

/* table style for execute query result */
table.ExecuteTable	{ 
	background: #cbcbcb;
	font-size: 11px;
	margin-left: 2px; margin-right: 2px;
}
table.ExecuteTable th { 
	background:white; 
	color: #707070;
	font-weight: bold;
	padding: 3px;
	text-align: center;
}
table.ExecuteTable td { 		
	padding: 3px;
}
table.ExecuteTable tr.OddRow { background: white; vertical-align: top;}
table.ExecuteTable tr.EvenRow { background: #F0F0F0; vertical-align: top;}

.ErrorBox {
	border: 1px solid #707070;
    margin: 0px;
    padding: 0px;
}
.tnbrFilter {
	font-size: 0.8em;
}
.tnbrFound {
	font-size: 0.8em;
}

</style>
}

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup width="100%">
<hgroup id="mainGroup" cellVAlign="top">
<hgroup id="searchGroup" valign="top">
<pane id="searchPane" paneName="searchPane"/>
<html id="searchExpander" valign="top">
<span id="spanArrow" title="Hide or show the search box" 
onclick="zenPage.toggleSearch();" 
onmouseover="this.style.color='rgb(218,72,72)';this.style.cursor='pointer'" 
onmouseout="this.style.color='';this.style.cursor='';">&#171;</span>
</html>
</hgroup>
<group valign="top">
<pane id="resultPane" paneName="resultPane" />
</group>
</hgroup>
</vgroup>
</pane>
}

/// This pane displays the search criteria. We provide defaults and user can change them.
/// User's values are saved and used as future defaults for this user.
/// Subclass to override.
XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup labelPosition="left" containerStyle="padding-top:4px;">
<timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>
<jsonProvider id="jsonSQLInfo" OnGetTargetObject="GetSQLInfo">
 </jsonProvider>

<hgroup showLabel="false" labelPosition="left" >
<combobox id="txtFilter" label="Filter" comboType="timer" delay="200" editable="true" unrestricted="true" size="20"
dropdownWidth="300px" valign="middle"
title="Enter a string to filter the tree - use '*' for wildcard, e.g. C*.* for schema.tables starting with C." 
onchange="zenPage.toggleClearText(zenThis);zenPage.doSearch();" onkeyup="return zenPage.toggleClearText(zenThis);"
 enclosingStyle="padding-right:2px;"/>
 <image id="imageCleartxtFilter" src="csp/broker/deepsee/ds2_circle_x_44.png" width="12" height="12" onclick="var sc = zenPage.doAction('ClearFilter'); zenPage.doSearch();" 
 title="Clear filter text" valign="middle" enclosingStyle="padding-right:2px;"/>
<select id="selFilter" label="applies to"
valueList="Tables,Views,Procedures,CQs,All" 
displayList="Tables,Views,Procedures,Cached Queries,All"
title="Apply filter string to this catalog. If 'All' is selected then the filter string you entered will be applied to all catalogs in the tree."
value="All" showEmpty="false" onchange="zenPage.doFilterType();"/>
<image id="imgRefresh" src="csp/broker/deepsee/ds2_refresh_44.png" width="12" height="12" title="Refresh tree" onclick="zenPage.doSearch();"/>
</hgroup>
<select id="cmbProcOption" label="Show" hidden="true" showEmpty="false" title="Select an filter option for procedures" valueList="1,2,3,4,5" value="1"
displayList="Functions &amp; Queries,Functions &amp; Queries &amp; Extent,Functions,Queries,Queries &amp; Extent"
onchange="zenPage.doSearch();"/>
<hgroup showLabel="false" labelPosition="left">
<checkbox id="chkSystem" label="System" title="Include system items" onchange="zenPage.doSearch();"/>
<checkbox id="chkDeprecated" label="Deprecated" title="Include deprecated items" onchange="zenPage.doSearch();"/>
</hgroup>
<hgroup showLabel="false" labelPosition="left">
<dataCombo id="cmbSchema" label="Schema" queryClass="%SQL.Manager.Catalog" queryName="Schemas" showEmpty="true" 
multiColumn="true" dropdownWidth="500px" size="30"
displayColumns="1"
choiceColumn="1"
valueColumn="1"
maxRows="100000"
OnExecuteResultSet="ListSchemas"
title="Select an existing schema for filtering."
onchange="zenPage.selectSchema(zenThis.value);"
 >
 <parameter value="0"/>
 </dataCombo>
 </hgroup>
 </vgroup>
<SMPDynaTree id="tree"
imageContracted="images/arrow-5-10.png"
imageExpanded="images/arrow-down-5-10.png"
 dragEnabled="true"
 showLines="false"
 showFolders="false"
 onclick="zenPage.doTree(zenThis);"
 OnGetTreeInfo="GetTreeInfo" onupdate="zenPage.updateTreeItems();">
<parameter id="showSystem" paramName="showSystem" value="0" />
</SMPDynaTree>
<hgroup containerStyle="padding:2px;" valign="top">
<label id="lblTotalLoaded" valign="middle" controlStyle="white-space:pre-line"/>
</hgroup>
</pane>
}

XData resultPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="resultGroup" containerStyle="padding:2px">
<hmenu id="topMenu" containerStyle="padding-right:10px;">
<menu id="menuData" caption="Wizards" layout="vertical">

<menuItem caption="Data Import" 
					link="UtilSqlExImWizard.csp?Wizard=Import"
					title="Import data to this system from a text file."
					/>
<menuItem caption="Data Export" 
					link="UtilSqlExImWizard.csp?Wizard=Export"
					title="Export data from this system to a text file."
					/>
<menuItem caption="Data Migration" 
					link="UtilSqlLink.csp?Wizard=DataMigration"
					title="Migrate class definition and data from other systems to this system."
					/>
<menuItem caption="Link Table" 
					link="UtilSqlLink.csp?Wizard=LinkTable"
					title="Link remote table to this system."
					/>
<menuItem caption="Link Procedure" 
					link="UtilSqlLink.csp?Wizard=LinkProcedure"
					title="Link remote stored procedure to this system."
					/>
<menuItem caption="FileMan" 
					link="%25CSP.UI.Portal.FileMan.zen"
					title="Map FileMan files to InterSystems classes."
					/>								
</menu>
<menu id="menuAction" caption="Actions" layout="vertical">
<menuItem id="menuCreateView" caption="Create View..." onclick="zenPage.doAction('CreateView');"
					title="Create a new view. Selecting this option will open a new window."
					/>
<menuItem caption="Print Catalog" onclick="zenPage.doActionTable('PrintDetails');"
					title="Print catalog details. Click a table from the tree first.  Selecting this option will open a new window."
					/>
<menu caption="Purge Cached Queries" layout="vertical">
<menuItem caption="Purge ALL queries for this namespace" onclick="zenPage.doAction('PurgeCQNamespace');"
					title="If confirmed, all cached queries will be purged in this namespace."/>
<menuItem caption="Purge all queries for the selected table" onclick="zenPage.doActionTable('PurgeCQTable');"
					title="Click a table from the tree first."/>
<menuItem caption="Purge selected queries only" onclick="zenPage.doActionTable('PurgeCQRoutines');"
					title="Check the queries from the Cached Queries list for the selected table first."/>
</menu>
<menuItem caption="Tune Table Information..." onclick="zenPage.doActionTable('TuneTable');"
					title="Run TuneTable the selected table, see table's tuned metadata, or manually modify a table's tune metadata. Click a table from the tree first. Selecting this option will open a new window."
					/>
<menuItem caption="Tune all tables in schema..." onclick="zenPage.doAction('TuneAllTable');"
					title="Tune all tables for a selected schema.  Selecting this option will open a new window."
					/>
<menuItem id="menuRebuildIndices" caption="Rebuild Table's Indices..." onclick="zenPage.doActionTable('RebuildIndices');"
					title="Rebuild indices for selected table. Click a table from the tree first. Indices will be auto-purged and an extent lock will be acquired on the table for the index build."
					/>
<menuItem id="menuDelete" caption="Drop this item..." onclick="zenPage.doActionTable('Delete');"
					title="Drop selected item. Click a table from the tree first. "
					/>
<menuItem id="menuRunScript" caption="Run Script" onclick="zenPage.doActionTable('RunScript');"
					title="Run a scripted file." hidden="true"
					/>
<menuItem id="menuStatementExport" caption="Export All Statements" onclick="zenPage.doAction('StatementExport');"
					title="Run a scripted file." hidden="false"
					/>
<menuItem id="menuStatementImport" caption="Import Statements" onclick="zenPage.doAction('StatementImport');"
					title="Run a scripted file." hidden="false"
					/>
</menu>
<!-- disabled until a table or view is selected from the tree -->
<menuItem id="menuOpenTable" caption="Open Table" disabled="true" onclick="zenPage.doActionTable('OpenTable');"
					 title="Browse data for the selected table."/>

<menu id="menuPTools" caption="Tools" layout="vertical">
<menuItem id="menuPTools1" caption="SQL Runtime Statistics" onclick="zenPage.doAction('pTools1');"
					title="Perform SQL runtime statistic diagnostics."/>
<menuItem id="menuPTools2" caption="Index Analyzer" target="_new" onclick="zenPage.doAction('pTools2');"
					title="View SQL index analyzer reports."/>
<menuItem id="menuPTools3" caption="Alternate Show Plans" onclick="zenPage.doAction('pTools3');"
					title="View alternate plan."/>
<menuItem id="menuPTools4" caption="Generate Report" onclick="zenPage.doAction('pTools4');"
					title="Generate SQL troubleshooting report."/>
<menuItem id="menuPTools5" caption="Import Report" onclick="zenPage.doAction('pTools5');"
					title="Import SQL troubleshooting report."/>	
<menuItem id="menuPTools6" caption="Current Statements" onclick="zenPage.doAction('currentStatements');"
					title="Review currently executing SQL statements."/>					
</menu>
<menu caption="Documentation" layout="vertical">
<menuItem id="menuSQLCodes" caption="SQL Codes" onclick="zenPage.doAction('SQLCodes');"
					title="View SQL codes and descriptions."/>
<menuItem id="menuReservedWords" caption="SQL Reserved Words" onclick="zenPage.doAction('ReservedWords');"
					title="View SQL reserved words."/>
<menuItem id="menuClassDoc" caption="Class Documentation" disabled="true" onclick="zenPage.doActionTable('ClassDoc');"
					title="Show class documentation."/>

</menu>
</hmenu>
<tabGroup id="tabGroup" showTabBar="true" showBody="false" enclosingStyle="margin:10px;"
currTab="2">
<tab id="tab1" caption="Catalog Details" enclosingStyle="overflow:auto" onshow="zenPage.RefreshTableStatements();">
<label id="idRespond" enclosingClass="note" value="Please select an item from the tree." hidden="false" containerStyle="padding:4px 4px 4px 0px;"/>
<group id="groupDetails" hidden="true">
<hgroup id="groupCatalog" labelPosition="left" containerStyle="padding:2px;">
<label id="lblTableName" label="Table: " labelClass="caption" controlClass="caption"/>
<radioSet name="radCatalog" id="radCatalog" valign="bottom" 
valueList="0,1,2,3,4,5,6" 
displayList="Table Info,Fields,Maps/Indices,Triggers,Constraints,Cached Queries,Table's SQL Statements" 
onclick="zenPage.showCatalog();" originalValue="0" value="0"/>
<radioSet name="radCatalogView" id="radCatalogView" valign="bottom" 
valueList="0,1" 
displayList="View Info,View's SQL Statements" 
onclick="zenPage.showCatalogView();" originalValue="0" value="0"/>
<radioSet name="radCatalogProc" id="radCatalogProc" valign="bottom" 
valueList="0,1"
displayList="Stored procedure Info,Stored Procedure's SQL Statements" 
onclick="zenPage.showCatalogProc();" originalValue="0" value="0"/>
<radioSet name="radCatalogCQ" id="radCatalogCQ" valign="bottom" 
valueList="0,1,2,3"
displayList="Cached Query Info,Column Metadata (Basic),Column Metadata (Advanced),Parameter Metadata" 
onclick="zenPage.showCatalogCQ();" originalValue="0" value="0"/>
</hgroup>
<!-- Show Table Info -->
<group id="tblTable0">
<html id="htmlTableInfo" OnDrawContent="DrawTableDetails"/>
<group labelPosition="left">
<text id="txtOpenTableMaxRows" label="Number of rows to load when table is opened:" 
size="3" valign="middle" onchange="zenPage.doOpenTableMax(zenThis.getValue());"
 title="Enter a number between 1 and 10000" />
</group>
</group>
<!-- Show Table Details -->
<tablePane id="tblTable1"
queryClass="%SQL.Manager.Catalog"
queryName="Fields"
initialExecute="false"
maxRows="1000"
showZebra="true"
useSnapshot="true"
>
<column colName="FIELD_NAME" header="Field Name"/>
<column colName="DATATYPE" header="Datatype"/>
<column colName="COLUMN_NUMBER" header="Column #"/>
<column colName="REQUIRED" header="Required"/>
<column colName="UNIQUE" header="Unique"/>
<column colName="COLLATION_FUNCTION" header="Collation"/>
<column colName="HIDDEN" header="Hidden"/>
<column colName="MAXLEN" header="MaxLen"/>
<column colName="MAXVAL" header="MaxVal"/>
<column colName="MINVAL" header="MinVal"/>
<column colName="BLOB" header="Stream"/>
<column colName="CONTAINER_FIELD" header="Container"/>
<column colName="XDBC_TYPENAME" header="xDBC Type"/>
<column colName="REFERENCE_TO" header="ReferenceTo" link="javascript:zenPage.doReferenceTo('#(%query.REFERENCE_TO)#',0);" title="Click to view catalog details for this table."/>
<column colName="VERSION_COLUMN" header="Version Column"/>
<column colName="SELECTIVITY" header="Selectivity"/>
<column colName="OUTLIER_SELECTIVITY" header="Outlier Selectivity"/>
<column colName="OUTLIER_VALUE" header="Outlier Value"/>
<column colName="AVERAGE_FIELD_SIZE" header="Average Field Size"/>
<column colName="HISTOGRAM" hidden="true" />
<parameter value=""/>
<parameter value=""/>
<condition colName="REFERENCE_TO" predicate="EQ" value="" cellStyle="disabled" targetCol="REFERENCE_TO"/>
</tablePane>
<tablePane id="tblTable2" hidden="true"
queryClass="%SQL.Manager.Catalog"
queryName="Indices"
initialExecute="false"
maxRows="1000"
showZebra="true"
useSnapshot="true"
>
<column colName="INDEX_NAME" header="Index Name"/>
<column colName="SQL_MAP_NAME" header="SQL Map Name"/>
<column colName="FIELDS" header="Columns"/>
<column colName="TYPE" header="Type"/>
<column colName="BI_ARGUMENT" hidden="true"/>
<column colName="SIZE_MB" header="Size (MB)"/>
<column colName="GLOBAL" header="Global" OnDrawCell="DrawGlobalLink" />
<column colName="MAP_INHERITED" header="Map Inherited?"/>
<column colName="MAP_STATUS" header="Status" OnDrawCell="DrawToggleIndexStatus" />

<column linkCaption="Rebuild Index" id="linkRebuild" 
link="javascript:zenPage.doRebuildIndex('#(%query.BI_ARGUMENT)#',0);" 
cellTitle="Rebuild this index in the background after acquiring an extent lock for the table" 
linkConfirm="Are you sure you want to rebuild this index? "
/>

<parameter value=""/>
<parameter value=""/>
<condition colName="TYPE" predicate="CONTAINS" value="Data" cellStyle="disabled" targetCol="Rebuild Index"/> 
</tablePane>
<tablePane id="tblTable3" hidden="true"
queryClass="%SQL.Manager.Catalog"
queryName="Triggers"
initialExecute="false"
maxRows="1000"
showZebra="true"
useSnapshot="true"
>
<column colName="TRIGGER_NAME" header="Trigger Name"/>
<column colName="TIME_EVENT" header="Time Event"/>
<column colName="ORDER" header="Order"/>
<column colName="CODE" header="Code"/>
<parameter value=""/>
<parameter value=""/>
</tablePane>
<tablePane id="tblTable4" hidden="true"
queryClass="%SQL.Manager.Catalog"
queryName="Constraints"
initialExecute="false"
maxRows="1000"
showZebra="true"
useSnapshot="true"
>
<column colName="CONSTRAINT_NAME" header="Constraint Name"/>
<column colName="CONSTRAINT_TYPE" header="Constraint Type"/>
<column colName="CONSTRAINT_DATA" header="Constraint Data"/>
<parameter value=""/>
<parameter value=""/>
</tablePane>
<tablePane id="tblTable5" hidden="true"
dataSource="columns"
queryClass="%SQL.Manager.Catalog"
queryName="CachedQueryTable"
initialExecute="false"
maxRows="10000"
multiSelect="true"
showZebra="true"
valueColumn="Routine"
useSnapshot="true"
>
<column colName="Routine" header="Class Name" link="javascript:zenPage.showCQTable('#(%query.Routine)#');"
title="View details of this SQL cached query; check checkbox for Action Purge Cached Queries."/>
<column colName="Query" header="Query"/>
<column colName="CreateTime" header="Creation Time"/>
<column colName="Source" header="Source"/>
<column colName="QueryType" hidden="true"/>
<column colName="QueryTypeExt" header="Query Type"/>
<column colName="Cost" hidden="true"/>
<column colName="STATEMENT_OPTIONS" hidden="false" header="Statement Features"/>
<parameter value=""/>
<parameter value=""/>
</tablePane>
<tablePane id="tblTable6" hidden="true"
dataSource="columns"
queryClass="%SQL.Manager.Catalog"
queryName="StatementIndex"
initialExecute="false"
maxRows="10000"
showZebra="true"
useSnapshot="true"
showRowNumbers="true"
>
<column colName="STATEMENT_ID" header="Table Name" hidden="true"/>
<column colName="RELATION_NAME" header="Table Name"/>
<column colName="PLAN_STATE" header="Plan State" title="The state of the frozen plan for this statement: Frozen/Explicit, Frozen/Upgrade, Unfrozen/Parallel or Unfrozen."/>
<column colName="FROZEN_DIFF" header="New plan" title="True if the frozen plan is different to current query plan, i.e. there is a new plan available"/>
<column colName="COUNT" header="Execution count" title="Number of times this query has been called."/>
<column colName="AVERAGECOUNT" header="Execution count/day" title="Average number of times this query has been called per day since we first recorded it."/>
<column colName="TOTAL" header="Total time" title="Total time spent running this query (s)."/>
<column colName="AVERAGE" header="Average time" title="Average time running this query (s)."/>
<column colName="STDDEV" header="StdDev time" title="Standard deviation of the time running this query."/>
<column colName="ROWCOUNT" header="Row Count" title="Total %ROWCOUNT from running this query."/>
<column colName="AVERAGEROWCOUNT" header="Row Count/day" title="Average %ROWCOUNT per day for running this query."/>
<column colName="COMMANDS" header="Commands executed" title="Total ObjectScript commands executed from running this query."/>
<column colName="AVERAGECOMMANDS" header="Commands executed/day" title="Average ObjectScript commands executed per day for running this query."/>
<column colName="LOCATION" header="Location"/>
<column colName="STATEMENT" header="Statement" link="javascript:zenPage.doStatementDetailsTo('#(%query.STATEMENT_ID)#');" title="Click to view SQL statement details and to freeze the plan for this statement."/>
<parameter value=""/>
<parameter value=""/>
</tablePane>
<!-- Show View Info -->
<html id="htmlViewInfo" OnDrawContent="DrawViewDetails"/>
<!-- Show View Details -->
<tablePane id="tblView0" hidden="true"
dataSource="columns"
queryClass="%SQL.Manager.Catalog"
queryName="StatementIndex"
initialExecute="false"
maxRows="10000"
showZebra="true"
useSnapshot="true"
showRowNumbers="true"
>
<column colName="STATEMENT_ID" header="Table Name" hidden="true"/>
<column colName="RELATION_NAME" header="Table Name"/>
<column colName="PLAN_STATE" header="Plan State" title="The state of the frozen plan for this statement: Frozen/Explicit, Frozen/Upgrade, Unfrozen/Parallel or Unfrozen."/>
<column colName="FROZEN_DIFF" header="New plan" title="True if the frozen plan is different to current query plan, i.e. there is a new plan available"/>
<column colName="COUNT" header="Execution count" title="Number of times this query has been called."/>
<column colName="AVERAGECOUNT" header="Execution count/day" title="Average number of times this query has been called per day since we first recorded it."/>
<column colName="TOTAL" header="Total time" title="Total time spent running this query (s)."/>
<column colName="AVERAGE" header="Average time" title="Average time running this query (s)."/>
<column colName="STDDEV" header="StdDev time" title="Standard deviation of the time running this query."/>
<column colName="ROWCOUNT" header="Row Count" title="Total %ROWCOUNT from running this query."/>
<column colName="AVERAGEROWCOUNT" header="Row Count/day" title="Average %ROWCOUNT per day for running this query."/>
<column colName="COMMANDS" header="Commands executed" title="Total ObjectScript commands executed from running this query."/>
<column colName="AVERAGECOMMANDS" header="Commands executed/day" title="Average ObjectScript commands executed per day for running this query."/>
<column colName="LOCATION" header="Location"/>
<column colName="STATEMENT" header="Statement" link="javascript:zenPage.doStatementDetailsTo('#(%query.STATEMENT_ID)#');" title="Click to view SQL statement details and to freeze the plan for this statement."/>
<parameter value=""/>
<parameter value=""/>
</tablePane>
<!-- Show Procedure Details -->
<html id="htmlProcInfo" OnDrawContent="DrawProcedureDetails"/>
<!-- Show Procedure Details -->
<tablePane id="tblProc0" hidden="true"
dataSource="columns"
queryClass="%SQL.Manager.Catalog"
queryName="StatementIndex"
initialExecute="false"
maxRows="10000"
showZebra="true"
useSnapshot="true"
showRowNumbers="true"
>
<column colName="STATEMENT_ID" header="Table Name" hidden="true"/>
<column colName="RELATION_NAME" header="Table Name"/>
<column colName="PLAN_STATE" header="Plan State" title="The state of the frozen plan for this statement: Frozen/Explicit, Frozen/Upgrade, Unfrozen/Parallel or Unfrozen."/>
<column colName="FROZEN_DIFF" header="New plan" title="True if the frozen plan is different to current query plan, i.e. there is a new plan available"/>
<column colName="COUNT" header="Execution count" title="Number of times this query has been called."/>
<column colName="AVERAGECOUNT" header="Execution count/day" title="Average number of times this query has been called per day since we first recorded it."/>
<column colName="TOTAL" header="Total time" title="Total time spent running this query (s)."/>
<column colName="AVERAGE" header="Average time" title="Average time running this query (s)."/>
<column colName="STDDEV" header="StdDev time" title="Standard deviation of the time running this query."/>
<column colName="ROWCOUNT" header="Row Count" title="Total %ROWCOUNT from running this query."/>
<column colName="AVERAGEROWCOUNT" header="Row Count/day" title="Average %ROWCOUNT per day for running this query."/>
<column colName="COMMANDS" header="Commands executed" title="Total ObjectScript commands executed from running this query."/>
<column colName="AVERAGECOMMANDS" header="Commands executed/day" title="Average ObjectScript commands executed per day for running this query."/>
<column colName="LOCATION" header="Location"/>
<column colName="STATEMENT" header="Statement" link="javascript:zenPage.doStatementDetailsTo('#(%query.STATEMENT_ID)#');" title="Click to view SQL statement details and to freeze the plan for this statement."/>
<parameter value=""/>
<parameter value=""/>
</tablePane>
<!-- Show CQ Details -->
<html id="htmlCQInfo" OnDrawContent="DrawCQDetails"/>
<!-- Show CQ Column Metadata Details -->
<tablePane id="tblCQ0" hidden="true"
initialExecute="false"
maxRows="10000"
queryClass="%SQL.Manager.Catalog"
queryName="CachedQueryColumnMetadata"
showZebra="true"
valueColumn="Routine"
useSnapshot="true"
caption="Cached Query Column Metadata"
>
<column colName="Column" header="Column#" style="text-align:left;" title="Column position in the select list."/>
<column colName="Name" header="Name" title="Name of the column"/>
<column colName="Type" header="Type" title="Datatype of the column"/>
<column colName="Precision" header="Precision" title="Precision of the column's value"/>
<column colName="Scale" header="Scale" title="Scale of the column's value"/>
<column colName="Nullable" header="Nullable" title="Is this column nullable?  1 if the column can include NULLs, 0 if the column cannot include NULLs, empty if the nullability for the column is unknown"/>
<column colName="ColumnLable" header="Column Label" title="Lable for this column"/>
<column colName="TableName" header="Table Name" title="Name of the table that this column belongs to"/>
<column colName="SchemaName" header="Schema Name" title="Name of the schema that the table of this column belongs to"/>
<column colName="AutoIncrement" header="Auto Increment?" title="Is the value for this column assigned an auto incremented value during insert.  1 if yes, 0 if no."/>
<column colName="CaseSensitive" header="Case Sensitive?" title="A string field that uses %Exact, %String, or %SqlString collation.  1 if yes, 0 if no."/>
<column colName="Currency" header="Currency?" title="A column which has a server side datatype of %Library.Currency."/>
<column colName="ReadOnly" header="Read Only?" title="A column that is defined as readonly, or is a system generated value, or is an identity field and AllowIdentityInsert is off, returns 1, otherwise it is 0."/>
<column colName="RowVersion" header="Row Version?" title="A column which has a server side datatype of %Library.RowVersion."/>
<column colName="Unique" header="Unique?" title="A column which has a unique value within the table.  1 for yes, 0 for no."/>
<column colName="Aliased" header="Aliased?" title="The column has a lable or AS clause specified to supply the column name.  1 for yes, 0 for 0"/>
<column colName="Expression" header="Expression?" title="The column is an SQL expression.  1 for yes, 0 for no."/>
<column colName="Hidden" header="Hidden?" title="A column defined in the SQL table as a hidden column.  1 for yes, 0 for no."/>
<column colName="Identity" header="Identity?" title="A column defined in the SQL table as an identity column.  1 for yes, 0 for no."/>
<column colName="KeyColumn" header="Key Column?" title="A column from the SQL table that is specified in a unique index.  1 for yes, 0 for no."/>
<column colName="RowID" header="RowID?" title="A column defined in the SQL table as the RowID column or an field in the IDKey index.  1 for yes, 0 for no."/>
<column colName="DataSlot" header="FS Data Slot" title="Internal value used in server client communication"/>
<parameter value=""/>
</tablePane>
<tablePane id="tblCQ0b" hidden="true"
initialExecute="false"
maxRows="10000"
queryClass="%SQL.Manager.Catalog"
queryName="CachedQueryColumnMetadataBasic"
showZebra="true"
valueColumn="Routine"
useSnapshot="true"
caption="Cached Query Column Metadata"
>
<column colName="Column" header="Column#" style="text-align:left;" title="Column position in the select list."/>
<column colName="Name" header="Name" title="Name of the column"/>
<column colName="Type" header="Type" title="Datatype of the column"/>
<column colName="Precision" header="Precision" title="Precision of the column's value"/>
<column colName="Scale" header="Scale" title="Scale of the column's value"/>
<column colName="Nullable" header="Nullable" title="Is this column nullable?  1 if the column can include NULLs, 0 if the column cannot include NULLs, empty if the nullability for the column is unknown"/>
<column colName="ColumnLable" header="Column Label" title="Lable for this column"/>
<column colName="TableName" header="Table Name" title="Name of the table that this column belongs to"/>
<column colName="SchemaName" header="Schema Name" title="Name of the schema that the table of this column belongs to"/>
<parameter value=""/>
</tablePane>
<!-- Show CQ Column Parameter Details -->
<tablePane id="tblCQ1" hidden="true"
dataSource="columns"
initialExecute="false"
maxRows="10000"
queryClass="%SQL.Manager.Catalog"
queryName="CachedQueryParameterMetadata"
showZebra="true"
valueColumn="Column"
useSnapshot="true"
caption="Cached Query Parameter Metadata"
>
<column colName="Column" header="Parameter#" style="text-align:left;" title="Parameter position in the statement."/>
<column colName="Type" header="Type" title="Datatype of the parameter"/>
<column colName="Precision" header="Precision" title="Precision of the parameter's value"/>
<column colName="Scale" header="Scale" title="Scale of the parameter's value"/>
<column colName="Nullable" header="Nullable" title="is the parameter nullable?"/>
<parameter value=""/>
</tablePane>
</group>
<!-- end of groupDetails -->
</tab>

<tab id="tab2" caption="Execute Query" enclosingStyle="overflow:auto">
<hgroup enclosingStyle="padding-top:6px;" labelPosition="left">
<button id="btnExecute" caption="Execute" onclick="zenPage.doExecute();" title="Execute query"/>
<button id="btnCancel" caption="Cancel" onclick="if (confirm($$$Text('Are you sure you want to cancel this operation?'))) zenPage.CancelQuery();" title="Cancel query" hidden="true"/>
<button id="btnShowPlan" caption="Show Plan" onclick="zenPage.doShowPlan();" title="Show query plan"/>
<button id="btnHistory" caption="Show History" onclick="zenPage.doHistory();" title="Show or hide the query history"/>
<button id="btnQueryBuilder" caption="Query Builder" onclick="zenPage.doQueryBuilder();" title="Use the Query Builder to select and build a query"/>
<hgroup labelPosition="left" enclosingStyle="background:#F1F1F1;">
<select id="selRuntimeMode" containerStyle="padding-left:2px;" 
title="Display mode used for executing query" 
valueList="0,1,2" displayList="Logical Mode,ODBC Mode,Display Mode" showEmpty="false" value="2"
onchange="zenPage.updateParameters();"/>
<text id="txtMaxRows" label="Max" labelStyle="padding-left:4px;" maxlength="6" size="4" 
title="Maximum number of items to load and display in result table and tree (enter a number less or equal to 100000)." value="1000"
 onchange="zenPage.updateParameters();"/>
<link id="linkOptions" caption="more" title="show or hide more options" href="javascript:zenPage.toggleOptions();" />
<spacer width="4"/>
<select id="selDialect" label="Dialect" hidden="true" 
title="SQL dialect used to prepare dynamic SQL statements" 
valueList="IRIS,Sybase,MSSQL" showEmpty="false" value="IRIS"
onchange="zenPage.updateParameters();"/>
<checkbox id="chkShowRowNum" caption="Row Number" captionClass="zenLabel" title="Display row numbers in result table" hidden="true" 
onchange="zenPage.updateParameters();"/>
<checkbox id="chkForeground" caption="Execute Query in the foreground" captionClass="zenLabel" value="0" hidden="true"
title="Not recommended for SQL queries that may take a long time to run"
onchange="zenPage.updateParameters();"/>
</hgroup>
</hgroup>
<hgroup enclosingStyle="padding-top:6px;" >
<textarea id="QueryText" dropEnabled="true"
rows="10" 
cols="80"
valign="top"
onkeyup="return zenPage.keyUpQueryText(zenThis);"
ondrop="return zenPage.tableDropHandler(dragData);"
 />
 <image id="imageClearQueryText" src="csp/broker/deepsee/ds2_circle_x_44.png" width="16" height="16" onclick="zenPage.doAction('ClearQueryText');" title="Clear query text" valign="top" hidden="true"/>
</hgroup>
<!-- maxRows for History is changed to "Max" if user changes it. -->
<vgroup id="idHistory" hidden="true" enclosingStyle="width:600px;height:300px;overflow:auto;" containerStyle="padding-left:2px;">
<tableNavBar showFilter="true" showPageSize="true" showMaxRows="true" tablePaneId="tableQueryHistory" 
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'tableQueryHistory');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'tableQueryHistory');"
onfilterChange="zenPage.historyFilterChanged(value);"
/>
<tablePane id="tableQueryHistory"
pageSize="0"
maxRows="1000"
initialExecute="false"
queryClass="%SQL.Manager.Catalog"
queryName="QueryHistory"
showZebra="true"
valueColumn="ID"
useSnapshot="true"
onselectrow="zenPage.selectHistory(zenThis.getValue(),'Select');"
>
<column colName="SQL_STATEMENT_120" header="SQL Statement" title="Click a row to view full statement."/>
<column colName="SQL_STATEMENT" hidden="true"/>
<column colName="ID" hidden="true"/>
<column colName="LAST_EXECUTED" header="Execution Time" title="Timestamp of the last execution of the statement."/>
<column colName="EXECUTE_COUNT" header="Count" title="Number of times this Statement has been executed."/>
<column linkCaption="Execute" link="javascript:zenPage.selectHistory('#(%query.ID)#','Execute');" title="Execute this query"/>
<column linkCaption="Plan" link="javascript:zenPage.selectHistory('#(%query.ID)#','ShowPlan');" title="Show Plan for this query"/>
<column linkCaption="Print" link="javascript:zenPage.selectHistory('#(%query.ID)#','Print');" title="Print or Export query results"/>
<column linkCaption="Delete" link="javascript:zenPage.selectHistory('#(%query.ID)#','Delete');" title="Delete this query from history"/>
<parameter value="#(%page.Filter)#"/>
</tablePane>
<button id="btnDeleteAll" caption="Delete All" title="Delete all query histories" onclick="zenPage.doDeleteAll();"/>
</vgroup>
<hgroup id="idPerformance" hidden="true">
<html OnDrawContent="DrawPerformance"/>
<link id="btnPrint" caption="Print" enclosingStyle="background:#F1F1F1;padding-right:4px;" title="printer friendly version of the last execute" href="javascript:zenPage.selectHistory('','Print');"/>
</hgroup>
<html id="htmlResult" OnDrawContent="DrawHTML" enclosingStyle="width:60px;height:100px;overflow:auto;" onrefresh="zenPage.updateStatistics();"/>
<html id="htmlPlan" OnDrawContent="DrawShowPlan"/>

</tab>

<tab id="tab3" caption="Browse" enclosingStyle="overflow:auto">
<hgroup>
<link caption="Show All Schemas" href="#" onclick="zenPage.doAllSchemas(0);return false;" title="Display all schemas in this namespace."/>
<spacer width="10px"/>
<link caption="Show Schemas with Filter" href="#" onclick="zenPage.doAllSchemas(1);return false;" title="Display schemas that match the Filter you entered on the left."/>
</hgroup>
<tablePane id="browseTable0"
pageSize="0"
maxRows="100000"
initialExecute="false"
queryClass="%SQL.Manager.Catalog"
queryName="Schemas"
showZebra="true"
valueColumn="SCHEMA_NAME"
useSnapshot="true"
>
<column colName="SCHEMA_NAME" header="Schema Name" onclick="zenPage.doDrill(1,'#(%query.SCHEMA_NAME)#',1);"
cellTitle="click to select this schema"/>
<column colName="TABLE_EXISTS" hidden="true"/>
<column colName="VIEW_EXISTS" hidden="true"/>
<column colName="PROCEDURE_EXISTS" hidden="true"/>
<column colName="CACHED_QUERY_EXISTS" hidden="true"/>

<column linkCaption="Tables" link="javascript:zenPage.doDrill(1,'#(%query.SCHEMA_NAME)#',1);"
style="text-align:center;"/>
<column linkCaption="Views" link="javascript:zenPage.doDrill(2,'#(%query.SCHEMA_NAME)#',1);"
style="text-align:center;"/>
<column linkCaption="Procedures" link="javascript:zenPage.doDrill(3,'#(%query.SCHEMA_NAME)#',1);"
style="text-align:center;"/>
<column linkCaption="Queries" link="javascript:zenPage.doDrill(4,'#(%query.SCHEMA_NAME)#',1);"
style="text-align:center;"/>

<condition colName="TABLE_EXISTS" predicate="EQ" value="0" cellStyle="disabled" targetCol="Tables"/>
<condition colName="VIEW_EXISTS" predicate="EQ" value="0" cellStyle="disabled" targetCol="Views"/>
<condition colName="PROCEDURE_EXISTS" predicate="EQ" value="0" cellStyle="disabled" targetCol="Procedures"/>
<condition colName="CACHED_QUERY_EXISTS" predicate="EQ" value="0" cellStyle="disabled" targetCol="Queries"/>

<parameter value="0"/>
<parameter value=""/>
</tablePane>

<tablePane id="browseTable1" hidden="true" 
pageSize="0"
maxRows="100000"
initialExecute="false"
onselectrow="zenPage.doSelectRow(zenThis);"
queryClass="%SQL.Manager.Catalog"
queryName="TablesOnly"
showZebra="true"
valueColumn="NAME"
useSnapshot="true"
>
<column colName="NAME" header="Name"/>
<column colName="OWNER" header="Owner"/>
<column colName="LAST_COMPILED" header="Last Compiled"/>
<column colName="EXTERNAL" header="External"/>
<column colName="EXTERNAL_TYPE" header="External Type"/>
<column colName="READ_ONLY" header="ReadOnly"/>
<column colName="CLASSNAME" header="Class Name"/>
<column colName="EXTENTSIZE" header="Extent size"/>
<column colName="ALLOW_DROP" hidden="true"/>
<parameter id="schemaName" value=""/>
<parameter id="grantOnly" value="0"/>
<parameter id="tableFilter" value=""/>
</tablePane>

<tablePane id="browseTable2" hidden="true"
pageSize="0"
maxRows="100000"
initialExecute="false"
onselectrow="zenPage.doSelectRow(zenThis);"
queryClass="%SQL.Manager.Catalog"
queryName="ViewsOnly"
showZebra="true"
valueColumn="NAME"
useSnapshot="true"
>
<column colName="NAME" header="Name"/>
<column colName="OWNER" header="Owner"/>
<column colName="LAST_COMPILED" header="Last Compiled"/>
<column colName="READ_ONLY" header="ReadOnly"/>
<column colName="UPDATABLE" header="Updatable"/>
<column colName="CLASSNAME" header="Class Name"/>
<column colName="CHECK_OPTION" header="Check Option"/>
<column colName="CLASSTYPE" hidden="true"/>
<parameter value=""/>
<parameter value="0"/>
<parameter value=""/>
</tablePane>

<tablePane id="browseTable3" hidden="true"
pageSize="0"
maxRows="100000"
initialExecute="false"
onselectrow="zenPage.doSelectRow(zenThis);"
queryClass="%SQL.Manager.Catalog"
queryName="Procedures"
showZebra="true"
valueColumn="PROCEDURE_NAME"
useSnapshot="true"
>
<column colName="PROCEDURE_NAME" header="Name"/>
<column colName="PROCEDURE_TYPE" header="Type"/>
<column colName="PROCEDURE_CLASS" header="Class"/>
<column colName="METHOD_OR_QUERY_NAME" header="Method/Query"/>
<column colName="ALLOW_DELETE" hidden="true"/>
<parameter value=""/>
<parameter value="0"/>
<parameter value=""/>
<parameter value=""/>
</tablePane>

<tablePane id="browseTable4" hidden="true"
pageSize="0"
maxRows="100000"
initialExecute="false"
onselectrow="zenPage.doSelectRow(zenThis);"
queryClass="%SQL.Manager.Catalog"
queryName="CachedQueryInfo"
showZebra="true"
valueColumn="Routine"
useSnapshot="true"
>
<column colName="Routine" header="Class"/>
<column colName="Query" header="Statement"/>
<column colName="CreateTime" header="Time Created"/>
<column colName="Source" header="Source"/>
<column colName="QueryType" hidden="true" header="Query Type"/>
<column colName="QueryTypeExt" hidden="false" header="Query Type"/>
<column colName="Cost" hidden="true"/>
<column colName="STATEMENT_OPTIONS" hidden="false" header="Statement Features"/>
<parameter value=""/>
</tablePane>
</tab>

<tab id="tab4" caption="SQL Statements" enclosingStyle="overflow:auto" onshow="zen('statementTable0').executeQuery(0);">
<group id="groupDetails2" hidden="false">
<hgroup id="groupCatalog2" labelPosition="left" containerStyle="padding:2px;">
<label id="lblStatementName" label="All SQL Statements in this namespace" labelClass="caption" controlClass="caption" title="All SQL statements in this namespace"/>
</hgroup>
<!-- Show Statement List -->
<hgroup id="groupCatalog2b" labelPosition="left" containerStyle="padding:2px;">
<tableNavBar id="tblNavBar"
tablePaneId="statementTable0"
showFilter="true" 
showPageSize="true" 
showMaxRows="true" 
saveSizeMax="true"
onfilterChange="zenPage.statementFilterChanged(value);" 
onPageSizeChange="zenPage.navPageSizeChanged(value,'statementTable0');" 
onMaxRowsChange="zenPage.navMaxRowsChanged(value,'statementTable0');"
title="To filter: enter one or more characters of any column followed by [Tab]."
/>
<button id="btnRefresh" caption="Refresh" onclick="zenPage.statementRefresh();" title="Click to refresh the results for 'All SQL statements in this namespace' table."/>
<spacer width="50" />
<button id="btnClean" caption="Clean stale" onclick="zenPage.StatementIndexClean();" title="Click to clean SQL statements that no longer have any routine/class associated with them."/>
</hgroup>
<tablePane id="statementTable0"
queryClass="%SQL.Manager.Catalog"
queryName="StatementIndexAll"
dataSource="columns"
initialExecute="false"
maxRows="1000"
pageSize="100"
showZebra="true"
useSnapshot="true"
nowrap="false"
showRowNumbers="true">
<parameter value="#(%page.StatementFilter)#"/>
<parameter value="#(%page.StatementMaxRows)#"/>
<column colName="STATEMENT_ID" header="Statement Hash ID" title="Hash of the satement text and other input that defines the ID of this statement." hidden="true"/>
<column colName="RELATION_NAME" header="Table/View/Procedure Name(s)" link="javascript:zenPage.doStatementDetailsTo('#(%query.STATEMENT_ID)#',1);" title="Click to view SQL statement details in new tab"/>
<column colName="PLAN_STATE" header="Plan State" title="The state of the frozen plan for this statement: Frozen/Explicit, Frozen/Upgrade, Unfrozen/Parallel or Unfrozen."/>
<column colName="FROZEN_DIFF" header="New plan" title="True if the frozen plan is different to current query plan, i.e. there is a new plan available"/>
<column colName="COUNT" header="Execution count" title="Number of times this query has been called."/>
<column colName="AVERAGECOUNT" header="Execution count/day" title="Average number of times this query has been called per day since we first recorded it."/>
<column colName="TOTAL" header="Total time" title="Total time spent running this query (s)."/>
<column colName="AVERAGE" header="Average time" title="Average time running this query (s)."/>
<column colName="STDDEV" header="StdDev time" title="Standard deviation of the time running this query."/>
<column colName="ROWCOUNT" header="Row Count" title="Total %ROWCOUNT from running this query."/>
<column colName="AVERAGEROWCOUNT" header="Row Count/day" title="Average %ROWCOUNT per day for running this query."/>
<column colName="COMMANDS" header="Commands executed" title="Total ObjectScript commands executed from running this query."/>
<column colName="AVERAGECOMMANDS" header="Commands executed/day" title="Average ObjectScript commands executed per day for running this query."/>
<column colName="LOCATION" header="Location(s)" title="Routine name the statement resides in."/>
<column colName="STATEMENT" header="SQL Statement Text" link="javascript:zenPage.doStatementDetailsTo('#(%query.STATEMENT_ID)#');" title="Click to view SQL statement details and to freeze the plan for this statement."/>
</tablePane>
</group>
<!-- end of groupDetails -->
</tab>
</tabGroup>

</pane>
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod statementFilterChanged(value) [ Language = javascript ]
{
	this.StatementFilter = value;
	var tableId = "statementTable0";
	var table = zen(tableId);
	table.executeQuery();
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	this.UpdateTableNavState(value,this.StatementPageSize,this.StatementMaxRows,tableId);
}

/// this method maybe called from StatementDetails page to update table
ClientMethod statementRefresh() [ Language = javascript ]
{
	zen('statementTable0').executeQuery(0);
}

/// Call logic to cleanup stale statement index entries that do not have routines/classes anymore
ClassMethod StatementIndexClean() [ ZenMethod ]
{
	Do CleanSQLIndex^%SYS.SQLSRV(0,1)
	&js<zenPage.statementRefresh()>
}

/// drillType indicate the type (1 based. Tables/Views...) if overrideFilter is 0 then do not override Filter unless it is null.
ClientMethod doDrill(drillType, schemaname, overrideFilter) [ Language = javascript ]
{
	// if name passed in is null (e.g. when Schema is not selected) then show Schemas with Filter.
	if (schemaname.length < 1) {
		this.doAllSchemas(1);
		return;
	}
	var zs = zenSynchronousMode;
    zenSynchronousMode = true;
	// first hide all browse tables
	for (var n=0; n<5; n++) {
		zen("browseTable"+n).setHidden(true);
	}
	zen("cmbSchema").setValue(schemaname);
	this.FILTERSCHEMA = schemaname;
	var table = "";
	var lblCaption = "";
	var tablePaneId = "browseTable" + drillType;
	table = zen(tablePaneId);
	switch (drillType) {
		case 1:
			lblCaption = $$$Text("Tables with schema: ")+schemaname;
			break;
		case 2:
			lblCaption = $$$Text("Views with schema: ")+schemaname;
			break;
		case 3:
			lblCaption = $$$Text("Stored procedures with schema: ")+schemaname;
			table.parameters[3].value = zen("cmbProcOption").getValue();
			break;
		case 4:
			lblCaption = $$$Text("Cached queries with schema: ")+schemaname;
			zen("txtFilter").setValue("");
			zenPage.toggleClearText(zen("txtFilter"));
			this.doSearch();
			break;
		default:
			lblCaption = $$$Text("Tables with schema: ")+schemaname;
			this.selectSchema(schemaname);
			break;
	}
	if (drillType < 4) {
		if (zen("txtFilter").getValue() == "") overrideFilter = 1;
		if (overrideFilter) this.selectSchema(schemaname);
		else this.doSearch();	
	}
	table.setHidden(false);
	table.parameters[0].value = schemaname;
	if (drillType < 4) {
		table.parameters[2].value = zen("txtFilter").getValue();
	}
	table.executeQuery(0);
	table.setProperty("caption","(" + table.getProperty("rowCount") + ") " + lblCaption);
	
	zenSynchronousMode = zs;
}

/// Overriden to add tabId and tableId to the page name to distinguish the type for the page.
ClientMethod navPageSizeChanged(value, tableId) [ Language = javascript ]
{
	if (tableId == 'statementTable0') {
		this.StatementPageSize = value;
		this.UpdateTableNavState(this.StatementFilter,value,this.StatementMaxRows,tableId);
	} else {
		this.TablePageSize = value;
		this.UpdateTableNavState(this.Filter,value,this.TableMaxRows,tableId);
	}
}

/// Overriden to add tabId and tableId to the page name to distinguish the type for the page.
ClientMethod navMaxRowsChanged(value, tableId) [ Language = javascript ]
{
	if (tableId == 'statementTable0') {
		// max rows for Statement table must be in the 10-10000 range.
		if (parseInt(value) < 10) {
			value = 10;
			zen(tableId).setProperty('maxRows',value);
		}
		if (parseInt(value) > 10000) {
			value = 10000;
			zen(tableId).setProperty('maxRows',value);
		}
		this.StatementMaxRows = value;
		this.UpdateTableNavState(this.StatementFilter,this.StatementPageSize,value,tableId);
	} else {
		this.TableMaxRows = value;
		this.UpdateTableNavState(this.Filter,this.TablePageSize,value,tableId);
	}
}

/// Used to Save tableNavBar values, add MapType to the page name to distinguish the type for the page.
ClassMethod UpdateTableNavState(pFilter As %String, pPageSize As %Integer, pMaxRows As %Integer, ptableId As %String) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName()_"^"_ptableId,"TableNavState") = $lb(pFilter,pPageSize,pMaxRows)
}

/// This method is fired up after onDrawContent is finished. Hide progress message and display error if exists.
ClientMethod updateStatistics() [ Language = javascript ]
{
	zen("btnExecute").setDisabled(false);	
	var result = this.GetStatus(zenPage.getProperty('CurrentQueryID'));
	if (result.Status == "Done") {
		if (result.Error != "") {
			self.document.getElementById("statistics").innerHTML = result.Error;
		} else {
			self.document.getElementById("statistics").innerHTML = result.Performance;
			zen("btnPrint").setHidden(false);
			zen("htmlResult").setHidden(false);
		}
		zen("btnExecute").setHidden(false);
		zen("btnCancel").setHidden(true);
		zenPage.setProperty('CurrentQueryID', '');
	} 
	else {
		if (result.Error != "") {
			self.document.getElementById("statistics").innerHTML = result.Error;
		} else {
			// no error but not done yet
		}
		/*var error = $$$Text("Unexpected error occurred. Execute query did not finish as expected.");
		self.document.getElementById("statistics").innerHTML = error;*/
	}
}

/// when DrawHTML is finished, Status is "Done" then we update the Performance value.
ClassMethod GetStatus(pCurrentQueryID As %Integer = "") As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	if pCurrentQueryID'="" {
		Set proxy.Status = $G(^IRIS.Temp.ExecuteQuery($Username,pCurrentQueryID,"Status"))
		Set proxy.Error = $G(^IRIS.Temp.ExecuteQuery($Username,pCurrentQueryID,"Error"))
		Set proxy.Performance = $G(^IRIS.Temp.ExecuteQuery($Username,pCurrentQueryID,"Performance"))
		if $d(^IRIS.Temp.ExecuteQuery($Username,pCurrentQueryID,"DiagResult"), tDiagResultID) && tDiagResultID { 
			kill pp 
			set pp("resultID") = tDiagResultID, 
				pp("$NAMESPACE") = $namespace,
				tDiagResult = ^IRIS.Temp.ExecuteQuery($Username,pCurrentQueryID,"DiagResult")
			set proxy.Performance = "<a href="""_..Link("/csp/sys/op/%25CSP.UI.Portal.SQL.Logs.zen",.pp,1)_""" target=""_new"">"_$$$TextHTML("%SQL_Diag.Result.ID: ")_tDiagResultID_"</a><br>"_proxy.Performance 
		}
		if $d(^IRIS.Temp.ExecuteQuery($username,pCurrentQueryID,"mlconfiguration"),mlconfig),$system.Context.SQL().MLConfiguration'=mlconfig { set $system.Context.SQL().MLConfiguration=mlconfig } // Statement updated the ML Configuration, update this process's MLConfiguration
		kill:pCurrentQueryID'=0 ^IRIS.Temp.ExecuteQuery($username,pCurrentQueryID)  // Retain foreground information global; Kill background information global!
	}
	Quit proxy
}

///  Curently we do not display the ribbon for this page.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 0
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Quit $$$OK
}

ClientMethod onloadHandler(load) [ Language = javascript ]
{
	var navbar = zen("tblNavBar");
	navbar.setFilterSize(40);
	//navbar.findElement('maxRows').size = 5;
	this.invokeSuper('onloadHandler',arguments);
	try {
		this.doSearch();
		var json = zen('jsonSQLInfo').getContentObject();
		this._sqlInfo = json;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onloadHandler');
	}
 
 	if ((this.ShowRowNum == true) || (this.Foreground == true)) { // --- Display 'linkOptions' [more] Details if any [more] Properties are set ---
 		zenPage.toggleOptions(); 
 	}
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSizes();
}

ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var winWidth = zenGetWindowWidth();
		var winHeight = zenGetWindowHeight();
		var searchDiv = zen('searchPane').getEnclosingDiv();
		var treeDiv = zen('tree').getEnclosingDiv();
		var resultDiv = zen('resultGroup').getEnclosingDiv();
		resultDiv.style.display = 'block';
		var propHeight = winHeight - 150;
		propHeight = Math.max(propHeight,100);
		treeDiv.style.height = propHeight + 'px';
		/// calculate sizes for result div:
		var propWidth = 5;
		var resultWidth = winWidth - 50;
		resultWidth = Math.max(resultWidth,100);
		if (!this.searchExpanded) {
			resultDiv.style.width = resultWidth + 'px';
			searchDiv.style.display = 'none';
		} else {
			propWidth = 390;
			resultWidth = resultWidth - propWidth;
			resultWidth = Math.max(resultWidth,100);
			resultDiv.style.width = resultWidth + 'px';
			searchDiv.style.display = 'block';
		}

		/// calculate sizes for query history table
		var history = zen('idHistory').getEnclosingDiv();
		history.style.width = resultWidth + 'px';
		propHeight = winHeight - 360;
		propHeight = Math.max(propHeight,100);
		history.style.height = propHeight + 'px';
		
		/// calculate sizes for result table:
		var tableResult = zen('htmlResult').getEnclosingDiv();
		tableResult.style.width = resultWidth + 'px';
		propHeight = winHeight - 400;
		propHeight = Math.max(propHeight,100);
		tableResult.style.height = propHeight + 'px';
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Check if user hit [Enter].
ClientMethod keyUp(zenEvent, flag) [ Language = javascript ]
{
	if ((zenEvent.which==13)||(zenEvent.keyCode==13)) {
		if (flag == 'filter') this.doSearch();
	}
}

ClientMethod selectSchema(schema) [ Language = javascript ]
{
	zen("txtFilter").setValue(schema+".*");
	zenPage.toggleClearText(zen("txtFilter"));
	this.doSearch();
}

/// user changed filter type. Show or hide procedure options.
ClientMethod doFilterType() [ Language = javascript ]
{
	var filterType = zen("selFilter").getValue();
	zen("cmbProcOption").setHidden(filterType!="Procedures");
	this.doSearch();
}

/// reload tree with new filter. when this happens we want to hide groupDetails and 
/// show the message to remind user to select item from tree.
ClientMethod doSearch() [ Language = javascript ]
{
	var filtertype = zen("selFilter").getValue();
	var filter = zen("txtFilter").getValue();
	var filteroption = zen("cmbProcOption").getValue();
	this.FILTERTYPE = filtertype;
	this.SQLFILTER = filter;
	this.FILTERPROC = filteroption;
	this.FILTERSCHEMA = zen("cmbSchema").getValue();
	this.SYSTEMFLAG = zen("chkSystem").getValue() ? 1 : 0;
	this.DEPRECATEDFLAG = zen("chkDeprecated").getValue() ? 1 : 0;
	this.CurrentItem = "";
	this.CurrentCatalog = -1;
	var tree = zen("tree");
	tree.refreshContents(1);
	var RecentURLs = this.GetRecentList(filtertype);
	zen("txtFilter").setProperty("valueList",RecentURLs);
	zen("idRespond").setHidden(false);
	zen("groupDetails").setHidden(true);
}

ClientMethod doSelectRow(thisTable) [ Language = javascript ]
{
	var selectedItem = thisTable.getValue();
	var tableId = thisTable.getProperty("id");
	tableId = tableId.charAt(11);
	if (tableId != 4) selectedItem = this.FILTERSCHEMA + "." + selectedItem;
	tableId = parseInt(tableId) - 1;
	var tree = zen("tree");
	var expanded = tree.isNodeExpanded(tableId);	
	if (!expanded) {
		tree.toggleExpanded(tableId);	
	} else {		
		var found = 0;
		var n = 4;
		while (tree.getNodeText(n)) {
			if (tree.getNodeText(n) == selectedItem) {
				found = 1;
				break;	
			}
			n++;
		}
		if (found) {
			zen("idRespond").setHidden(true);
			zen("groupCatalog").setHidden(false);
			tree.setProperty('selectedIndex',n);
			this.doTree(tree);
		} 
	}
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("SQL")
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	If ..NAMESPACE = "" Set ..NAMESPACE = $namespace
	#; set filter/pagesize/max for Query Histroy
	Do ..%GetNavTableState(..%GetPageName()_"^"_"tableQueryHistory")
	If ..Filter = "*",$G($$$IRISTempMgt($Username,..%GetPageName(),"TableNavState"))="" Set ..Filter=""
	
	Set SQLFilterPreference = $G($$$IRISTempMgt($Username,"SQLFilterPreference"))
	Set FILTERTYPE = $LG(SQLFilterPreference,1)
	Set SQLFILTER = $LG(SQLFilterPreference,2)
	#; default filter type to "All" so the Filter user entered maybe maximized in matching list
	Set:FILTERTYPE="" FILTERTYPE = "All"
	Set FILTERPROC = $LG(SQLFilterPreference,3)
	#; default procedure filter type to "Functions & Queries & Extent" to match query Procedures for browse
	Set:FILTERPROC="" FILTERPROC = "2"
	Set (%page.SYSTEMFLAG,..%GetComponentById("chkSystem").value) = +$LG(SQLFilterPreference,4)
	Set (%page.DEPRECATEDFLAG,..%GetComponentById("chkDeprecated").value) = +$LG(SQLFilterPreference,5)
		
	Set (%page.FILTERTYPE,..%GetComponentById("selFilter").value) = FILTERTYPE
	Set ..%GetComponentById("txtFilter").valueList = ..GetRecentList(FILTERTYPE)
	Set (%page.SQLFILTER,..%GetComponentById("txtFilter").value) = SQLFILTER
	Set (%page.FILTERPROC,..%GetComponentById("cmbProcOption").value) = FILTERPROC
	Set:FILTERTYPE="Procedures" ..%GetComponentById("cmbProcOption").hidden = 0
	Set ..%GetComponentById("imageCleartxtFilter").hidden = $S(SQLFILTER="":1,1:0)
	Set SQLExecutePreference = $G($$$IRISTempMgt($Username,"SQLExecutePreference"))
	If SQLExecutePreference '= "" {
		Set (%page.RuntimeMode,..%GetComponentById("selRuntimeMode").value) = $LG(SQLExecutePreference,1)
		Set (%page.MaxRows,..%GetComponentById("txtMaxRows").value) = $LG(SQLExecutePreference,2)
		Set (%page.ShowRowNum,..%GetComponentById("chkShowRowNum").value) = $LG(SQLExecutePreference,3)
		Set (%page.Dialect,..%GetComponentById("selDialect").value) = $LG(SQLExecutePreference,4)
		Set (%page.Foreground,..%GetComponentById("chkForeground").value) = $LG(SQLExecutePreference,6)
	}
	Set ..%GetComponentById("txtOpenTableMaxRows").value = ##class(%CSP.UI.SQL.BrowseTablePane).GetOpenTableMaxRows()
	Set ..%GetComponentById("idRespond").value = $$$TextHTML("Please select an item from the tree.")
	If '##class(%SQL.Manager.API).HasPriv($Username,"0,0,0,0,0,0,0,0,0,0,0,1",0) {
		Set ..%GetComponentById("menuCreateView").disabled = 1
		Set ..%GetComponentById("menuCreateView").title = $$$Text("'Create View' disabled because you do not have %CREATE_VIEW privilege in this namespace.")
	}
	Set EventData = "Filter: "_SQLFILTER_$$$CRLF_"Filter type: "_FILTERTYPE
	Set EventDesc = $$$EventDescription
	$$$SMPAuditView
	#; set filter/pagesize/max for SQL Statement tab
	Set tPageName = ..%GetPageName()_"^"_"statementTable0"
	Set TableState = $G($$$IRISTempMgt($Username,tPageName,"TableNavState"))
	If TableState '= "" {
		Set ..StatementFilter = $lg(TableState,1)
		Set ..StatementPageSize = $lg(TableState,2)
		Set ..StatementMaxRows = $S(+$lg(TableState,3)=0:1000,1:$lg(TableState,3))
		Set tableId = $P(tPageName,"^",2)
		If tableId '= "" {
			Set ..%GetComponentById(tableId).pageSize = ..StatementPageSize
			Set ..%GetComponentById(tableId).maxRows = ..StatementMaxRows
			Set ..%GetComponentById(tableId).lastFilter = ..StatementFilter
		}
	}

	Quit $$$OK
}

/// Draw the contents of the Table Header (the region between the diagram and the table).
Method DrawTableHeader(pSeed As %String) As %Status
{
	Quit $$$OK
}

/// Provide contents of the data source tree.
ClassMethod GetTreeInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
     Set tSC = $$$OK
     #; Save to global for future use
     Set FILTERTYPE = %page.FILTERTYPE
     Set SQLFILTER = %page.SQLFILTER
     Set FILTERPROC = %page.FILTERPROC
     Set FILTERSCHEMA = %page.FILTERSCHEMA
     Set tSystem = %page.SYSTEMFLAG
	 Set tDeprecated = %page.DEPRECATEDFLAG
     Do ..SaveFilter(FILTERTYPE, SQLFILTER, FILTERPROC, tSystem, tDeprecated)
     #; Build the base levels
     #; each node supplies: $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)
     #; top-most nodes are children of 0
     Set tStyle = "font-size:14px;font-weight:bold;"
     Set tExpanded = 0
     If pRoot = "" {
         For n = 1:1:4 Set pTree(0,"ch",n) = ""
         Set lblItem = $$$Text("Tables")
         Set pTree(1) = $LB(lblItem,"Tables",1,"",tExpanded,,lblItem,tStyle)
         Set lblItem = $$$Text("Views")
         Set pTree(2) = $LB(lblItem,"Views",1,"",tExpanded,,lblItem,tStyle)
         Set lblItem = $$$Text("Procedures")
         Set pTree(3) = $LB(lblItem,"Procedures",1,"",tExpanded,,lblItem,tStyle)
         Set lblItem = $$$Text("Cached Queries")
         Set pTree(4) = $LB(lblItem,"CQs",1,"",tExpanded,,lblItem,tStyle)
         Do ..SaveLastTreeLoaded(0,0)
     }
     ElseIf pRoot = "Tables" {
         Set tTotalNumber =..GetTables(tSystem,$S(FILTERTYPE="All"!(FILTERTYPE=pRoot):SQLFILTER,1:""),0,tDeprecated,.pTree)
     	 Do ..SaveLastTreeLoaded(1,tTotalNumber)
     }
     ElseIf pRoot = "Views" {
         Set tTotalNumber =..GetViews(tSystem,$S(FILTERTYPE="All"!(FILTERTYPE=pRoot):SQLFILTER,1:""),0,tDeprecated,.pTree)
     	 Do ..SaveLastTreeLoaded(3,tTotalNumber)
     }
     ElseIf pRoot = "Procedures" {
         Set tTotalNumber =..GetProcedures(tSystem,$S(FILTERTYPE="All"!(FILTERTYPE=pRoot):SQLFILTER,1:""),FILTERPROC,0,tDeprecated,.pTree)
     	 Do ..SaveLastTreeLoaded(4,tTotalNumber) 
     }
     ElseIf pRoot = "CQs" {
         Set tTotalNumber = ..GetCQs(tSystem,$S(FILTERTYPE="All"!(FILTERTYPE=pRoot):SQLFILTER,1:""),FILTERSCHEMA,0,.pTree)
     	 Do ..SaveLastTreeLoaded(5,tTotalNumber) 
     } 
     Else {
	     Set tTableLevel = ..GetTableFields(0,0,pRoot,.pTree)
     }
     Do:$G(tTotalNumber)'="" ..SaveLastTreeLoaded(6,tTotalNumber)
     Quit tSC
}

/// Build array for Tables tree
ClassMethod GetTables(pShowSystem, pFilter, pSchemaNumber, pDeprecated, ByRef pTree) As %Integer
{
     Set tHasChildren = 1
     Set tExpanded = 0
     Set tRoot = 0
     Set tStyle = ""
     Set tMaxRows = $$$SQLMaxTreeLoad
     Set pTree(tRoot,"ch",1) = ""
     Set tSchemaNumber = pSchemaNumber
     Set iconItem = ""  //$S('pShowSystem:..Link("/csp/broker/deepsee/table_16.gif"),1:..Link("/csp/broker/deepsee/system_16.png"))
     Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:TablesTree")
     Do tRS.Execute(pShowSystem,pFilter,pDeprecated)
     #; each node supplies: $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)
     While (tRS.Next() && (tSchemaNumber <= tMaxRows)) {
         Set tSchemaNumber = tSchemaNumber + 1
         Set tSchema = tRS.Data("SCHEMA_NAME")
         Set tTable = tRS.Data("TABLE_NAME")
         
         ;# Class name may be different than schema.table name
         Set tClass = $LG(##class(%SQL.Manager.Catalog).GetTableInfo(tSchema,tTable),7) 
         
         Set pTree(tRoot,"ch",tSchemaNumber) = ""
         Set pTree(tSchemaNumber) = $LB(tSchema_"."_tTable,tSchema_"=="_tTable_"=="_tClass,tHasChildren,"",tExpanded,iconItem,"",tStyle)
     }
     If tSchemaNumber = 0 Quit tSchemaNumber
     Quit tSchemaNumber
}

/// Build field array for a table
ClassMethod GetTableFields(pSchemaNumber, pTableLevel, pTableName, ByRef pTree) As %Integer
{
     #; each node supplies: $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)
	Set lblHiddenTooltip = $$$Text("hidden field name")
	Set tFieldNumber = pTableLevel
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Fields")
	Do tRS.Execute($P(pTableName,"==",1),$P(pTableName,"==",2))
	While tRS.Next() {
		Set tFieldNumber = tFieldNumber + 1
		Set tFieldName = tRS.Data("FIELD_NAME")
		Set pTree(pSchemaNumber,"ch",tFieldNumber) = ""
		#; each node supplies: $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)
		Set tValue = tFieldName_"==0==0==0", tStyle = "",tTooltip = ""
		If tRS.Data("HIDDEN")= "Yes" Set tValue = "", tStyle = "color:gray", tTooltip = lblHiddenTooltip
		Set pTree(tFieldNumber) = $LB(tFieldName,tValue,0,"",0,,tTooltip,tStyle)
	}
	Quit tFieldNumber
}

/// Build array for Views tree
ClassMethod GetViews(pShowSystem, pFilter, pTotalNumber, pDeprecated, ByRef pTree) As %Integer
{
	Set tHasChildren = 0
	Set tRoot = 0
    Set tMaxRows = $$$SQLMaxTreeLoad
	Set pTree(tRoot,"ch",1) = ""
	Set tTotalNumber = pTotalNumber
	Set iconView = ..Link("/csp/broker/deepsee/write_16.png")
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewsTree")
	Do tRS.Execute(pShowSystem,pFilter,pDeprecated)
	While (tRS.Next() && (tTotalNumber <= tMaxRows)) {
		Set tTotalNumber = tTotalNumber + 1
		Set tName = tRS.Data("SCHEMA_NAME")_"."_tRS.Data("VIEW_NAME")
		Set pTree(tRoot,"ch",tTotalNumber) = ""
		Set pTree(tTotalNumber) = $LB(tName,tRS.Data("SCHEMA_NAME")_"=="_tRS.Data("VIEW_NAME"),tHasChildren,"",0,iconView,"")
	}
	Quit +tTotalNumber
}

/// Build array for Procedures tree
ClassMethod GetProcedures(pShowSystem, pFilter, pFilterOption, pTotalNumber, pDeprecated, ByRef pTree) As %Integer
{
	Set tHasChildren = 0
	Set tRoot = 0
    Set tMaxRows = $$$SQLMaxTreeLoad
	Set pTree(tRoot,"ch",1) = ""
	Set tTotalNumber = pTotalNumber
	Set lblProcedures = $$$TextHTML("Procedures")
	Set iconProcedure = ""  //..Link("/csp/broker/deepsee/notepad_16.png")
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ProceduresTree")
	Do tRS.Execute(pShowSystem,pFilter,pFilterOption,pDeprecated)
	While (tRS.Next() && (tTotalNumber <= tMaxRows)) {
		Set tTotalNumber = tTotalNumber + 1
		Set tName = tRS.Data("SCHEMA_NAME")_"."_tRS.Data("PROCEDURE_NAME")
		Set pTree(tRoot,"ch",tTotalNumber) = ""
		Set pTree(tTotalNumber) = $LB(tName,tRS.Data("SCHEMA_NAME")_"=="_tRS.Data("PROCEDURE_NAME"),tHasChildren,"",0,iconProcedure,"")
	}
	Quit +tTotalNumber
}

/// Build array for Cached Queries tree. 
/// If schema is not null then use CachedQueryInfo that takes in the schema name and get routines(classes) that belong to that schema.
/// If filter is not null then match routine name to that filter.
ClassMethod GetCQs(pShowSystem, pFilter, pSchema, pTotalNumber, ByRef pTree) As %Integer
{
	Set lFilter = $ZCVT(pFilter,"L")
	Set tHasChildren = 0
	Set tRoot = 0
    Set tMaxRows = $$$SQLMaxTreeLoad
	Set pTree(tRoot,"ch",1) = ""	
	Set tTotalNumber = pTotalNumber
	Set iconCQ = ""  //..Link("/csp/broker/deepsee/column_16.gif")
	If pSchema = "" {
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:CachedQueryTree")
		Do tRS.Execute()
	}
	Else  {
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:CachedQueryInfo")
		Do tRS.Execute(pSchema)
	}
	While (tRS.Next() && (tTotalNumber <= tMaxRows)) {
		If $ZCVT(tRS.Data("Routine"),"L") '[ lFilter Continue
		Set tName = tRS.Data("Routine")
		Set tTotalNumber = tTotalNumber + 1
		Set pTree(tRoot,"ch",tTotalNumber) = ""
		Set pTree(tTotalNumber) = $LB(tName,tName,tHasChildren,"",0,iconCQ,"")
	}
	Quit +tTotalNumber
}

/// Given schema == table, return a list of fields concatenated by commas excluding hidden fields. Used by drag and drop.
ClassMethod TableFields(tableName) As %String [ ZenMethod ]
{
	Set tSchema = $P(tableName,"==",1)
	Set tTable = $P(tableName,"==",2)
	If tSchema = "" || tTable = "" Quit tableName
	Set tFields = ""
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Fields")
	Do tRS.Execute(tSchema,tTable)
	While tRS.Next() {
		If tRS.Data("HIDDEN") = "No" {
			Set tFields = tFields_$S(tFields'="":", ",1:"")_$$quoter2^%apiSQL(tRS.GetData(1))
		}
	}	
	Quit tFields
}

ClassMethod GetLastTreeLoaded() As %String [ ZenMethod ]
{
	Quit $$$IRISTempMgt($Username,"LastTreeLoaded")
}

/// This functions takes a table/view schema.name and quote either piece if needed
ClassMethod Quoter2(val) As %String [ ZenMethod ]
{
	QUIT:val'["." $$quoter2^%apiSQL(val)	// Is it even possible we don't have schema.table?
	QUIT:$l(val,".")=2 $$quoter2^%apiSQL($p(val,".",1))_"."_$$quoter2^%apiSQL($p(val,".",2))	// schema.table, no other dots
	QUIT $$quoter2^%apiSQL($p(val,".",1,*-1))_"."_$$quoter2^%apiSQL($tr($p(val,".",*),$c(2),"."))	// schema and/or name has dots in it
}

ClassMethod SaveLastTreeLoaded(pBranch, pTotalNumber) As %String
{
	#; pBranch = 0 means to clear temp global for reloading a new tree (e.g. change namespace, or refresh page)
	If pBranch = 0 Set $$$IRISTempMgt($Username,"LastTreeLoaded") = "" Quit
	If pBranch = 1 Set tText = $$$FormatText($$$Text("%1 tables found"),pTotalNumber)
	#; Else  If pBranch = 2 Set tText = $$$FormatText($$$Text("%1 system tables found"),pTotalNumber)
	Else  If pBranch = 3 Set tText = $$$FormatText($$$Text("%1 views found"),pTotalNumber)
	Else  If pBranch = 4 Set tText = $$$FormatText($$$Text("%1 procedures found"),pTotalNumber)
	Else  If pBranch = 5 Set tText = $$$FormatText($$$Text("%1 cached queries found"),pTotalNumber)
	Else  Set tText = ""
	Set $P($$$IRISTempMgt($Username,"LastTreeLoaded"),",",pBranch) = tText
}

/// *** Methods for tree item text click ***
ClientMethod doTree(tree) [ Language = javascript ]
{
	var index = tree.getProperty('selectedIndex');
	var itemValue = tree.getNodeValue(index);
	// zero based - indicating which root it is: Tables, Views, Procedures, CQs
	var parent = tree.getNodeParent(index);
	var parentValue = tree.getNodeValue(parent);
	if (index > -1 && index < 4 && parent > -1) this.updateTreeItems();

	// if user clicked a root label, then show browse pane.
	if (parent < 0) {
		zen("tabGroup").setProperty('currTab',3);
		// if schema name is not null then show matching table
		for (var n=0; n<5; n++) zen("browseTable"+n).setHidden(true);
		var schemaname = zen("cmbSchema").getValue();
		if (schemaname.length > 0) index = parseInt(index) + 1;
		this.doDrill(index,schemaname,0);
		return;
	}
	var isNotTable = (parent>0);
	var isNotView = (parent!=1);
	var isNotProc = (parent!=2);
	var isNotCQ = (parent!=3);
	var text = tree.getNodeText(index);
	var value = tree.getNodeValue(index);
	var schematable = value.split("==");
	// if user clicked a field (value=="" indicate hidden field) for a table, do nothing and quit.
	if (schematable.length == 4 || value == "") return;
	this.CurrentCatalog = parent;
	this.CurrentItem = value;
	zen("lblTableName").setValue(text);
	zen("tabGroup").setProperty('currTab',1);
	zen("menuOpenTable").setDisabled(parent>1);
	zen("menuClassDoc").setDisabled(isNotTable);
	zen("radCatalog").setHidden(isNotTable);
	zen("radCatalogView").setHidden(isNotView);
	zen("radCatalogProc").setHidden(isNotProc);
	zen("radCatalogCQ").setHidden(isNotCQ);
	// hide all the table property fields
	for (var n=0; n<7; n++) zen("tblTable"+n).setHidden(true);
	// hide all the view property fields
	zen("tblView0").setHidden(true);
	// hide all the stored procedure property fields
	zen("tblProc0").setHidden(true);
	zen("htmlViewInfo").setHidden(true);
	zen("htmlProcInfo").setHidden(true);
	zen("htmlCQInfo").setHidden(true);
	zen("tblCQ0").setHidden(true);
	zen("tblCQ0b").setHidden(true);
	zen("tblCQ1").setHidden(true);
	// show table properties
	zen("tblTable1").setHidden(isNotTable);
	switch (parent) {
		case '0':
			zen("lblTableName").setProperty("label",$$$Text("Table: "));
			this.showCatalog();
			break;
		case '1':
			zen("lblTableName").setProperty("label",$$$Text("View: "));
			this.showCatalogView();
			//var html = zen("htmlViewDetails");
			//html.setHidden(false);
			//html.seed = value;
			//html.refreshContents();
			break;
		case '2':
			zen("lblTableName").setProperty("label",$$$Text("Procedure: "));
			this.showCatalogProc();
			//var html = zen("htmlProcedureDetails");
			//html.setHidden(false);
			//html.seed = value;
			//html.refreshContents();
			break;
		case '3':
			zen("lblTableName").setProperty("label",$$$Text("Cached Query: "));
			this.showCatalogCQ(value);
			break;				
	}
	zen("idRespond").setHidden(true);
	zen("groupDetails").setHidden(false);
}

/// This method is called to show schemas
ClientMethod doAllSchemas(applyFilter) [ Language = javascript ]
{
	var zs = zenSynchronousMode;
    zenSynchronousMode = true;
	
	zen("tabGroup").setProperty('currTab',3);
	if (applyFilter == 1) {
		var filter = zen("txtFilter").getValue();
		var lblCaption = $$$Text("Schemas with Filter");
	} else {
		var filter = "";
		var lblCaption = $$$Text("Schemas");
	}
	for (var n=0; n<5; n++) {
		zen("browseTable"+n).setHidden(true);
	}
	var table = zen("browseTable0");
	table.setHidden(false);
	table.parameters[0].value = zen("chkSystem").getValue();
	table.parameters[1].value = filter;
	table.executeQuery();
	table.setProperty("caption","(" + table.getProperty("rowCount") + ") " + lblCaption);
	
	zenSynchronousMode = zs;
	return;
}

/// This method reload a particular listType.
/// The expected behavior: <br>
/// <p>If the current list selected on the tree is equal to the listType and is expanded, then reload the list and expand.</li>
/// </p>
ClientMethod doReloadNode(listType) [ Language = javascript ]
{
	var tree = zen("tree");
	tree.reloadNode(listType);
}

/// User clicked a ReferenceTo link. 
/// Check the current tree to see if we can find the reference class. If yes then make it selected and we won't need to refresh tree.
/// Otherwise, refresh tree with the new reference class as filter.
/// The tree will be collapsed and we will hide groupDetails and show message to remind user to reselect item from tree.
/// type arguement.  0 = Tables, 1 = View, 2 = Stored procedures
ClientMethod doReferenceTo(newtable, type) [ Language = javascript ]
{
	var tree = zen("tree");
	// loop through tree
	try {
		var found = 0;
		var n = 4;
		while (tree.getNodeText(n)) {
			if (tree.getNodeText(n) == newtable) {
				found = 1;
				break;	
			}
			n++;
		}
		if (!found) {
			if (zen("selFilter").getValue() != "All") zen("selFilter").setValue("All");
			zen("txtFilter").setValue(newtable);
			zenPage.toggleClearText(zen("txtFilter"));
			this.doSearch();
			var expanded = tree.isNodeExpanded(type);	
			if (!expanded) {
				tree.toggleExpanded(type);
			}
		} 
		else {
			zen("idRespond").setHidden(true);
			zen("groupCatalog").setHidden(false);
			tree.setProperty('selectedIndex',n);
			this.doTree(tree);
		}
	} 
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in doReferenceTo');
	}
}

/// User clicked a StatementDetailsTo link. 
ClientMethod doStatementDetailsTo(stmthash, openInTab) [ Language = javascript ]
{
	try {
		if (openInTab == null) {
			openInTab = 0;	
		}
		url = this.SQLStatementDetailsPage + "&NAMESPACE=" + encodeURIComponent(this.NAMESPACE) + "&SCHEMA=" + encodeURIComponent(this.FILTERSCHEMA) + "&STMTHASH=" + stmthash + "&OpenInTab=" + openInTab;
		if (openInTab) {
			var win = window.open(url, '_blank');
			win.focus();
		} else {
			zenLaunchPopupWindow(url,'StatementDetails','status,scrollbars,resizable=yes');
		}
	} 
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in doStatementDetailsTo');
	}
}

/// User clicked the Cached Query link (it used to be a routine and now it's class) after executed a query. Hide components so that we can show CQ details.
/// Check the current tree to see if we can find the routine. If yes then make it selected and we won't need to refresh tree.
/// Otherwise, refresh tree with the new routine as filter.
/// The tree will be collapsed and we will hide groupDetails and show message to remind user to reselect item from tree.
ClientMethod prepareProp(routine) [ Language = javascript ]
{
	try {
		var tree = zen("tree");
		var index = tree.getProperty('selectedIndex');
		// zero based - indicating which root it is: Tables, Views, Procedures, CQs
		var parent = tree.getNodeParent(index);
		var expanded = tree.isNodeExpanded(3);
		var found = 0;
		// loop through tree if CQ is open
		if (expanded) {
			var n = 4;
			while (tree.getNodeText(n)) {
				if (tree.getNodeText(n) == routine) {
					found = 1;
					break;	
				}
				n++;
			}
		}
		if (!found) {
			if (zen("selFilter").getValue() != "All") zen("selFilter").setValue("CQs");
			zen("txtFilter").setValue(routine);
			zenPage.toggleClearText(zen("txtFilter"));
			zen("cmbSchema").setValue("");
			tree.setProperty('selectedIndex',-1);
			expanded = false;
			this.doSearch();
			if (!expanded) {
				tree.toggleExpanded(3);
				var timer = zen('timer');
				timer.setProperty('timeout',500);
				timer.startTimer();
			}
		} else {
			zen("idRespond").setHidden(true);
			zen("groupCatalog").setHidden(false);
			tree.setProperty('selectedIndex',n);
			this.doTree(tree);
		}
		
		zen("tabGroup").setProperty('currTab',1);
		zen("menuOpenTable").setDisabled(true);
		zen("menuClassDoc").setDisabled(true);
		zen("radCatalog").setHidden(true);	
		zen("radCatalogView").setHidden(true);	
		zen("radCatalogProc").setHidden(true);	
		zen("radCatalogCQ").setHidden(true);	
		// hide all the table property fields
		for (var n=0; n<7; n++) zen("tblTable"+n).setHidden(true);
		// hide all the view property fields
		zen("tblView0").setHidden(true);
		// hide all the view stored procedure fields
		zen("tblProc0").setHidden(true);
		zen("htmlViewInfo").setHidden(true);
		zen("htmlProcInfo").setHidden(true);
		zen("htmlCQInfo").setHidden(true);

	} 
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in prepareProp');
	}
	
	zen("htmlCQInfo").setHidden(true);
}

/// show catalog details for a table
ClientMethod showCatalog() [ Language = javascript ]
{
	var parent = this.CurrentCatalog;
	var value = this.CurrentItem;
	if (parent < 0) return;
	var schematable = value.split("==");
	var radOption = zen("radCatalog").getValue();
	// hide tables that is not the current selection
	for (var n=0; n<7; n++) zen("tblTable"+n).setHidden(n!=radOption);
	if (radOption == 0) {
		var html = zen("htmlTableInfo");
		html.seed = value;
		html.refreshContents();
	} else {
		// now open the selected table and reload
		var table = zen("tblTable"+radOption);
		table.parameters[0].value = schematable[0];
		table.parameters[1].value = schematable[1];
		table.executeQuery();
	}
}

/// show catalog details for a table
ClientMethod RefreshTableStatements() [ Language = javascript ]
{
	var parent = this.CurrentCatalog;
	var value = this.CurrentItem;
	if (parent == 0) {
		var radOption = zen("radCatalog").getValue();
		if (radOption == 6) {
			var schematable = value.split("==");
			var table = zen("tblTable6");
			table.parameters[0].value = schematable[0];
			table.parameters[1].value = schematable[1];
			table.executeQuery();
		}
	}
	if (parent == 1) {
		var radOption = zen("radCatalogView").getValue();
		if (radOption == 1) {
			var schematable = value.split("==");
			var table = zen("tblView0");
			table.parameters[0].value = schematable[0];
			table.parameters[1].value = schematable[1];
			table.executeQuery();
		}
	}
	if (parent == 2) {
		var radOption = zen("radCatalogProc").getValue();
		if (radOption == 1) {
			var schematable = value.split("==");
			var table = zen("tblProc0");
			table.parameters[0].value = schematable[0];
			table.parameters[1].value = schematable[1];
			table.executeQuery();
		}
	}
}

/// show catalog details for a view
ClientMethod showCatalogView() [ Language = javascript ]
{
	var parent = this.CurrentCatalog;
	var value = this.CurrentItem;
	if (parent < 0) return;
	var schematable = value.split("==");
	var radOption = zen("radCatalogView").getValue();
	if (radOption == 0) {
		zen("htmlViewInfo").setHidden(false);
		zen("tblView0").setHidden(true);
		var html = zen("htmlViewInfo");
		html.seed = value;
		html.refreshContents();
	}
	else {
		// now open the selected table and reload
		zen("htmlViewInfo").setHidden(true);
		zen("tblView0").setHidden(false);
		var table = zen("tblView0");
		table.parameters[0].value = schematable[0];
		table.parameters[1].value = schematable[1];
		table.executeQuery();
	}
}

/// show catalog details for a stored procedure
ClientMethod showCatalogProc() [ Language = javascript ]
{
	var parent = this.CurrentCatalog;
	var value = this.CurrentItem;
	if (parent < 0) return;
	var schematable = value.split("==");
	var radOption = zen("radCatalogProc").getValue();
	if (radOption == 0) {
		zen("htmlProcInfo").setHidden(false);
		zen("tblProc0").setHidden(true);
		var html = zen("htmlProcInfo");
		html.seed = value;
		html.refreshContents();
	}
	else {
		// now open the selected table and reload
		zen("htmlProcInfo").setHidden(true);
		zen("tblProc0").setHidden(false);
		var table = zen("tblProc0");
		table.parameters[0].value = schematable[0];
		table.parameters[1].value = schematable[1];
		table.executeQuery();
	}
}

/// show catalog details for a cached query
ClientMethod showCatalogCQ() [ Language = javascript ]
{
	var parent = this.CurrentCatalog;
	var value = this.CurrentItem;
	if (parent < 0) return;
	var radOption = zen("radCatalogCQ").getValue();
	if (radOption == 0) {
		zen("htmlCQInfo").setHidden(false);
		zen("tblCQ0").setHidden(true);
		zen("tblCQ0b").setHidden(true);
		zen("tblCQ1").setHidden(true);
		var html = zen("htmlCQInfo");
		html.seed = value;
		html.refreshContents();
	}
	if (radOption == 1) {
		zen("htmlCQInfo").setHidden(false);
		zen("tblCQ0b").setHidden(false);
		zen("tblCQ0").setHidden(true);
		zen("tblCQ1").setHidden(true);
		var html = zen("htmlCQInfo");
		html.seed = value;
		html.refreshContents();
		var table = zen("tblCQ0b");
		table.parameters[0].value = value;
		table.executeQuery();
	}
	if (radOption == 2) {
		zen("htmlCQInfo").setHidden(false);
		zen("tblCQ0").setHidden(false);
		zen("tblCQ0b").setHidden(true);
		zen("tblCQ1").setHidden(true);
		var html = zen("htmlCQInfo");
		html.seed = value;
		html.refreshContents();
		var table = zen("tblCQ0");
		table.parameters[0].value = value;
		table.executeQuery();
	}
	if (radOption == 3) {
		zen("htmlCQInfo").setHidden(false);
		zen("tblCQ0").setHidden(true);
		zen("tblCQ0b").setHidden(true);
		zen("tblCQ1").setHidden(false);
		var html = zen("htmlCQInfo");
		html.seed = value;
		html.refreshContents();
		var table = zen("tblCQ1");
		table.parameters[0].value = value;
		table.executeQuery();
	}
}

ClientMethod showCQ(routine) [ Language = javascript ]
{
	zen("lblTableName").setProperty("label",$$$Text("Cached Query: "));
	zen("lblTableName").setProperty("value",routine);
	this.showCQTable(routine);
}

ClientMethod showCQTable(routine) [ Language = javascript ]
{
	var html = zen("htmlCQInfo");
	html.setHidden(false);
	html.seed = routine;
	html.refreshContents();
}

/// show statement details for a table
ClientMethod showStatements() [ Language = javascript ]
{
	//var parent = this.CurrentCatalog;
	//var value = this.CurrentItem;
	//if (parent < 0) return;
	//var schematable = value.split("==");
	var radOption = zen("radStatements").getValue();
	this.StatementRadioSelect = "statementTable"+radOption;

	// hide tables that is not the current selection
	for (var n=0; n<4; n++) zen("statementTable"+n).setHidden(n!=radOption);

	// now open the selected table and reload
	var table = zen("statementTable"+radOption);
	table.executeQuery();
	var navBar = zen("tblNavBar");
	navBar.tablePaneId=zen("statementTable"+radOption);
	navBar.renderContents();
}

ClientMethod showStatement(statement) [ Language = javascript ]
{
	zen("lblTableName").setProperty("label",$$$Text("SQL Statement: "));
	zen("lblTableName").setProperty("value",statement);
	this.showCQTable(statement);
}

ClientMethod showStatementTable(statement) [ Language = javascript ]
{
	var html = zen("htmlStatementDetails");
	html.setHidden(false);
	html.seed = statement;
	html.refreshContents();
}

/// *** Methods for Exeucte Query ***
ClientMethod doHistory() [ Language = javascript ]
{
	zen("idHistory").setHidden(!zen("idHistory").getProperty("hidden"));
	var table = zen("tableQueryHistory");
	table.executeQuery();
	zen("htmlResult").setHidden(true);
	zen("htmlPlan").setHidden(true);
	zen("idPerformance").setHidden(true);
}

ClientMethod doQueryBuilder() [ Language = javascript ]
{
	var text = zen("QueryText").getValue();
	var url = this.BuilderPage+"ClassFilter=&ColumnType=2&$ID1="+encodeURIComponent(text)+"&zenLaunch=1";
	//Do not use zenLuanch here so that query builder could be properly closed by using the 'x' button.
	var win = window.open(url,'QueryBuilder','status=0,scrollbars,resizable,location=0,toolbar=0,titlebar=0,fullscreen=1');
	win.focus();
	zenPage._popupName = 'QueryBuilder';
	return;
}

/// This is currently used for cached queries. When user clicks the cached query name from the Execute Query tab,
/// we reload the tree for the cached query and starts the timer. When the timer reaches it's end it calls this method
/// to have the selected cached query "clicked" so that the CQ info block can be shown.
ClientMethod timeout() [ Language = javascript ]
{
	var tree = zen("tree");
	var expanded = tree.isNodeExpanded(3);
	if (!expanded) {
		var timer = zen('timer');
		timer.setProperty('timeout',500);
		timer.startTimer();
	} else {
		var cqname = zen("txtFilter").getValue();
		this.prepareProp(cqname);
		this.doTree(zen("tree"));
	}
}

/// show or hide the Clear image for Query Text or Filter
ClientMethod toggleClearText(tControl) [ Language = javascript ]
{
	var flag = tControl.getValue()=="";
	zen("imageClear"+tControl.getProperty("id")).setHidden(flag);
	return true;
}

ClientMethod keyUpQueryText(tControl) [ Language = javascript ]
{
	zenPage.toggleClearText(tControl);
	if ((zenEvent.ctrlKey && zenEvent.which == 13)
		 || (zenEvent.ctrlKey && zenEvent.keyCode == 13)) {
		if (!zen('btnCancel').getHidden()){
			if (confirm($$$Text('Are you sure you want to cancel this operation?'))) zenPage.CancelQuery();
		} else {
			zenPage.doExecute();
		}
	}
	return true;
}

/// User clicked Exeucte or ShowPlan link from the Cached Query details box. Query Routine is passed in.
ClientMethod selectCQ(tRoutine, tAction) [ Language = javascript ]
{
	if (tRoutine == "") return;
	// put query text in the Execute Query text box
	var tText = this.GetCQText(tRoutine);
	zen("QueryText").setValue(tText);
	// switch to Execute Query tab
	zen("tabGroup").setProperty('currTab',2);
	switch (tAction) {
		case "Execute":
			this.doExecute();
			break;
		case "ShowPlan":
			this.doShowPlan();
			break;
	}
}

/// This method processes actions for a query history item.
ClientMethod selectHistory(tID, tAction) [ Language = javascript ]
{
	if (tID != "") {
		var tText = this.GetText(tID);
		zen("QueryText").setValue(tText);
		this.toggleClearText(zen("QueryText"));
	}
	switch (tAction) {
		case "Execute":
			this.doExecute();
			break;
		case "ShowPlan":
			this.doShowPlan();
			break;
		case "Delete":
			var ok = this.DeleteHistory(tID);
			if (ok) {
				var table = zen("tableQueryHistory");
				table.executeQuery();
			} else {
				alert(ok);	
			}
			break;
		case "Print":
			var parms = {
					$ID1:tID,
					RuntimeMode:this.RuntimeMode,
					Dialect:this.Dialect,
					ObjectSelectMode:this.ObjectSelectMode,
					ShowRowNum:(this.ShowRowNum ? 1 : 0),
					$NAMESPACE:this.NAMESPACE,
					Foreground:(this.Foreground ? 1 : 0)
			};
			zenLaunchPopupWindow('%CSP.UI.Portal.SQL.PrintQuery.zen','Print','status,scrollbars,resizable=yes',parms);		
			break;

	}
}

/// user clicked a tab. hide/show result tables, and alter tab's background color.
ClientMethod tabChanged(tab, totalTabs) [ Language = javascript ]
{
	var flag;
	var bgcolor;
	for (var n=1; n <= totalTabs; n++) {
		if (document.getElementById("div"+n)) {
			flag = (n != tab) ? "none" : "block";
			document.getElementById("div"+n).style.display = flag;
			document.getElementById("extab"+n).className = (n != tab) ? "tabGroupButtonOff" : "tabGroupButtonOn";
		}
	}
}

ClientMethod toggleOptions() [ Language = javascript ]
{
	var group = zen("selDialect");
	var newOption = !group.getProperty("hidden");
	var linkLabel = (newOption ? $$$Text("more") : $$$Text("less"));
	zen("chkShowRowNum").setHidden(newOption);
	zen("selDialect").setHidden(newOption);
	zen("chkForeground").setHidden(newOption);
	zen("linkOptions").setProperty("caption",linkLabel);
}

/// Drop handler for model table.
ClientMethod tableDropHandler(dragData) [ Language = javascript ]
{
	if (dragData.value == "") return;
	// current query text
	var textarea = zen("QueryText");
	var query = textarea.getValue();

	// tree node
	var tree = zen("tree");
	var index = tree.getProperty('selectedIndex');

	// zero based - indicating which root it is: Tables, Views, Procedures, CQs
	var parent = tree.getNodeParent(index);
	if (parent < 0) return;
	var parentNode = tree.getNodeValue(parent);
	if (parentNode == "CQs") {
		return;	
	}
	var fields = this.TableFields(dragData.value);
	if (fields != dragData.value) {
		if (query != "") query = query + "\n\n";
		if (fields != "" ) query = query + "SELECT \n" + fields + "\nFROM " + this.Quoter2(dragData.text);
		else query = query + dragData.text;	
	} else {
		if (query != "") query = query + ", ";
		query = query + dragData.value;
	}
	zen("QueryText").setValue(query);
	this.toggleClearText(zen("QueryText"));
}

ClientMethod validateText() [ Language = javascript ]
{
	var text = zen("QueryText").getValue();
	if (zenTrim(text) == "") {
		alert($$$Text("Query Text is empty. Please enter query text and try again."));
		return false;
	}
	return true;
}

/// Return tree's selected index value
ClientMethod getTable() [ Language = javascript ]
{
	var tree = zen("tree");
	var index = tree.getProperty('selectedIndex');
	if (index < 0) return '';
	var value = tree.getNodeValue(index);
	return value
}

/// This method takes care of actions that need schema.table name
ClientMethod doActionTable(action) [ Language = javascript ]
{
	var value = this.CurrentItem;
	var schematable = value.split("==");
	if (schematable == "") {
		alert(this.msgSelectTable);
		return;
	}
	var url = "";
	var schema = schematable[0];
	var table = schematable[1];
	var param = "$ID1=" + encodeURIComponent(schema) + "&$ID2=" + encodeURIComponent(table);
	switch (action) {
		case 'PrintDetails':
			url = this.PrintDetailsPage + param;
			zenLaunchPopupWindow(url,action,'resizable=yes');
			break;
		case 'OpenTable':
			var page = (this.CurrentCatalog == 0) ? this.OpenTablePage : this.OpenViewPage;
			url = page + param;
			var win = window.open(url,action,'status=0,scrollbars,resizable,location=0,toolbar=0,titlebar=0,fullscreen=0');
			win.focus();
			break;
		case 'ClassDoc':
			// class name (may be different than schema.table name
			this.doOpenDoc(schematable[2]); 
			break;
		case 'Delete':
			var dropType = "";
			if (this.CurrentCatalog == 0) {
				if (confirm($$$Text("Are you sure you want to drop this table or link?"))) {
					dropType = "TABLE";
				}
			}
			if (this.CurrentCatalog == 1) {
				if (confirm($$$Text("Are you sure you want to drop this view?"))) {
					dropType = "VIEW";
				}				
			}
			if (this.CurrentCatalog == 2) {
				if (confirm($$$Text("Are you sure you want to drop this procedure?"))) {
					dropType = "PROCEDURE";
				}								
			} 	
			if (this.CurrentCatalog == 3) {
				if (confirm($$$Text("Are you sure you want to delete this cached query?"))) {
					dropType = "CACHEDQUERY";
				}								
			}
			if (dropType == "") {
				break;
			}
			var ok = this.Drop(dropType, schema, table);
			if (ok != "") {
				alert(ok);
			} else {
				/// we need to refresh the page so Catalog Details can be cleared too
				document.location = this.SQLHomePage;
			}
			break;
		case 'TuneTable':
			if (this.CurrentCatalog < 1) {
				var parms = {
				$NAMESPACE: this.NAMESPACE,
				SCHEMANAME: schema,
				TABLENAME: table
				};
				zenLaunchPopupWindow(this.TuneTablePage,'TuneTable','status,scrollbars,resizable=yes,width=1000,height=800',parms);
			} else {
				alert(this.msgSelectTable);	
			}
			break;
		case 'RebuildIndices':
			if (confirm($$$Text("Are you sure you want to rebuild indices for this table or link? This will acquire an extent lock on the table in order to build the indices.  Job will be run in the background."))) {
				var ok = this.RebuildIndices(schema, table);
				if (ok != "") {
					alert(ok);
				}
			}
			break;
		case 'PurgeCQTable':
			if (this.CurrentCatalog == 4) {
				alert(this.msgSelectTable);
				break;	
			}
			if (!table) {
				alert($$$Text("To purge all cached query for a table, please select a table from the tree first."));	
				break;
			}
			var cqname = schema+"."+table;
			var msg = this.msgDeleteCQTable.replace("%1",cqname);
			ok = confirm(msg);
			if (ok == false) return;
			ok = this.DeleteQuery(action,cqname);
			if (ok != 1) alert(ok);
			// refresh CQ table only if we are looking at it
			if (zen("radCatalog").getValue()==5) zen("tblTable5").executeQuery(0);
			// refresh statement table only if we are looking at it
			if (zen("radCatalog").getValue()==6) zen("tblTable6").executeQuery(0);
			if (zen("radCatalogView").getValue()==1) zen("tblView0").executeQuery(0);
			if (zen("radCatalogProc").getValue()==1) zen("tblProc0").executeQuery(0);
			break;	
		case 'PurgeCQRoutines':
			if (this.CurrentCatalog < 2) {
				this.deleteSelectedQuery();
			} else {
				if (confirm($$$Text("Are you sure you want to delete this cached query?"))) {
					dropType = "CACHEDQUERY";
					var ok = this.Drop(dropType, schema, table);
					if (ok != "") {
						alert(ok);
					} else {
						/// we need to refresh the page so Catalog Details can be cleared too
						document.location = this.SQLHomePage;
					}
				}						
			}				
			break;
	}
}

/// This method opens Documatic in a seperate window. Called by table class doc and procedure doc.
ClientMethod doOpenDoc(className) [ Language = javascript ]
{
	url = this.DocumaticPage + "LIBRARY=" + encodeURIComponent(this.NAMESPACE) + "&CLASSNAME=" + encodeURIComponent(className);
	var win = window.open(url,'docbook','status,scrollbars,resizable,location=1,toolbar=1,menubar=1');
	win.focus();
}

ClientMethod doOpenTableMax(maxRows) [ Language = javascript ]
{
	if ((maxRows == "") || (isNaN(maxRows)==true) || (maxRows == 0)) {
		maxRows = 100;
	} else if ((parseInt(maxRows) > 10000)) {
		maxRows = 10000;
	} else {
		maxRows = Math.round(maxRows);
	}
	zen("txtOpenTableMaxRows").setValue(maxRows);	
	this.OpenTableMaxRowsUpdate(maxRows);
}

/// if there are selected quries, then we are deleting selected queries.
/// else 1) if there are selected schema.table, then asking if user wants to delete 
ClientMethod deleteSelectedQuery() [ Language = javascript ]
{
	var table = zen("tblTable5");
	var total = table.getProperty("rowCount");
	if (total < 1) {
		alert($$$Text("Nothing to delete."));
		return;	
	}
	var selectedRows = table.getProperty("selectedRows");
	var ok = this.PrepareDeletion("PurgeCQRoutines",selectedRows);
	if (ok == 0) {
		alert($$$Text("No queries were selected for deletion."));
		return;
	}
	ok = confirm($$$Text("Are you sure you want to delete the selected queries?"));
	if (ok == false) return;
	// now go delete them
	ok = this.DeleteQuery("PurgeCQRoutines");
	if (ok != 1) alert(ok);
	table.executeQuery(0);
}

/// This method takes care of actions that do not need schema.table name
ClientMethod doAction(action) [ Language = javascript ]
{
	var url = "";
	var openwin = 0;
	if (action.substring(0,6) === "pTools") {
		var pToolsMenu = action;
		action = 'pTools';
	}
	switch (action) {
		case 'CreateView':
			url = this.SQLViewPage + "isNew=1&NAMESPACE=" + encodeURIComponent(this.NAMESPACE) + "&SCHEMA=" + encodeURIComponent(this.FILTERSCHEMA);
			if (this.CurrentCatalog == 3) {
				url = url + "&VIEWNAME=" + encodeURIComponent(this.CurrentItem);
			}
			break;
		case 'EditView':
			url = this.SQLViewPage + "isNew=0&NAMESPACE=" + encodeURIComponent(this.NAMESPACE) + "&SCHEMA=" + encodeURIComponent(this.FILTERSCHEMA) + "&VIEWNAME=" + encodeURIComponent(this.CurrentItem);
			break;			
		case 'ClearFilter':
			zen("txtFilter").setValue('');
			this.toggleClearText(zen("txtFilter"));
			zen("txtFilter").focus();
			break;
		case 'ClearQueryText':
			zen("QueryText").setValue('');
			this.toggleClearText(zen("QueryText"));
			zen("QueryText").focus();
			break;
		case 'SQLCodes':
			url = this.DocBookPage + "KEY=RERR_sql";
			openwin = 1;
			break;
		case 'ReservedWords':
			url = this.DocBookPage + "KEY=RSQL_reservedwords";
			openwin = 1;
			break;
		case 'PurgeCQNamespace':
			var msg = this.msgDeleteCQNamespace.replace("%1",this.NAMESPACE);
			var ok = confirm(msg);
			if (ok == false) return;
			ok = this.DeleteQuery(action,this.NAMESPACE);
			if (ok != 1) {
				alert(ok);
				return;
			}
			/// refresh page because we need to reload the tree and CQ catalog table (if it is being shown)
			document.location = this.SQLHomePage;		
			break;
		case 'TuneAllTable':
			var value = this.CurrentItem;
			var schematable = value.split("==");
			var schema = schematable[0];
			url = this.TuneAllTablePage + "SCHEMA=" + encodeURIComponent(schema);
			break;
		case 'StatementExport':
			var parms = {
					HASH:'',
					EXPORTALL:1,
					$NAMESPACE:this.NAMESPACE
			};
			zenLaunchPopupWindow('%CSP.UI.Portal.SQL.ExportStatement.zen','Export','status,scrollbars,resizable=yes,width=610,height=700',parms);
			break;
		case 'StatementImport':
			var parms = {
					$NAMESPACE:this.NAMESPACE
			};
			zenLaunchPopupWindow('%CSP.UI.Portal.SQL.ImportStatement.zen','Import','status,scrollbars,resizable=yes,width=610,height=700',parms);
			break;
		case 'pTools':
			var menu = pToolsMenu.substring(6);
			if (this._sqlInfo) {
				if (this._sqlInfo.pTools[menu-1]) {
					url = this._sqlInfo.pTools[menu-1].url;
				}
				openwin = 1;
			}
			break;
		case 'currentStatements':
			openwin = 1;
			url = this.CurrentStatementPage;
			break;
	}
	if (url == "") return;
	if (openwin) {
		var openWinName = (action=='pTools') ? 'pTools' : 'docbook';
		var win = window.open(url,openWinName,'status,scrollbars,resizable,location=1,toolbar=1,menubar=1');
		win.focus();
	} else {
		zenLaunchPopupWindow(url,action,'status,scrollbars,resizable=yes,width=700,height=600');
	}
}

ClientMethod doDeleteAll() [ Language = javascript ]
{
	if (confirm($$$Text("Are you sure you want to delete all query history?"))==true) {
		this.DeleteHistoryAll();
		this.doHistory();
	}
}

ClientMethod doInprogress() [ Language = javascript ]
{
	self.document.getElementById("statistics").innerHTML = $$$Text("Executing query...") + (zen("chkForeground").getValue() ? '   [Process: ' + this.processID + ']' : '');
	zen("idPerformance").setHidden(false);
	zen("btnPrint").setHidden(true);
}

ClientMethod doExecute() [ Language = javascript ]
{
	if (this.validateText() == false) return;
	this.doInprogress();
	var text = zen("QueryText").getValue();
	zen("htmlPlan").setHidden(true);
	var html = zen("htmlResult");
	html.setHidden(true);
	// use the following code which will not re-execute if the query text is the same as the last time
	var promptCount = this.PrepareQuery(text,this.RuntimeMode,this.Dialect,this.ObjectSelectMode);
	if (isNaN(promptCount)) {
		zen("idPerformance").setHidden(true);
		html.setHidden(false);
		html.seed = 'error:'+promptCount;
		html.refreshContents();
	} else {
		if (promptCount > 0) {
			var url = this.SQLParametersPage + "PromptCount=" + promptCount;
			zenLaunchPopupWindow(url,'ParametersInput','status,scrollbars,resizable=yes');
		} else {
			// use the following code to force re-execute even if the query text is the same (needed if Display mode is changed)
 			if (zen("chkForeground").getValue() == true) { // --- Execute SQL Query in the Foreground ---
				zen("btnExecute").setDisabled(true);
				var sc = zenPage.StartQuery(1);
				html.seed = "text";
				html.refreshContents();
 			}
 			else { // --- Execute SQL Query in the Background ---
				zen("btnExecute").setHidden(true);
				var sc = zenPage.StartQuery(0);
				zen("btnCancel").setHidden(false);
				html.seed = "text";
				//html.refreshContents();
 			}
			zen("idHistory").setHidden(true);
		}
	}
}

Method CancelQuery() As %Boolean [ ZenMethod ]
{
	set tTaskID = $g(^IRIS.Temp.ExecuteQuery($Username,..CurrentQueryID,"TaskID"))
	if tTaskID {
		set tSC=$SYSTEM.SQL.CancelQuery(tTaskID)             // Graceful Termination
		do:$$$ISERR(tSC) $SYSTEM.Process.Terminate(tTaskID)  // Forced Termination
		kill ^IRIS.Temp.ExecuteQuery($Username,..CurrentQueryID)
	}
	set ..CurrentQueryID = ""
	&js<zenPage.clearBackgroundTask();
		zen('btnCancel').setHidden(true);
		zen('btnExecute').setHidden(false);
		self.document.getElementById("statistics").innerHTML = "Query cancelled";>
	quit $$$OK
}

Method StartQuery(foreground As %Boolean = 0) As %Boolean [ ZenMethod ]
{
	set (n,tSQL)="", sc = $$$OK
	for  {
		set n = $o(%session.Data($Username,"SQL","QueryText",n)) 
		quit:n=""  
		set tSQL = tSQL_$$$CRLF_%session.Data($Username,"SQL","QueryText",n)
	}
	
	if foreground { // --- Store Foreground Execution Query Output in Slot 0 --- [MRP1305]
		set ..CurrentQueryID=0  // Slot 0 reserved for Foreground Execution!
		kill ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID)   // Tabula Rasa!
		set ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID)=1  // Acquire Slot
	}
	else { // --- Find a Free Slot to Store Background Execution Query Output --- [BDB933]
		for { // --- Acquire a '..CurrentQueryID' Slot ---
			lock +^IRIS.Temp.ExecuteQuery($username):0   // Acquire Top-Level Global LOCK!
			continue:'$test  // Lock already Acquired!
			
			set currentQueryID=$o(^IRIS.Temp.ExecuteQuery($username," "),-1)+1
			set ^IRIS.Temp.ExecuteQuery($username,currentQueryID)=1  // Acquire Slot
			set ..CurrentQueryID=currentQueryID
			lock -^IRIS.Temp.ExecuteQuery($username)  // Unlock Top-Level Global!
			quit
		}
	}
	
	merge ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"sessionData") = %session.Data($username,"SQL")
	set ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"mlconfiguration")=$system.Context.SQL().MLConfiguration	// record current process's ML Configuration, use the same one in the backgroupd process
	set ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"FullSQL") = tSQL // BDB927
	set ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"interface")=$CASE(foreground,1:"Foreground",:"Background")
	quit $s(foreground:$$$OK, 1:..%RunBackgroundMethod("StartQueryExecution", 1, ..CurrentQueryID, %page.RuntimeMode, %page.Dialect, %page.ObjectSelectMode, %page.ShowRowNum, %page.MaxRows))
}

ClassMethod %OnFinishBackgroundTask(pTaskID As %String) As %Status
{
	&js<zen('htmlResult').refreshContents();>
}

ClassMethod %OnMonitorBackgroundTask(pTaskID As %String, pStatus As %String, pPercentComplete As %Float)
{
	set tStatus = $zconvert(pStatus,"O","JS")
	&js<self.document.getElementById("statistics").innerHTML = "#(tStatus)#";>
}

ClassMethod StartQueryExecution(pRunInBackground As %Boolean = 1, pQueryID As %Integer, pRuntimeMode As %String, pDialect As %String, pObjectSelectMode As %Integer, pShowRowNum As %Boolean, pMaxRows As %Integer) As %Status
{
	if pRunInBackground { new %inBackground set %inBackground=1 }
	set tSC=$$$OK
	try {
		// BDB836
		do:pRunInBackground ..%SetBackgroundMethodStatus($$$Text("Executing query")_"...")
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "TaskID") = +$job
		
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "Status") = ""
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "Time") = $ZDT($ZU(188),3,,3)
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "Error") = ""
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "Performance") = ""
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "DiagResult") = ""
		if $d(^IRIS.Temp.ExecuteQuery($username, pQueryID, "mlconfiguration"),mlconfig),$system.Context.SQL().MLConfiguration'=mlconfig { set $system.Context.SQL().MLConfiguration=mlconfig } // get MLConfiguration from parent process
		
		// BDB927 
		set pSQL = ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "FullSQL")
		
		// BDB836
		merge tSessionData = ^IRIS.Temp.ExecuteQuery($username, pQueryID, "sessionData")
		
		#;HSU284+
		s tAccStat = 0
		Do ##class(%CSP.UI.Portal.SQL.Utils).InitCollectStats(.tAccStat)
		#;HSU284-
		
		Set msgCount = $$$TextHTML("Row count")
		Set msgStatistics = $$$TextHTML("Performance")	
		Set msgSeconds = $$$TextHTML("seconds")
		Set msgGloRefs = $$$TextHTML("global references")
		Set msgLines = $$$TextHTML("commands executed")
		Set msgDiskRead = $$$TextHTML("disk read latency (ms)")
		Set tStart = $ZH
		Set EventDesc = "Execute Query"
		Set EventData = "Query text: "_pSQL
		// Cause sharded queries to collect shard-local statistics
		new %SNGetQueryStats
		s %SNGetQueryStats=1
		Set tResult = ##class(%CSP.UI.Portal.SQL.Utils).SQLExecuteQuery(pSQL, .tClassName, pRuntimeMode, pDialect, pObjectSelectMode,,.tDiskRead,.StatementType,.tAccStat,.tSessionData,pQueryID,.pRuntimeClassName)
		If $L(EventData) > 16300 Set EventData = $E(EventData,1,16300)_"..."
		$$$SMPAuditExecute

		// BDB836
		do:pRunInBackground ..%SetBackgroundMethodStatus($$$Text("Fetching query result")_"...")
		
		Set tDrawTab = 1
		Do ##class(%CSP.UI.Portal.SQL.Utils).DrawResult(tResult,tDrawTab,pShowRowNum,.tAccStat,pMaxRows,pQueryID)
		
		// BDB836
		do:pRunInBackground ..%SetBackgroundMethodStatus($$$Text("Rendering result")_"...")
		
		Set tCount = $G(^IRIS.Temp.ExecuteQuery($Username, pQueryID, "ResultCount"))
		Set tTime = $ZH - tStart

		Set tGlobals = tAccStat("gloref"),tCommands=tAccStat("commands"),tDiskRead=$zu(67,41,$J)+$system.Context.WorkMgr().DiskReadMilliseconds-tDiskRead
		if $g(^IRIS.Temp.ExecuteQuery($username, pQueryID, "mlconfiguration"))'=$system.Context.SQL().MLConfiguration { set ^IRIS.Temp.ExecuteQuery($username,"mlconfiguration")=$system.Context.SQL().MLConfiguration }	// ML CONFIGURATION changed, record it in temp global
		
		Set tStats = msgCount _": <b>"_tCount_"</b> "_msgStatistics _": <b>"_$FN(tTime,"",4) _ "</b> "_msgSeconds_"&nbsp;&nbsp;<b>" _ tGlobals _ "</b> " _ msgGloRefs_ "&nbsp;<b>"_tCommands_"</b> "_msgLines_$select($get(^%SYS("Compiler","EnableDiskReadTiming"),1):"&nbsp;<b>"_tDiskRead_"</b> "_msgDiskRead,1:"")
		If $G(tClassName) '= "" {
			set cls(1) = tClassName
			set:$G(pRuntimeClassName)'="" cls(2)= pRuntimeClassName
			set key=""
			for{
				set key = $o(cls(key),1,cqName) q:key=""
				Set t = $$$HTMLENCODE(cqName)
				if '((StatementType>6 && (StatementType<20)) || ((StatementType>25) && (StatementType '= 45))) {
					Set tStats = tStats _$s(key=1:"&nbsp;&nbsp;"_$$$TextHTML("Query: "),1:$$$TextHTML(", "))_"<a href='#' onclick='zenPage.prepareProp("""_t_"""),zenPage.showCQ("""_t_""")'>"_t_"</a></div>"	
				}
				else {	// cached query not retained, so don't allow user to click to clink on the link.
					Set tStats = tStats _ $s(key=1:"&nbsp;&nbsp;"_$$$TextHTML("Query: "),1:$$$TextHTML(", "))_t
					if StatementType=69 { set DiagResult=tResult.%ROWID }
				}
				
				// BDB883 - flag frozen statements
				// tClassName will not exist if we don't keep the cached query class (e.g., for DDL statements).
				try {
					set tStatementHash = $select($System.CLS.IsMthd(cqName, "%New"):$parameter(cqName, "%StatementIndexHash"), 1:"")
				} catch {
					set tStatmentHash = ""
				}
				if (tStatementHash '= "") {
					do ##class(%SQL.Manager.Catalog).GetStatementInfo(tStatementHash,,,,.tPlanState)
					if (+$g(tPlanState))>0 { // only display if not unfrozen
						set tPlanStateStr = $case(tPlanState,0:$$$TextHTML("Unfrozen"),1:$$$TextHTML("Frozen/Explicit"),2:$$$Text("Frozen/Upgrade"),3:$$$TextHTML("Unfrozen/Parallel"),:"")
						set tStats = tStats _ "&nbsp;&nbsp;(<a href=""javascript:zenPage.doStatementDetailsTo('"_tStatementHash_"');"" title=""Click to view SQL statement details"">"_tPlanStateStr_"</a>)"
					}
				}
			}
		}
		Set tStats = tStats _"&nbsp;&nbsp;"_$$$TextHTML("Last update: ")_^IRIS.Temp.ExecuteQuery($Username, pQueryID, "Time")
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "Status") = "Done"
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID ,"Performance") = tStats
		set:$d(DiagResult) ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "DiagResult") = DiagResult	// LOAD DATA
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID, "Error") = $$$HTMLENCODE($system.Status.GetErrorText(tSC))
		Set ^IRIS.Temp.ExecuteQuery($Username, pQueryID ,"Status") = "Done"
	}
	do:pRunInBackground ..%EndBackgroundMethod()
 	Quit $$$OK
}

/// This is the method for rebuilding a particular index
ClientMethod doRebuildIndex(pIndex) [ Language = javascript ]
{
	var value = this.CurrentItem;
	var schematable = value.split("==");
	if (schematable == "") return;
	var schema = schematable[0];
	var table = schematable[1];
	var ok = this.RebuildIndices(schema, table, pIndex);
	if (ok != "") {
		alert(ok);
	}
}

ClientMethod doShowPlan() [ Language = javascript ]
{
	if (this.validateText() == false) return;
	var text = zen("QueryText").getValue();
	this.updateParameters();
	zen("htmlResult").setHidden(true);
	zen("idPerformance").setHidden(true);	
	var html = zen("htmlPlan");
	html.setHidden(false);
	var ok = this.PrepareAction(text);
	if (ok) {
		html.seed = "text";
		html.refreshContents();
		zen("idHistory").setHidden(true);
	}
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod historyFilterChanged(value) [ Language = javascript ]
{
	this.Filter = value;
	var table = zen("tableQueryHistory");
	table.parameters[0].value = value;
	table.executeQuery();
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows,"tableQueryHistory");
}

/// Update number of tree items loaded after a tree branch is loaded.
/// Totals are displayed at the bottom of the the tree pane
ClientMethod updateTreeItems() [ Language = javascript ]
{
	var last = this.GetLastTreeLoaded();
	var items = last.split(",");
	var text = "";
	for (var n=0;n<items.length;n++) {
		if (items[n] != "") text = text + items[n] + "\n";
	}
	zen("lblTotalLoaded").setValue(text);
}

/// Update properties for Execute Query and save to server for the future.
ClientMethod updateParameters() [ Language = javascript ]
{
	// Validate max rows. Maximum allowed is 100000.
	// If nothing is entered, invalid entry is entered or a number is greater than 100000, then default to 100000.
	var maxRows = zenTrim(zen("txtMaxRows").getValue());
	if ((maxRows == "") || (isNaN(maxRows)==true) || (parseInt(maxRows) > 100000)) {
		maxRows = 100000;
	} else {
		maxRows = Math.round(maxRows);
	}
	if (maxRows < 0) maxRows = 1000;
	zen("txtMaxRows").setValue(maxRows);
	this.RuntimeMode = zen("selRuntimeMode").getValue();
	this.MaxRows = maxRows;
	this.ShowRowNum = (zen("chkShowRowNum").getValue() ? 1 : 0);
	this.Dialect = zen("selDialect").getValue();
	this.Foreground = (zen("chkForeground").getValue() ? 1 : 0);
	this.SaveParameters(this.RuntimeMode,this.MaxRows,this.ShowRowNum,this.Dialect,this.ObjectSelectMode,this.Foreground);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return;
	switch(popupName) {
	case 'switchNamespace':
		var url = zenPage.GetNewURL(value,"%25CSP.UI.Portal.SQL.Home.zen");
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = url;
		break;
	case 'QueryBuilder':
		zen("QueryText").setValue(value);
		zen("QueryText").focus();
		break;
	case 'CreateView':
		//reloadNode for tree Views
		this.doReloadNode(2);
		break;
	case 'EditView':
		//update the currently selected view Catalog Details
		this.doTree(zen("tree"));
		break;
	case 'TuneAllTable':
		break;
	case 'ParametersInput':
		var html = zen("htmlResult");
		html.seed = "text";
 		if (zen("chkForeground").getValue() == true) { // --- Execute SQL Query in the Foreground ---
			zen("btnExecute").setDisabled(true);
			var sc = zenPage.StartQuery(1);
			html.refreshContents();
 		}
 		else { // --- Execute SQL Query in the Background ---
			zen("btnExecute").setHidden(true);
			var sc = zenPage.StartQuery(0);
			zen("btnCancel").setHidden(false);
			//html.refreshContents();
 		}
		zen("idHistory").setHidden(true);
		break;
	case 'TuneTable':
		var table = zen("tblTable2");
		table.parameters[0].value = schematable[0];
		table.parameters[1].value = schematable[1];	
		table.executeQuery(0);
		break;
	case 'StatementDetails':
		var table = zen("statementTable0");
		table.executeQuery(0);
		// refresh statement table only if we are looking at it
		if (zen("radCatalog").getValue()==6) zen("tblTable6").executeQuery(0);
		if (zen("radCatalogView").getValue()==1) zen("tblView0").executeQuery(0);
		if (zen("radCatalogProc").getValue()==1) zen("tblProc0").executeQuery(0);
		break;
	default:
	}
}

/// Given a history ID, return query text
ClassMethod GetText(pID) As %String [ ZenMethod ]
{
	If $D($$$CQ("SMPQueryHistory",$username,0,pID),tData) { Quit $lg(tData,4) }
	Quit ""
}

ClassMethod DeleteHistory(pID) As %String [ ZenMethod ]
{
	Set tSC = $$DeleteHistory^%SYS.DynamicStatement(pID)
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Quit tSC
}

ClassMethod DeleteHistoryAll() [ ZenMethod ]
{
	Kill $$$CQ("SMPQueryHistory",$username)
	Quit
}

ClassMethod DrawPerformance(pSeed) As %Status
{
	Set hlpStatistics = $$$TextHTML("These statistics show the rough cost of executing this query. These values include some cost for displaying the query results.")	
	&html<<div id="statistics" align="left" title="#(hlpStatistics)#" style="color: #404040; font-size: 0.9em; line-height: 150%; padding:4px;">&nbsp;</div>
	<div>>	
	Quit $$$OK
}

/// Draw HTML for Execute Query result.
Method DrawHTML(pText As %String(MAXLEN="")) As %Status
{
	quit:pText="" $$$OK
	
	if ($p(pText,":",1)="error") {
		set sqlcode = $p(pText,":",2), message = $p(pText,":",3,*)
		set sqlcode = $s(sqlcode="":"???", 1:$$$HTMLENCODE(sqlcode))
		set message = $s(message="":$$$TextHTML("Unknown error"), 1:$$$HTMLENCODE(message))
		&html<<div class="Text1">#($$$Text("The following error was raised preparing this statement:"))#</div>>
		&html<<table width="100%" style="border: grey solid 1px; padding: 0px; margin: 0px;">> 
		&html<<tr><th style="border: grey solid 1px; color: white; background: rgb(255,66,66); padding: 2px;">#($$$TextHTML("Error"))#</th></tr>>
		&html<<tr><td style="padding: 2px;"><tt><b>SQLCODE: #(sqlcode)#</b><br/><b>Message: </b>#(message)#</td></tr>>
		&html<</table>>
		quit $$$OK
	}
	
	quit:..CurrentQueryID="" $$$OK
	
	// Foreground execution
	if $g(^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"interface"))="Foreground" {
		quit ..StartQueryExecution(0,..CurrentQueryID,%page.RuntimeMode,%page.Dialect,%page.ObjectSelectMode,%page.ShowRowNum,%page.MaxRows)  // MRP1304
	}
	
	// Background execution: results are waiting in 
	// ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"data")
	quit:'$d(^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"data")) $$$OK
	for i = 1:1:$g(^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"data")) {
		write ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"data",i),!
	}
	// final cleanup happens in GetStatus()
	quit $$$OK
}

ClassMethod DrawShowPlan(pText As %String(MAXLEN="")) As %Status
{
	If pText = "" Quit $$$OK
	Set (n,pText) = ""
	For  Set n = $O(%session.Data($Username,"SQL","QueryText",n)) Quit:n=""  Set pText(n) = %session.Data($Username,"SQL","QueryText",n),pText=n	
	&html<
    <style type="text/css">
   pre { white-space: normal; }
   </style>>
	&html<<div class="Text1">#($$$Text("The execution plan is displayed below:"))#</div>>
	&html<<table cellpadding="0" cellspacing="1" border="0" width="100%">>
	&html<<tr bgcolor="#818181"><td valign="top" align="center">>

	Set tPlan = ##class(%SQL.Manager.ShowPlan).ShowPlan(.pText,,1,,,1,,,,,,,1)

	&html<#(tPlan)#>
	&html<</table>>
	
	Quit $$$OK
}

/// Prepare to execute query.
/// Save user's latest query text into global for later execution
/// Return number of parameters the query text may have.
ClassMethod PrepareQuery(pText, pRuntimeMode, pDialect, pObjectSelectMode) As %String [ ZenMethod ]
{
	#; Save query text
	Set tSC = ..PrepareAction(pText)
	If tSC '= 1 Quit tSC
	#; Findout if there are parameters
	Set tPromptCount = 0
	Set tResult = ##class(%CSP.UI.Portal.SQL.Utils).GetQueryParameters(.pText, pRuntimeMode, pDialect, pObjectSelectMode, .tPromptCount)
	If tResult.%Message = "" Quit tPromptCount
	Quit tResult.%SQLCODE_":"_tResult.%Message
}

ClassMethod OpenTableMaxRowsUpdate(pMax) [ ZenMethod ]
{
	Do ##class(%CSP.UI.SQL.BrowseTablePane).OpenTableMaxRowsUpdate(pMax)
}

/// Save user's latest query text into global for later execution
ClassMethod PrepareAction(pText) As %String [ ZenMethod ]
{
	Set FILETYPE = "SQL"
	KILL %session.Data($Username,FILETYPE,"QueryText")
	#; When pText reach certain size, when it comes here it becomes %Stream.GlobalCharacter object.
	#; We need to read through it and save in to temp globals for future use.
	Set n = 0
	If $IsObject(pText) {
	 	While 'pText.AtEnd {
	 		Set line = pText.ReadLine()
	 		Do ..ParseTextPiece(.n, line)
		}
	} Else {
		Do ..ParseTextPiece(.n, pText)
	}
	Set %session.Data($Username,FILETYPE,"QueryText") = n
	Set tSC = ..SaveQueryHistory(pText, .HistoryId)
	Kill %session.Data($Username,FILETYPE,"HistoryId")
	If $$$ISERR(tSC) {
		Quit $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
	} Else {
		Set %session.Data($Username,FILETYPE,"HistoryId") = HistoryId
	}
	Quit $$$OK
}

/// Parse $C(10) from each line of query text and put into session array
ClassMethod ParseTextPiece(n, tLine)
{
	For m = 1:1:$L(tLine,$C(10)) {
		Set n = n + 1
 		Set piece = $P(tLine,$C(10),m)
		Set %session.Data($Username,"SQL","QueryText",n) = $translate(piece,$char(13))
	}
}

ClassMethod SaveQueryHistory(QueryText As %String, Output HistoryId) As %Status
{
	QUIT $$SaveQueryHistory^%SYS.DynamicStatement(QueryText, .HistoryId)
}

/// Draw HTML for Table info and build link for Class documatic.
ClassMethod DrawTableDetails(pSeed) As %Status
{
	If pSeed = "" Quit $$$OK
	Set schema = $P(pSeed,"==",1)
	Set table = $P(pSeed,"==",2)
	Set tData = ##class(%SQL.Manager.Catalog).GetTableInfo(schema,table)
	If $Lg(tData,1) = 0 {
		Write $$$HTMLENCODE($Lg(tData,2))
		Quit $$$OK	
	}
	Set tClassName = $Lg(tData,7)
	Set tClassTitle = $$$Text("click to see class definition")
	Set tLink = ..Link("/csp/documatic/%25CSP.Documatic.cls",,1)_"LIBRARY="_$ZCVT($namespace,"O","URL")_"&CLASSNAME="_..EscapeURL(tClassName)
	&html<<table class="DetailTable" border="0" cellspacing="0" cellpadding="0">>
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Table Type"))#</td><td class="value">#(..EscapeHTML($Lg(tData,2)))#</td></tr>>
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Owner"))#</td><td class="value">#(..EscapeHTML($Lg(tData,3)))#</td></tr>>
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Last Compiled"))#</td><td class="value">#(..EscapeHTML($Lg(tData,4)))#</td></tr>>
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("External"))#</td><td class="value">#(..EscapeHTML($Lg(tData,5)))#</td></tr>>
 	if $lg(tData,23)'="" { // foreign table
 		&html<<tr><td class="caption" nowrap>#($$$TextHTML("Foreign Server"))#</td><td class="value">#(..EscapeHTML($lg(tData,23)_" ("_$lg(tData,24)_")"))#</td></tr>>
 	}
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Readonly"))#</td><td class="value">#(..EscapeHTML($Lg(tData,6)))#</td></tr>>
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Class Name"))#</td><td class="value"><a href="#(tLink)#" class="link" target="blank" title="#(tClassTitle)#">#(..EscapeHTML(tClassName))#</a></td></tr>>
 	if $lg(tData,15)=1 { // shard-master table
	 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Extent Size (per shard)"))#</td><td class="value">#(..EscapeHTML($Lg(tData,9)))#</td></tr>>
 	} else {
	 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Extent Size"))#</td><td class="value">#(..EscapeHTML($Lg(tData,9)))#</td></tr>>
 	}
 	if $lg(tData,10)'="" &html<<tr><td class="caption" nowrap>#($$$TextHTML("Parent Table"))#</td><td class="value">#(..EscapeHTML($Lg(tData,10)))#</td></tr>>
 	if $lg(tData,11)'="" {
	 	if $l($lg(tData,11)," , ")>1 { &html<<tr><td class="caption" nowrap>#($$$TextHTML("Child Tables"))#</td><td class="value">#(..EscapeHTML($Lg(tData,11)))#</td></tr>> }
	 	else                         { &html<<tr><td class="caption" nowrap>#($$$TextHTML("Child Table"))#</td><td class="value">#(..EscapeHTML($Lg(tData,11)))#</td></tr>> }
 	}
 	if $lg(tData,12)'="" { 
 		&html<<tr><td class="caption" nowrap>#($$$TextHTML("References"))#</td><td class="value">>
 		Set tRefs = $Lg(tData,12)
 		Set tLen = $L(tRefs," , ")
 		For n = 1:1:tLen {
	 		Set tPiece = $P(tRefs," , ",n)
	 		Set tRef = $P(tPiece,"->",2)
	 		If tRef '= "" {
		 		&html<<a href="#" onclick="zenPage.doReferenceTo('#(tRef)#',0);return false;">#(..EscapeHTML(tPiece))#</a>>
		 		If n < tLen &html<,>
		 		&html<&nbsp;>
	 		}
 		}
 		&html<</td></tr>> 
 	}
 	if $Lg(tData,13)=1 { set tDefaultStorage=$$$TextHTML("Yes") } else { set tDefaultStorage=$$$TextHTML("No") }
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Default Storage?"))#</td><td class="value">#(tDefaultStorage)#</td></tr>>
 	if $Lg(tData,14)=1 { set bmfriendly=$$$TextHTML("Yes") } else { set bmfriendly=$$$TextHTML("No") }
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Supports Bitmap Indices"))#</td><td class="value">#(bmfriendly)#</td></tr>>
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("RowID Field Name"))#</td><td class="value">#($lg(tData,17))#</td></tr>>
 	if $lg(tData,18)'="" {
	 	set basedfields=$listtostring($lg(tData,18))
	 	if $ll($lg(tData,18))=1 {
		 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("RowID is based on field"))#</td><td class="value">#(basedfields)#</td></tr>>
	 	} else {
		 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("RowID is based on fields"))#</td><td class="value">#(basedfields)#</td></tr>>
	 	}
 	}
 	set sharded=$case($lg(tData,15),1:$$$TextHTML("Yes - Shard Master Table"),2:$$$TextHTML("Yes - Shard Local Table"),:$$$TextHTML("No"))
 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Sharded"))#</td><td class="value">#(sharded)#</td></tr>>
 	if $lg(tData,16)'="" {
	 	set shardkey=$listtostring($lg(tData,16))
	 	if $ll($lg(tData,16))=1 {
			&html<<tr><td class="caption" nowrap>#($$$TextHTML("Shard Key Field"))#</td><td class="value">#(shardkey)#</td></tr>>
	 	} else {
			&html<<tr><td class="caption" nowrap>#($$$TextHTML("Shard Key Fields"))#</td><td class="value">#(shardkey)#</td></tr>>
	 	}
 	}
 	if $lg(tData,15)=1 {
 	 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Shard Local Class Name"))#</td><td class="value"><a href="#(tLink)#" class="link" target="blank" title="#(tClassTitle)#">#(..EscapeHTML($lg(tData,19)))#</a></td></tr>>
 	 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Shard Local Table Name"))#</td><td class="value">#(..EscapeHTML($Lg(tData,20)))#</td></tr>>
 	} elseif $lg(tData,15)=2 {
 	 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Shard Master Class Name"))#</td><td class="value"><a href="#(tLink)#" class="link" target="blank" title="#(tClassTitle)#">#(..EscapeHTML($lg(tData,21)))#</a></td></tr>>
 	 	&html<<tr><td class="caption" nowrap>#($$$TextHTML("Shard Master Table Name"))#</td><td class="value">#(..EscapeHTML($Lg(tData,22)))#</td></tr>>
 	}
	&html<</table>>		
	Quit $$$OK
}

ClassMethod DrawViewDetails(pSeed) As %Status
{
	If pSeed = "" Quit $$$OK
	Set tID(1) = $P(pSeed,"==",1)
	Set tID(2) = $P(pSeed,"==",2)
	Set LBLMSG("OWNER") = $$$TextHTML("Owner")
	Set LBLMSG("LAST_COMPILED") = $$$TextHTML("Last Compiled")
	Set LBLMSG("DEFINED_AS_READ_ONLY") = $$$TextHTML("Defined as Read Only")
	Set LBLMSG("UPDATABLE") = $$$TextHTML("View is Updatable")
	Set LBLMSG("CLASSNAME") = $$$TextHTML("Class Name")
	Set LBLMSG("CHECK_OPTION") = $$$TextHTML("Check Option")
	Set LBLMSG("CLASSTYPE") = $$$TextHTML("Class Type")
	Set LBLMSG("FIELD_NAME") = $$$TextHTML("Field Name")
	Set LBLMSG("DATATYPE") = $$$TextHTML("Data Type")
	Set LBLMSG("COLLATION") = $$$TextHTML("COLLATION Parameter")
	Set LBLMSG("MAXLEN") = $$$TextHTML("MAXLEN Parameter")
	Set LBLMSG("MAXVAL") = $$$TextHTML("MAXVAL Parameter")
	Set LBLMSG("MINVAL") = $$$TextHTML("MINVAL Parameter")
	Set LBLMSG("BLOB") = $$$TextHTML("BLOB")
	Set LBLMSG("LENGTH") = $$$TextHTML("Length")
	Set LBLMSG("PRECISION") = $$$TextHTML("Precision")
	Set LBLMSG("SCALE") = $$$TextHTML("Scale")
	
	Set msgViewText = $$$TextHTML("View Text")
	Set AllowEdit = ##class(%SQL.Manager.API).HasPriv($Username,"0,0,0,0,0,0,0,0,0,0,0,0,1",0)
	Set msgAlter = $$$Text("'Edit View' disabled because you do not have %ALTER_VIEW privilege in this namespace.")

	// Get Query Text
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewInfo")
	Do tRS.Execute(tID(1),tID(2))
	If tRS.Next() Set sQuery = tRS.GetData(1)
	Else  Set sQuery = "&nbsp;"
	Kill tRS
	// Get View Info Data
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewInfo2")
	Do tRS.Execute(tID(1),tID(2))
	If tRS.Next() {
		Set tInfoCount = tRS.GetColumnCount()
		Kill tInfoData
		For tCol = 1:1:tInfoCount Set tInfoData(tCol,tRS.GetColumnName(tCol)) = $s(tRS.GetData(tCol)'="":tRS.GetData(tCol),1:"&nbsp;")
	}
	Kill tRS
	// Get View Field Data
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewFields")
	Do tRS.Execute(tID(1),tID(2))
	If $$$ISOK(tRS) {
		Set tColCount = tRS.GetColumnCount()
		Set tRow = 0
		Kill tColData
		While tRS.Next() {
			Set tRow = tRow + 1
			For tCol = 1:1:tColCount Set tColData(tRow,tCol) = $s(tRS.GetData(tCol)'="":tRS.GetData(tCol),1:"&nbsp;")
		}
	}
	&html<<table class="DetailTable" border="0" cellspacing="0" cellpadding="0">>
	Set tRow = 0
	Set tRow = $o(tInfoData(tRow))
	While tRow '= "" {
		Set tColName = $O(tInfoData(tRow,""))
 		&html<<tr>
 		<td class="caption" nowrap>#(LBLMSG(tColName))#</td>
 		<td class="value" colspan="#(tColCount-1)#">>
 		If tColName '= "CLASSTYPE" {
	 		&html<#(tInfoData(tRow,tColName))#>
 		} Else {
	 		If tInfoData(tRow,tColName) = "VIEW" {
		 		Set lblEditView = $$$TextHTML("Edit View")
		 		&html<#($$$TextHTML("VIEW"))#>
	 			If AllowEdit {
					&html<&nbsp;
					<a href="javascript:zenPage.doAction('EditView');" class="link">
						<nobr>#(lblEditView)#</nobr></A>
					>
	 			} Else {
		 			&html<&nbsp;<span class="zenHint" title="#(msgAlter)#">&nbsp;(#(lblEditView)#)</span>>
	 			}
	 		} Else {
		 		&html<#(tInfoData(tRow,tColName))#>
	 		}
	 	} 
	 	&html<</td></tr>>	
		Set tRow = $o(tInfoData(tRow))
	}
	&html<<tr><td class="caption">#(msgViewText)#</td>
	<td class="value" colspan="#(tColCount)#">#(sQuery)#</td></tr>>
	&html<<tr>>
	For tCol = 1:1:tColCount &html<<td class="caption" nowrap>#(LBLMSG(tRS.GetColumnName(tCol)))#</td>>
	&html<</tr>>
	Set tRow = 0
	Set tRow = $o(tColData(tRow))
	While tRow '= "" {
		&html<<tr>>
		For tCol = 1:1:tColCount &html<<td class="value" nowrap>#(tColData(tRow,tCol))#</td>>
		&html<</tr>>
		Set tRow = $o(tColData(tRow))
	}

	&html<</table>>

	Quit $$$OK
}

/// Draw html for Procedure detiails
ClassMethod DrawProcedureDetails(pSeed) As %Status
{
	If pSeed = "" Quit $$$OK
	Set tID(1) = $P(pSeed,"==",1)
	Set tID(2) = $P(pSeed,"==",2)
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ProcedureInfo")
	Do tRS.Execute(tID(1),tID(2))

	Set LBLMSG("CLASS_NAME") = $$$TextHTML("Class Name")
	Set LBLMSG("PROCEDURE_TYPE") = $$$TextHTML("Procedure Type")
	Set LBLMSG("METHOD_OR_QUERY_NAME") = $$$TextHTML("Method or Query Name")
	Set LBLMSG("DESCRIPTION") = $$$TextHTML("Description")
	Set LBLMSG("NUMBER_INPUT_PARAMS") = $$$TextHTML("Number of Input Parameters")
	Set LBLMSG("NUMBER_INPUT_OUTPUT_PARAMS") = $$$TextHTML("Number of Input/Output Parameters")
	Set LBLMSG("NUMBER_OUTPUT_PARAMS") = $$$TextHTML("Number of Output Parameters")
	Set LBLMSG("PROCEDURE_INTERFACE") = $$$TextHTML("Procedure Interface")
	Set LBLMSG("NUMBER_OF_COLUMNS") = $$$TextHTML("Number of Columns")
	Set LBLMSG("INPUT_PARAMETERS") = $$$TextHTML("Input Parameters")
	Set LBLMSG("INPUT_OUTPUT_PARAMETERS") = $$$TextHTML("Input/Output Parameters")
	Set LBLMSG("OUTPUT_PARAMETERS") = $$$TextHTML("Output Parameters")
	Set LBLMSG("RESULTSET_COLUMNS") = $$$TextHTML("ResultSet Columns")
	Set LBLMSG("RETURN_VALUE") = $$$TextHTML("Return Value")
	
	Set LBLMSG("query") = $$$Text("query")
	Set LBLMSG("function") = $$$Text("function")
	Set cmdDoc = $$$Text("Class Document")
	Set cmdRun = $$$Text("Run Procedure")
	Set tColumns = tRS.GetColumnCount()
	Set tInterfaceA = $$$Text("-2:  Procedure with a return value that may return result sets")
	Set tInterfaceB = $$$Text("-1:  Procedure without a return value that may return result sets")
	Set tInterfaceC = $$$Text("0:  Procedure without a return value, no result sets")
	Set tInterfaceD = $$$Text("1:  Query procedure (single static result set)")
	Set tInterfaceE = $$$Text("2:  Function with a return value, no result sets")
	Set tInterfaceF = $$$Text("Undetermined")
	Set helpClass = $$$Text("Click to see class definition")
	Set helpQuery = $$$Text("Click to run this procedure")
	Set linkQuery = ..Link("/csp/sys/exp/UtilSqlRunQuery.csp",,1)_"$NAMESPACE="_..EscapeURL($namespace)
	Set linkFunction = ..Link("/csp/sys/exp/UtilSqlRunFunction.csp",,1)_"$NAMESPACE="_..EscapeURL($namespace)
	&html<<table class="DetailTable" border="0" cellspacing="0" cellpadding="0">>
	While tRS.Next() {
		For tCol = 1:1:tColumns {
			Set tCaption = $S($G(LBLMSG(tRS.GetColumnName(tCol)))'="":LBLMSG(tRS.GetColumnName(tCol)),1:tRS.GetColumnName(tCol))
			&html<<tr>
			<td >&nbsp;</td>
			<td class="caption" NOWRAP>#(tCaption)#</td>>
			If tRS.GetColumnName(tCol) = "CLASS_NAME",tRS.GetData(tCol)'="" {
				Set tClassName = tRS.GetData(tCol)
				Set tLink = %page.DocumaticPage _ "LIBRARY=" _ ..EscapeURL(%page.NAMESPACE) _ "&CLASSNAME="_..EscapeURL(tClassName)
				&html<
				<td class="value" nowrap>#(tClassName)#&nbsp;&nbsp;<a href="#(tLink)#" class="link" title="#(helpClass)#" target="_blank">#(cmdDoc)#<a></td>>	
			} ElseIf tRS.GetColumnName(tCol) = "METHOD_OR_QUERY_NAME" {
				Set tLink = $S(procedureType="query":linkQuery,1:linkFunction)_"&$ID1="_..EscapeURL(tID(1))_"&$ID2="_..EscapeURL(tID(2))_"&$ID3="_..EscapeURL($G(tClassName))_"&$ID4="_..EscapeURL(tRS.GetData(tCol))
				&html<
				<td class="value" nowrap>#(tRS.GetData(tCol))#<a href="#(tLink)#" class="link" title="#(helpQuery)#" target="_blank">#(cmdRun)#<a></td>>	
			} ElseIf tRS.GetColumnName(tCol) = "PROCEDURE_INTERFACE" {
				&html<
				<td class="value" nowrap>#($Case(tRS.GetData(tCol),-2:tInterfaceA,-1:tInterfaceB,0:tInterfaceC,1:tInterfaceD,2:tInterfaceE,:tInterfaceF))#</td>
				</tr>>
			} Else {
				&html<
				<td class="value" nowrap>#($s(tRS.GetData(tCol)'="":tRS.GetData(tCol),1:"&nbsp;"))#</td>
				</tr>>
			}
			#; save procedureType for building the link for next row after "Method or Query Name".
			If tRS.GetColumnName(tCol) = "PROCEDURE_TYPE" Set procedureType = tRS.GetData(tCol)
		}
	}

	Set tRS = ""
	// footer
	&html<</TABLE>>

	Quit $$$OK
}

/// Draw html for Cached Query details
ClassMethod DrawCQDetails(pSeed) As %Status
{
	If pSeed = "" Quit $$$OK
	#; CQRoutine = Cached Query Routine Name

	Set CQRoutine = $P(pSeed,"==",1)
	Set (sCreate,sLast,sQueryType) = ""
	Set cmdExecute = $$$Text("Execute")
	Set cmdShowPlan = $$$Text("Show Plan")
	If $G(CQRoutine) = "" Write "<p>",$$$TextHTML("Cached query is no longer defined. Unable to continue."),"</p>" Quit $$$OK
	Set sQuery = ##class(%SQL.Manager.API).GetCachedQueryInfo(CQRoutine,.sCreate,.sLast,.bSource,.sQueryType,,.sStatementOptions)
	Set tQType = $$$TextHTML("Class Name")
	set %session.Data($Username,"SQL","noRTPC")=$s(sQueryType=10:1,1:0)
	&html<<table class="DetailTable" border="0" cellspacing="0" cellpadding="0">>
	&html<<tr>
		<td class="caption" nowarp>#(tQType)#</td>
		<td class="value" nowarp>>
	Set titleOpenRoutine = $$$Text("click to view source code")
	If $Get(bSource) = 1 {
		Set tRoutineName = CQRoutine_".1.int"
		Set link = %page.OpenRoutinePage_"$TYPE=rtn&FILENAME=" _ tRoutineName
		&html<<a href="#(link)#" class="link" title="#(titleOpenRoutine)#" target="_blank">#(CQRoutine)#</a>>
		
	} Else {
		&html<#(CQRoutine)#>
	}
	&html<</td></tr>>
	&html<<tr>
	<td class="caption" nowarp>#($$$TextHTML("Date Created"))#</td>
	<td class="value" nowarp>#($S(sCreate'="":sCreate,1:"&nbsp;"))#
	</td></tr>>

	&html<<tr>
	<td class="caption" nowarp>#($$$TextHTML("Source Code"))#</td>
	<td class="value">#($S(+$Get(bSource)=0:"n/a",1:$$$Text("Click class name to view")))#
	</td></tr>>
	
	&html<<tr>
	<td class="caption" nowarp>#($$$TextHTML("Cached Query Type"))#</td>
	<td class="value">#($S(sQueryType=9:$$$Text("ODBC/JDBC Statement"),sQueryType=10:$$$Text("%Library.ResultSet Dynamic SQL"),sQueryType=8:$$$Text("%SQL.Statement Dynamic SQL"),sQueryType=11:$$$Text("Embedded cached SQL"),1:"n/a"))#
	</td></tr>>
	
	if sQueryType = 9 {
		&html<<tr>
		<td class="caption" nowarp>#($$$TextHTML("Statement Features"))#</td>
		<td class="value">#(sStatementOptions)#
		</td></tr>>
	}
	
	// BDB883 - show statement & frozen flag
	set tStatementHash = $parameter(CQRoutine,"%StatementIndexHash")
	if (tStatementHash'="") {
		&html<<tr>
		<td class="caption" nowarp>#($$$TextHTML("Statement"))#</td>
		<td class="value">>
		&html<<a href="javascript:zenPage.doStatementDetailsTo('#(tStatementHash)#');" title="Click to view SQL statement details">#(tStatementHash)#</a> >
		do ##class(%SQL.Manager.Catalog).GetStatementInfo(tStatementHash,,,,.tPlanState)
		set tPlanStateStr = $case(tPlanState,0:$$$TextHTML("Unfrozen"),1:$$$TextHTML("Frozen/Explicit"),2:$$$TextHTML("Frozen/Upgrade"),3:$$$TextHTML("Unfrozen/Parallel"),:"")
		&html<(#(tPlanStateStr)#)>
		&html<</td></tr>>
	}

	Set espNamespace = $ZCVT($namespace,"O","URL")
	&html<<tr>
	<td class="caption" nowarp>#($$$TextHTML("Query Text"))#>
	if (sQueryType = 8) || (sQueryType = 9) || (sQueryType=11) {		
		if sQueryType'=11 &html<<br><a href="javascript:zenPage.selectCQ('#(CQRoutine)#','Execute');" class="link">#(cmdExecute)#</a>>
		&html<<br><a href="javascript:zenPage.selectCQ('#(CQRoutine)#','ShowPlan');" class="link">#(cmdShowPlan)#</a>>
	}
	&html<
	</td>
	<td class="value">#($S(sQuery'=0:sQuery,1:"&nbsp;"))#
	</td></tr>>
		
	&html<</TABLE>>

	Quit $$$OK
}

/// Given cached query routine name, return query text
ClassMethod GetCQText(pRoutine) As %String [ ZenMethod ]
{
	Quit ##class(%SQL.Manager.API).GetCachedQueryInfo(pRoutine)
}

/// Drop a Table, View, Procedure, or CachedQuery
ClassMethod Drop(pDropType, pSchema, pTable) As %String [ ZenMethod ]
{
	Set Schema = pSchema
	Set Table = pTable
	Set tmsg = ""
	If pDropType '= "CACHEDQUERY" {
		Set gvDummy = ##class(%SQL.Manager.API).CheckIdentifier(.Schema)
		Set gvDummy = ##class(%SQL.Manager.API).CheckIdentifier(.Table)
		Set TableName = Schema_$S(pTable'="":"."_Table,1:"")
		Set EventDesc = "Drop"
		Set EventData = "Drop: "_pDropType_$$$CRLF_"Schema: "_Schema_" Table: "_Table_$$$CRLF_$G(tmsg)
		Set tSC = ##class(%SQL.Manager.API).DropTable(TableName,$ZCVT(pDropType,"U"),.SQLCODE,.tmsg)
	} Else {
		#; Delete a cached query from tree selection
		Set EventDesc = "Purge"
		Set EventData = "Purge query: "_pDropType_$$$CRLF_"Schema: "_Schema	
		Set tSC = ##class(%SQL.Manager.API).PurgeQuery(Schema)
		If $$$ISERR(tSC) Set tmsg = $System.Status.GetErrorText(tSC)
	}
	$$$SMPAuditChange
	Quit $G(tmsg)
}

ClassMethod RebuildIndices(pSchema, pTable, pIndex = "") As %String [ ZenMethod ]
{
	Set tmsg = ""
	If pIndex '= "" Set $li(tParms("Indices"),1) =pIndex
	Set ShowName = pSchema_$s(pTable'="":"."_pTable,1:"")
	Set ClassName = ##class(%SQL.Manager.API).FindClassName(ShowName)
	
	#; YCL214 - check if this is a collection child table, if it is, use the parent class name
	Set TableName=$$IntQualifiedName^%apiSQL(ShowName)
	Set ExtentName=$$$GetExtentNameFromIQN(TableName)
	set ExtInfo = $$$EXTsqlinfo($$$rEXT,ExtentName)
	set:$$$SQLLocTableChildTableType(ExtInfo)'="" ClassName = $$$GetClassNameFromIQN($$$SQLLocTableParentTable(ExtInfo))
	
	Set tParms("ClassName") = ClassName
	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("RebuildIndices",$namespace,.tParms,.tJob)
	If $$$ISERR(status) Set tmsg = $System.Status.GetErrorText(status)
	Quit tmsg
}

/// FILTERTYPE is any of the choices from Filter drop-down.
ClassMethod SaveFilter(FILETYPE, SQLFILTER, FILTERPROC, SYSTEMFLAG, DEPRECATEDFLAG) As %Boolean [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,"SQLFilterPreference") = $LB(FILETYPE, SQLFILTER, FILTERPROC, SYSTEMFLAG, DEPRECATEDFLAG)
	Set:SQLFILTER'="" $$$IRISTempMgt($Username,FILETYPE,"Recent",SQLFILTER) = $zdt($h,3)
	// clean up recent URL list
	// sort list by time, delete oldest...
	Set tCount = 0
	Set tRecent = $order($$$IRISTempMgt($Username,"Recent",FILETYPE,""))
	While (tRecent '= "") {
		Set tCount = tCount + 1
		Set tSort($$$IRISTempMgt($Username,"Recent",FILETYPE,tRecent)) = tRecent
		Set tRecent = $order($$$IRISTempMgt($Username,"Recent",FILETYPE,tRecent))
	}	
	// remove oldest items (there are up to 10)
	While (tCount > 10) {
		Set tOld = $order(tSort(""))
		Kill $$$IRISTempMgt($Username,"Recent",FILETYPE,tSort(tOld))
		Set tCount = tCount - 1
	}
	Quit 1
}

ClassMethod SaveParameters(RuntimeMode, MaxRows, ShowRowNum, Dialect, ObjectSelectMode, Foreground) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,"SQLExecutePreference") = $LB(RuntimeMode,MaxRows,ShowRowNum,Dialect,ObjectSelectMode,Foreground)
}

ClassMethod GetRecentList(FILTERTYPE) As %String [ ZenMethod ]
{
	Quit ##class(%CSP.UI.Template.List).GetRecentList(FILTERTYPE)
}

/// Save selected cached query routines into %session
/// FILETYPE = "PurgeCQRoutines"
ClassMethod PrepareDeletion(FILETYPE, selectedRows) As %String [ ZenMethod ]
{
	Quit ##class(%CSP.UI.Template.List).PrepareAction(FILETYPE, selectedRows)
}

/// FILETYPE = "PurgeCQNamespace", "PurgeCQTable", or "PurgeCQRoutines"
ClassMethod DeleteQuery(FILETYPE, selectedRows) As %String [ ZenMethod ]
{
	Kill tItems
	Set tResult = ""
	Set EventDesc = "Purge"
	If FILETYPE = "PurgeCQNamespace" {
		Set EventData = "Purge all quries in namespace "_$namespace
		// delete ALL quries
		Set tSC = ##class(%SQL.Manager.API).PurgeAllQueries(0)
		If $$$ISERR(tSC) Set tResult = $System.Status.GetErrorText(tSC)
	} ElseIf FILETYPE = "PurgeCQTable" {
		Set EventData = "Purge a table: "_selectedRows
		// delete table (passed in as schema.table)
		Set tSC = ##class(%SQL.Manager.API).PurgeQueriesForTable(selectedRows)
		If $$$ISERR(tSC) Set tResult = $System.Status.GetErrorText(tSC)
	} Else {
		Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",""))
		While tRow '= "" {
			Set selectedRows = %session.Data($Username,FILETYPE,"selectedRows",tRow)
			Set n = 1
			Set tLen = $L(selectedRows,",")
			While n '> tLen {
				Set tName = $P(selectedRows,",",n)
				If tName '= "" {
					Set tItems(tName) = ""
					Set tSC = ##class(%SQL.Manager.API).PurgeQuery(tName)
					If $$$ISERR(tSC) Set tResult = $S(tResult'="":tResult_"\n",1:"")_$System.Status.GetErrorText(tSC)
				}
				Set n = n + 1
			}
			Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",tRow))
		}
		Set EventData = "Purge cached queries"_$$$CRLF
		Do $$$PatEventRows(.EventData,.tItems)
	}
	$$$SMPAuditChange
	If tResult = "" Quit 1
	Quit tResult
}

/// Method for executing the query for list schemas.
Method ListSchemas(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set tSC = pRS.Execute(%page.SYSTEMFLAG)
	Quit tSC
}

/// ******** Special Code for Expand *************
/// If true, the search area is visible.
Property searchExpanded As %Boolean [ InitialExpression = 1, Internal ];

ClientMethod showExpand() [ Language = javascript ]
{
	var span = self.document.getElementById('spanArrow');
	if (this.searchExpanded) {
		// left arrow - click to hide
		span.innerHTML = '&#171;';
		span.title = $$$Text("Hide the search criteria box");
	}
	else {
		// right arrow - click to show
		span.innerHTML = '&#187;';
		span.title = $$$Text("Show the search criteria box");
	}
}

/// Toggle display of search pane.
ClientMethod toggleSearch() [ Language = javascript ]
{
	this.searchExpanded = !this.searchExpanded;
	this.showExpand();
	this.adjustSizes();
	var expandstate = (this.searchExpanded) ? 1 : 0;
	this.SaveExpandState("SQL",expandstate);
}

ClassMethod SaveExpandState(FILETYPE, searchExpanded) [ ZenMethod ]
{
	Set %session.Data($Username,FILETYPE,"searchExpanded") = searchExpanded
}

ClassMethod GetExpandState(FILETYPE) As %String
{
	Quit $G(%session.Data($Username,FILETYPE,"searchExpanded"),1)
}

/// ******** End of Special Code for Expand *************
/// Return json for info. 
Method GetSQLInfo(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set pObject = $$$NULLOREF
		Set tSC = ##class(%CSP.UI.Portal.SQL.QButtons.Utils).GetSQLPageData(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// True if pages in the management portal are permitted to use auto-refresh behaviour.
Property enableAutoRefresh As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Draw HTML link to View Global Contents page
ClassMethod DrawGlobalLink(table As %ZEN.Component.tablePane, name As %String, seed As %String) As %Status
{
	set global = %query(name), isViewableGlobal = 0
	try {
		set isViewableGlobal = ($e(global)="^") && (global=$name(@(global_$s($f(global,"(")&&($e(global,*)'=")"):")",1:""))))
	} catch {}
	
	if 'isViewableGlobal {
		&html<#(global)#>
	} else {
		set params("$ID2") = $e(global,2,*),
			params("$NAMESPACE") = $namespace
		set link = ..Link("/csp/sys/exp/UtilExpGlobalView.csp",.params,1)
		&html<<a href="#(link)#" target="_new">#(global)#</a>>
	}
	quit $$$OK
}

/// Draw link to toggle map selectability
ClassMethod DrawToggleIndexStatus(table As %ZEN.Component.tablePane, name As %String, seed As %String) As %Status
{
	set status = %query(name)
	if $f($$$UPPER(status),"SELECTABLE") && ('$f($$$UPPER(%query("TYPE")),"DATA")) && ('$f($$$UPPER(%query("TYPE")),"EXTENT")) {
		set tab = table.parameters.GetAt(1).value_"."_table.parameters.GetAt(2).value, 
			index = %query("INDEX_NAME"), 
			bool = 1-($$$UPPER(status)="SELECTABLE")
		&html<<a href="#" onclick="zenPage.toggleIndexStatus('#(tab)#','#(index)#',#(bool)#);">#(status)#</a>>
	} else {
		&html<#(status)#>
	}
	quit $$$OK
}

ClassMethod toggleIndexStatus(tableName As %String, indexName As %String, selectability As %Boolean) As %Status [ ZenMethod ]
{
	set sc = $SYSTEM.SQL.Util.SetMapSelectability(tableName, indexName, selectability)
	if $$$ISOK(sc) {
		&js<zen("tblTable2").executeQuery();>
	} else {
		set msg = $zconvert($SYSTEM.Status.GetErrorText(sc),"O","JS")
		&js<alert("Error changing map selectability: #(msg)#");>
	}
	quit $$$OK
}

}
