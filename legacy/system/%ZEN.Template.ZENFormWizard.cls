/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template: New ZEN Form
Class %ZEN.Template.ZENFormWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Form";

Parameter TEMPLATETITLE = "Zen Form Wizard";

Parameter TEMPLATEDESCRIPTION = "Creates a Zen page with a data entry form whose fields are based on a class definition.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "new";

Parameter TEMPLATEGROUP = "Zen";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body">
<tabGroup id="tabGroup">
<tab>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<dataCombo label="Package Name:"
		id="ctrlPackage"
		name="Package"
		required="true"
		labelClass="zenRequired"
		title="Enter or select a package name for the new Zen page class. This is required. If the package does not exist, the wizard will create a new one for you, with this name." 
		editable="true"
		unrestricted="true"
		searchKeyLen="0"
		maxRows="500"
		dropdownWidth="20.0em"
		size="40"
		OnCreateResultSet="CreatePackageRS"
		onchange="zenPage.updateState();"
/>
<text label="New Class Name:" 
	id="ctrlClassName"
	name="ClassName"
	size="40"
	required="true"
	labelClass="zenRequired"
	title="Class name for the new Zen page class. This is required. Do not enter space characters." 
	onchange="zenPage.updateState();"
/>
<radioSet label="Application?" id="ctrlType" value="none" 
name="Type"
title="(Optional) Zen application to associate with the new Zen page class"
valueList="none,existing,new" 
displayList="None,Use Existing,Create New" 
onchange="zenPage.updateForm();"
/>
<dataCombo label="Application Name:"
		id="ctrlApplication"
		name="Application"
		title="If you enter a package and class name and the application does not exist, the wizard will create it" 
		hidden="true"
		editable="true"
		unrestricted="true"
		searchKeyLen="0"
		multiColumn="false"
		displayColumns="1"
		valueColumn="1"
		choiceColumn="1"
		maxRows="500"
		size="40"
		dropdownWidth="20.0em"
		OnCreateResultSet="CreateApplicationRS" 
		onchange="zenPage.updateState();"
/>
</vgroup>
</tab>
<tab>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc2" OnDrawContent="%GetDescHTML2"/>
<!-- %OnAfterCreatePage populates this combobox -->
<combobox label="Package and Class for Form Data:"
		id="ctrlDataClass"
		name="DataClass"
		title="Package and class name of the class whose properties will define the fields in the form. This must be a subclass of %ZEN.DataModel.Adaptor and %Persistent." 
		required="true"
		labelClass="zenRequired"
		size="40"
		dropdownWidth="20.0em"
		onchange="zenPage.updateState();"
	  />
<text label="Form Title:" 
	id="ctrlFormName"
	size="40"
	name="FormName"
	title="(Optional) Title text that will appear at the top of the window or tab when you view the Zen page that contains the new form." 
/>
<text label="CSS Files:" 
	id="ctrlCSSFiles"
	size="40"
	name="CSSFiles"
	title="(Optional) Comma-separated list of one or more existing CSS stylesheets that you want to reference from the Zen page that contains the new form." 
/>
<textarea label="Description:" 
	id="ctrlDescription"
	name="Description"
	rows="5"
	cols="40"
	title="(Optional) Descriptive text that will appear as a comment inside the new Zen page class." 
	onchange="zenPage.updateState();"
/>
</vgroup>
</tab>
</tabGroup>
</pane>
}

/// Provide contents of description component on the first tab.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$Text("This wizard creates a new Zen page class that contains a form.<br/>")
	Write $$$Text("Fill in the form below and then press Next to choose the<br/>")
	Write $$$Text("existing class that will define the fields in your form.")
	Quit $$$OK
}

/// Provide contents of description component on the second tab.
Method %GetDescHTML2(pSeed As %String) As %Status
{
	Write $$$Text("Fill in the fields below and then press Next.")
	Quit $$$OK
}

/// Update state of controls on the wizard form.
ClientMethod updateForm() [ Language = javascript ]
{
	var type = zen('ctrlType').getValue();
	var sup = zen('ctrlApplication');
	if ('none' == type) {
		sup.setHidden(true);
	}
	else {
		sup.setHidden(false);
	}
	zenPage.updateState();
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	// give focus to name
	var ctrl = zen('ctrlClassName');
	if (ctrl) {
		ctrl.focus();
		ctrl.select();
	}
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	
	switch(tabNo) {
		case 1:	{
			/* It's conceptually accurate to require this test on tab 1,
			   but it's confusing to the user because the form doesn't know
			   when you are done typing the Class Name in that field,
			   so it doesn't run this test and Next looks disabled when it shouldn't.
			   So let tab 2 run this validation as it first displays (it does).
			return zenPage.validateTab1(false);
			   */
			return true;
		}
	}

	return false;
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	if (!this.validateTab1(true)) {
		return;
	}
	var tabGroup = zen('tabGroup');
	tabGroup.showNextTab();
	this.updateState();
}

/// Go to the previous page of the template (if there is one).<br>
ClientMethod previousPage() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	tabGroup.showPreviousTab();
	this.updateState();
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	return (tabGroup.getCurrTabNo() > 1);
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	var okay1 = zenPage.validateTab1(true);
	var okay2 = zenPage.validateTab2(true);
	return (okay1 && okay2);
}

/// If speak is true, output an alert message with results of validation.
/// If speak is false, do not output an alert. In both cases return 
/// true if the package name and class name are valid, false if invalid.
ClientMethod validateTab1(speak) [ Language = javascript ]
{
	// test if class name is valid
	var pkgName = zen('ctrlPackage').getValue();
	var clsName = zen('ctrlClassName').getValue();
	var appName = zen('ctrlApplication').getValue();

	// IsValidClassName is provided by the superclass
	var msgIsValidClass = this.IsValidClassName(pkgName + "." + clsName);
	if ('' != msgIsValidClass) {
		if (speak) alert(msgIsValidClass);
		return false;
	}
	
	if ('' != appName) {
		var msgIsValidApp = this.IsValidClassName(appName);
		if ('' != msgIsValidApp) {
			if (speak) alert("The application name is invalid.");
			return false;
		}
	}
	
	return true;
}

