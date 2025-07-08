/// tablePane Test Page
Class ZENTest.TableTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Table Pane Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">

/* override of label control style */
.labelText {
	padding: 2px;
	background: white;
	color: darkblue;
	border: 1px solid black;
	height: 1.0em;
	width: 12.0em;
}

#table {
	border: 1px solid darkblue;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="tablePane Test Page">
<demo:demoTitle id="title" title="Zen tablePane Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="tablePane" title="tablePane Test Page" />
</locatorBar>

<spacer height="20"/>
<vgroup>
<spacer height="5"/>
<hgroup width="100%">
<tablePane id="table" 
	caption="This is a tablePane"
	
	tableName="ZENDemo_Data.Employee"
	
	useSnapshot="true"
	showQuery="true"
	showFilters="true"
	fixedHeaders="true"
	bodyHeight="15.0em"
	ondblclick="alert(zenThis.getProperty('selectedIndex'));"
	filtersDisabled="false"
	autoExecute="true"

	showZebra="true"
	pageSize="10"
	showRowNumbers="true"
	valueColumn="ID"
	maxRows="1000"
	useKeys="true"

	onupdate="zenPage.updatePagingInfo();"
	onselectrow="zenPage.rowSelected(zenThis);"
	onunselectrow="zenPage.rowUnselected(zenThis);"
	onmultiselect="zenPage.rowMultiSelected(zenThis);"
	>
<parameter id="P1" value="B"/>

<column colName="ID" hidden="true"/>
<column colName="Name" id="nameColumn" width="20%" filterType="text" />
<column colName="Active" width="5%" 
	filterOp="=" 
	filterType="enum" 
	filterEnum="1,0"
	filterEnumDisplay="active,inactive"
	/>
<column colName="Title" width="30%" 
		cellTitle="Employee's title" 
		filterType="custom"
		filterOp="%STARTSWITH" 
		OnDrawFilter="DrawTitleFilter" />
<column colName="Home_City" width="20%" 
		OnDrawCell="DrawCity" seed="abc" 
		filterType="text"
		filterLabel="City:"
		filterOp="%STARTSWITH" />

<column colName="HireDate" width="20%" 
		filterType="datetime"
		filterLabel="Start:,End:"
		filterOp="BETWEEN" />

<column colName="Salary" width="20%" 
		filterType="text"
		filterOp="BETWEEN"
		filterLabel=" Range (Min,Max):"
		 />

<column width="50" />

<column linkCaption="Edit" width="10%" link="ZENTest.FormTest.cls?ID=#(%query.ID)#" cellTitle="Edit this record." />

<condition colName="Name" predicate="CONTAINS" value="K" rowStyle="background: #A0A0F0;"/>
<condition colName="Active" predicate="EQ" value="1" rowStyle="font-weight: bold;"/>
</tablePane>
</hgroup>
<tableNavigator tablePaneId="table"/>
<spacer height="5"/>
<form>
<text id="selectedIndex" label="selectedIndex:" onchange="zenPage.selectedIndexChange(zenThis);" />
<spacer height="5"/>
<text id="pageSize" label="pageSize:" value="#(#table.pageSize)#" onchange="zenPage.pageSizeChange(zenThis);" />
<spacer height="5"/>
<text id="value" label="value:" readOnly="true" />
<spacer height="5"/>
<text id="rowCount" label="rowCount:" readOnly="true" />
<spacer height="5"/>
<hgroup>
<checkbox id="rowSelect" caption="rowSelect" value="#(#table.rowSelect)#" onclick="zenPage.rowSelect(zenThis);" />
<checkbox id="multiSelect" caption="multiSelect" value="#(#table.multiSelect)#" onclick="zenPage.multiSelect(zenThis);" />
<spacer width="5"/>
<text id="selectedRows" label="selectedRows:" size="50" readOnly="true" />
</hgroup>
<radioSet id="headerLayout" label="headerLayout" value="#(#table.headerLayout)#" valueList="headersOnTop,filtersOnTop" onchange="zenPage.headerLayout(zenThis);" />
<spacer height="5"/>
<hgroup>
<checkbox id="showRowNos" caption="showRowNumbers" value="1" onclick="zenPage.showRowNumbers(zenThis);" />
<checkbox id="showRowSelector" caption="showRowSelector" value="#(#table.showRowSelector)#" onclick="zenPage.showRowSelector(zenThis);" />
<checkbox id="showZebra" caption="showZebra" value="#(#table.showZebra)#" onclick="zenPage.showZebra(zenThis);" />
<checkbox id="showFilters" caption="showFilters" value="#(#table.showFilters)#" onclick="zenPage.showFilters(zenThis);" />
<checkbox id="filtersDisabled" caption="filtersDisabled" value="#(#table.filtersDisabled)#" onclick="zenPage.filtersDisabled(zenThis);" />
<checkbox id="useSnapshot" caption="Use Snapshot" value="1" onclick="zenPage.useSnapshot(zenThis);" />
<checkbox id="autoExecute" caption="autoExecute" value="#(#table.autoExecute)#" onclick="zenPage.autoExecute(zenThis);" />
<checkbox id="showValueInTooltip" caption="showValueInTooltip" value="#(#table.showValueInTooltip)#" onclick="zenPage.showValueInTooltip(zenThis);" />
<checkbox id="fixedHeaders" caption="fixedHeaders" value="#(#table.fixedHeaders)#" onclick="zenPage.fixedHeaders(zenThis);" />
</hgroup>

