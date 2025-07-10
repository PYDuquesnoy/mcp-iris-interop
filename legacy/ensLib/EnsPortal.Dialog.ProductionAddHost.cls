/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Add a new component to a production
Class EnsPortal.Dialog.ProductionAddHost Extends EnsPortal.Dialog.standardDialog [ Abstract, System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to view this page and its subclasses.
Parameter RESOURCE = "%Ens_ProductionConfig:WRITE";

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css";

/// Name of production that is displayed.
Property ProductionName As %ZEN.Datatype.string(ZENURL = "PRODUCTION");

Property LinkHelp As %String [ Calculated ];

/// Holder for return value.
Property retValue As %ZEN.Datatype.string;

/// HTML info of possible default settings
Property defaultSettingsHTML As %ZEN.Datatype.string;

Method LinkHelpGet() As %String [ CodeMode = expression, Internal ]
{
##class(%CSP.Page).Link("/csp/docbook/DocBook.UI.Page.cls",,1)
}

Method %OnGetJSResources(ByRef pResources As %String) As %Status [ Private ]
{
	Set pResources("msgHostErrorsStart") = $$$TextJS("Errors:")
	Set pResources("msgHostErrorsEnd") = $$$TextJS("NOTE: Because there were errors, your changes have not been saved.")
	Set pResources("msgHostFixSave") = $$$TextJS("To save your work, click OK in this alert box, correct the reported problems, and then click OK in the Wizard dialog.")
	Set pResources("msgHostClass") = $$$TextJS("Please select a Class Name.")
	Set pResources("msgHostRule") = $$$TextJS("Please enter a Rule Name or check Auto-Create.")
	Set pResources("msgHostInput") = $$$TextJS("Please choose an Input Type.")
	Set pResources("msgHostOutput") = $$$TextJS("Please choose an Output Type.")
	Set pResources("msgHostName") = $$$TextJS("Please enter a Name for this item.")
	Set pResources("msgHostStarter") = $$$TextJS("Please modify the Name for this item.")
	Set pResources("msgHostBadChar") = $$$TextJS("Please do not use the characters ;,:|!*-$ or [ in the host name and do not start the name with _.")
	Set pResources("msgRuleBadChar") = $$$TextJS("Please do not use the characters ;,:|!*-$ or [ in the rule name.")
	Set pResources("msgHostLong") = $$$TextJS("Please keep the Name length under 100 characters.")
	Set pResources("msgTargetName") = $$$TextJS("If you do not want to choose an existing item as the Target, select Create or None.")
	Set pResources("msgHostDescLong") = $$$TextJS("Please keep the Comment length under 500 characters.")
	Quit $$$OK
}

/// Do validation of all fields on the form.
ClientMethod validateAll(host, type) [ Language = javascript ]
{
	var ok = true;
	var msg = zenText('msgHostErrorsStart') + '\n';

	var formName = host + type;

	// It is difficult to distinguish configuration items
	// with the same name and class, so don't create duplicates
	var prod = zenPage.ProductionName;
	var name = zen(formName + 'Name').getValue();
	if (name !== name.replace(/^\s+|\s+$/g,'')) {
		msg += ('  ' + $$$FormatText($$$Text("Item name '%1' has leading or trailing spaces."),name) + '\n');
		ok = false;
	}
	var cls = zen(formName + 'ClassName').getValue();
	var enab = zen(formName + 'Enabled').getValue();
	var commentOrClass = zen(formName + 'Comment').getValue();
	if (commentOrClass == '') commentOrClass = cls;
	if (commentOrClass.length > 500) {
		msg += ('  ' + zenText('msgHostDescLong') + '\n');
		ok = false;
	}
	var nameOrCls = (name == '' ? cls : name);
	var ret = zenPage.ItemAlreadyExists(prod,nameOrCls,commentOrClass,host,enab);
	var exists = ret.split(":");
	if (exists[0] == "Duplicate") {
		msg += ('  ' + $$$FormatText($$$Text("An item already exists with the name '%1'."),nameOrCls) + '\n');
		ok = false;
	}
	if (exists[1] == "Enabled") {
		msg += ('  ' + $$$FormatText($$$Text("You cannot enable this new host without disabling the other item with name '%1' that is already enabled."),nameOrCls,commentOrClass) + '\n');
		ok = false;
	}
	if (nameOrCls.match(/^[^;,:|[-_][^;,:|[]*[^;,:|[!$-]$|^[^*;,:|[!$-]$/) == null) {
		msg += ('  ' + zenText('msgHostBadChar') + '\n');
		ok = false;
	}
	if (nameOrCls.length > 128) {
		msg += ('  ' + zenText('msgHostLong') + '\n');
		ok = false;
	}
	switch (formName) {
		case 'ServiceMETRIC':
		case 'ServiceOTHER':
		case 'ProcessCOMPONENT':
		case 'OperationWORKFLOW':
		case 'OperationOTHER':
			if (cls == '') {
				msg += ('  ' + zenText('msgHostClass') + '\n');
				ok = false;
			}
			break;
		case 'ProcessOTHER':
			if (zenPage.isRouter) { // handle it like ProcessHL7 or ProcessX12
				var rule = zen(formName + 'RuleName').getValue(); // test rule name
				if (rule == '') {
					if (!zenPage.isChecked) {
						msg += ('  ' + zenText('msgHostRule') + '\n');
						ok = false;
					}
				}
				else {
					if (rule.length > 128) {
						msg += ('  ' + zenText('msgHostLong') + '\n');
						ok = false;
					}
					if (rule.match(/^[^*;,:|!*$'"<>&-]+$/) == null) {
						msg += ('  ' + zenText('msgRuleBadChar') + '\n');
						ok = false;
					}
				}
			} else { // Handle it like ServiceOTHER or OperationOTHER
				if (cls == '') {
					msg += ('  ' + zenText('msgHostClass') + '\n');
					ok = false;
				}
			}
			break;
		case 'ServiceX12':
		case 'ServiceHL7':
			if (cls == '') {
				msg += ('  ' + zenText('msgHostInput') + '\n');
				ok = false;
			}
			if (name == '') {
				msg += ('  ' + zenText('msgHostName') + '\n');
				ok = false;
			}
			if (name.charAt(name.length - 1) == '_') {
				msg += ('  ' + zenText('msgHostStarter') + '\n');
				ok = false;
			}
			var auto = zen(formName + 'TargetAuto').getValue();
			var targ = zen(formName + 'TargetName').getValue();
			if ((auto == 'Choose') && (targ == '')) {
				msg += ('  ' + zenText('msgTargetName') + '\n');
				ok = false;
			}
			break;
		case 'OperationX12':
		case 'OperationHL7':
			if (cls == '') {
				msg += ('  ' + zenText('msgHostOutput') + '\n');
				ok = false;
			}
			if (name == '') {
				msg += ('  ' + zenText('msgHostName') + '\n');
				ok = false;
			}
			if (name.charAt(name.length - 1) == '_') {
				msg += ('  ' + zenText('msgHostStarter') + '\n');
				ok = false;
			}
			break;
		case 'ProcessX12':
		case 'ProcessHL7':
			var rule = zen(formName + 'RuleName').getValue(); // test rule name
			if (rule == '') {
				if (!zenPage.isChecked) {
					msg += ('  ' + zenText('msgHostRule') + '\n');
					ok = false;
				}
			} else {
				if (rule.length > 128) {
					msg += ('  ' + zenText('msgHostLong') + '\n');
					ok = false;
				}
				if (rule.match(/^[^*;,:|!*$'"<>&-]+$/) == null) {
					msg += ('  ' + zenText('msgRuleBadChar') + '\n');
					ok = false;
				}
			}
			break;
	}
	// finish
	if (ok == false) {
		msg += ('\n' + zenText('msgHostErrorsEnd') + ' ' + zenText('msgHostFixSave') + '\n');
		alert(msg);
	}
	zenPage.retValue = ok;
	return ok;
}

/// This method returns a value that JavaScript can understand as 1 (true) or 0 (false).
ClassMethod RuleAlreadyExists(pClassName As %String) As %Boolean [ ZenMethod ]
{
	Set found = 0
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Do tRS.Execute("Ens.Rule.Definition")
	If (tRS) {
		While ('found && tRS.Next()) {
			If (tRS.Data("Name") = pClassName) Set found = 1
		}
	}
	Quit found
}

ClassMethod ItemAlreadyExists(production As %String, name As %String, cls As %String, busType As %String, enabled As %ZEN.Datatype.boolean = 0) As %String [ ZenMethod ]
{
	Set tFoundDuplicate = "" ; No configuration item with this name and class name was found in the package
	Set tFoundEnabled = "" ; No configuration item with this name is currently enabled
	Set tMsg = ""
	Set tBusinessTypes($$$eHostTypeService) = "Service"
	Set tBusinessTypes($$$eHostTypeProcess) = "Process"
	Set tBusinessTypes($$$eHostTypeOperation) = "Operation"
	Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateConfigItems")
	Do tRS.Execute(production,,0) ; Look through the entire production for this item
	If (tRS) {
		While ((tRS.Next()) && ((tFoundDuplicate="") || (tFoundEnabled=""))) {
			If (name = tRS.Data("ConfigName")) {
				If ((cls = tRS.Data("CommentOrClassName")) || (busType '= $G(tBusinessTypes(tRS.Data("BusinessType")),""))) {
					Set tFoundDuplicate = "Duplicate" ; We found an item that matches
				}
				If ((enabled) && (1 = tRS.Data("Enabled"))) {
					Set tFoundEnabled = "Enabled"
				}
			}
		}
	}
	Quit tFoundDuplicate _ ":" _ tFoundEnabled
}

/// Generic method for adding a new host
ClassMethod AddNewItem(pForm As %String, prefix As %String, production As Ens.Config.Production, Output item As Ens.Config.Item, poolSize As %Integer = "") As %Status
{
	Try {
		// add new item to production
		Set item = ##class(Ens.Config.Item).%New()
		Set item.PoolSize = poolSize ; set before ClassName
		Set item.Name = %page.%GetValueById(prefix_"Name")
		Set item.ClassName = %page.%GetValueById(prefix_"ClassName")
		Set:item.Name="" item.Name = item.ClassName
		Set item.Category = %page.%GetValueById(prefix_"Category")
		Set item.Comment = %page.%GetValueById(prefix_"Comment")
		Set item.Enabled = %page.%GetValueById(prefix_"Enabled")
		Set tSC = production.Items.Insert(item)
		If $$$ISOK(tSC) Set tSC = $$$AuditModifyProductionConfig(production.Name,item.Name,$$$Text("Item added to production using Management Portal"))
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add new routing rule to complete a new HL7 or X12 service that has created its own "dedicated" router.
Method SubmitRoutingRule(protocol As %String, serviceName As %String = "", schema As %String = "", itemRouter As Ens.Config.Item, ruleAlias As %String, ruleClass As %String, validation As %String = "", novalidation As %Boolean = 0) As %Status
{
	Set tSC = $$$OK

	If $IsObject($G(itemRouter)) {
		// validation
		Do ..ItemSettingsInsert(.itemRouter,"Validation","Host",validation,novalidation)

		// rule name
		Do ..ItemSettingsInsert(.itemRouter,"BusinessRuleName","Host",ruleClass) // connect router to routing rule

		// create a new rule only if a rule by this name does not already exist
		If (..RuleAlreadyExists(ruleClass)) Quit $$$OK

		// add rule
		Set ruleDefinition = ##class(Ens.Rule.Model.ruleDefinition).%New()
		Set ruleDefinition.production = ..ProductionName
		Set ruleDefinition.isRoutingRule = 1

		If (protocol = "HL7") {
			Set ruleDefinition.assistClass = "EnsLib.HL7.MsgRouter.RuleAssist"
			Set ruleDefinition.context = ##class(EnsLib.HL7.MsgRouter.RuleAssist).GetContextClass()
		}
		ElseIf (protocol = "X12") {
			Set ruleDefinition.assistClass = "EnsLib.MsgRouter.VDocRuleAssist"
			Set ruleDefinition.context = ##class(EnsLib.MsgRouter.VDocRuleAssist).GetContextClass()
		}
		ElseIf (protocol = "OTHER") {
			Set rs=##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
			Do rs.Execute("Ens.Rule.Assist")
			Set found=0
			Set tAssistName=""
			Set tContext=""
			For {
				Quit:found
				Quit:'rs.Next()
				Set tAssistName=rs.Data("Name")
				Continue:tAssistName["Compatible" // those classes are only for legacy rules
				Continue:'##class(%Dictionary.CompiledClass).%ExistsId(tAssistName)
				Set tContext=$classmethod(tAssistName,"GetContextClass")
				If tContext=itemRouter.ClassName { Set found=1 }
			}
			Set ruleDefinition.assistClass = tAssistName
			Set ruleDefinition.context = tContext
		}
		Else { // unknown 'protocol'
		}

		If (""'=ruleAlias) {
			Set ruleDefinition.alias = ruleAlias
		}

		set ruleSet = ##class(Ens.Rule.Model.ruleSet).%New()
		do ruleDefinition.ruleSets.Insert(ruleSet)

		set rule = ##class(Ens.Rule.Model.rule).%New()
		do ruleSet.actions.Insert(rule)

		If (protocol = "HL7" || protocol = "X12") {
			If (""'=serviceName) {
				set constraint = ##class(Ens.Rule.Model.constraint).%New()
				set constraint.name = "source"
				set constraint.value = serviceName
				do rule.constraints.Insert(constraint)
			}
			If (""'=schema) {
				set constraint = ##class(Ens.Rule.Model.constraint).%New()
				set constraint.name = "docCategory"
				set constraint.value = schema
				do rule.constraints.Insert(constraint)
			}
		}

		If (protocol = "X12") {
			set constraint = ##class(Ens.Rule.Model.constraint).%New()
			set constraint.name = "msgClass"
			set constraint.value = "EnsLib.EDI.X12.Document"
			do rule.constraints.Insert(constraint)
		}

		Set tSC = ruleDefinition.SaveAs(ruleClass)
		Quit:$$$ISERR(tSC) tSC
		Set tSC = $system.OBJ.Compile(ruleClass,"k-d")
	}
	Else {
		Set tSC = $$$EnsError($$$EnsErrGeneral,"Unable to add routing rule to the router for this service.")
	}
	Quit tSC
}

/// This method checks to see if the supplied field value is a simple name or a full class name.
/// If a simple name this method prepends the package for the identified production to the simple name.
/// <p>
/// This method also determines if the field value supplied in the wizard is going to have to be made into an alias
/// and if so, returns the corresponding alias name and class name that it is going to use when it creates the rule.
/// This gives the user the chance to accept/decline creating a rule with that alias and/or class name.
/// <p>
/// The return value of this method is a string that provides a class name and/or alias name,
/// in one of the following comma-separated formats:
/// <p>
/// First position: "+" if we needed to prepend a package name to a simple rule name but it was otherwise fine, blank if we did not prepend anything<br/>
/// Second position: &lt;aliasName&gt; if a suitable class name had to be derived from an alias name, and this is the alias<br/>
/// Third position: &lt;className&gt; giving the class name (in any case)<br/>
/// Fourth position: "-" if a rule with this class name already exists, otherwise blank<br/>
/// 
ClassMethod DeriveRuleNames(pProdId As %String, pFieldValue As %String, pUserRequestedPackage As %String) As %String [ ZenMethod ]
{
	Set msg = ""
	Set production = ##class(Ens.Config.Production).%OpenId(pProdId)
	If $IsObject($G(production)) {
		// find the package name
		If pUserRequestedPackage'="" {
			Set tPackage = pUserRequestedPackage
			#; Update cache
			Do ..DefaultRulePackage(pUserRequestedPackage)
		} Else {
			Set tPackage = production.Name
			Set tPackage = $P(tPackage,".",1,$L(tPackage,".")-1)
		}

		// rule name
		If ($P(pFieldValue,".")=pFieldValue)||($P(pFieldValue,".")="Ens")||($P(pFieldValue,".")="EnsLib") {
			/*	No package found in the supplied rule name
				OR
				the item name would lead to rule class name being in Read Only ENSLIB
				Prepend the production package name to the simple rule name
			*/
			Set className = ##class(EnsPortal.Component.ruleSelector).GetClassName(pFieldValue)
			Set aliasName = pFieldValue
			Set:className="" aliasName = tPackage_"."_pFieldValue
			Set:className="" className = ##class(EnsPortal.Component.ruleSelector).GetClassName(tPackage_"."_pFieldValue)
			Set:className="" className  = ##class(Ens.Rule.Upgrade).ConvertRulenameToClassname(tPackage,pFieldValue)
			If aliasName=className { // the field value was a simple name (needed to prepend a package name) but was otherwise fine as a class name
				Set msg = "+,,"_className
			}
			Else { // the field value was a simple name (needed to prepend a package name) and a suitable class name had to be derived
				Set msg = "+,"_aliasName_","_className
			}
		}
		Else { // Package found in the supplied rule name
			// Use the full rule name
			Set len = $L(pFieldValue,".")
			Set tClassPackage = $P(pFieldValue,".",1,len-1)
			Set tClassSimpleName = $P(pFieldValue,".",len)
			Set className = ##class(EnsPortal.Component.ruleSelector).GetClassName(pFieldValue)
			Set:className="" className  = ##class(Ens.Rule.Upgrade).ConvertRulenameToClassname(tClassPackage,tClassSimpleName)
			Set aliasName = pFieldValue
			If aliasName=className { // the field value was a full name and was fine as a class name (no name changes occurred)
				Set msg = ",,"_className
			}
			Else { // the field value was a full name and a suitable class name had to be derived
				Set msg = ","_aliasName_","_className
			}
		}
		If ..RuleAlreadyExists(className) {
			Set msg = msg_",-"
		}
		Else {
			Set msg = msg_","
		}
	}
	Quit msg
}

ClassMethod AddServiceSettings(pForm As %String, prefix As %String, item As Ens.Config.Item) As %Status
{
	Set clsName = %page.%GetValueById(prefix_"ClassName")

	// adapter settings
	If (clsName [ "FileService") {
		// "File Path"
		Do ..ItemSettingsInsert(.item,"FilePath","Adapter",%page.%GetValueById(prefix_"FilePath1"))
		// 	"Archive Path"
		Do ..ItemSettingsInsert(.item,"ArchivePath","Adapter",%page.%GetValueById(prefix_"Archive"))
		// 	"Filenames"
		Do ..ItemSettingsInsert(.item,"FileSpec","Adapter",%page.%GetValueById(prefix_"FileSpec1"))
	}
	ElseIf (clsName [ "FTPService") {
		// "Server Address"
		Do ..ItemSettingsInsert(.item,"FTPServer","Adapter",%page.%GetValueById(prefix_"Addr1"))
		// "Port Number"
		Do ..ItemSettingsInsert(.item,"FTPPort","Adapter",%page.%GetValueById(prefix_"Port1"))
		// "Credentials"
		Do ..ItemSettingsInsert(.item,"Credentials","Adapter",%page.%GetValueById(prefix_"Cred"))
		// "File Path"
		Do ..ItemSettingsInsert(.item,"FilePath","Adapter",%page.%GetValueById(prefix_"FilePath2"))
		// 	"Archive Path"
		Do ..ItemSettingsInsert(.item,"ArchivePath","Adapter",%page.%GetValueById(prefix_"Archive"))
		// 	"Filenames"
		Do ..ItemSettingsInsert(.item,"FileSpec","Adapter",%page.%GetValueById(prefix_"FileSpec1"))
	}
	ElseIf ((clsName [ "TCPService") || (clsName [ "HTTPService") || (clsName [ "SOAPService")) {
		Do ..ItemSettingsInsert(.item,"Port","Adapter",%page.%GetValueById(prefix_"Port1"))
	}
	Else {
		// do nothing; there are no settings of interest
	}
}

ClassMethod AddOperationSettings(pForm As %String, prefix As %String, item As Ens.Config.Item) As %Status
{
	Set clsName = %page.%GetValueById(prefix_"ClassName")

	// adapter settings
	If (clsName [ "FileOperation") {
		// "File Path"
		Do ..ItemSettingsInsert(.item,"FilePath","Adapter",%page.%GetValueById(prefix_"FilePath3"))
		// "Filenames"
		Do ..ItemSettingsInsert(.item,"Filename","Host",%page.%GetValueById(prefix_"FileSpec2"))
	}
	ElseIf (clsName [ "FTPOperation") {
		// "Server Address"
		Do ..ItemSettingsInsert(.item,"FTPServer","Adapter",%page.%GetValueById(prefix_"Addr1"))
		// "Port Number"
		Do ..ItemSettingsInsert(.item,"FTPPort","Adapter",%page.%GetValueById(prefix_"Port2"))
		// "Credentials"
		Do ..ItemSettingsInsert(.item,"Credentials","Adapter",%page.%GetValueById(prefix_"Cred"))
		// "File Path"
		Do ..ItemSettingsInsert(.item,"FilePath","Adapter",%page.%GetValueById(prefix_"FilePath4"))
		// "Filenames"
		Do ..ItemSettingsInsert(.item,"Filename","Host",%page.%GetValueById(prefix_"FileSpec2"))
	}
	ElseIf (clsName [ "TCPOperation") {
		// "IP Address"
		Do ..ItemSettingsInsert(.item,"IPAddress","Adapter",%page.%GetValueById(prefix_"Addr2"))
		// "Port Number"
		Do ..ItemSettingsInsert(.item,"Port","Adapter",%page.%GetValueById(prefix_"Port2"))
	}
	ElseIf (clsName [ "HTTPOperation") {
		// "Server Address"
		Do ..ItemSettingsInsert(.item,"HTTPServer","Adapter",%page.%GetValueById(prefix_"Addr1"))
		// "Port Number"
		Do ..ItemSettingsInsert(.item,"HTTPPort","Adapter",%page.%GetValueById(prefix_"Port2"))
		// "Credentials"
		Do ..ItemSettingsInsert(.item,"Credentials","Adapter",%page.%GetValueById(prefix_"Cred"))
		// "URL"
		Do ..ItemSettingsInsert(.item,"URL","Adapter",%page.%GetValueById(prefix_"URL"))
	}
	Else {
		// do nothing; there are no settings of interest
	}
}

/// Choose the correct adapter class and hide/show the correct fields for the selected protocol type.
/// host = Service,Operation; edi = HL7,X12; type = TCP,File,FTP,HTTP,SOAP
ClientMethod changeType(host, edi) [ Language = javascript ]
{
	zenPage.hideAll(host, edi);
	var formName = host + edi;
	var type = zen(formName + 'InOutType').getValue();

	// show the common fields for all protocol types
	zenPage.showRow(formName + 'Name');
	zenPage.showRow(formName + 'Category');
	zenPage.showRow(formName + 'Comment');
	zenPage.showRow(formName + 'Enabled');
	switch (formName) {
		case 'ServiceHL7': {
			zenPage.showRow(formName + 'TargetAuto');
			//zenPage.showRow(formName + 'TargetName'); // the only time we show this is when selected in TargetAuto
			zenPage.showRow(formName + 'SchemaCategory');
			zenPage.showRow(formName + 'DefaultableFields');
			break;
		}
		case 'ServiceX12': {
			zenPage.showRow(formName + 'TargetAuto');
			//zenPage.showRow(formName + 'TargetName'); // the only time we show this is when selected in TargetAuto
			zenPage.showRow(formName + 'DefaultableFields');
			break;
		}
		case 'OperationHL7': {
			if (type!='SOAP') {
				zenPage.showRow(formName + 'DefaultableFields');
			} else {
				zenPage.hideRow(formName + 'DefaultableFields');
			}
			break;
		}
		case 'OperationX12': {
			if (type!='SOAP') {
				zenPage.showRow(formName + 'DefaultableFields');
			} else {
				zenPage.hideRow(formName + 'DefaultableFields');
			}
			break;
		}
	}

	// show the special fields for this protocol type
	switch (host + type) {
		case 'ServiceFile': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Service.FileService');  break;
				case 'X12': zen(formName + 'ClassName').setValue('EnsLib.EDI.X12.Service.FileService');  break;
			}
			zenPage.showRow(formName + 'FilePath1Grp'); 		//	"File Path"
			zenPage.showRow(formName + 'ArchiveGrp'); 			// 	"Archive Path"
			zenPage.showRow(formName + 'FileSpec1'); 			// 	"Filenames"
			break;
		}
		case 'ServiceFTP': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Service.FTPService');  break;
				case 'X12': zen(formName + 'ClassName').setValue('EnsLib.EDI.X12.Service.FTPService');  break;
			}
			zenPage.showRow(formName + 'Addr1');				// "Server Address"
			zenPage.showRow(formName + 'Port1');				// "Port Number"
			zenPage.showRow(formName + 'Cred');					// "Credentials"
			zenPage.showRow(formName + 'FilePath2');			// "File Path"
			zenPage.showRow(formName + 'ArchiveGrp'); 			// "Archive Path"
			zenPage.showRow(formName + 'FileSpec1'); 			// 	"Filenames"
			break;
		}
		case 'ServiceTCP': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Service.TCPService');  break;
				case 'X12': zen(formName + 'ClassName').setValue('EnsLib.EDI.X12.Service.TCPService');  break;
			}
			zenPage.showRow(formName + 'Port1');				// "Port Number"
			break;
		}
		case 'ServiceHTTP': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Service.HTTPService');  break;
				case 'X12': zen(formName + 'ClassName').setValue('');  break;
			}
			zenPage.showRow(formName + 'Port1');				// "Port Number"
			break;
		}
		case 'ServiceSOAP': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Service.SOAPService');  break;
				case 'X12': zen(formName + 'ClassName').setValue('EnsLib.EDI.X12.Service.SOAPService');  break;
			}
			zenPage.showRow(formName + 'Port1');				// "Port Number"
			break;
		}
		case 'OperationFile': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Operation.FileOperation');  break;
				case 'X12': zen(formName + 'ClassName').setValue('EnsLib.EDI.X12.Operation.FileOperation');  break;
			}
			zenPage.showRow(formName + 'FilePath3Grp');			// "File Path"
			zenPage.showRow(formName + 'FileSpec2');			// "Filename"
			break;
		}
		case 'OperationFTP': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Operation.FTPOperation');  break;
				case 'X12': zen(formName + 'ClassName').setValue('EnsLib.EDI.X12.Operation.FTPOperation');  break;
			}
			zenPage.showRow(formName + 'Addr1');				// "Server Address"
			zenPage.showRow(formName + 'Port2');				// "Port Number"
			zenPage.showRow(formName + 'Cred');					// "Credentials"
			zenPage.showRow(formName + 'FilePath4');			// "File Path"
			zenPage.showRow(formName + 'FileSpec2');			// "Filename"
			break;
		}
		case 'OperationTCP': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Operation.TCPOperation');  break;
				case 'X12': zen(formName + 'ClassName').setValue('EnsLib.EDI.X12.Operation.TCPOperation');  break;
			}
			zenPage.showRow(formName + 'Addr2');				// "IP Address"
			zenPage.showRow(formName + 'Port2');				// "Port Number"
			break;
		}
		case 'OperationHTTP': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Operation.HTTPOperation');  break;
				case 'X12': zen(formName + 'ClassName').setValue('');  break;
			}
			zenPage.showRow(formName + 'Addr1');				// "Server Address"
			zenPage.showRow(formName + 'Port2');				// "Port Number"
			zenPage.showRow(formName + 'Cred');					// "Credentials"
			zenPage.showRow(formName + 'URL');					// "URL"
			break;
		}
		case 'OperationSOAP': {
			switch(edi) {
				case 'HL7': zen(formName + 'ClassName').setValue('EnsLib.HL7.Operation.SOAPOperation');  break;
				case 'X12': zen(formName + 'ClassName').setValue('EnsLib.EDI.X12.Operation.SOAPOperation');  break;
			}
			break;
		}
		default: {
			break;
		}
	}
	return true;
}

/// If "auto-create service target" is true, disable the dataCombo field for choosing a service.
ClientMethod changeTarget(formName) [ Language = javascript ]
{
		var option = zen(formName + 'TargetAuto').getValue();
		var target = zen(formName + 'TargetName');
		var package = zen(formName + 'TargetAutoPackage');
		switch (option)
		{
			case "Create":
				target.setHidden(1);
				target.required = 0;
				target.setValue("");
				package.setHidden(0);
				var defaultPackage = this.DefaultRulePackage();
				if (!package.value) package.setValue(defaultPackage);
				break;
			case "None":
				target.setHidden(1);
				target.required = 0;
				target.setValue("");
				package.setHidden(1);
				break;
			case "Choose":
				target.setHidden(0);
				target.required = 1;
				package.setHidden(1);
				// The user must set a value for this field
				break;
		}
}

ClientMethod selectDirectory(controlName) [ Language = javascript ]
{
	if (!this.canViewFileSystem) return;
	var control = zen(controlName);
	if (!control) return;
	this._selectDirectoryControl = controlName;
	var parms = {
		"Dir": control.getValue(),
		"showdirectoryonly": 1
	};
	zenLaunchPopupWindow(zenLink('_ZEN.Dialog.fileSelect.zen'),this.addPopupSuffix('SelectDirectory'),'status,scrollbars,resizable=yes,width=600,height=700',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	popupName = this.removePopupSuffix(popupName);

	switch(popupName) {

	case 'SelectDirectory':
		if (action == 'ok') {
			var control = zen(this._selectDirectoryControl);
			if (control) {
				control.setValue(value);
			}
		}
		delete this._selectDirectoryControl;
		break;

	}

	return true;
}

/// Hide all form fields in response to the choice of protocol/adapter (Input Type).
ClientMethod hideAll(host, edi) [ Language = javascript ]
{
	var formName = host + edi;
	switch (host)
	{
		case "Service":
			// empty the values
			zen(formName + 'ClassName').setValue('');
			zen(formName + 'Name').setValue('');
			zen(formName + 'Category').setValue('');
			zen(formName + 'Comment').setValue('');
			zen(formName + 'Enabled').setValue('');
			zen(formName + 'TargetAuto').setValue('');
			zen(formName + 'TargetAutoPackage').setValue('');
			zen(formName + 'TargetName').setValue('');
			zen(formName + 'Addr1').setValue('');
			zen(formName + 'Port1').setValue('');
			zen(formName + 'Cred').setValue('');
			zen(formName + 'FilePath1').setValue('');
			zen(formName + 'FilePath2').setValue('');
			zen(formName + 'Archive').setValue('');
			zen(formName + 'FileSpec1').setValue('');

			// hide all rows
			zenPage.hideRow(formName + 'Name');
			zenPage.hideRow(formName + 'Category');
			zenPage.hideRow(formName + 'Comment');
			zenPage.hideRow(formName + 'Enabled');
			zenPage.hideRow(formName + 'TargetAuto');
			zenPage.hideRow(formName + 'TargetAutoPackage');
			zenPage.hideRow(formName + 'TargetName');
			zenPage.hideRow(formName + 'Addr1');
			zenPage.hideRow(formName + 'Port1');
			zenPage.hideRow(formName + 'Cred');
			zenPage.hideRow(formName + 'FilePath1Grp');
			zenPage.hideRow(formName + 'FilePath2');
			zenPage.hideRow(formName + 'ArchiveGrp');
			zenPage.hideRow(formName + 'FileSpec1');

			// handle special stuff
			if (edi == 'HL7') {
				zen(formName + 'SchemaCategory').setValue('');
				zenPage.hideRow(formName + 'SchemaCategory');
			}
			break;
		case 'Operation':
			// empty the values
			zen(formName + 'ClassName').setValue('');
			zen(formName + 'Name').setValue('');
			zen(formName + 'Category').setValue('');
			zen(formName + 'Comment').setValue('');
			zen(formName + 'Enabled').setValue('');
			zen(formName + 'Addr1').setValue('');
			zen(formName + 'Addr2').setValue('');
			zen(formName + 'Port2').setValue('');
			zen(formName + 'Cred').setValue('');
			zen(formName + 'FilePath3').setValue('');
			zen(formName + 'FilePath4').setValue('');
			zen(formName + 'FileSpec2').setValue('');

			// hide all rows
			zenPage.hideRow(formName + 'Name');
			zenPage.hideRow(formName + 'Category');
			zenPage.hideRow(formName + 'Comment');
			zenPage.hideRow(formName + 'Enabled');
			zenPage.hideRow(formName + 'Addr1');
			zenPage.hideRow(formName + 'Addr2');
			zenPage.hideRow(formName + 'Port2');
			zenPage.hideRow(formName + 'Cred');
			zenPage.hideRow(formName + 'FilePath3Grp');
			zenPage.hideRow(formName + 'FilePath4');
			zenPage.hideRow(formName + 'FileSpec2');

			// handle special stuff
			if (edi == 'HL7') {
				zen(formName + 'URL').setValue('');
				zenPage.hideRow(formName + 'URL');
			}
			break;
	}
	return true;
}

/// Hide a form field; this usually happens based on the choice of protocol/adapter (Input Type).
ClientMethod hideRow(fieldName) [ Language = javascript ]
{
	zen(fieldName).setHidden(1);
	return true;
}

/// Show a form field; this usually happens based on the choice of protocol/adapter (Input Type).
ClientMethod showRow(fieldName) [ Language = javascript ]
{
	zen(fieldName).setHidden(0);
	return true;
}

Method GetHelp(pSeed As %String) As %String [ ZenMethod ]
{
	Quit ..LinkHelp _ "KEY=" _ pSeed
}

Method GetFrom() As %String [ ZenMethod ]
{
	Quit $$$Text("From")_"_"
}

Method GetTo() As %String [ ZenMethod ]
{
	Quit $$$Text("To")_"_"
}

ClassMethod ItemSettingsInsert(ByRef pItem As Ens.Config.Item, pName As %String = "", pTarget As %String = "Adapter", pValue As %String = "", pOverridePageDefaultSetting As %Boolean = 0) [ Internal ]
{
	/*	If not defined on the page useDefaultForEmptyValue is ""
		Use try/catch to account for not using in web page
		Allow caller to override.
		Default is to not save empty string
	*/
	Try {
		If (pValue'="") || pOverridePageDefaultSetting || '%page.%GetValueById("useDefaultForEmptyValue") {
			#dim setting = ##class(Ens.Config.Setting).%New()
			Set setting.Name = pName
			Set setting.Target = pTarget
			Set setting.Value = pValue
			Do pItem.Settings.Insert(setting)
		}
	} Catch { /* account for not called in a web page */}
}

ClassMethod DefaultRulePackage(pPackage As %String = "") As %String [ Internal, ZenMethod ]
{
	#dim tReturn = pPackage
	#; The assumption is that there is not a user called All
	#dim tAll = "All"
	Try {

		#dim tProductionDefault = $Get(^EnsPortal.Settings(tAll,"HostWizard","RulePackage"))
		If pPackage = "" {
			Set tReturn = $Get(^EnsPortal.Settings($username,"HostWizard","RulePackage"),tProductionDefault)
			Quit
		}

		Set ^EnsPortal.Settings($username,"HostWizard","RulePackage") = pPackage
		If tProductionDefault="" Set ^EnsPortal.Settings(tAll,"HostWizard","RulePackage") = pPackage

	} Catch {}

	Quit tReturn
}

ClientMethod toggleDefaultForEmpty(host, tab) [ Language = javascript ]
{
	var tabUseDefaultForEmpty = zen(host+tab+"UseDefault");
	if (tabUseDefaultForEmpty) {
		var pageUseDefaultForEmpty = zen("useDefaultForEmptyValue");
		if (pageUseDefaultForEmpty) {
			pageUseDefaultForEmpty.setValue(tabUseDefaultForEmpty.getValue());
		}
	}
}

ClientMethod showPossibleDefault(prefix, setting) [ Language = javascript ]
{
	var possibleDefaultMsgJS = zenPage.PossibleDefaultJS(prefix,setting);
	return possibleDefaultMsgJS;
}

/// Return JS escaped sentence for an alert() on one setting.
/// Supported Setting Names - Validation
Method PossibleDefaultJS(prefix As %String = "", setting As %String = "") As %String [ Internal, ZenMethod ]
{
	#; Check supported Setting names
	If setting '= "Validation" Quit ""

	#dim tMessage = ""

	#dim tNoSpecificName = 0

	/* validate setting is an approved Setting Name */
	#dim tProductionName = ..ProductionName
	#dim tHostName = ..%GetValueById(prefix_"Name")
	#dim tClassName = ..%GetValueById(prefix_"ClassName")

	If tHostName = "" {

		Set tHostName = tClassName
		Set tNoSpecificName = 1
	}

	#dim tDefault = ..possibleDefaultValue(tProductionName, tHostName, tClassName, setting)

	Quit ..possibleDefaultMessageJS(prefix,$ZCVT(tDefault,"O","JS"),tNoSpecificName)
}

Method possibleDefaultMessageJS(pPrefix As %String = "", pDefaultValueJS As %String = "", pNoSpecificName As %Boolean = 0) As %String [ Internal ]
{
	#dim tMessage = ""

	If pDefaultValueJS = "" {

		Set tMessage = $$$TextJS("Based on information there is no default value for this setting.")

		If pNoSpecificName = "" {

			Set tMessage =tMessage_" "_$$$TextJS("This could be because a name has not been entered yet for this host")

		}

	} Else {

		Set tMessage = $$$FormatTextJS("%1 is the expected default value. The actual value will be shown when the item is added to the production.", pDefaultValueJS)

	}

	Quit tMessage
}

/// Internal method - based on an item not existing in a production
ClassMethod possibleDefaultValue(pProductionName As %String = "", pHostName As %String = "", pClassName As %String = "", pSettingName As %String = "", Output pSource As %Integer = {$$$eConfigSettingValueTypeProperty}) As %String [ Internal ]
{
	#dim tDefault = ""
	/* no Registry look up */

	#dim tTargetClassnameArray
	#dim tAdapterClassName = ""

	Try {

		If pClassName = "" Quit
		If pSettingName = "" Quit

		Set tTargetClassnameArray("Host") = pClassName

		Set tAdapterClassName = $parameter(pClassName,"ADAPTER")

		#dim tClass

		#dim tTargetType
		Set tTargetType(1)="Host"
		Set tTargetType(2)="Adapter"
		#dim tType = 0

		#dim tSDSValue

		For tClass=pClassName, tAdapterClassName {

			If (tClass="") || (tDefault'="") Quit

			Set tTargetType = $Get(tTargetType($I(tType)))

			Set tDefault = $classmethod(tClass,"EvalInitialExpression",pSettingName)

			If ##class(Ens.Config.DefaultSettings).%GetSetting(pProductionName, pHostName, tClass, tTargetType, pSettingName, .tSDSValue) {

				Set tDefault = tSDSValue
				Set pSource = $$$eConfigSettingValueTypeSystem

			}

		}

	} Catch {Set tDefault = ""}

	Quit tDefault
}

ClientMethod showPossibleDefaults(hosttype, edi) [ Language = javascript ]
{
	/*
		Use Server side methods to generate table
		Then call table popup display
	*/

	var ok = this.GenerateSettingsListHTML(hosttype,edi);

	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ProductionAddItemSettings.zen'),this.addPopupSuffix('ItemDefaults'),'status,scrollbars,resizable=yes,width=900,height=720');

	return '';
}

Method GenerateSettingsListHTML(pHostType As %String = "", pEDIType As %String = "") As %Status [ Internal, ZenMethod ]
{
	/*
		Create an HTML Table to show results in EnsPortal.Dialog.ProductionAddItemSettings
		Similar table to that generated in EnsPortal.Dialog.ProductionItemSettings
	*/
	Set ..defaultSettingsHTML = ""
	#dim tDefaultsArray
	#dim ok = ..GenerateSettingsList(pHostType,pEDIType,.tDefaultsArray)
	Set ok = ..CreateDefaultSettingsTable(.tDefaultsArray)
	Quit $$$OK
}

Method GenerateSettingsList(pHostType As %String = "", pEDIType As %String = "", ByRef pDefaultsArray) As %Status [ Internal, Private ]
{
	Kill pDefaultsArray

	#dim tProductionName = ..ProductionName

	#dim tFormName = pHostType_pEDIType
	#dim tHostName = ..%GetValueById(tFormName_"Name")
	#dim tClassName = ..%GetValueById(tFormName_"ClassName")

	#dim tInOutType = ..%GetValueById(tFormName_"InOutType")

	#dim tDefaultableSettings
	Do ..findDefaultableSettings(pHostType,pEDIType,tInOutType,.tDefaultableSettings)

	#dim tHostNameorClassName = tHostName
	If tHostNameorClassName = "" Set tHostNameorClassName = tClassName

	#dim tSetting
	#dim tSource
	#dim tDefaultValue = ""
	#dim tSettingName = $Order(tDefaultableSettings(""))
	While tSettingName '= "" {

		Kill tSource
		Set tDefaultValue = ..possibleDefaultValue(tProductionName, tHostNameorClassName, tClassName, tSettingName,.tSource)
		Set tSetting = $I(pDefaultsArray)
		Set pDefaultsArray(tSetting,"name")=tSettingName
		Set pDefaultsArray(tSetting,"defaultValue")=tDefaultValue
		Set pDefaultsArray(tSetting,"source")=tSource

		Set tSettingName = $Order(tDefaultableSettings(tSettingName))

	}

	Quit $$$OK
}

ClassMethod findDefaultableSettings(pHostType As %String = "", pEDIType As %String = "", pInOutType As %String = "", Output pSettingNames) [ Internal ]
{
	/*
		Only returning those that user can enter and could use default if left blank
	*/
	Kill pSettingNames

	If pHostType = "Service" {

		Set pSettingNames("TargetConfigNames")=""

		If pEDIType = "HL7" {

			Set pSettingNames("MessageSchemaCategory")=""

		}

		If pInOutType = "File" {

			Set pSettingNames("FilePath")=""
			Set pSettingNames("ArchivePath")=""
			Set pSettingNames("FileSpec")=""

		} ElseIf pInOutType = "FTP" {

			Set pSettingNames("FTPServer")=""
			Set pSettingNames("FTPPort")=""
			Set pSettingNames("Credentials")=""
			Set pSettingNames("FilePath")=""
			Set pSettingNames("ArchivePath")=""
			Set pSettingNames("FileSpec")=""

		} ElseIf pInOutType = "TCP" {

			Set pSettingNames("Port")=""

		} ElseIf pInOutType = "HTTP" {

			Set pSettingNames("Port")=""

		} ElseIf pInOutType = "SOAP" {

			Set pSettingNames("Port")=""

		}

	} ElseIf pHostType = "Operation" {

		If pInOutType = "File" {

			Set pSettingNames("FilePath")=""
			Set pSettingNames("Filename")=""

		} ElseIf pInOutType = "FTP" {

			Set pSettingNames("FTPServer")=""
			Set pSettingNames("FTPPort")=""
			Set pSettingNames("Credentials")=""
			Set pSettingNames("FilePath")=""
			Set pSettingNames("FileSpec")=""

		} ElseIf pInOutType = "TCP" {

			Set pSettingNames("Port")=""
			Set pSettingNames("IPAddress")=""

		} ElseIf pInOutType = "HTTP" {

			Set pSettingNames("HTTPServer")=""
			Set pSettingNames("HTTPPort")=""
			Set pSettingNames("Credentials")=""
			Set pSettingNames("URL")=""

		}

	}

	Quit
}

Method CreateDefaultSettingsTable(ByRef pDefaultsArray) As %Status [ Internal, Private ]
{
	#dim lbl
	#dim lblLocal
	#dim title

	Set lbl(1) = $$$TextHTML("Setting")
	Set lbl(2) = $$$TextHTML("Default")
	Set lbl(3) = $$$TextHTML("Possible Value")
	Set lbl(4) = $$$TextHTML("Default Source")
	Set lbl(5) = $$$TextHTML("Source")

	Set title(1) = $$$TextHTML("Setting")
	Set title(2) = $$$TextHTML("Possible Default value")
	Set title(3) = $$$TextHTML("Where the default value is coming from")

	Set lblLocal("ClassDef") = $$$TextHTML("Class definition")
	Set lblLocal("DefaultSetting") = $$$TextHTML("System default setting")
	#dim tHTML = "<html>"
	Set tHTML = tHTML_"<table class='DetailTable' border='1' cellspacing='0' cellpadding='4'>"
	Set tHTML = tHTML_"<tr><th title='"_(title(1))_"' rowspan='2'>"_(lbl(1))_"</th>"
	Set tHTML = tHTML_"<th colspan='2' style='border-bottom:1px solid gray;'>"_(lbl(3))_"</th></tr>"
	Set tHTML = tHTML_"<tr><th title='"_(title(2))_"' style='border-top:0px;'>"_(lbl(2))_"</th>"
	Set tHTML = tHTML_"<th title='"_(title(3))_"' style='border-top:0px;'>"_(lbl(5))_"</th></tr>"

	Try {

		#dim tSetting = $Order(pDefaultsArray(""))
		#dim tName
		#dim tDefaultValue
		#dim tSource

		While tSetting'="" {

			Set tName = $Get(pDefaultsArray(tSetting,"name"))
			Set tDefaultValue = $Get(pDefaultsArray(tSetting,"defaultValue"))
			Set tSource = $Get(pDefaultsArray(tSetting,"source"))

			Do ..WriteRow(.tHTML,tName,tDefaultValue,tSource,.lblLocal)

			Set tSetting = $Order(pDefaultsArray(tSetting))

		}

	} Catch {} 

	Set tHTML = tHTML_"</table></html>"
	Set ..defaultSettingsHTML = tHTML
	Quit $$$OK
}

Method WriteRow(ByRef pHTML, pName As %String = "", pDefaultValue As %String = "", pSource As %String = "", ByRef lblLocal As %String) [ Internal, Private ]
{
	// Setting,Default Value,Default Source

	#dim txtName = $$$GetLocalizedName(pName)

	#dim dt = $Case(pSource,$$$eConfigSettingValueTypeSystem:lblLocal("DefaultSetting"),$$$eConfigSettingValueTypeRegistry:lblLocal("Registry"),:lblLocal("ClassDef"))
	#dim labelColor = $Case(pSource,$$$eConfigSettingValueTypeProduction:"black",$$$eConfigSettingValueTypeSystem:"blue",$$$eConfigSettingValueTypeRegistry:"brown",:"darkgreen")

	Set pHTML = pHTML_"<tr>"
	Set pHTML = pHTML_"<td nowrap class='label' style='color:"_(labelColor)_"; title='"_(pName)_"'><b>"_($ZCVT(txtName,"O","HTML"))_"</b></td>"
	Set pHTML = pHTML_"<td nowrap>"_($S(pDefaultValue'="":$ZCVT(pDefaultValue,"O","HTML"),1:"&nbsp;"))_"</td>"
	Set pHTML = pHTML_"<td nowrap>"_(dt)_"</td>"
}

}
