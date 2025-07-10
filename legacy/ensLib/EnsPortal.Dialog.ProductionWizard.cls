/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Create a new production and add components to it.
Class EnsPortal.Dialog.ProductionWizard Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:WRITE";

Parameter PAGENAME = "Create Production";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css";

/// Holder for return value.
Property retValue As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<spacer height="20" />
<hgroup>
<spacer width="20" />
<vgroup enclosingClass="wizardBox" >
	<form name="productionForm" id="productionForm">
	  <spacer height="10" />
		<vgroup labelPosition="left" id="groupForm">
		<spacer height="10" />
		<selector name="pkgName" id="pkgName" label="Package" hidden="false" 
			enclosingStyle="padding-bottom:4px;" size="47" labelClass="labelRequired" required="true" 
			title="Choose or enter a package name."
			  multiSelect="false" context="Ens.ContextSearch/ClassPackages" /> 
		<spacer height="10" />
		<text label="Production Name" name="txtProduction" id="txtProduction" labelClass="labelRequired" value="NewProduction" size="50"
			title="Enter a new production name in this field. Avoid using an existing name. Do not use the characters ;,:|!*-_ or $ in the name." />
		<spacer height="10" />
		<textarea label="Production Description" name="txtDescription" id="txtDescription" labelClass="labelNormal" value="" cols="39"
			title="Enter a description of the production in this field. The maximum length is 500 characters."/>
		<spacer height="3" />
		<label label="Production Type" labelClass="labelRequired" id="lblProdType"
			title="Create a generic production with an empty initial configuration, or an HL7 message routing production. The HL7 production provides some basic items in its initial configuration." />
		<!-- the default selection is Generic -->
		<radioButton name="radType" id="radGeneric" captionClass="labelNormal" caption="Generic - Create a generic production that can be further configured" 
			value="Generic" optionValue="Generic" /> 
		<radioButton name="radType" id="radHL7" captionClass="labelNormal" caption="HL7 Messaging - Create an HL7 message routing production" 
			optionValue="HL7" /> 
		<spacer height="10" />
	</vgroup>
</form>
</vgroup>
<spacer width="20" />
<vgroup valign="top">
<spacer height="40" />
<label id="helpSubject" enclosingClass="labelComment" label="Use this form to create a new Production." />
<spacer height="10" />
<label id="helpHover" enclosingClass="labelComment" label="For help with any field in this form, hover the cursor over the field name." />
<spacer height="10" />
<label id="helpRequired" enclosingClass="labelComment" label="* Indicates a required field. You may configure other settings later." hidden="true" />
</vgroup>
</hgroup>
</pane>
}

Method %OnGetJSResources(ByRef pResources As %String) As %Status [ Private ]
{
	Set pResources("msgHostErrorsStart") = $$$TextJS("Errors:")
	Set pResources("msgHostErrorsEnd") = $$$TextJS("NOTE: Because there were errors, your changes have not been saved.")
	Set pResources("msgHostFixSave") = $$$TextJS("To save your work, click OK in this alert box, correct the reported problems, and then click OK in the Wizard dialog.")
	Set pResources("msgProdExists") = $$$TextJS("A production of this name already exists in this package.")
	Set pResources("msgProdCreatePackage") = $$$TextJS("Please do not use the characters ;,:|!*-_ or $ in the package name.")
	Set pResources("msgProdCreatePackageEmpty") = $$$TextJS("Please enter or choose a package name.")
	Set pResources("msgProdCreateName") = $$$TextJS("Please do not use the characters ;,:|!*-_ or $ in the production name.")
	Set pResources("msgProdCreateNameEmpty") = $$$TextJS("Please enter a new production name.")
	Set pResources("msgProdCreateDescLong") = $$$TextJS("Please keep the description length under 500 characters.")
	Quit $$$OK
}

