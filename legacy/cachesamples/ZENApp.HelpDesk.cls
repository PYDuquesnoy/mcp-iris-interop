/// ZENApp.HelpDesk
/// This is the main page of the Help Desk sample application.
/// Note that this page extends the <class>ZENApp.TemplatePage</class>
/// class; this is a template that provides a standardized 
/// look & feel for the application.
Class ZENApp.HelpDesk Extends ZENApp.TemplatePage
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENApp.SampleApp";

/// Displayed name of this page.
Parameter PAGENAME = "HelpDesk";

/// Domain used for localization.
Parameter DOMAIN = "ZENAPP";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

/* style for menu pane */
#treeMenu {
	height: 20.0em;
	width: 10.0em;
	overflow: auto;
	border: 1px solid darkblue;
	background: #EEEEEE;
}

/* style for message box */
#msgBox {
	height: 8.0em;
	width: 10.0em;
	overflow: auto;
	border: 1px solid darkblue;
	background: white;
}


#navBar .tnbrTable {
	width: 800px;
	border-bottom: none;
}

/* style for table pane */
#table table {
	width: 800px;
}

</style>
}

/// This XML block defines the contents of the menu pane.
XData menuPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<dynaTree
	id="treeMenu"
	dataGlobal="%helpDeskMenu"
	showLines="true"
/>
</pane>
}

/// This XML block defines the contents of the message pane.
/// Here we use an HTML component and call a server-method to
/// get the message contents.
/// We use a timer to force periodic updates of the message box.
XData messagePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<timer id="timer" 
	ontimeout="zenPage.msgTimer(zenThis);" 
	timeout="5000"/>

<titleBox title="Messages"/>

<html id="msgBox" OnDrawContent="DrawMessage" />
</pane>
}

/// This XML block defines the contents of the table pane.
XData tablePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="tPane" xmlns="http://www.intersystems.com/zen">
<titleBox title="HelpDesk: Incidents" 
		subtitle="Customer-reported incidents are listed below. Click on a row to edit its details." />
<tableNavigatorBar id="navBar" showPageSize="true" tablePaneId="table" />
<tablePane id="table"
	width="100%"
	useSnapshot="true"
	maxRows="1000"
	pageSize="20"
	tableName="ZENApp_Data.Incident"
	valueColumn="ID"
	onselectrow="zenPage.rowSelected(zenThis);"
	showQuery="false"
	showZebra="true"
	useKeys="false"
	fixedHeaders="true"
	bodyHeight="15.0em"
	headerLayout="headersOnTop"
	>
<column colName="ID" 
		width="50"
		/>
<column colName="Priority"
		width="100"
		id="filterPriority"
		filterType="enum"
		filterEnum="Critical,High,Low"
		filterOp="="
		 />

<column colName="Customer"
		colExpression="Customer->Name" 
		width="200"
		filterType="query"
		filterQuery="SELECT Name FROM ZENApp_Data.Customer ORDER BY Name"
		filterOp="="
		
		/>
<column colName="AssignedTo"  
		colExpression="AssignedTo->Name" 
		width="22%"
		filterType="text"/>
<column colName="CreateDate" 
		width="22%"
		filterType="date"
		filterOp="BETWEEN"
		 />
<condition colName="Priority" 
		predicate="EQ" 
		value="Critical" rowStyle="font-weight: bold;"/>

</tablePane>

<spacer height="10"/>

</pane>
}

/// This XML block defines the contents of the details pane.
XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<fieldSet id="detailGroup" disabled="true" legend="Details">
<form id="detailForm" 
	layout="vertical" 
	labelPosition="top" 
	cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;"
	onchange="zenPage.detailFormChange(zenThis);" >