/// If speak is true, output an alert message with results of validation.
/// If speak is false, do not output an alert. In both cases return 
/// true if the data class name is valid, false if invalid.
ClientMethod validateTab2(speak) [ Language = javascript ]
{
	// test if data class name is valid
	msg = zenPage.IsValidDataClass(zen('ctrlDataClass').getValue());

	// output message
	if ('' != msg) {
		if (speak) alert(msg);
		return false;
	}

	return true;
}

/// Validate that the given class name is valid to use as the class on which to base the form. 
/// Returns an error message if invalid.
Method IsValidDataClass(pCls As %String) As %String [ ZenMethod ]
{
	Set txt =""
	Set oid = ##class(%Dictionary.ClassDefinition).%OpenId(pCls)
	If (oid) {
		If ((oid.Name [ "%") || (oid.Name [ "csp.") || (oid.Name [ "CSPX.") || (oid.Name [ "Ens.") || (oid.Name [ "EnsLib.") || (oid.Name [ "EnsPortal.")) {
			Set txt = txt _ "The data class specified for the form is not a user-defined class. "
		}
		If '($classmethod(pCls,"%Extends","%ZEN.DataModel.Adaptor")) {
			Set txt = txt _ "The data class specified for the form is not a %ZEN.DataModel.Adaptor subclass. "
		}
		If '($classmethod(pCls,"%Extends","%Persistent")) {
			Set txt = txt _ "The data class specified for the form is not a %Persistent subclass. "
		}
	}
	Else {
		Set txt = txt _ "The data class specified for the form does not exist. "
	}
	Quit txt
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set tPackage = ..%GetValueByName("Package")
	Set tClassName = ..%GetValueByName("ClassName")
	Set tApplication = ..%GetValueByName("Application")
	Set tDataClass = ..%GetValueByName("DataClass")
	Set tFormName = ..%GetValueByName("FormName")
	Set tCSSFiles = ..%GetValueByName("CSSFiles")
	Set tDescription = ..%GetValueByName("Description")

	do ..CreatePage(tDataClass,tApplication,tPackage,tClassName,tFormName,tCSSFiles,tDescription)
	
	Set cls = tPackage_"."_tClassName
	Do ..%AddToProject(cls _ ".cls")
	
	if tApplication'="" {
		if ##class(%Dictionary.ClassDefinition).%ExistsId(tApplication) {
			Do ..%AddToProject(tApplication _ ".cls")
		}
	}
	
	Quit $$$OK
}

/// Create the result set used by the Package dataCombo.
Method CreatePackageRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "%ZEN.Utils"
	Set tRS.QueryName = "EnumeratePackages"
	Quit tRS
}

/// Create the result set used by the Application dataCombo.
Method CreateApplicationRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "%ZEN.Utils"
	Set tRS.QueryName = "EnumerateApplications"
	Quit tRS
}

/// Create the result set used by the DataClass dataCombo.
Method CreateDataClassRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "%Dictionary.ClassDefinition"
	Set tRS.QueryName = "SubclassOf"
	Quit tRS
}