ClientMethod validateAll() [ Language = javascript ]
{
	var ok = true;
	var msg = zenText('msgHostErrorsStart') + '\n';

	// get package and production names
	var pkg = zenTrim(zen('pkgName').getValue());
	var prod = zenTrim(zen('txtProduction').getValue());

	// don't create duplicate productions
	var nam = pkg + '.' + prod;
	if (zenPage.ProductionAlreadyExists(nam) == 1) {
		msg += ('  ' + zenText('msgProdExists') + '\n');
		ok = false;
	}
	else {
		var len = nam.length;
		if (len > 128) {
			msg += '  ' + $$$Text("The proposed package and production name, joined together, are longer than the limit of 128 characters.") + '\n';
			ok = false;
		}
	}
	// check for and report other naming issues
	pkg = pkg.replace(/^\s+|\s+$/g, "");	
	pkg = pkg.replace(/^\t+|\t+$/g, "");
	if (pkg.match(/[;,:|!*$_-]/)) {
		msg += '  ' + zenText('msgProdCreatePackage') + '\n';
		ok = false;
	}
	else {
		var len = pkg.length;
		if (len == 0) {
			msg += '  ' + zenText('msgProdCreatePackageEmpty') + '\n';
			ok = false;
		}
	}
	if (prod.match(/[;,:|!*$_-]/)) {
		msg += '  ' + zenText('msgProdCreateName') + '\n';
		ok = false;
	}
	else {
		var len = prod.length;
		if (len == 0) {
			msg += '  ' + zenText('msgProdCreateNameEmpty') + '\n';
			ok = false;
		}
	}
	var descCtrl = zen('txtDescription');
	var desc = descCtrl.getValue();
	if (desc.length > 500) {
		msg += '  ' + zenText('msgProdCreateDescLong') + '\n';
		ok = false;
	}

	if (ok == false) {
		msg += ('\n' + zenText('msgHostErrorsEnd') + ' ' + zenText('msgHostFixSave') + '\n');
		alert(msg);
	}
	return ok;
}

/// This method returns a value that JavaScript can understand as 1 (true) or 0 (false). /* TODO */
ClassMethod ProductionAlreadyExists(prodCls As %String) As %Boolean [ ZenMethod ]
{
	Set found = 0 ; No production of this name was found in the package
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Do tRS.Execute("Ens.Production") 
	If (tRS) { ; There is data 
		While ('found & tRS.Next()) { 
			If (prodCls = tRS.Data("Name")) { ; we found it
				Set found = 1 
			}
		}
	}
	Quit found ; Return the result as 1 (true) or 0 (false)
}

