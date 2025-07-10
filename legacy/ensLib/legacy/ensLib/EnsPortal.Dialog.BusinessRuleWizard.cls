/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user create a new Business Rule.
Class EnsPortal.Dialog.BusinessRuleWizard Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// User needs WRITE permissions on one of the following resources to view this page:
/// %Ens_Code, %Ens_Rules, %Ens_RoutingRules or %Ens_BusinessRules
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_Rules:WRITE,%Ens_RoutingRules:WRITE,%Ens_BusinessRules:WRITE";

/// Default rule name to be used.
Property RULE As %ZEN.Datatype.string(ZENURL = "RULE");

/// Holder for return value.
Property retValue As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
a.radioSetCaption {
	color: #404040;
	font-size: 10pt;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:8px;">

<selector id="rulePackage" context="/Packages" controlStyle="width:400px;"
label="Package"
hint="Class package name of this business rule"
title="Enter or select the full package portion of the rule name"
/>

<text id="ruleName" controlStyle="width:400px;"
label="Name"
hint="Name of this business rule"
title="Enter the simple rule name. Do not use any punctuation or space characters."
/>

<text id="ruleAlias" controlStyle="width:400px;"
label="Alias"
hint="(Optional) Alias for this business rule"
title="Not needed in new rules. This field is provided for backward compatibility with older rule names that use _ (underscore) or space characters. Do not use ;,:|!*-$'&quot;&lt;&gt; or &amp; characters."
/>

<textarea id="ruleDescription" rows="3" controlStyle="width:400px;"
label="Description"
hint="(Optional) Description of this business rule"
title="Enter a text description of the rule"
/>

<select id="ruleType" onchange="zenPage.ruleTypeChanged();" showEmpty="false" controlStyle="width:400px;"
label="Type"
hint="Type of this business rule"
title="Please select what type of rule you want to create"
/>

<hgroup>
<text id="ruleContextClass" controlStyle="width:400px;"
label="Context Class"
hint="(Optional) Context class for this business rule"
title="Select the context class of the business process associated with this rule"
/>
<spacer width="4"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectContextClass();" title="Select new context class"/>
</hgroup>

</pane>
}

ClientMethod ruleTypeChanged() [ Language = javascript ]
{
	var ruleType = zen("ruleType").getValue();
	var assistClass = ruleType.split(":")[0];
	var contextClass = ruleType.split(":")[1];
	zen("ruleContextClass").setValue(contextClass);
	zen("ruleContextClass").setProperty("disabled",contextClass != "");
	return;
}

ClassMethod GetRuleAssistList() As %String [ ZenMethod ]
{
	set tDisplayList="",tValueList=""
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Do tRS.Execute("Ens.Rule.Assist")
	While (tRS.Next()) {
		set tClassname = tRS.GetData(1)
		set tDescription = $classmethod(tClassname,"GetDescription")
		set tContextClass = $classmethod(tClassname,"GetContextClass")
		set tIsHidden = $classmethod(tClassname,"IsHidden")
		if tIsHidden continue
		Set tDisplayList=tDisplayList_","_tDescription
		set tValueList=tValueList_","_tClassname_":"_tContextClass
	}
	Do tRS.Close()
	quit $e(tDisplayList,2,*)_"|"_$e(tValueList,2,*)
}

Method GetContextClass(pClass As %String) As %String [ ZenMethod ]
{
	quit $classmethod(pClass,"GetContextClass")
}