<hgroup>
<text id="ID" name="ID" label="ID" readOnly="true" size="5"/>
<spacer width="15"/>
<text id="CreateDate" name="CreateDate" label="Date" readOnly="true" size="8"/>
<spacer width="15"/>
<dataCombo id="Priority" name="Priority" label="Priority"
	size="12"
	dropdownHeight="150px"
	editable="false"
	unrestricted="true"
	sql="SELECT Name FROM ZENApp_Data.Priority ORDER BY Name"/>

<spacer width="15"/>

<dataCombo id="Customer" name="Customer" label="Customer"
	size="24"
	dropdownHeight="150px"
	editable="false"
	unrestricted="true"
	sql="SELECT ID,Name FROM ZENApp_Data.Customer ORDER BY Name"/>

<spacer width="15"/>

<dataCombo id="AssignedTo" name="AssignedTo" label="Assigned To"
	size="24"
	dropdownHeight="150px"
	editable="false"
	unrestricted="true"
	sql="SELECT ID,Name FROM ZENApp_Data.Employee ORDER BY Name"/>
</hgroup>

<textarea id="Comments" name="Comments" label="Comments" rows="3" cols="60"/>
<button id="btnSave" caption="Save" disabled="true" onclick="zenPage.detailFormSave();" />
</form>
</fieldSet>
</pane>
}

/// This class method callback is called just before the server-side page 
/// object is created.
ClassMethod %OnBeforeCreatePage() As %Status
{
	#; Make sure sample data is created for the application
	If '##class(ZENApp.Data.Incident).%ExistsId(1) {
		Do ##class(ZENApp.Data.Incident).BuildData()
	}

	#; Make sure array that defines the menu tree is defined
	#; (use a local and not a global)
	Kill %helpDeskMenu

	#; View items by priority
	For p="All","Low","High","Critical" {
		Set %helpDeskMenu("Priority",p) = "javascript:zenPage.setFilter('filterPriority','"_$S(p="All":"",1:p)_"');"
	}

	#; adjust page size
	For sz = 5,10,20,50,100,500 {
		Set %helpDeskMenu("Options","PageSize",sz) = "javascript:zenPage.setPageSize("_sz_");"
	}

	Set %helpDeskMenu("Options","Zebra") = "javascript:zenPage.setZebra();"

	Set %helpDeskMenu("Other","Chart") = "ZENApp.Chart.cls"

	Set %helpDeskMenu("Reports","Sales") = "ZENApp.MyReport.cls"
	For m = 1:1:12 {
		Set %helpDeskMenu("Reports","Sales","Month " _ $J(m,2)) = "ZENApp.MyReport.cls?MONTH="_m
	}

	Quit $$$OK
}

/// Draw the HTML that will be displayed within the
/// MessageBox
Method DrawMessage(pSeed As %String) As %Status
{
	#; create a random message
	Set tColors = $LB("red","green","blue","black","orange")
	Set tColor = $LG(tColors,$R($LL(tColors))+1)

	Set tMsgs = $LB("Fresh coffee in kitchen!","Company share price has gone up.","The boss is coming!","Customer crisis!","Lunch Time!")
	Set tMsg = $LG(tMsgs,$R($LL(tMsgs))+1)

	&html<#($ZDT($H,11))#<div style="color: #(tColor)#;">#(tMsg)#</div>>
	
	Quit $$$OK
}

/// MessageBox timer has fired.
ClientMethod msgTimer(timer) [ Language = javascript ]
{
	var html = this.getComponentById('msgBox');
	zenASSERT(html,"Unable to find html object",arguments);
	
	// update contents of message box
	html.refreshContents();

	timer.startTimer();
}

/// User selected a row in the table
ClientMethod rowSelected() [ Language = javascript ]
{
	var table = this.getComponentById('table');

	// update details pane using ID value from table
	var id = table.getProperty('value');
	this.ShowDetails(id);
}

/// Set page size for the table
ClientMethod setPageSize(sz) [ Language = javascript ]
{
	var table = this.getComponentById('table');
	table.setProperty('pageSize',sz);
}

