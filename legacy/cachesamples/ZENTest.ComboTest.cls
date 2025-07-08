/// ZENTest.ComboTest
Class ZENTest.ComboTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Combobox Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">

.labelText {
	border: 1px solid darkblue;
	padding: 1px;
	margin: 1px;
	background: white;
	width: 100px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Combobox Test Page">
<demo:demoTitle id="title" title="Zen Combobox Test Page" category="Zen Test Suite" />

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="ComboBox" title="ComboBox Test Page" />
</locatorBar>

<titleBox title="Zen ComboBox Test Page" 
		subtitle="Use this page to test the various Zen custom combo box controls." />
<spacer height="25"/>
<hgroup>
<spacer width="25"/>
<select id="select" label="select" 
	valueList="True,False"
	displayList="Yes,No"
	showEmpty="false"
	value="False"
	onchange="zenPage.notifyOnChange(zenThis);"
	>
</select>

<spacer width="25"/>
<combobox id="combobox" label="combobox"
		onchange="zenPage.notifyOnChange(zenThis);"
		editable="false">
<option value="" text="" />
<option value="1" text="Apple" />
<option value="2" text="Banana" style="font-size: 2.5em; "/>
<option value="3" text="Carnitas" />
</combobox>

<spacer width="25"/>
<combobox id="comboboxEdit" label="combobox Editable" 
		onchange="zenPage.notifyOnChange(zenThis);"
		editable="true"
		unrestricted="true"	>
<option value="1" text="Apple" />
<option value="2" text="Banana" style="font-size: 2.5em; "/>
</combobox>

<spacer width="25"/>
<dataCombo id="dataCombo"
		comboType="button"
		buttonCaption="Find" 
		label="dataCombo" name="dataCombo"
		editable="true"
	 	unrestricted="true"	
		searchKeyLen="0"
		choiceColumn="1"
		valueColumn="2"
		maxRows="10000"
		displayColumns="1,4,3"
		dropdownWidth="50.0em"
		sql="SELECT Name,ID,Title,SSN FROM ZENDemo_Data.Employee ORDER BY Name"
		columnHeaders="Name,SSN,Title"
		onchange="zenPage.notifyOnChange(zenThis);"
		>
</dataCombo>

<spacer width="25"/>
<dataCombo id="dataCombo2"
		label="dataCombo2" name="dataCombo2"
		editable="true"
		unrestricted="true"
		searchKeyLen="3"
		dropdownWidth="20.0em"
		OnCreateResultSet="CreateComboRS"
		onchange="zenPage.notifyOnChange(zenThis);"
		>
</dataCombo>

<spacer width="25"/>
<dataCombo id="dataCombo3"
		comboType="timer"
		delay="400" 
		label="dataComboTimer" name="dataCombo3"
		editable="true"
		searchKeyLen="10"
		maxRows="10"
		onchange="zenPage.notifyOnChange(zenThis);"
		sql="SELECT TOP 100 ID,Name FROM ZENDemo_Data.Employee WHERE Name %STARTSWITH ? ORDER BY Name"
		sqlLookup="SELECT Name FROM ZENDemo_Data.Employee WHERE ID = ?"
		>
</dataCombo>

<spacer width="25"/>
<dataCombo id="dataComboX"
		label="dataComboX" name="dataComboX"
		editable="true"
		searchKeyLen="3"
		dropdownWidth="20.0em"
		queryClass="ZENDemo.Data.Employee"
		queryName="ListEmployees"
		onchange="zenPage.notifyOnChange(zenThis);"
		>
</dataCombo>
</hgroup>
<spacer height="50"/>

<hgroup>
<spacer width="25"/>
<listBox id="listBox" label="listBox" 
	listWidth="300px" 
	onchange="zenPage.notifyOnChange(zenThis);"
	value="2">
<option value="1" text="Apple" />
<option value="2" text="Banana" style="font-size: 1.5em; "/>
<option value="3" text="Cherry" />
<option value="4" text="Apple" />
<option value="5" text="Banana" style="font-size: 1.5em; "/>
<option value="6" text="Cherry" />
<option value="7" text="Apple" />
<option value="8" text="Banana" style="font-size: 1.5em; "/>
<option value="9" text="Cherry" />
<option value="10" text="Cherry" />
<option value="11" text="Cherry" />
<option value="12" text="Cherry" />
<option value="13" text="Cherry" />
<option value="14" text="Cherry" />
<option value="15" text="Cherry" />
<option value="16" text="Cherry" />
<option value="17" text="Cherry" />
</listBox>
<spacer width="25"/>
<dataListBox id="dataListBox" label="dataListBox" name="dataListBox"
		maxRows="1000"
		listHeight="300px"
		sql="SELECT Name FROM ZENDemo_Data.Employee ORDER BY Name"
		onchange="zenPage.notifyOnChange(zenThis);"
		>
</dataListBox>
</hgroup>
<vgroup>
<text id="currComp" label="Component:" readOnly="true"/>
<text id="currText" label="Text:" readOnly="true"/>
<text id="currValue" label="Value:" onchange="zenPage.changeValue(zenThis);"/>
<spacer height="25"/>
<button caption="Clear combobox" onclick="zenPage.getComponentById('combobox').resetOptions();"/>
<button caption="Add to combobox" onclick="zenPage.getComponentById('combobox').appendOption(22,'Elvis');"/>
</vgroup>

</page>
}

/// Create the result set used by dataCombo2.
Method CreateComboRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set sql = "SELECT Name FROM ZENDemo_Data.Employee WHERE Name %STARTSWITH ? ORDER BY Name"
	Set tRS = ##class(%ResultSet).%New()
	Set tSC = tRS.Prepare(sql)
	Set pInfo.queryText = sql

	Quit tRS
}

/// notifyOnChange: on change event handler.
ClientMethod notifyOnChange(comp) [ Language = javascript ]
{
	// remember which component was changed
	this._currComp = comp;
	
	// display current value of component
	this.getComponentById('currComp').setValue(comp.id);
	this.getComponentById('currValue').setValue(comp.getValue());
	if (comp.id != "select") {
		this.getComponentById('currText').setValue(comp.getProperty('text'));
	} else {
		this.getComponentById('currText').setValue('');
	}
}

/// Change value of current component.
ClientMethod changeValue(ctrl) [ Language = javascript ]
{
	var comp = null;
	if (this._currComp) {
		comp = this._currComp;
	}

	// !!!
	//comp = zenPage.getComponentById('dataCombo');
	//comp.executeQuery();

	if (comp) {
		comp.setValue(ctrl.getValue());
	}
}

}

