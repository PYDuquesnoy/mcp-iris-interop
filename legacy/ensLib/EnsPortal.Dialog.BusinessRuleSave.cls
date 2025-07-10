/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a Business Rule.
Class EnsPortal.Dialog.BusinessRuleSave Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// User needs WRITE permissions on one of the following resources to view this page:
/// %Ens_Code, %Ens_Rules, %Ens_RoutingRules or %Ens_BusinessRules
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_Rules:WRITE,%Ens_RoutingRules:WRITE,%Ens_BusinessRules:WRITE,";

/// (full) rule name.
Property ruleName As %ZEN.Datatype.string(ZENURL = "RULE");

Property aliasName As %ZEN.Datatype.string(ZENURL = "ALIAS");

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="rulePackage" label="Package" hint="Class package containing this Business Rule" size="50" context="/Packages"/>
<text id="ruleName" label="Name" hint="Name of this Business Rule" size="50"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Save Business Rule")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Save this Business Rule definition.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.ruleName;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener();

		var pkg = zen('rulePackage').getValue();
		var name = zen('ruleName').getValue();

		var ruleName = (''!==pkg)? (pkg+'.'+name) : name;

		// test for missing name
		if ('' == zenTrim(ruleName)) {
			alert($$$Text('Please enter a name for this Business Rule.'));
			return false;
		}

		// test for valid name
		if (!zenPage.IsNameValid(ruleName)) {
			alert($$$Text('Name or Package is not valid for this Business Rule.'));
			return false;
		}

		/* Test for conflict with existing alias
		This check is performed here because doing so earlier could prevent users 
		from saving as existing Business Rule with the given alias and doing so 
		later would make Rule Editor attempt to load a bad Business Rule */
		var collision = zenPage.IsAliasOkay(ruleName, this.aliasName);
		if (collision != "") {
			alert($$$FormatText($$$Text('Alias collision in Business Rule. Please eliminate the following collision before saving: \n\n %1'), collision));
			return false;
		}

		// test for overwrite
		if (!zenPage.IsNameUnique(ruleName)) {
			if (zenPage.IsNameReadOnly(ruleName)) {
				alert($$$FormatText($$$Text('Your source control framework has marked the class %1 as read only.  Please select a different Name and Package combination before saving.'),ruleName));
				if (this.ruleName == ruleName) {
					// If this document was found to be readOnly, gray out buttons to indicate this
					main.zenPage.grayOutButtons();
				}
				return false; 
			}
			if (zenPage.IsRuleClass(ruleName)) {
				var overwrite = $$$FormatText($$$Text('Name and Package combination is not unique. Saving will overwrite the existing Business Rule %1. Continue?'),ruleName);
			}
			else {
				var overwrite = $$$FormatText($$$Text('Name and Package combination is not unique. Saving will overwrite the existing class %1. Continue?'),ruleName);
			}
			if (!confirm(overwrite)) { return false;}
		}

		// update main page
		main.zenPage.RULE = ruleName;
		main.zenPage.renamed = (this.ruleName != ruleName);
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

		// split name
		Set tPkg = $P(..ruleName,".",1,$L(..ruleName,".")-1)
		Set tName = $P(..ruleName,".",$L(..ruleName,"."))
		Set tPkgCtrl.value = tPkg
		Set tNameCtrl.value = tName
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given business rule name is valid.
ClassMethod IsNameValid(pName As %String) As %Boolean [ ZenMethod ]
{
	Quit $ZNAME(pName,4)
}

/// Test if the alias conflicts with that of another Business Rule
ClassMethod IsAliasOkay(pName As %String, pAlias) As %String [ ZenMethod ]
{
	Set msg = ""
	Set tSC = ##class(Ens.Projection.Rule).ValidateAlias(pName,pAlias)
	If $$$ISERR(tSC) {
		Set msg = $System.Status.GetErrorText(tSC)
	} Else {
		If pAlias '="" && ($d(^Ens.Rule("class",pAlias)) || (pName=pAlias)) {
			Set msg = $$$Text("Alias name already in use as a class name; choose another alias.  Remember alias is not required.")
		}
		If $d(^Ens.Rule("alias",pName),classname2) {
			Set msg = $$$FormatText($$$Text("Class name already in use as an alias for class %1; choose another class name."),classname2)
		}
	}
	Quit msg
}

/// Test if the given name is unique.
ClassMethod IsNameUnique(pName As %String) As %Boolean [ ZenMethod ]
{
	// test against class names
	Quit '##class(%Dictionary.ClassDefinition).%ExistsId(pName)
}

ClassMethod IsNameReadOnly(pName As %String) As %Boolean [ ZenMethod ]
{
	Set tName = $$$NormalizeClassname(pName)_".CLS"
	Quit ##class(%CSP.Portal.SourceControl.Base).IsSourceControlReadOnly(tName)
}

/// Test if class name is that of an existing business rule
ClassMethod IsRuleClass(pName As %String) As %Boolean [ ZenMethod ]
{
	Quit ##class(%Dictionary.XDataDefinition).IDKEYExists(pName,"RuleDefinition")
}

}