ClassMethod CreatePage(dataClassName As %String, appName As %String, pkgName As %String, newClassName As %String, formName As %String, cssNames As %String, clsComment As %String) As %Status
{

	#define crlf $c(13,10)

	// We need a Package and DataClass; these are required fields in the ZenFormWizard.
	if pkgName="" Quit // Having trouble using the $$$ERROR macro here...?
	if dataClassName="" Quit // $$$ERROR(...)
    if '##class(%Dictionary.ClassDefinition).%ExistsId(dataClassName) Quit // $$$ERROR(...)

	// A Class name is also required in the ZenFormWizard, but we can get by without it.
	if newClassName="" set newClassName=dataClassName
	
	// It's okay not to have an App...
	if appName'="" {
		// ...but if we do, check to see if App exists; if not, create it.
		if '##class(%Dictionary.ClassDefinition).%ExistsId(appName) {
			do ..CreateZenApp(appName)
		}
	}
	
	// We can manage without the rest of the information.
	if formName="" set formName=dataClassName_" Zen Page"
	
	// if page already exists, delete existing one first.
	if ##class(%Dictionary.ClassDefinition).%ExistsId(pkgName_"."_newClassName) {
		do ##class(%Dictionary.ClassDefinition).%DeleteId(pkgName_"."_newClassName)
	}

	set zenPg=##class(%Dictionary.ClassDefinition).%New()
	set zenPg.Name=pkgName_"."_newClassName
	set zenPg.Super="%ZEN.Component.page"
	set zenPg.ProcedureBlock=1
	set zenPg.Description=clsComment

	set param=##class(%Dictionary.ParameterDefinition).%New()
	set param.Name="APPLICATION"
	set param.Default=appName
	do zenPg.Parameters.Insert(param)
	
	set param=##class(%Dictionary.ParameterDefinition).%New()
	set param.Name="PAGENAME"
	set param.Default=pkgName_"."_newClassName
	do zenPg.Parameters.Insert(param)

	set param=##class(%Dictionary.ParameterDefinition).%New()
	set param.Name="DOMAIN"
	set param.Default="ZENDEMO"
	do zenPg.Parameters.Insert(param)

	set param=##class(%Dictionary.ParameterDefinition).%New()
	set param.Name="CSSINCLUDES"
	set param.Default=cssNames
	do zenPg.Parameters.Insert(param)

	set prop=##class(%Dictionary.PropertyDefinition).%New()
	set prop.Name="MyId"
	set prop.Type="%Integer"
	//set prop.InitialExpression=1
	do zenPg.Properties.Insert(prop)
	
	set xds=##class(%Dictionary.XDataDefinition).%New()
	set xds.parent=zenPg
	set xds.Name="Style"
	set xds.Data=##class(%Stream.TmpCharacter).%New()
	do xds.Data.Rewind()
	do xds.Data.Write(" <style type=""text/css"">"_$$$crlf_"</style>")
	do xds.%Save()

	set xdc=##class(%Dictionary.XDataDefinition).%New()
	set xdc.parent=zenPg
	set xdc.Name="Contents"
	set xdc.XMLNamespace="http://www.intersystems.com/zen"
	set xdc.Data=##class(%Stream.TmpCharacter).%New()
	do xdc.Data.Rewind()
	do xdc.Data.Write("<page xmlns=""http://www.intersystems.com/zen"" title="""_formName_""" >"_$$$crlf)
	do xdc.Data.Write("<dataController id=""mvc"" modelClass="""_dataClassName_""" modelId="""" />"_$$$crlf)
	do xdc.Data.Write("<form controllerId=""mvc"" id="""_newClassName_""" width=""100%"" >"_$$$crlf)

	do xdc.Data.Write("<spacer height=""10"" />"_$$$crlf)
	do xdc.Data.Write("<vgroup align=""left"" valign=""top"" labelPosition=""left"" >"_$$$crlf)

	do xdc.Data.Write("<hgroup>"_$$$crlf)
	do xdc.Data.Write("<button id=""btnNew"" caption=""New"" title=""Clear all fields so that you can create a new record"" onclick=""zenPage.newRec();""/>"_$$$crlf)
	do xdc.Data.Write("<button id=""btnView"" caption=""View"" title=""To edit or delete a record, enter the number in the ID field, then click this button"" onclick=""zenPage.viewRec();""/>"_$$$crlf)
	do xdc.Data.Write("<button id=""btnSave"" caption=""Save"" title=""Save the record currently in view"" onclick=""zenPage.validateAndSave(); zenPage.refreshSearchTable();""/>"_$$$crlf)
	do xdc.Data.Write("<button id=""btnDelete"" caption=""Delete"" title=""Delete the record currently in view"" onclick=""zenPage.deleteRec(); zenPage.refreshSearchTable();"" />"_$$$crlf)
	do xdc.Data.Write("<button id=""btnSearch"" caption=""Search"" title=""Find all records"" onclick=""zenPage.toggleSearchTable();"" />"_$$$crlf)
	do xdc.Data.Write("</hgroup>"_$$$crlf)
	do xdc.Data.Write("<spacer height=""10"" />"_$$$crlf)
	do xdc.Data.Write(" <text label=""(System Assigned) ID"" id=""ID"" title=""System assigned identifier. Do not edit when creating a new record."" size=""10"" value=""#(%page.MyId)#"" height=""23"" onblur=""zenPage.getRecord(zenThis.getValue());"" />"_$$$crlf)

	// iterate through the properties to create data controls
	
	set class=##class(%Dictionary.ClassDefinition).%OpenId(dataClassName)
	set numProps=class.Properties.Count()
	set reqText=""
	for i=1:1:numProps {
		set tip=""
		set prop=class.Properties.GetAt(i)
		set pName=prop.Name
		// Here is where we might parse property naming conventions to add spaces between words in labels.
		// Better yet, we should rewrite to offer a choice of editing the labels, like the CSP wizard does!
		if prop.Required { 
			set labText = pName_" *"
			set reqText="* Indicates a required field"
		}
		else {
			set labText = pName
		}
		if prop.Type["Boolean" {
			do xdc.Data.Write(" <checkbox id="""_pName_""" label="""_labText_""" title=""Click the box to enable"" height=""23"" dataBinding="""_pName_""" />"_$$$crlf)
		}	
		elseif prop.Type["Date" {
			// if you want to use a dateText control, per Joe DeSantis:
			// "Make sure you set the FORMAT of the %Date property to 3 (YYYY-MM-DD)"
			//do xdc.Data.Write(" <dateText id="""_pName_""" height=""23"" dataBinding="""_pName_""" />"_$$$crlf)
			do xdc.Data.Write(" <text id="""_pName_""" label="""_labText_""" title=""YYYY-MM-DD"" height=""23"" dataBinding="""_pName_""" />"_$$$crlf)
		}	
		elseif prop.Type["TimeStamp" {
			do xdc.Data.Write(" <text id="""_pName_""" label="""_labText_""" title=""YYYY-MM-DD HH:MM:SS"" height=""23"" dataBinding="""_pName_""" />"_$$$crlf)
		}	
		elseif prop.Type["Time" {
			do xdc.Data.Write(" <text id="""_pName_""" label="""_labText_""" title=""HH:MM:SS"" height=""23"" dataBinding="""_pName_""" />"_$$$crlf)
		}	
		// %Float is deprecated but might be found in older classes
		elseif ((prop.Type["Float") || (prop.Type["Double") || (prop.Type["Decimal")) {
			do xdc.Data.Write(" <text id="""_pName_""" label="""_labText_""" title=""Enter a number"" height=""23"" dataBinding="""_pName_""" />"_$$$crlf)
		}	
		elseif prop.Type["String" {

			// MINLEN
			
			set len=+prop.Parameters.GetAt("MINLEN")
			if (len) set tip=tip_"At least "_len_" characters. "

			// MAXLEN
			
			set len=+prop.Parameters.GetAt("MAXLEN")
			if (len) set tip=tip_"Up to "_len_" characters. "
			if (len >= 100) {
				if (len >= 250) { 
					set hgt = 5 
					}
				else {
					set hgt = len \ 50 
					}
				set wid = 50
				do xdc.Data.Write("<textarea id="""_pName_""" label="""_labText_""" title="""_tip_""" cols="""_wid_""" rows="""_hgt_""" dataBinding="""_pName_""" />"_$$$crlf)
			}
			else {
				set wid = len
				if wid=0 set wid=50
				
				// VALUELIST and DISPLAYLIST
				// Work around Prodlog 70883 "combobox works only when its valueList matches the DISPLAYLIST of its modelClass property" 
			
				set combo=0
				if $L(prop.Parameters.GetAt("DISPLAYLIST"))>1 {
					set vlist=prop.Parameters.GetAt("DISPLAYLIST")
					set combo=1
				}
				else {
					if $L(prop.Parameters.GetAt("VALUELIST"))>1 {
						set vlist=prop.Parameters.GetAt("VALUELIST")
						set combo=1
					}
				}
				if combo {
					set delim=$E(vlist,1)
					set wid=$L(vlist,delim)
					set hgt = wid * 25
					do xdc.Data.Write(" <combobox id="""_pName_""" label="""_labText_""" valueList="""_vlist_""" title=""Choose a value"" dropdownHeight="""_hgt_""" dropdownWidth=""200"" dataBinding="""_pName_""" />"_$$$crlf)
				}
				else {
					if (tip = "") set tip = "Enter a value"
					do xdc.Data.Write(" <text id="""_pName_"""  label="""_labText_""" title="""_tip_""" size="""_wid_""" dataBinding="""_pName_""" height=""23"" />"_$$$crlf)
				}
			}
		}	
		else {
			
			// MINVAL
			
			set val=+prop.Parameters.GetAt("MINVAL")
			if (val) set tip=tip_"Greater than or equal to "_val_". "
			
			// MAXVAL

			set val=+prop.Parameters.GetAt("MAXVAL")
			if (val) set tip=tip_"Less than or equal to "_val_". "
			
			if (tip = "") set tip = "Enter a value"
			do xdc.Data.Write(" <text id="""_pName_"""  label="""_labText_""" title="""_tip_""" size=""50"" dataBinding="""_pName_""" height=""23"" />"_$$$crlf)
		}
	}

	if (reqText'="") {
		do xdc.Data.Write(" <html id=""requiredText"" >"_reqText_"</html>"_$$$crlf)
	}
	
	set sqltablename = $$$comClassKeyGet(dataClassName,$$$cCLASSsqlschemaname)_"."_$$$comClassKeyGet(dataClassName,$$$cCLASSsqltablename) 
	do xdc.Data.Write("   <spacer height=""20"" />"_$$$crlf)
	do xdc.Data.Write("   <tablePane id=""searchTable"" hidden=""true"" maxRows=""50"" sql=""SELECT * FROM "_sqltablename_" ORDER BY ID"" >"_$$$crlf)
	do xdc.Data.Write("     <column colName=""ID"" link=""javascript:zenPage.getRecord(#(%query.ID)#);"" />"_$$$crlf)
	do xdc.Data.Write("   </tablePane>"_$$$crlf)
	do xdc.Data.Write("   <spacer height=""10"" />"_$$$crlf)
	
	do xdc.Data.Write("  </vgroup>"_$$$crlf)
	do xdc.Data.Write(" </form>"_$$$crlf)
	do xdc.Data.Write("</page>"_$$$crlf)
	do xdc.%Save()

	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClassMethod=1
	set method.ZenMethod=1
	set method.Name="ModelIdExists"
	set method.ReturnType="%Boolean"
	set method.FormalSpec="modelId:%String"
	set method.parent=zenPg
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" if ($classmethod("""_dataClassName_""",""%ExistsId"",modelId)) {"_$$$crlf)
 	do code.Write("  Quit 1"_$$$crlf)
 	do code.Write(" }"_$$$crlf)
 	do code.Write(" else {"_$$$crlf)
 	do code.Write("  Quit 0"_$$$crlf)
    do code.Write(" }"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
 
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="saveRec"
	set method.ReturnType="%Status"
	set method.FormalSpec="ok"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" if (ok == true) {"_$$$crlf)
 	do code.Write("  var form=zen('"_newClassName_"');"_$$$crlf)
 	do code.Write("  var save=form.save();"_$$$crlf)
 	do code.Write("  if (save.length == 0) ok = false;"_$$$crlf)
 	do code.Write("  else var cls=zen('mvc').getModelClass();"_$$$crlf)
    do code.Write(" }"_$$$crlf)
    do code.Write(" if (ok == true) alert(zenText('SuccessSaveRecord'));"_$$$crlf)
    do code.Write(" else alert(zenText('FailedDataValidation'));"_$$$crlf)
    do code.Write(" return ok;"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
 
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="viewRec"
	set method.ReturnType="%Status"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
    do code.Write(" var id = zen('ID');"_$$$crlf)
    do code.Write(" var val = id.getValue();"_$$$crlf)
    do code.Write(" if (val.length <= 0) {"_$$$crlf)
	do code.Write("  alert(zenText('NothingRecord'));"_$$$crlf)
	do code.Write("  return false;"_$$$crlf)
    do code.Write(" }"_$$$crlf)
    do code.Write(" if (zenPage.ModelIdExists(val) == 0) {"_$$$crlf)
	do code.Write("  alert(zenText('NoExistRecord'));"_$$$crlf)
	do code.Write("  return false;"_$$$crlf)
    do code.Write(" }"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
 
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="newRec"
	set method.ReturnType="%Status"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var id = zen('ID');"_$$$crlf)
	do code.Write(" id.setValue('');"_$$$crlf)
	do code.Write(" var controller = zen('mvc');"_$$$crlf)
	do code.Write(" controller.createNewObject();"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
 
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="deleteRec"
	set method.ReturnType="%Status"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
 	do code.Write(" var id = zen('ID');"_$$$crlf)
 	do code.Write(" var val = id.getValue();"_$$$crlf)
 	do code.Write(" if (val.length <= 0) {"_$$$crlf)
	do code.Write("  alert(zenText('NothingRecord'));"_$$$crlf)
	do code.Write("  return false;"_$$$crlf)
 	do code.Write(" }"_$$$crlf)
 	do code.Write(" if (zenPage.ModelIdExists(val) == 0) {"_$$$crlf)
	do code.Write("  alert(zenText('NoExistRecord'));"_$$$crlf)
	do code.Write("  return false;"_$$$crlf)
 	do code.Write(" }"_$$$crlf)
 	do code.Write(" if (confirm(zenText('ConfirmDelete'))) {"_$$$crlf)
	do code.Write("  var controller = zen('mvc');"_$$$crlf)
	do code.Write("  controller.deleteId(controller.getModelId());"_$$$crlf)
	do code.Write("  controller.createNewObject();"_$$$crlf)
	do code.Write("  controller.update();"_$$$crlf)
	do code.Write("  if (id.setValue('') == false) {"_$$$crlf)
	do code.Write(" 	 alert(zenText('FailedDelete'));"_$$$crlf)
	do code.Write(" 	 return false;"_$$$crlf)
	do code.Write("  }"_$$$crlf)
	do code.Write("  alert(zenText('SuccessDelete'));"_$$$crlf)
	do code.Write("  return false;"_$$$crlf)
	do code.Write(" }"_$$$crlf)
	do code.Write(" else {"_$$$crlf)
 	do code.Write("  alert(zenText('FailedDelete'));"_$$$crlf)
 	do code.Write("  return false;"_$$$crlf)
 	do code.Write(" }"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
 
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="getRecord"
	set method.ReturnType="%Status"
	set method.FormalSpec="id:%Integer"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var controller = zen('mvc');"_$$$crlf)
	do code.Write(" controller.setModelId(id);"_$$$crlf)
	do code.Write(" var idText = id.toString();"_$$$crlf)
	do code.Write(" zenPage.MyId = idText;"_$$$crlf)
	do code.Write(" var id = zen('ID');"_$$$crlf)
	do code.Write(" id.setValue(idText);"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="toggleSearchTable"
	set method.ReturnType="%Status"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var tab = zen('searchTable');"_$$$crlf)
	do code.Write(" if (tab.hidden == true) { "_$$$crlf)
	do code.Write("  tab.setHidden(false); "_$$$crlf)
	do code.Write("  var btn = zen('btnSearch'); "_$$$crlf)
 	do code.Write("  btn.caption = zenText('LabelHide');"_$$$crlf)
 	do code.Write("  btn.title = zenText('LabelTitleHide'); "_$$$crlf)
 	do code.Write("  tab.executeQuery(); "_$$$crlf)
 	do code.Write("  zenPage.refreshContents(); "_$$$crlf)
 	do code.Write(" } "_$$$crlf)
 	do code.Write(" else { "_$$$crlf)
 	do code.Write("  zenPage.hideSearchTable(); "_$$$crlf)
 	do code.Write(" }"_$$$crlf)
	set method.Implementation=code
	set method.Description="Display the table of records on the form."
	do method.%Save()
 
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="hideSearchTable"
	set method.ReturnType="%Status"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var tab = zen('searchTable');"_$$$crlf)
	do code.Write(" tab.setHidden(true); "_$$$crlf)
	do code.Write(" var btn = zen('btnSearch'); "_$$$crlf)
	do code.Write(" btn.caption = zenText('LabelSearch'); "_$$$crlf)
	do code.Write(" btn.title = zenText('LabelTitleSearch');"_$$$crlf)
	do code.Write(" zenPage.refreshContents();"_$$$crlf)
	set method.Implementation=code
	set method.Description="Hide the table of records on the form."
	do method.%Save()
 
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="refreshSearchTable"
	set method.ReturnType="%Status"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var tab = zen('searchTable');"_$$$crlf)
	do code.Write(" if (tab.hidden == false) { "_$$$crlf)
	do code.Write("   tab.executeQuery(); "_$$$crlf)
	do code.Write(" } "_$$$crlf)
	set method.Implementation=code
	set method.Description="Refresh the table of records on the form."
	do method.%Save()
 
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.Name="%OnGetJSResources"
	set method.Private=1
	set method.ReturnType="%Status"
	set method.FormalSpec="&pResources:%String"
	set method.parent=zenPg
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	
	// Static text strings
	
    do code.Write(" Set pResources(""SuccessSaveRecord"") = $$$Text(""Record saved."")"_$$$crlf)
    do code.Write(" Set pResources(""NothingRecord"") = $$$Text(""Enter an ID value. To view a list of IDs click Search."")"_$$$crlf) 
    do code.Write(" Set pResources(""NoExistRecord"") = $$$Text(""No record with this ID exists. To view a list of valid IDs click Search."") "_$$$crlf)
    do code.Write(" Set pResources(""ConfirmDelete"") = $$$Text(""Are you sure you want to delete this record? You cannot undo this operation."") "_$$$crlf)
    do code.Write(" Set pResources(""FailedDelete"") = $$$Text(""Record was not deleted."") "_$$$crlf)
    do code.Write(" Set pResources(""SuccessDelete"") = $$$Text(""Record deleted."") "_$$$crlf)
    do code.Write(" Set pResources(""LabelHide"") = $$$Text(""Hide"")"_$$$crlf)
    do code.Write(" Set pResources(""LabelTitleHide"") = $$$Text(""Hide display of current records"")"_$$$crlf)
    do code.Write(" Set pResources(""LabelSearch"") = $$$Text(""Search"")"_$$$crlf)
    do code.Write(" Set pResources(""LabelTitleHide"") = $$$Text(""Find all records"")"_$$$crlf)
    do code.Write(" Set pResources(""FailedDataValidation"") = $$$Text(""Some data was incorrect or incomplete. Please try again. To view tips for entering the correct data format for a field, hover the cursor over the field (or its title) and wait for a tooltip to display""_ $c(13,10,13,10)) "_$$$crlf)
    do code.Write(" "_$$$crlf)
    
	// iterate through the properties to create dynamic text strings
	
	set class=##class(%Dictionary.ClassDefinition).%OpenId(dataClassName)
	set numProps=class.Properties.Count()
	set reqText=""
	for i=1:1:numProps {
		set prop=class.Properties.GetAt(i)
		set pName=prop.Name
		if prop.Type["Boolean" {
			Set tType="Boolean"
			Set txt=" was an invalid value."
		}	
		elseif prop.Type["Date" {	
			Set tType="Date"
			Set txt=" was not a date in YYYY-MM-DD format."
		}	
		elseif prop.Type["TimeStamp" {
			Set tType="TimeStamp"
			Set txt=" was not a time stamp in YYYY-MM-DD HH:MM:SS format."
		}	
		elseif prop.Type["Time" {
			Set tType="Time"
			Set txt=" was not a time in HH:MM:SS format."
		}	
		// %Float is deprecated but might be found in older classes
		elseif ((prop.Type["Float") || (prop.Type["Double") || (prop.Type["Decimal")) {
			Set tType="Decimal"
			Set txt=" contained non-numeric characters."
		}	
		elseif prop.Type["String" {
			Set tType="String"
			Set txt=" was too short or too long."
		}	
		else {
			Set tType="Integer"
			Set txt=" was not an integer or was outside the allowed range."
		}
		if prop.Required { 
    		do code.Write(" Set pResources(""Required"_pName_""") = $$$Text("""_pName_" is a required field, but it was empty.""_$c(13,10))"_$$$crlf)
		}
    	do code.Write(" Set pResources(""Failed"_tType_pName_""") = $$$Text("""_pName_txt_"""_$c(13,10))"_$$$crlf)
	}
	
    do code.Write(" "_$$$crlf)
    do code.Write(" Quit $$$OK"_$$$crlf)
	set method.Implementation=code
	set method.Description="Provide localized text strings for use in the form."
	do method.%Save()
 
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateAndSave"
	set method.ReturnType="%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var msg = '';"_$$$crlf)

	// iterate through the properties to create dynamic text strings
	
	set class=##class(%Dictionary.ClassDefinition).%OpenId(dataClassName)
	set numProps=class.Properties.Count()
	set reqText=""
	for i=1:1:numProps {
		set prop=class.Properties.GetAt(i)
		set pName=prop.Name
		if prop.Type["Boolean" {
			Set tType="Boolean"
		}	
		elseif prop.Type["Date" {	
			Set tType="Date"
		}	
		elseif prop.Type["TimeStamp" {
			Set tType="TimeStamp"
		}	
		elseif prop.Type["Time" {
			Set tType="Time"
		}	
		// %Float is deprecated but might be found in older classes
		elseif ((prop.Type["Float") || (prop.Type["Double") || (prop.Type["Decimal")) {
			Set tType="Decimal"
		}	
		elseif prop.Type["String" {
			Set tType="String"
		}	
		else {
			Set tType="Integer"
		}
		if prop.Required { 
    		do code.Write(" if (zenPage.validateRequired('"_pName_"') == false)"_$$$crlf)
    		do code.Write("  msg += zenText('Required"_pName_"');"_$$$crlf)
    		If (tType["String") {
    			If ((+prop.Parameters.GetAt("MINLEN")) || (+prop.Parameters.GetAt("MAXLEN"))) {
		    		Set rangeText = ..GetRangeText(prop,"MINLEN","MAXLEN")
			    	do code.Write(" else if (zenPage.validateString('"_pName_"'"_rangeText_") == false)"_$$$crlf)
			    	do code.Write("  msg += zenText('Failed"_tType_pName_"');"_$$$crlf)
    			}
	 			Else {
					// do nothing
				}
    		}
    		ElseIf (tType["Integer") {
	    		If ((+prop.Parameters.GetAt("MINVAL")) || (+prop.Parameters.GetAt("MAXVAL")))  {
		    		Set rangeText = ..GetRangeText(prop,"MINVAL","MAXVAL")
			    	do code.Write(" else if (zenPage.validateInteger('"_pName_"'"_rangeText_") == false)"_$$$crlf)
			    	do code.Write("  msg += zenText('Failed"_tType_pName_"');"_$$$crlf)
	    		}
	    		Else {
			    	do code.Write(" else if (zenPage.validateInteger('"_pName_"',false,0,false,0) == false)"_$$$crlf)
			    	do code.Write("  msg += zenText('Failed"_tType_pName_"');"_$$$crlf)
	    		}
    		}
			ElseIf ('(tType["Boolean")) {
		    	do code.Write(" else if (zenPage.validate"_tType_"('"_pName_"') == false)"_$$$crlf)
		    	do code.Write("  msg += zenText('Failed"_tType_pName_"');"_$$$crlf)
			}
			Else {
				// do nothing
			}
		}
		Else {
    		If (tType["String") {
	    		If ((+prop.Parameters.GetAt("MINLEN")) || (+prop.Parameters.GetAt("MAXLEN")))   {
		    		Set rangeText = ..GetRangeText(prop,"MINLEN","MAXLEN")
			    	do code.Write(" if ((zen('"_pName_"').getValue().length > 0) && (zenPage.validateString('"_pName_"'"_rangeText_") == false))"_$$$crlf)
			    	do code.Write("  msg += zenText('Failed"_tType_pName_"');"_$$$crlf)
	    		}
				Else {
					// do nothing
				}
    		}
    		ElseIf (tType["Integer") {
	    		If ((+prop.Parameters.GetAt("MINVAL")) || (+prop.Parameters.GetAt("MAXVAL"))) {
		    		Set rangeText = ..GetRangeText(prop,"MINVAL","MAXVAL")
			    	do code.Write(" if ((zen('"_pName_"').getValue().length > 0) && (zenPage.validateInteger('"_pName_"'"_rangeText_") == false))"_$$$crlf)
			    	do code.Write("  msg += zenText('Failed"_tType_pName_"');"_$$$crlf)
	    		}
	    		Else {
			    	do code.Write(" if ((zen('"_pName_"').getValue().length > 0) && (zenPage.validateInteger('"_pName_"',false,0,false,0) == false))"_$$$crlf)
			    	do code.Write("  msg += zenText('Failed"_tType_pName_"');"_$$$crlf)
	    		}
    		}
			ElseIf ('(tType["Boolean")) {
		    	do code.Write(" if ((zen('"_pName_"').getValue().length > 0) && (zenPage.validate"_tType_"('"_pName_"') == false))"_$$$crlf)
		    	do code.Write("  msg += zenText('Failed"_tType_pName_"');"_$$$crlf)
			}
			Else {
				// do nothing
			}
		}
	} // end loop through properties
	
	do code.Write(" if (msg.length == 0) zenPage.saveRec(true);"_$$$crlf)
	do code.Write(" else alert(zenText('FailedDataValidation') + msg);"_$$$crlf)
	set method.Implementation=code
	set method.Description="Refresh the table of records on the form."
	do method.%Save()

	// validation methods
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateTimeStamp"
	set method.ReturnType="%Status"
	set method.FormalSpec="fname:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var field = zen(fname).getValue();"_$$$crlf)
	do code.Write(" var len = field.length;"_$$$crlf)
	do code.Write(" if (len < 18) return false;"_$$$crlf)
	do code.Write(" var part = field.split(' ');"_$$$crlf)
	do code.Write(" if (part.length != 2) return false;"_$$$crlf)
	do code.Write(" if (zenPage.validateDateField(part[0]) == false) return false;"_$$$crlf)
	do code.Write(" if (zenPage.validateTimeField(part[1]) == false) return false;"_$$$crlf)
	do code.Write(" return true;"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateTime"
	set method.ReturnType="%Status"
	set method.FormalSpec="fname:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write("  return zenPage.validateTimeField(zen(fname).getValue());"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
 	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateTimeField"
	set method.ReturnType="%Status"
	set method.FormalSpec="field:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var len = field.length;"_$$$crlf)
	do code.Write(" if (len < 8) return false;"_$$$crlf)
	do code.Write(" if (field.charAt(2) != ':') return false;"_$$$crlf)
	do code.Write(" if (field.charAt(5) != ':') return false;"_$$$crlf)
	do code.Write(" var part = field.split(':');"_$$$crlf)
	do code.Write(" if (part.length != 3) return false;"_$$$crlf)
	do code.Write(" if (zenPage.validateHour(part[0]) == false) return false;"_$$$crlf)
	do code.Write(" if (zenPage.validateMinute(part[1]) == false) return false;"_$$$crlf)
	do code.Write(" if (zenPage.validateMinute(part[2]) == false) return false;"_$$$crlf)
	do code.Write(" return true;"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateHour"
	set method.ReturnType="%Status"
	set method.FormalSpec="field:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var val = parseInt(field); "_$$$crlf)
	do code.Write(" return ((val >= 0) && (val <= 23)); "_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateMinute"
	set method.ReturnType="%Status"
	set method.FormalSpec="field:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var val = parseInt(field); "_$$$crlf)
	do code.Write(" return ((val >= 0) && (val <= 59)); "_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateDate"
	set method.ReturnType="%Status"
	set method.FormalSpec="fname:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" return zenPage.validateDateField(zen(fname).getValue()); "_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateDateField"
	set method.ReturnType="%Status"
	set method.FormalSpec="field:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var len = field.length;"_$$$crlf)
	do code.Write(" if (len < 10) return false;"_$$$crlf)
	do code.Write(" if (field.charAt(4) != '-') return false;"_$$$crlf)
	do code.Write(" if (field.charAt(7) != '-') return false;"_$$$crlf)
	do code.Write(" var part = field.split('-');"_$$$crlf)
	do code.Write(" if (part.length != 3) return false;"_$$$crlf)
	do code.Write(" if (zenPage.validateYear(part[0]) == false) return false;"_$$$crlf)
	do code.Write(" if (zenPage.validateMonthDay(part[1],part[2]) == false) return false;"_$$$crlf)
	do code.Write(" return true;"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateYear"
	set method.ReturnType="%Status"
	set method.FormalSpec="field:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var val = parseInt(field); "_$$$crlf)
	do code.Write(" return ((val >= 0) && (val <= 9999)); "_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateMonthDay"
	set method.ReturnType="%Status"
	set method.FormalSpec="field1:%String,field2:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var m = parseInt(field1);"_$$$crlf)
	do code.Write(" var d = parseInt(field2);"_$$$crlf)
	do code.Write(" if ((m >= 1) && (m <= 12) && (d >= 1) && (d <= 31)) {"_$$$crlf)
	do code.Write("	 if ((m == 4) || (m == 6) || (m == 9) || (m == 11)) {"_$$$crlf)
	do code.Write("		 if (d <= 30) return true;"_$$$crlf)
	do code.Write("	 }"_$$$crlf)
	do code.Write("	 else if (m == 2) {"_$$$crlf)
	do code.Write("		 if (d <= 29) return true;"_$$$crlf)
	do code.Write("	 }"_$$$crlf)
	do code.Write("	 else return true;"_$$$crlf)
 	do code.Write(" }"_$$$crlf)
	do code.Write(" return false;"_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateInteger"
	set method.ReturnType="%Status"
	set method.FormalSpec="fname:%String,haveMin:%Boolean,min:%Integer,haveMax:%Boolean,max:%Integer"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var field = (zen(fname)).getValue(); "_$$$crlf)
	do code.Write(" if (isNaN(field)) return false; "_$$$crlf)
	do code.Write(" if ((haveMin == true) && (field < min)) return false; "_$$$crlf)
 	do code.Write(" if ((haveMax == true) && (field > max)) return false; "_$$$crlf)
 	do code.Write(" return true; "_$$$crlf)
	set method.Implementation=code
	do method.%Save()
	
	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateDecimal"
	set method.ReturnType="%Status"
	set method.FormalSpec="fname:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var field = (zen(fname)).getValue();"_$$$crlf)
	do code.Write(" var part = field.split('.');"_$$$crlf)
	do code.Write(" var len = part.length;"_$$$crlf)
	do code.Write(" if ((len <= 0) || (part.length > 2)) return false;"_$$$crlf)
	do code.Write(" for (i = 0; i < len; i++) {"_$$$crlf)
	do code.Write(" 	 if (isNaN(part[i])) return false;"_$$$crlf)
	do code.Write(" }"_$$$crlf)
	do code.Write(" return true;"_$$$crlf)
	set method.Implementation=code
	do method.%Save()

	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateRequired"
	set method.ReturnType="%Status"
	set method.FormalSpec="fname:%String"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
	do code.Write(" var field = (zen(fname)).getValue();"_$$$crlf)
	do code.Write(" if (field.length == 0) return false;"_$$$crlf)
	do code.Write(" else return true; "_$$$crlf)
	set method.Implementation=code
	do method.%Save()

	set method=##class(%Dictionary.MethodDefinition).%New()
	set method.ClientMethod=1
	set method.Name="validateString"
	set method.ReturnType="%Status"
	set method.FormalSpec="fname:%String,haveMin:%Boolean,min:%Integer,haveMax:%Boolean,max:%Integer"
	set method.parent=zenPg
	set method.Language="javascript"
	set code=##class(%Stream.TmpCharacter).%New()
	do code.Rewind()
 	do code.Write(" var field = (zen(fname)).getValue(); "_$$$crlf) 
 	do code.Write(" var len = field.length; "_$$$crlf)
 	do code.Write(" if ((haveMin == true) && (len < min)) return false; "_$$$crlf)
 	do code.Write(" if ((haveMax == true) && (len > max)) return false; "_$$$crlf)
 	do code.Write(" else return true; "_$$$crlf)
	set method.Implementation=code
	do method.%Save()

 	// save the whole page
 	
	set ok=zenPg.%Save()

	if ok { do $system.OBJ.Compile(pkgName_"."_newClassName) }
	quit ok
}

/// Get appropriate text to use when testing ranges for strings (length) and for integers (values).
ClassMethod GetRangeText(prop As %Dictionary.PropertyDefinition, p1 As %String, p2 As %String) As %String
{
	// MINLEN, MINVAL
	Set minLen=+prop.Parameters.GetAt(p1)
	If (minLen) {
		Set minText = ",true," _ minLen
	}
	Else {
		Set minText = ",false,0"
	}
	
	// MAXLEN, MAXVAL
	Set maxLen=+prop.Parameters.GetAt(p2)
	If (maxLen) {
		Set maxText = ",true," _ maxLen
	}
	Else {
		Set maxText = ",false,0"
	}
	
	// Result
	Quit minText_maxText
}

ClassMethod CreateZenApp(appName As %String) As %Status
{

	set zenApp=##class(%Dictionary.ClassDefinition).%New()
	set zenApp.Name=appName
	set zenApp.Super="%ZEN.application"
	set zenApp.ProcedureBlock=1

	set param=##class(%Dictionary.ParameterDefinition).%New()
	set param.Name="APPLICATIONNAME"
	set param.Default=appName
	do zenApp.Parameters.Insert(param)
	
	set param=##class(%Dictionary.ParameterDefinition).%New()
	set param.Name="HOMEPAGE"
	set param.Default=""
	do zenApp.Parameters.Insert(param)

	set param=##class(%Dictionary.ParameterDefinition).%New()
	set param.Name="DOMAIN"
	set param.Default="ZENDEMO"
	do zenApp.Parameters.Insert(param)

	set xds=##class(%Dictionary.XDataDefinition).%New()
	set xds.parent=zenApp
	set xds.Name="Style"
	set xds.Data=##class(%Stream.TmpCharacter).%New()
	do xds.Data.Rewind()
	do xds.Data.Write(" <style type=""text/css"">"_$$$crlf_"</style>"_$$$crlf)
	do xds.%Save()

	set ok=zenApp.%Save()
	if ok { do $system.OBJ.Compile(appName) }

	quit ok
}

Method %OnAfterCreatePage() As %Status
{
	// plug in default values
	Do %page.%SetValueById("ctrlPackage",##class(%ZEN.Utils).GetDefaultPackage())

	// Set up drop-down including subclasses of %ZEN.DataModel.Adaptor that are %Persistent and not system classes
	Set tCombo = ..%GetComponentById("ctrlDataClass")
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute("%ZEN.DataModel.Adaptor")
	While (tRS.Next()) {
		Set cls = tRS.Data("Name")  Continue:'##class(%Dictionary.CompiledClass).%ExistsId(cls)
		Set cdef = ##class(%Dictionary.ClassDefinition).%OpenId(cls)
		if $IsObject(cdef) {
			Set n = cdef.Name
			If (($classmethod(cls,"%Extends","%Persistent")) && '((n["%")||(n["csp.")||(n["CSPX.")||(n["Ens.")||(n["EnsLib.")||(n["EnsPortal.")) ) { 
				Set tOption = ##class(%ZEN.Auxiliary.option).%New()
				Do tCombo.options.Insert(tOption)
				Do ..%AddComponent(tOption)
				Set tOption.text = cls
				Set tOption.value = cls
		    }
		}
	}
	Quit $$$OK
}

}
