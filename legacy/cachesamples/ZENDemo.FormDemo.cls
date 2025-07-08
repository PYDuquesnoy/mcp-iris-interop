/// This is the Form Demonstration page for the Zen demonstration application.
Class ZENDemo.FormDemo Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Form Demo";

/// Domain used for localization.
Parameter DOMAIN = "ZENDEMO";

/// This property holds the patient ID passed in by URL (if any).
Property patientID As %ZEN.Datatype.string(ZENURL = "ID");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

body {
	font-family: "lucida sans unicode";
}


/* form labels */
.zenLabel {
	font-size: 10pt;
}

.zenHint {
	font-size: 8pt;
	color: #404040;
}

.fieldSet {
	font-size: 10pt;
}
.radioSetCaption {
	font-size: 10pt;
}
.comboboxInput {
	border-top: 1px solid #8080FF;
	border-bottom: 1px solid #8080FF;
	border-left: 1px solid #8080FF;
}

.comboboxTextButton {
	border: 1px solid #8080FF;
}
.comboboxImgButton {
	border-top: 1px solid #8080FF;
	border-bottom: 1px solid #8080FF;
	border-right: 1px solid #8080FF;
}

/* customize the combobox dropdown */
.comboboxTable {
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x500.png);
	background-repeat: repeat-x;
}

.comboboxTable td {
	padding: 1px;
	border-bottom: 1px solid gray;
}

#formGroup {
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x500.png);
	background-repeat: repeat-x;
	border: 1px solid darkblue;
}
</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Zen Form Demo">
<demo:demoTitle id="title" title="Form Demonstration"/>
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Form Demo" title="Form Demo" />
</locatorBar>
<hgroup>
<vgroup valign="top">
<demo:sidebar text="This Zen form demonstrates the following features:">
<demo:bullet text="Data-driven combobox" />
<demo:bullet text="Data-driven radio buttons" />
<demo:bullet text="Different flavors of date input controls" />
<demo:bullet text="Custom component" />
<demo:bullet text="Use of server-side methods to populate the form" />
<demo:bullet text="Built-in form validation" />
<demo:bullet text="Server-side submit logic" />
<demo:bullet text="Expando box to hide and show the form" />
</demo:sidebar>
</vgroup>

<spacer width="40"/>

<vgroup valign="top" id="formGroup">
<expando caption="Patient Record Form" framed="true" animate="true">
<form id="patientForm" 
	width="100%" 
	layout="vertical"
	 labelPosition="top"
	cellStyle="padding: 3px;" 
	>

<hgroup>
<text label="Patient ID:" id="PatientID" 
	name="PatientID" size="8" readOnly="true" />
<spacer width="20"/>
<dataCombo label="Name:" id="Name" name="Name" size="24"
	dropdownWidth="450"
	editable="true"
	searchKeyLen="5"
	required="false"
	comboType="button"
	buttonCaption="Search"
	buttonTitle="Search for a record by Patient Name"
	onchange="zenPage.selectPatient(zenThis);"
	sql="SELECT TOP 25 ID,Name,Home_City FROM ZENDemo_Data.Patient WHERE Name %STARTSWITH ? ORDER BY Name"
	unrestricted="true"
	displayColumns="2,3"
	choiceColumn="2"
	valueColumn="2"
	auxColumn="1"
	/>

<spacer width="20"/>

<dataCombo label="SSN:" id="SSN" name="SSN" size="24"
	dropdownWidth="450"
	editable="true"
	searchKeyLen="5"
	required="false"
	comboType="button"
	buttonCaption="Search"
	buttonTitle="Search for a record by Social Security Number"
	onchange="zenPage.selectPatient(zenThis);"
	sql="SELECT TOP 25 ID,SSN,Name FROM ZENDemo_Data.Patient WHERE SSN %STARTSWITH ? ORDER BY SSN"
	unrestricted="true"
	displayColumns="2,3"
	choiceColumn="2"
	valueColumn="2"
	auxColumn="1"
	/>
</hgroup>

<hgroup cellVAlign="top">

<dateSelect label="Date of Birth:" id="DOB" name="DOB"
 hint="Composite date control"/>
<spacer width="25"/>
<dateText label="Next Visit:" id="NextVisit" name="NextVisit" 
	hint="Popup calendar control"
	onshowPopup="zenPage.calendarSettings(settings);" />
<spacer width="25"/>
<colorPicker label="Favorite Color:" 
	hint="Custom color control"
	id="FavoriteColor" 
	name="FavoriteColor" colorList="white,red,green,blue,black,yellow,orange,purple"/>
</hgroup>
<radioSet label="Sex:" id="Sex" name="Sex" displayList="Male,Female,Other" valueList="M,F,O"/>
<radioSet label="Marital Status:" id="MaritalStatus" 
	name="MaritalStatus" 
	displayList="Single,Married,Divorced,Widowed,Other" 
	valueList="S,M,D,W,O"/>

<fieldSet id="fieldSet" 
	legend="Home Address" 
	layout="vertical" 
	title="Patient's home address">