/// This method is invoked when the user completes the Wizard pressing "OK".
/// Returns a null string if it succeeds, or an error message otherwise.
ClassMethod OnWizardCompletion(pPackage As %String, pProdName As %String, pType As %String, pDescription As %String) As %String [ ZenMethod ]
{
	Set tmsg = ""
		Do {
			Set tProdClass = pPackage _ "." _ pProdName

			If ('$ZNAME(tProdClass,4)) {
				Set tmsg = $$$Text("Invalid Production package or name.")
				Quit
			}

			// create empty production class
			Set tClsDef = ##class(%Dictionary.ClassDefinition).%New()
			Set tClsDef.Name = tProdClass
			Set tClsDef.Super = "Ens.Production"
			Set tClsDef.ClassVersion = 25

			Set tXData = ##class(%Dictionary.XDataDefinition).%New()
			Set tXData.Name = "ProductionDefinition"
			Do tXData.Data.WriteLine("<Production Name="""_tProdClass_"""/>")
			Do tClsDef.XDatas.Insert(tXData)

			Set tSC = tClsDef.%Save()
			Set tClsDef = ""
			Set tXData = ""
			If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC) Quit

			// now compile the class
			Set tSC = $System.OBJ.Compile(tProdClass,"k-d")
			If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC) Quit
			// fill in production:
			Set tProduction = ##class(Ens.Config.Production).%OpenId(tProdClass)
			If '$IsObject(tProduction) {
				Set tmsg = "Unable to open new production: " _ tProdClass
				Quit
			}
			Set tProduction.Name = tProdClass
			Set tProduction.Description = pDescription
			Set tProduction.ActorPoolSize = 2

			// create contents of production
			If (pType = "HL7") {
				Set tSC = ..ConfigureHL7Production(pProdName,tProduction,pPackage)
				If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC) Quit
			}

			// save production (and item), update production class and account for Source Control
			Set tSC = ##class(EnsPortal.Template.prodConfigSCPage).CallProductionUpdateAndSaveToClass(tProduction,"","SaveProduction")
			If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC) Quit
		} While(0)

	Quit tmsg
}

ClassMethod ConfigureHL7Production(pName As %String, pProduction As Ens.Config.Production, pPackage As %String) As %Status
{
	Set tSC = $$$OK
	Do {
		// router
		Set tItem = ##class(Ens.Config.Item).%New()
		Set tItem.Name = "MsgRouter"
		Set tItem.Comment = $$$Text("This handles message routing logic.")
		Set tItem.ClassName = "EnsLib.HL7.MsgRouter.RoutingEngine"
		Set tItem.PoolSize = 1

		// validation
		Set tSetting = ##class(Ens.Config.Setting).%New()
		Set tSetting.Target = "Host"
		Set tSetting.Name = "Validation"
		Set tSetting.Value = "" // by default, have no validation
		Do tItem.Settings.Insert(tSetting)

		// rule name
		Set tMsgRuleName = pName_".RoutingRule"
		Set classNameMsg = ##class(Ens.Rule.Upgrade).ConvertRulenameToClassname(pPackage,tMsgRuleName)
		Set tSetting = ##class(Ens.Config.Setting).%New()
		Set tSetting.Target = "Host"
		Set tSetting.Name = "BusinessRuleName"
		Set tSetting.Value = classNameMsg
		Do tItem.Settings.Insert(tSetting)

		// bad message handler setting for router item
		Set tSetting = ##class(Ens.Config.Setting).%New()
		Set tSetting.Target = "Host"
		Set tSetting.Name = "BadMessageHandler"
		Set tSetting.Value = "BadMessageHandler" ; point the BadMessageHandler SETTINGS property to the BadMessageHandler config item about to be created
		Do tItem.Settings.Insert(tSetting)

		Do pProduction.Items.Insert(tItem)

		// bad message handler itself
		Set tItem = ##class(Ens.Config.Item).%New()
		Set tItem.Name = "BadMessageHandler"
		Set tItem.Comment = "Bad messages are sent to this operation."
		Set tItem.ClassName = "EnsLib.HL7.Operation.FileOperation"
		Set tItem.Enabled = 0
		Do pProduction.Items.Insert(tItem)

		// alert handler
		Set tItem = ##class(Ens.Config.Item).%New()
		Set tItem.Name = "Ens.Alert"
		Set tItem.Comment = "This handles Alert routing logic."
		Set tItem.ClassName = "EnsLib.MsgRouter.RoutingEngine"

		Set tAlertRule = pName_".AlertRule"
		Set classNameAlert = ##class(Ens.Rule.Upgrade).ConvertRulenameToClassname(pPackage,tAlertRule)
		Set tSetting = ##class(Ens.Config.Setting).%New()
		Set tSetting.Target = "Host"
		Set tSetting.Name = "BusinessRuleName"
		Set tSetting.Value = classNameAlert
		Do tItem.Settings.Insert(tSetting)

		Do pProduction.Items.Insert(tItem)

		// email alert
		Set tItem = ##class(Ens.Config.Item).%New()
		Set tItem.Name = "EMailAlert"
		Set tItem.Comment = "This sends alerts via e-mail."
		Set tItem.ClassName = "EnsLib.EMail.AlertOperation"
		Set tItem.Enabled = 0
		Do pProduction.Items.Insert(tItem)

		// pager alert
		Set tItem = ##class(Ens.Config.Item).%New()
		Set tItem.Name = "PagerAlert"
		Set tItem.Comment = "This sends alerts to a pager via e-mail."
		Set tItem.ClassName = "EnsLib.EMail.AlertOperation"
		Set tItem.Enabled = 0
		Do pProduction.Items.Insert(tItem)

		// sample input
		Set tItem = ##class(Ens.Config.Item).%New()
		Set tItem.Name = "HL7FileService"
		Set tItem.ClassName = "EnsLib.HL7.Service.FileService"
		Set tItem.Comment = "This is a default HL7 File Service."
		Set tItem.Enabled = 0

		Set tSetting = ##class(Ens.Config.Setting).%New()
		Set tSetting.Target = "Host"
		Set tSetting.Name = "TargetConfigNames"
		Set tSetting.Value = "MsgRouter"
		Do tItem.Settings.Insert(tSetting)

		Do pProduction.Items.Insert(tItem)

		// sample output
		Set tItem = ##class(Ens.Config.Item).%New()
		Set tItem.Name = "HL7FileOperation"
		Set tItem.ClassName = "EnsLib.HL7.Operation.FileOperation"
		Set tItem.Comment = "This is a default HL7 File Operation."
		Set tItem.Enabled = 0

		Do pProduction.Items.Insert(tItem)

		// create new routing rules

		// create a new rule only if a rule by this name does not already exist
		If (##class(EnsPortal.Dialog.ProductionAddHost).RuleAlreadyExists(classNameMsg)) {
			// this is acceptable; we will use the old rule
		}
		Else {
			// msg routing rule
			Set ruleDefinition = ##class(Ens.Rule.Model.ruleDefinition).%New()
			Set ruleDefinition.assistClass = "EnsLib.HL7.MsgRouter.RuleAssist"
			Set ruleDefinition.context = ##class(EnsLib.HL7.MsgRouter.RuleAssist).GetContextClass()
			Set ruleDefinition.production = pPackage _ "." _ pName
			Set ruleDefinition.isRoutingRule = 1
			;
			set ruleSet = ##class(Ens.Rule.Model.ruleSet).%New()
			do ruleDefinition.ruleSets.Insert(ruleSet)
			;
			set rule = ##class(Ens.Rule.Model.rule).%New()
			do ruleSet.actions.Insert(rule)
			;
			set constraint = ##class(Ens.Rule.Model.constraint).%New()
			set constraint.name = "source"
			set constraint.value = "HL7FileService"
			do rule.constraints.Insert(constraint)
			;
			// we don't set a message class constraint for HL7
			;
			// default rule sends message to output
			set when = ##class(Ens.Rule.Model.when).%New()
			set when.condition=1
			do rule.whens.Insert(when)
			;
			set action = ##class(Ens.Rule.Model.send).%New()
			set action.target = "HL7FileOperation"
			do when.actions.Insert(action)
			;
			Set tSC = ruleDefinition.SaveAs(classNameMsg)
			If $$$ISERR(tSC) Quit
			Set tSC = $system.OBJ.Compile(classNameMsg,"k-d")
			If $$$ISERR(tSC) Quit
		}

		// create a new rule only if a rule by this name does not already exist
		If (##class(EnsPortal.Dialog.ProductionAddHost).RuleAlreadyExists(classNameAlert)) {
			// this is acceptable; we will use the old rule
		}
		Else {
			// alert routing rule
			Set ruleDefinition = ##class(Ens.Rule.Model.ruleDefinition).%New()
			Set ruleDefinition.assistClass = "EnsLib.MsgRouter.RuleAssist"
			Set ruleDefinition.context = ##class(EnsLib.MsgRouter.RuleAssist).GetContextClass()
			Set ruleDefinition.production = pPackage _ "." _ pName
			Set ruleDefinition.isRoutingRule = 1
			;
			set ruleSet = ##class(Ens.Rule.Model.ruleSet).%New()
			do ruleDefinition.ruleSets.Insert(ruleSet)
			;
			set rule = ##class(Ens.Rule.Model.rule).%New()
			do ruleSet.actions.Insert(rule)
			;
			Set tSC = ruleDefinition.SaveAs(classNameAlert)
			If $$$ISERR(tSC) Quit
			Set tSC = $system.OBJ.Compile(classNameAlert,"k-d")
			If $$$ISERR(tSC) Quit
		}
	} While(0)

	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production Wizard","Ensemble")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Create a new Production definition.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return encodeURIComponent(this.retValue);
}

/// This callback is called when the user presses the OK button.
/// If this returns false, then the action is canceled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var isValid = zenPage.validateAll();
		if (isValid) {
			var pkg = zenTrim(zen('pkgName').getValue());
			var prod = zenTrim(zen('txtProduction').getValue());
			var nam = pkg + '.' + prod;
			var radHL7Button = zen('radHL7');
			if (radHL7Button) {
				var type = radHL7Button.getValue();
			} else {
				var type = "";
			}
			var desc = zen('txtDescription').getValue();
			var msg = zenPage.OnWizardCompletion(pkg, prod, type, desc)
			if (msg != '') {
				alert(msg);
				isValid = false;
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
		isValid = false;
	}

	if (isValid) {
		this.retValue = nam;
		return true;
	}
	else {
		this.retValue = '';
		return false;
	}
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super() 
	If $$$ISERR(tSC) Quit tSC
	If '##class(%Library.InteroperabilityMgr).IsPackageInstalled("HL7") {
		Set sel = ..%GetComponentById("groupForm")
		For tChild=1:1:sel.children.Count(){
			If sel.children.GetAt(tChild).id = "radHL7" {Do sel.children.RemoveAt(tChild)  Quit}
		}
		Set sel = ..%GetComponentById("lblProdType")
		Set sel.title=$$$TextHTML("Create a generic production with an empty initial configuration.")
	}
	Quit $$$OK
}

}
