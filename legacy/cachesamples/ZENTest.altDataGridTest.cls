/// 
/// Created using the page template: Default
Class ZENTest.altDataGridTest Extends %ZEN.Component.page
{

/// 
/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

/// 
/// Displayed name of this page.
Parameter PAGENAME = "DataGrid Test";

/// 
/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// 
/// This Style block contains page-specific CSS style definitions.
XData Style
{

<style type="text/css">

#dataGrid {

	width: 100%;

	height: 500px;

}

</style>
}

/// 
/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{

<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="">

<demo:demoTitle id="title" title="Zen DataGrid Test Page Using The Alternate JSON SQL Provider widget" category="Zen Test Suite" />



<locatorBar id="locator">

<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>

<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>

<locatorLink caption="DataGridTest" title="DataGrid Test Page" />

</locatorBar>



<titleBox title="Zen DataGrid Test Page" 

		subtitle="Use this page to test the various DataGrid box controls." />

<spacer height="25"/>

<altJSONSQLProvider id="json" />

<vgroup width="100%" height="100%">

<hgroup enclosingStyle="background:#F0F0F0;">

<spacer width="600"/>

<label value="Filter current results : "/>

<image src="deepsee/ds2_magnify_18.png" onclick="zenPage.SetFilter(zen('txtFilter'));"/>

<text id="txtFilter" onchange="zenPage.SetFilter(zenThis);"/>

</hgroup>

 <dataGrid pageSize="20"  id="dataGrid" pagingMode="client" controllerId="json" sortMode="client" selectMode="cells" onaction="zenPage.fireAction(row,name,value);" onchangecell="return zenPage.fireChangeCell(value);" ongetlookupdata="return zenPage.fireLookupData();" >

 <columnDescriptor caption="ID" type="string" readOnly="false"/>

 <columnDescriptor caption="Age" type="string" readOnly="false"/>

 <columnDescriptor caption="DOB" type="string" readOnly="false"/>

 <columnDescriptor caption="FavoriteColors" type="lookup" readOnly="false" ongetlookupspec="return zenPage.fireLookupDataFavColors();"/>

 <columnDescriptor caption="Name" type="string" readOnly="false"/>

 <columnDescriptor caption="SSN" type="string" readOnly="false"/>

 <columnDescriptor caption="Spouse" type="lookup" readOnly="false"/>

 <columnDescriptor caption="Home_City" type="string" readOnly="false"/>

 <columnDescriptor caption="Home_State" type="lookup" readOnly="false" ongetlookupspec="return zenPage.fireLookupDataState('Home');"/>

 <columnDescriptor caption="Home_Street" type="string" readOnly="false"/>

 <columnDescriptor caption="Home_Zip" type="string" readOnly="false"/>

 <columnDescriptor caption="Office_City" type="string" readOnly="false"/>

 <columnDescriptor caption="Office_State" type="lookup" readOnly="false" ongetlookupspec="return zenPage.fireLookupDataState('Office');"/>

 <columnDescriptor caption="Office_Street" type="string" readOnly="false"/>

 <columnDescriptor caption="Office_Zip" type="string" readOnly="false"/>

 </dataGrid>

 <hgroup enclosingStyle="background:#F0F0F0;">

 <label value="Show all Names starting with : "/>

 <button caption="A" onclick="zenPage.changeQuery('A');"/>

 <button caption="B" onclick="zenPage.changeQuery('B');"/>

 <button caption="C" onclick="zenPage.changeQuery('C');"/>

 <label value=" ... "/>

 <button caption="Z" onclick="zenPage.changeQuery('Z');"/>

 <spacer width="10"/>

 <button caption="Show All" onclick="zenPage.changeQuery('');"/>

 </hgroup>

</vgroup>

</page>
}

ClientMethod SetFilter(pTextBox As %ZEN.Component.text) [ Language = javascript ]
{

	zen('dataGrid').setProperty('filterKey',pTextBox.getValue());

	zen('dataGrid').renderContents();
}

ClientMethod fireChangeCell(value) [ Language = javascript ]
{



	var cCol=zen('dataGrid').getProperty('currColumn');

	var cRow=zen('dataGrid').getProperty('currRow');

	var cPage=zen('dataGrid').getProperty('currPage');



	return value;
}

ClientMethod fireLookupData() [ Language = javascript ]
{

	var cCol=zen('dataGrid').getProperty('currColumn');



	if (cCol==4) return zenPage.fireLookupDataFavColors();  //Favorite Colors

	if (cCol==9) return zenPage.fireLookupDataState('Home');  //Home_State

	if (cCol==13) return zenPage.fireLookupDataState('Office');  //Office_State
}

ClientMethod fireLookupDataFavColors() [ Language = javascript ]
{

	//var values = ['Red','Orange','Yellow','Green','Blue','Purple','Black','White'];

	

	var FavColString = zenPage.GetFavoriteColors();

	var values = FavColString.split(',');

		  	

	return values
}

Method GetFavoriteColors() As %String [ ZenMethod ]
{
	Quit "Red,Orange,Yellow,Green,Blue,Purple,Black,White"
}

ClientMethod fireLookupDataState(what) [ Language = javascript ]
{

	var StatesString;

	

	if (what=='Home') StatesString = zenPage.GetStates(true);

	else  StatesString = zenPage.GetStates(false);

	

	var values = StatesString.split(',');

	//var values = ['MA','NY','OH'];

	

	return values
}

Method GetStates(Home As %Boolean = 1) As %String [ ZenMethod ]
{

	set sql="select distinct("_$s(Home=1:"Home",1:"Office")_"_State) as State from Sample.Person order by "_$s(Home=1:"Home",1:"Office")_"_State "_$s(Home=1:"asc",1:"desc")

	

	Set rs=##class(%ResultSet).%New()

	do rs.Prepare(sql)

	do rs.Execute()

	

	Set StatesString=""

	While (rs.Next()) {

		Set StatesString=StatesString_rs.Get("State")_","

	}

	

	do rs.Close()

	

	Set:$e(StatesString,$l(StatesString))="," StatesString=$e(StatesString,1,$l(StatesString)-1)

	

	Quit StatesString
}

ClientMethod fireAction(row, name, value) [ Language = javascript ]
{
	alert(row + ' : ' + name + ' : ' + value + ' : ' + zen('dataGrid').getCurrPage());
}

ClientMethod changeQuery(namestartswith) [ Language = javascript ]
{

	var ret = zenPage.ChangeQueryOnServer(namestartswith);

	zen('json').reloadContents();
}

Method ChangeQueryOnServer(namestartswith As %String = "") As %Boolean [ ZenMethod ]
{

	

	set %page.%GetComponentById("json").sql = "select * from sample.person "_$s(namestartswith'="":"where name %startswith '"_namestartswith_"'",1:"")_" order by name"

	quit 1
}

/// 
/// This callback is called after the server-side page 
/// 
/// object and all of its children are created.<br/>
/// 
/// Subclasses can override this to add, remove, or modify 
/// 
/// items within the page object model, or to provide values
/// 
/// for controls.
Method %OnAfterCreatePage() As %Status
{

	Set provider = ..%GetComponentById("json")

	Set provider.sql = "select * from sample.person order by name"

	Quit $$$OK
}

}