<text label="Street:" id="HomeStreet" name="HomeStreet" size="40" />
<text label="City:" id="HomeCity" name="HomeCity" size="25" />
<hgroup>
<text label="State:" id="HomeState" name="HomeState" size="2"  maxlength="2" />
<spacer width="10"/>
<text label="Zip Code:" id="HomeZip" name="HomeZip" size="10" />
</hgroup>
</fieldSet>

<textarea label="Memo:" id="Memo" name="Memo" cols="80" rows="3"/>
<spacer height="5" />
<hgroup width="100%" cellAlign="right">
<spacer width="5" />
<submit caption="Save" action="save"/>
<spacer width="5" />
<button caption="Reset" onclick="zenPage.resetForm();"/>
<spacer width="5" />
</hgroup>
</form>
</expando>
</vgroup>
</hgroup>
</page>
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	If (..patientID '= "") {
		#; load contents of given object into form
		Set tForm = ..%GetComponentById("patientForm")
		Do ..LoadPatient(tForm,..patientID)
	}

	Quit $$$OK
}

/// User has selected a new Patient from the list.
ClientMethod selectPatient(cb) [ Language = javascript ]
{
	var ctrl = zenPage.getComponentById('PatientID');
	var patid = ctrl.getValue();

	// get id of patient
	// this is in the "auxiliary" value of the dataCombo
	var id = cb.getAuxValue();

	// if user has selected a new id, load it
	if (patid != id) {
		var form = zenPage.getComponentById('patientForm');
		
		// go to server; get patient data
		this.LoadPatient(form, id);

	}
}

/// Load given patient data into the form.
ClassMethod LoadPatient(pForm As %ZEN.Component.form, pID As %ZEN.Datatype.string) [ ZenMethod ]
{
	#; open patient object from database
	Set tPatient = ##class(ZENDemo.Data.Patient).%OpenId(pID)
	If $IsObject(tPatient) {
		Do %page.%SetValueById("PatientID",pID)
		Do %page.%SetValueById("Name",tPatient.Name)
		Do %page.%SetValueById("SSN",tPatient.SSN)
		Do %page.%SetValueById("MaritalStatus",tPatient.MaritalStatus)
		Do %page.%SetValueById("Sex",tPatient.Sex)
		Do %page.%SetValueById("FavoriteColor",tPatient.FavoriteColor)
		Do %page.%SetValueById("Memo",tPatient.Memo)

		Do %page.%SetValueById("DOB",tPatient.DOBLogicalToDisplay(tPatient.DOB))
		Do %page.%SetValueById("HomeStreet",tPatient.Home.Street)
		Do %page.%SetValueById("HomeCity",tPatient.Home.City)
		Do %page.%SetValueById("HomeState",tPatient.Home.State)
		Do %page.%SetValueById("HomeZip",tPatient.Home.ZIP)
		Do %page.%SetValueById("NextVisit",tPatient.NextVisitLogicalToDisplay(tPatient.NextVisit))
	}
	Quit
}

/// submit handler:
/// This method is called when this form is submitted.
/// The submitted values are placed within a special submit object
/// and are indexed by control <em>name</em>.
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	If (pSubmit.%Action = "save") {
		Set tID = pSubmit.%GetValue("PatientID")

		#; open and save object (with lock)
		Set tPatient = ##class(ZENDemo.Data.Patient).%OpenId(tID,4)
		If $IsObject(tPatient) {
			Set tPatient.Name = pSubmit.%GetValue("Name")
			Set tPatient.SSN = pSubmit.%GetValue("SSN")
			Set tPatient.DOB = tPatient.DOBDisplayToLogical(pSubmit.%GetValue("DOB"))
			Set tPatient.NextVisit = tPatient.DOBDisplayToLogical(pSubmit.%GetValue("NextVisit"))
			Set tPatient.MaritalStatus = pSubmit.%GetValue("MaritalStatus")
			Set tPatient.Sex = pSubmit.%GetValue("Sex")
			Set tPatient.FavoriteColor = pSubmit.%GetValue("FavoriteColor")
			Set tPatient.Memo = pSubmit.%GetValue("Memo")

			Set tPatient.Home.Street = pSubmit.%GetValue("HomeStreet")
			Set tPatient.Home.City = pSubmit.%GetValue("HomeCity")
			Set tPatient.Home.State = pSubmit.%GetValue("HomeState")
			Set tPatient.Home.ZIP = pSubmit.%GetValue("HomeZip")

			Set tSC = tPatient.%Save()
			If $$$ISERR(tSC) {
				#; set form error
				Do pSubmit.%SetError("PatientID","There was an error saving this form.")
			}
		}
		
		#; pass ID on to new display of page
		Set %response.Context("ID") = tID
	}
	Quit $$$OK
}

/// Return an array of quick links to be displayed by the locator bar.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	#; dispatch to our application class
	Quit %application.GetQuickLinks(.pLinks)
}

/// Apply additional settings to popup calendar.
ClientMethod calendarSettings(settings) [ Language = javascript ]
{
	settings.gapWidth = '60px';
}

/// Reset the contents of the form.
ClientMethod resetForm() [ Language = javascript ]
{
	var form = zenPage.getComponentById('patientForm');
	form.reset();
}

}