<hgroup>
<button caption="Refresh" onclick="zenPage.refreshTable();" />
<spacer width="5"/>
<button caption="Execute" onclick="zenPage.executeQuery();" />
<spacer width="5"/>
<button caption="More..." onclick="zenPage.moreRows();" />
<spacer width="5"/>
<button caption="Change style" onclick="zenPage.changeStyle();" />
<spacer width="5"/>
<button caption="Get Row" onclick="zenPage.getRowFromSnapshot();" />
<spacer width="5"/>
<button caption="Get Filters" onclick="zenPage.getFilterValues();" />
<spacer width="5"/>
<button caption="Restore Filters" onclick="zenPage.restoreFilters();" />
</hgroup>
</form>
</vgroup>

</page>
}

/// Create the result set used by the table pane.
/// <var>pInfo</var> holds details on how to create the query.
Method CreateRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK
	
	Set tTOP = "TOP 10000"
	Set tSELECT = "ID,Name,Title,Home_City,SSN,Ranking"
	Set tFROM = "ZENDemo_Data.Employee"
	Set tORDERBY = pInfo.sortColumn
	Set tSORTORDER = pInfo.sortOrder
	Set tWHERE = ""

	// Build WHERE clause based on filters
	If ($G(pInfo.filters("Name"))'="") {
		Set tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ "Name %STARTSWITH '" _ pInfo.filters("Name") _ "'"
	}
	If ($G(pInfo.filters("Title"))'="") {
		Set tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ "Title %STARTSWITH '" _ pInfo.filters("Title") _ "'"
	}
	If ($G(pInfo.filters("Home_City"))'="") {
		Set tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ "Home_City %STARTSWITH '" _ pInfo.filters("Home_City") _ "'"
	}
	If ($G(pInfo.filters("SSN"))'="") {
		Set tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ "SSN %STARTSWITH '" _ pInfo.filters("SSN") _ "'"
	}

	Set sql = "SELECT " _ tTOP _ " " _ tSELECT _ " FROM " _ tFROM
	Set:tWHERE'="" sql = sql _ " WHERE " _tWHERE
	Set:tORDERBY'="" sql = sql _ " ORDER BY " _tORDERBY _ $S(tSORTORDER="desc":" desc",1:"")

	Set tRS = ##class(%ResultSet).%New()
	Set tSC = tRS.Prepare(sql)
	Set pInfo.queryText = sql
	
	Set pInfo.rowCount = "UNKNOWN" // !!!
	
	Quit tRS
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
Method %OnAfterCreatePage() As %Status
{
	Set tColumn = %page.%GetComponentById("cityList")
	If '$IsObject(tColumn) {
		Quit $$$OK
	}

	Set tCity = ""

	#; compute DISTINCT list of city names
	&sql(DECLARE sql1 CURSOR FOR
			SELECT DISTINCT Home_City INTO :city
			FROM ZENDemo_Data.Employee
			ORDER BY Home_City
	)
	&sql(OPEN sql1)
	&sql(FETCH sql1)
	While (SQLCODE = 0) {
		Set tCity = tCity _ $S(tCity="":"",1:",") _ city
		&sql(FETCH sql1)
	}
	&sql(CLOSE sql1)
	
	Set tColumn.filterEnum = tCity

	Quit $$$OK
}

/// User override of cell-display for tablePane.
Method DrawCity(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#; Draw HTML to render table cell.
	&html<<img src="images/folder.gif"/>&nbsp;#(%query(pName))#>
	Quit $$$OK
}

/// User override of filter for Title column.
Method DrawTitleFilter(pTable As %ZEN.Component.tablePane, pName As %String, pColInfo As %ZEN.Auxiliary.column) As %Status
{
	#; Draw HTML to display as filter.
	Set captions = $LB("All","Assistants","Executives")
	Set values = $LB("","Assistant","Executive")

	#; draw set of radio buttons
	#; These have id values of the form #(pTable.%MakeId("filterN_"_pName))#
	#; in order to cooperate with filter disabling
	For n=1:1:$LL(values) {
		Set tValue = $LG(values,n)
		Set tCaption = $LG(captions,n)
		&html<<input type="radio" id=#(pTable.%MakeId("filter"_n_"_"_pName))# name="titleFilter_#(pTable.index)#" #($S(pColInfo.filterValue=tValue:"checked",1:""))# onclick="zenPage.setTitleFilter('#(tValue)#');" >#(tCaption)#>
	}
	Quit $$$OK
}

/// User click on custom title filter
ClientMethod setTitleFilter(value) [ Language = javascript ]
{
	var table = this.getComponentById('table');
	table.setFilterValue('Title',value);
	table.applyFilters();
}

/// Refresh contents of the table
ClientMethod refreshTable() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	table.setProperty('parameters',1,'C');
}