/// Toggle zebra striping for the table
ClientMethod setZebra() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	table.setProperty('showZebra',!table.getProperty('showZebra'));
}

/// Update table to new filter value
ClientMethod setFilter(filterId, value) [ Language = javascript ]
{
	var table = this.getComponentById('table');
	var column = this.getComponentById(filterId);
	zenASSERT(column,"Unable to find column object",arguments);

	// update filter value and re-execute query
	column.setProperty('filterValue',value);

	// 'true' means do not change current page for table
	table.executeQuery(true);
}

/// Form changed handler for detail form.
/// This is called whenever the modified state of the form changes.
ClientMethod detailFormChange(form) [ Language = javascript ]
{
	var mod = form.isModified();
	
	// toggle save button
	var btn = zenPage.getComponentById('btnSave');
	btn.setProperty('disabled',!mod);
}

/// Save contents of details panel.
ClientMethod detailFormSave() [ Language = javascript ]
{
	// send form to server and save details
	var form = zenPage.getComponentById('detailForm');
	this.SaveDetails(form);
}

/// ShowDetails:
/// Show contents of details pane.
ClassMethod ShowDetails(id) [ ZenMethod ]
{
	// try to open the object
	Set tObj = ##class(ZENApp.Data.Incident).%OpenId(id)
	If $IsObject(tObj) {
		&js<zenPage.getComponentById('ID').setValue('#(tObj.%Id())#');>
		&js<zenPage.getComponentById('CreateDate').setValue('#(tObj.CreateDateLogicalToDisplay(tObj.CreateDate))#');>
		&js<zenPage.getComponentById('Priority').setValue('#(tObj.PriorityGetObjectId())#','#($ZCVT(tObj.Priority.Name,"O","JS"))#');>
		&js<zenPage.getComponentById('Customer').setValue('#(tObj.CustomerGetObjectId())#','#($ZCVT(tObj.Customer.Name,"O","JS"))#');>
		&js<zenPage.getComponentById('AssignedTo').setValue('#(tObj.AssignedToGetObjectId())#','#($ZCVT(tObj.AssignedTo.Name,"O","JS"))#');>
		&js<zenPage.getComponentById('Comments').setValue('#($ZCVT(tObj.Comments,"O","JS"))#');>

		#; enable form/ clear mod flag
		&js<zenPage.getComponentById('detailGroup').setProperty('disabled',false);>
		&js<zenPage.getComponentById('detailForm').clearModified();>
	}
	Else {
		#; clear & disable form
		&js<zenPage.getComponentById('detailGroup').setProperty('disabled',true);>
		&js<zenPage.getComponentById('detailForm').reset();>
	}
	Quit
}

/// Save contents of details pane.
ClassMethod SaveDetails(form As %ZEN.Component.form) [ ZenMethod ]
{
	#; as we passed form object to server, we can
	#; finds its control values using %page.%GetValueById
	
	Set tID = %page.%GetValueById("ID")

	#; try to open the object (with exclusive lock)
	Set tObj = ##class(ZENApp.Data.Incident).%OpenId(tID,4)
	If $IsObject(tObj) {
		Do tObj.PrioritySetObjectId(%page.%GetValueById("Priority"))
		Do tObj.CustomerSetObjectId(%page.%GetValueById("Customer"))
		Do tObj.AssignedToSetObjectId(%page.%GetValueById("AssignedTo"))
		Set tObj.Comments = %page.%GetValueById("Comments")

		Set tSC = tObj.%Save()
		If $$$ISERR(tSC) {
			&js<alert('Error saving object!');>
		}
		Else {
			#; clear mod flags for form
			&js<zenPage.getComponentById('detailForm').clearModified();>
			
			#; update tablePane with new query
			&js<zenPage.getComponentById('table').executeQuery();>
		}
	}
	Else {
		&js<alert('Unable to save object!');>
	}
	Quit
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.setTraceOption('js',false);
}

}