ClientMethod selectContextClass() [ Language = javascript ]
{
	if ( !zen("ruleContextClass").getProperty("disabled") ) {
		var parms = { 
			MODE : "classes",
			ABSTRACT : 0,
			GENERATED : "",
			SYSTEM : 0,
			PERCENT : 0,
			DATATYPE : 0,
			PRODUCT : 0
		}
		zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode),this.addPopupSuffix('contextClass'),'status,scrollbars,resizable=yes,width=800,height=600', parms);
	}
	return;
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Business Rule Wizard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Create a new Business Rule definition.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.retValue;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener();

		var pkg = zenTrim(zen('rulePackage').getValue());
		var alias = zenTrim(zen('ruleAlias').getValue());
		var name = zenTrim(zen('ruleName').getValue());

		var ruleName = (''!==pkg)? (pkg+'.'+name) : name;
		var ruleDescription = zen('ruleDescription').getValue();
		var ruleContextClass = zenTrim(zen('ruleContextClass').getValue());
		var ruleType = zen("ruleType").getValue();
		var ruleAssistClass = ruleType.split(":")[0];
		
		// test for valid alias (without ;,:|!*-$'"<> or &)
		if (alias.match(/.*[;,:\|\!\*\-\$'"<>&].*/g)) {
			alert($$$Text('Some alias characters are not valid.'));
			return false;
		}

		// test for missing package portion
		if ('' == pkg) {
			alert($$$Text('Please enter a package for this Business Rule.'));
			return false;
		}

		// test for missing name portion
		if ('' == name) {
			alert($$$Text('Please enter a name for this Business Rule.'));
			return false;
		}

		// test for alias and classname same
		if (alias == ruleName) {
			alert($$$Text('Please enter an alias and full class name which are distinct from each other. Remember the alias may be left blank.'));
			return false;
		}

		// create new class
		var msg = this.CreateRuleClass(alias,ruleName,ruleDescription,ruleAssistClass,ruleContextClass);
		if (msg != '') { 
			alert(msg);
			return false;
		}

		this.retValue = ruleName;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Try {
		Set tPkgCtrl = ..%GetComponentById("rulePackage")
		Set tNameCtrl = ..%GetComponentById("ruleName")

		Set tPkgCtrl.value = ""
		Try {
			if ..RULE '= "" {
				Set tPkgCtrl.value = $p(..RULE,".",1,$l(..RULE,".")-1)
				Set tNameCtrl.value = $p(..RULE,".",$l(..RULE,"."))
			} else {
				Set tPkgCtrl.value = $G(^EnsPortal.Settings($UserName,"LastPackage"))
			}
			Set cmb = ..%GetComponentById("ruleType")
			Set array = ..GetRuleAssistList()
			Set cmb.displayList = $P(array,"|",1)
			Set cmb.valueList = $P(array,"|",2)
			#; Default to General Business Rule
			Set cmb.value = "Ens.Rule.GeneralBusinessRuleAssist:"
		}
		Catch(ex) {
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given name is valid.
ClassMethod IsNameValid(pName As %String) As %Boolean
{
	Quit $ZNAME(pName,4)
}

/// Test if the given name is unique
ClassMethod IsNameUnique(pName As %String, isAlias As %Boolean = 0) As %Boolean
{
	Set tFound=0
	
	// test against class names
	If ##class(%Dictionary.ClassDefinition).%ExistsId(pName) {
		If isAlias {
			Set tFound = ##class(%Dictionary.XDataDefinition).IDKEYExists(pName,"RuleDefinition")
		} Else {
			Set tFound=1
		}
	}
	
	// test against alias names
	// don't check per Mo Cheng; this will be checked correctly at compile time
	
	Quit 'tFound
}

/// Create a new BP class. Return "" if ok otherwise an error message.
ClassMethod CreateRuleClass(pAlias As %String, pClassName As %String, pDescription As %String = "", pAssistClass As %String = "", pContextClass As %String = "") As %String [ ZenMethod ]
{
	// While we are on the server, do the validation checks for which we need the server
	If ('..IsNameValid(pClassName)) {
		Quit $$$Text("Name or Package is not valid for this Business Rule.")
	}
	If ('..IsNameUnique(pClassName)) {
		Quit $$$Text("Class name is not unique; choose another class name.")
	}
	If ((pAlias '="" ) && ('..IsNameUnique(pAlias, 1))) {
			Quit $$$Text("Alias name already in use as a class name; choose another alias.  Remember alias is not required.")
	}
	If $D(^Ens.Rule("alias",pClassName),classname2) {
		Quit $$$FormatText($$$Text("Class name already in use as an alias for class %1; choose another class name."),classname2)
	}
	If (pContextClass'="" && '..IsNameValid(pContextClass)) {
		Quit $$$Text("Context class name is not valid.")
	}
	
	// Now create the rule class
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tPkg = $P(pClassName,".",1,$L(pClassName,".")-1)
		Try {
			Set:tPkg'="" ^EnsPortal.Settings($UserName,"LastPackage") = tPkg
		}
		Catch(ex) {
		}
		Set tClassDefinition = ##class(Ens.Rule.Model.ruleDefinition).%New()
		Set:pAlias'="" tClassDefinition.alias = pAlias
		Set tClassDefinition.assistClass = pAssistClass
		Set tClassDefinition.context = pContextClass
		Set tClassDefinition.description = pDescription

		Set tRuleSet = ##class(Ens.Rule.Model.ruleSet).%New()
		Do tClassDefinition.ruleSets.Insert(tRuleSet)
		
		Set tSC = tClassDefinition.SaveAs(pClassName)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'contextClass':
			if ( value.substr(value.length-4,4)==".cls" ) { value = value.substr(0,value.length-4); }
			zen("ruleContextClass").setValue(value);
			break;
		default:
			alert(popupName);
			break;
	}
}

}