/// Execute the query for the table.
ClientMethod executeQuery() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	table.executeQuery();
}

/// More rows...
ClientMethod moreRows() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	//table.maxRows = 1000;
	table.currPage++;
	table.refreshContents();
}

/// Change style of the table
ClientMethod changeStyle() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	var col = this.getComponentById('nameColumn');
	zenASSERT(col,"Unable to find column",arguments);
	if (col) {
		if (col.style != "background: orange;") {
			col.style = "background: orange;";
		}
		else {
			col.style = "background: gray;"
		}
	}
	table.refreshContents();
}

/// Get a row from the table snapshot.
ClientMethod getRowFromSnapshot() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	var index = table.getProperty('selectedIndex');
	if (index < 0) {
		alert('No row is selected in the table.');
		return;
	}

	var data = table.getRowData(index);
	
	if (data == null) {
		alert('Table is not in snapshot mode or invalid request.');
	}
	else {
		// unpackage returned object
		var msg = '';
		for (var p in data) {
			msg += p + ': ' + data[p] + ': ' + (typeof data[p]) + '\n';
		}
		alert('Row data:\n--------------\n'+msg);
	}
}

/// Get current set of filter values.
ClientMethod getFilterValues() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	var state = table.getColumnFilters();
	
	if (state == null) {
		alert('Unable to get filter values!');
	}
	else {
		// save filter state
		this.filterState = state;

		// unpackage returned object
		var msg = '';
		for (var p in state) {
			msg += p + ': ' + state[p] + '\n';
		}
		alert('Filter State:\n--------------\n'+msg);
	}
}

/// Restore saved set of filter values.
ClientMethod restoreFilters() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	
	if (null == this.filterState) {
		alert('No saved filter state found.');
	}
	else {
		table.setColumnFilters(this.filterState);
	}
}

/// User unselected the current row in the table
ClientMethod rowUnselected() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	var ctrl = this.getComponentById('selectedIndex');
	var idx = table.getProperty('selectedIndex');
	if (idx<0) {
		ctrl.setValue("");
		var ctrl = this.getComponentById('value');
		ctrl.setValue("");
	}
}

/// User selected a new row in the table
ClientMethod rowSelected() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	var ctrl = this.getComponentById('selectedIndex');
	ctrl.setValue(table.getProperty('selectedIndex'));

	var ctrl = this.getComponentById('value');
	ctrl.setValue(table.getProperty('value'));
}

/// User multi-selected a new row in the table
ClientMethod rowMultiSelected() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	var ctrl = this.getComponentById('selectedRows');
	ctrl.setValue(table.getProperty('selectedRows'));
}

/// selectedIndexChange
ClientMethod selectedIndexChange(ctrl) [ Language = javascript ]
{
	var table = this.getComponentById('table');
	table.setProperty('selectedIndex',ctrl.getValue());
}

/// pageSizeChange
ClientMethod pageSizeChange(ctrl) [ Language = javascript ]
{
	var table = this.getComponentById('table');
	table.setProperty('pageSize',ctrl.getValue());
}

ClientMethod showRowNumbers(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('showRowNumbers',(cb.getValue() == 1) ? true : false);
}

ClientMethod showValueInTooltip(cb As %String) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('showValueInTooltip',(cb.getValue() == 1) ? true : false);
}

ClientMethod showRowSelector(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('showRowSelector',(cb.getValue() == 1) ? true : false);
}

ClientMethod showZebra(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('showZebra',(cb.getValue() == 1) ? true : false);
}

ClientMethod autoExecute(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('autoExecute',(cb.getValue() == 1) ? true : false);
}

ClientMethod showFilters(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('showFilters',(cb.getValue() == 1) ? true : false);
}

ClientMethod filtersDisabled(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('filtersDisabled',(cb.getValue() == 1) ? true : false);
}

ClientMethod rowSelect(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('rowSelect',(cb.getValue() == 1) ? true : false);
}

ClientMethod multiSelect(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('multiSelect',(cb.getValue() == 1) ? true : false);
}

ClientMethod headerLayout(rs) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('headerLayout',rs.getValue());
}

ClientMethod useSnapshot(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('useSnapshot',(cb.getValue() == 1) ? true : false);
}

ClientMethod fixedHeaders(cb) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.setProperty('fixedHeaders',(cb.getValue() == 1) ? true : false);
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
}

/// update page info
/// This is called whenever the server updates the tablePane object
ClientMethod updatePagingInfo() [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	zenASSERT(table,'Unable to find table',arguments);

	var pageNo = table.getProperty('currPage');
	var pageCount = table.getPageCount();

	// rowcount
	var text = this.getComponentById('rowCount');
	text.setValue(table.getProperty('rowCount'));

	// multi-select info
	var ctrl = this.getComponentById('selectedRows');
	ctrl.setValue(table.getProperty('selectedRows'));
}

/// This callback is called at the start of the HTML BODY section of the page.<br>
/// (default implementation is a simple expression).
Method %OnDrawHTMLBody() As %Status
{
	Write "<!-- GETIO ",$$$GETIO," -->",!
	Quit $$$OK
}

}

