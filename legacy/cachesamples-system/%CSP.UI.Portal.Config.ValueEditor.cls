/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syNLS

/// This value editor is specific for the Configure individual Startup/Memory/Compatibility settings
Class %CSP.UI.Portal.Config.ValueEditor Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.ValueEditor.zen";

Parameter HELPADDRESS = "Home,Configuration";

Parameter EMSSERVICE = "Config";

Parameter RECENT = 0;

/// A CSL listing those properties that should get a restart required warning even if the 
/// parent class does not implement the NoRestartOnActivate method.
Parameter RESTARTREQUIREDLIST = "NullSubscripts";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Name of the current configuration class
Property ClassName As %ZEN.Datatype.string(ZENURL = "ClassName");

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property IsRequired As %Boolean [ InitialExpression = 0 ];

Property PID As %ZEN.Datatype.string(ZENURL = "PID");

Property pType As %ZEN.Datatype.string;

/// Subject name for the setting page. 
Property Subject As %String(ZENURL = "Subject");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.brownnote {
	font-size: 0.8em;
	color: #000000;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
 <!-- block to show result -->
<label id="idRespond" enclosingClass="errorNote" hidden="true" containerStyle="padding-bottom:2px;"/>
<vgroup id="fld">
<form cellStyle="padding:4px;" enclosingClass="EditForm" enclosingStyle="padding-top:2px;" labelPosition="left" hidden="false">
 <hidden id="firstFailed"/>
<vgroup id="mainGroup" labelPosition="left">
<vgroup id="idEdit" labelPosition="left" cellStyle="padding:4px;" >
 </vgroup> 
 <spacer height="5" />
 <html id="desc" OnDrawContent="%GetDescHTML"/>
</vgroup>
</form>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If ..Subject["Miscellaneous" {
		Set ..lblTitle = $$$Text("Use the form below to edit a compatibility setting:")
		Set ..HelpAddress = "Home,Configuration,Compatibility Settings,Compatibility Setting"
	} ElseIf ..Subject["Startup" {
		Set ..lblTitle = $$$Text(" Use the form below to edit a startup setting:")
		Set ..HelpAddress = "Home,Configuration,Startup Settings"
	} ElseIf ..Subject["Memory" {
		Set ..lblTitle = $$$Text("Use the form below to edit a memory setting:")
		Set ..HelpAddress = "Home,Configuration,Advanced Memory Settings"
	} Else {
		#; User tinkered with Subject from the URL!
		Set ..Subject = ""	
	}
	If ..Subject = "" {
		Set ..lblTitle = $$$Text("Incorrect Subject. Unable to continue.")
		Set ..%GetComponentById("fld").hidden = 1
		Set ..IsEditForm = 0
		Quit $$$OK	
	}
	Do ..DrawAfterCreatePage()
	Set tPageName = "%CSP.UI.Portal.Config."_$S(..Subject["Memory":"Memory",..Subject["Startup":"Startup",1:"Compatibility")_".zen"
	Set tParam(1) = "Subject="_$P(..Subject,"Edit",1)
	Set ..ParentURL = ..Link($ZCVT(tPageName,"O","URL"),,1)_tParam(1)
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..Subject["Miscellaneous" {
		Quit $$$Text("Edit Compatibility Settings")
	} ElseIf ..Subject["Startup" {
		Quit $$$Text("Edit Startup Settings")
	} ElseIf ..Subject["Memory" {
		Quit $$$Text("Edit Memory Settings")
	} Else {
		Quit $$$Text("Unknown Subject")
	}
}

/// Provide contents of description component only if locale is English.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Set CurrentLocale =  $G($$$LOCALENAME,"enu8")
	If $ZCVT($E(CurrentLocale,1,2),"L") '= "en" Quit $$$OK
	
	If ((..ClassName'= "")&&(..PID'="")) {
		Do ##class(%ZEN.Utils).%DrawPropertyDescription(..ClassName,..PID)
	}
	Quit $$$OK
}

/// Check if field is required and make value is not null
ClientMethod doSave() [ Language = javascript ]
{
	try {
		var tValue = "";
		if (this.PID == "DBSizesAllowed") {
			// go through each checkbox and concatenate checked ones together.
			for (var i=1;i<=6;i++) {
				var id = "chkDB_" + i;
				var chk = zen(id);
				if (chk && (chk.getValue() == 1)) {
					var labelarray = chk.getProperty("label").split("(");
					if (tValue != "") tValue += ","; 
					tValue += labelarray[1].substring(0,labelarray[1].length-1);	
				}
			}
		} else {
			var value = zen("value");
			tValue = value.getValue();
			if (this.IsRequired && (zenTrim(tValue) == '')) {
				value.setProperty("hintClass","brownnote");
				value.focus();
				return false;
			}
		}
		var result = this.SaveData(this.ClassName,this.PID,tValue,this.pType);
		this.afterSave(result);
	} catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

Method DrawAfterCreatePage() As %Status
{
	If '$$$comMemberDefined(..ClassName,$$$cCLASSmethod,"Get") {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	
	Set tSC = $classmethod(..ClassName,"Get",.Properties)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	
	If '$$$comMemberDefined(..ClassName,$$$cCLASSproperty,..PID) {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	
	Set pValue = Properties(..PID)
	Set ..pType = $$$comMemberKeyGet(..ClassName,$$$cCLASSproperty,..PID,$$$cPROPruntimetype)
	
	Set group = ..%GetComponentById("idEdit")

	Set tType = $P(..pType,":",1)
	Set tTypeMod = $P(..pType,":",2)
	Set tTypeMod2 = $P(..pType,":",3)
	If tTypeMod2 = "" {
		Set tTypeMod2 = tTypeMod
	}
	If tTypeMod = "" {
		Set tTypeMod = $$$comMemberArrayGet(..ClassName,$$$cCLASSproperty,..PID,$$$cPROPparameter,"VALUELIST")
	} Else {
		Set tTypeMod = ","_tTypeMod
	}
	If tTypeMod2 = "" {
		Set tTypeMod2 = $$$comMemberArrayGet(..ClassName,$$$cCLASSproperty,..PID,$$$cPROPparameter,"DISPLAYLIST")
	}
	If tTypeMod2 = "" {
		Set tTypeMod2 = tTypeMod
	}
	If tTypeMod '= "" {
		Set tTypeMod = $P(tTypeMod,",",2,"999"),tType = "enum"
	}
	If tTypeMod2 '= "" {
		Set tTypeMod2 = $P(tTypeMod2,",",2,"999")
	}
	Set tMAXVAL = $$$comMemberArrayGet(..ClassName,$$$cCLASSproperty,..PID,$$$cPROPparameter,"MAXVAL")
	Set tMINVAL = $$$comMemberArrayGet(..ClassName,$$$cCLASSproperty,..PID,$$$cPROPparameter,"MINVAL")
	Set tRequired = $$$comMemberKeyGet(..ClassName,$$$cCLASSproperty,..PID,$$$cPROPrequired)

	Set labelText = $ZCVT(..PID,"O","HTML")
	// add edit control and text to field set based on type
	// (type comes from the settings entry for this property)
	If ($ZCVT(tType,"L") [ "boolean") {
		Set ctrl = ##class(%ZEN.Component.checkbox).%New()
		Do group.%AddChild(ctrl)

		Set ctrl.id = "value"
		Set ctrl.caption = $ZCVT(..PID,"O","HTML")
		Set ctrl.captionClass="zenLabel"
		Set ctrl.value = $S(pValue="true":1,pValue="false":0,1:+pValue)
		Set ctrl.onchange = "zenPage.doModified();"
		Set tHelp = $$$TextHTML("Please check the checkbox if the value for this setting is true.")
	} ElseIf ..PID = "DBSizesAllowed" {
		// This allows multiple selections and 8k to be default and cannot be unchecked.
		Set tDisplayList = "4K,8K,16K,32K,64K"
		Set tValueList = "4096,8192,16384,32768,65536"
		For n = 1:1:$L(pValue,",") Set tItem = $P(pValue,",",n) If tItem '= "" Set tSelected(tItem) = ""
		Set ctrl = ##class(%ZEN.Component.label).%New()
		Do group.%AddChild(ctrl)
		Set ctrl.label = labelText
		Set ctrl.labelClass="zenLabel"
		Set ctrl.hint = "("_$$$TextHTML("Check all that apply. 8K is required.")_")"
		Set ctrl.hintClass = "helpText"

		For n = 1:1:$L(tValueList,",") {
			Set tItem = $P(tValueList,",",n)
			Set allowed = ##class(SYS.Database).CheckBlockSizeAvailable(tItem)
			If allowed {
				Set ctrl = ##class(%ZEN.Component.checkbox).%New()
				Do group.%AddChild(ctrl)
				Set ctrl.id = "chkDB_"_n
				Set ctrl.label = $P(tDisplayList,",",n)_" ("_tItem_")"
				Set ctrl.labelClass = "zenLabel"
				Set ctrl.value = $S($D(tSelected(tItem)):1,1:"")
				Set ctrl.originalValue = $S($D(tSelected(tItem)):tItem,1:"")
				Set ctrl.onchange = "zenPage.doModified();"
				If tItem = 8192 {
					Set ctrl.disabled = 1
				} 
			}
		}
		Set ctrl = ##class(%ZEN.Component.label).%New()
		Do group.%AddChild(ctrl)
		Set ctrl.value = $$$TextHTML("NOTE: You must also configure Memory allocation in order to create databases with selected sizes.")
		Set ctrl.enclosingClass="helpText"
	} ElseIf (tType = "enum") {	// insert "" choice
		If ($L(tTypeMod,",") > 5) {
			Set ctrl = ##class(%ZEN.Component.combobox).%New()
			Do group.%AddChild(ctrl)
	
			Set ctrl.id = "value"
			Set ctrl.label = labelText
			Set ctrl.labelClass="zenLabel"
			Set ctrl.value = pValue
			Set ctrl.onchange = "zenPage.doModified();"
			For n=1:1:$L(tTypeMod,",") {
				Set tOption = ##class(%ZEN.Auxiliary.option).%New()
				Do ctrl.options.Insert(tOption)
				Do:$IsObject(%page) ..%AddComponent(tOption)
				Set tOption.value=$P(tTypeMod,",",n)
				Set tOption.text=$P(tTypeMod2,",",n)
			}
		} Else {
			Set ctrl = ##class(%ZEN.Component.radioSet).%New()
			Do group.%AddChild(ctrl)
	
			Set ctrl.id = "value"
			Set ctrl.label = labelText
			Set ctrl.labelClass="zenLabel"
			Set ctrl.value = pValue
			Set ctrl.onchange = "zenPage.doModified();"
			Set ctrl.valueList = tTypeMod
			Set ctrl.displayList = tTypeMod2
			Set ctrl.emptyCaption = "N/A"
		}
		Set tHelp = $$$TextHTML("Please make a selection among the available choices.")
	} Else {
		#; string etc.
		Set ctrl = ##class(%ZEN.Component.text).%New()
		Do group.%AddChild(ctrl)
		Set ctrl.id = "value"
		Set ctrl.label = labelText
		Set ctrl.labelClass="zenLabel"
		Set ctrl.value = pValue
		Set ctrl.onchange = "zenPage.doModified();"
		Set type = $ZCVT(tType,"L")
		If ((type [ "integer")||(type [ "length")||(type [ "float")) {
			Set ctrl.size = 12
		} Else {
			Set ctrl.size = 80
		}
		If tRequired = 1 Set tHelp = $$$TextHTML("Required. "),..IsRequired = 1
		If tMINVAL'="",tMAXVAL'="" {
			Set tHelp = $G(tHelp)_$$$FormatText($$$Text("Enter a number within this range: %1-%2"),tMINVAL,tMAXVAL)
		} Else {
			Set tHelp = $G(tHelp)_$$$FormatText($$$Text("Please enter a value of type %1."),tType)			
			If tType = "%Library.SysPath" {
				If ..ClassName = "Config.config",..PID="ConsoleFile" Set tHelp = $$$FormatText($$$Text("Please enter a directory or a file path ending in 'messages.log' where the console file will be saved. '%1messages.log' is used if left blank."),$zu(12))
				If ..ClassName = "Config.config",..PID="VMSConsoleTerminal" Set tHelp = $$$Text("Name of the console terminal device for logging messages on an OpenVMS system. 'device OPA0:' is used if left blank.")
				If ..ClassName = "Config.Startup",..PID="WebServerURLPrefix" Set tHelp = $$$Text("Enter InterSystems IRIS instance name if you are using a remote Web server to access it.")
				If ..ClassName = "Config.Startup",..PID="TempDirectory" Set tHelp = $$$Text("Enter the Name of a subdirectory in which to store temporary files for InterSystems IRIS. The default is 'Temp'.")
			}
			If ..PID = "LibPath" Set tHelp = $$$TextHTML("UNIX only: enter a string consisting of a colon-separated series of search path directory names.")
		}
	}


	#; help message
	If ($G(tHelp) '= "") {
		Set ctrl.hint = tHelp
		Set ctrl.hintClass = "helpText"
	}

	#; Warning for Memory change. 
	If ..ClassName [ "config" {
		Set spacer = ##class(%ZEN.Component.spacer).%New()
		Set spacer.height = 2
		Do group.%AddChild(spacer)
		
		Set warning = ##class(%ZEN.Component.label).%New()
		Set warning.id = "warning"
		i $classmethod(..ClassName,"NoRestartOnActivate",..PID) {
			Set warning.value = $$$TextJS("Note: Changes to this setting do not require a restart of the system.")
		} else {
			Set warning.value = $$$TextJS("Note: Changes to this setting will require a restart of the system.")
		}
		Set warning.enclosingClass = "brownnote"
		Do group.%AddChild(warning)
	}
	Else {
		If (..PID [ ..#RESTARTREQUIREDLIST) {
			Set spacer = ##class(%ZEN.Component.spacer).%New()
			Set spacer.height = 2
			Do group.%AddChild(spacer)
		
			Set warning = ##class(%ZEN.Component.label).%New()
			Set warning.id = "warning"
			Set warning.value = $$$TextJS("Note: Changes to this setting will require a restart of the system.")
			Set warning.enclosingClass = "brownnote"
			Do group.%AddChild(warning)
		}
	}
	
	Quit $$$OK
}

/// Call server save method. Values passed in is delimited by "|" if there are more than one.
ClassMethod SaveData(ConfigClass As %String, Properties As %String, Values As %String, SelectedType As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		If Values [ "|" {
			For i=1:1:$L(Properties,",") {
				Set t = $P(Properties,",",i)
				Set p(t) = $P(Values,"|",i+1)
			}
		} Else {
			Set p(Properties) = Values
		}
		If SelectedType [ "Boolean" {
			Set p(Properties) = $S(Values="true":1,1:0)
		}
		If '..Validate(ConfigClass,.p,.tMessage) {
			Set tProxy.ok = 0
			Set tProxy.ErrorMessage = tMessage
			Quit
		}
		Set tSC = $classmethod(ConfigClass,"Modify",.p)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	
	Quit tProxy
}

/// Perform any necessary validation on the values being set
/// <var>pMessage</var> is the error message to be displayed if validation fails
ClassMethod Validate(pConfigClass As %String, ByRef pProperties As %String, ByRef pMessage As %String = "") As %Boolean
{
	Set tOK = 1
	If ("Config.config"=pConfigClass) && ($D(pProperties("ConsoleFile"),tFileName)) {
		// Check filename is messages.log and directory exists or tFileName is just directory and directory exists
		If '(("messages.log" = $zcvt(##class(%File).GetFilename(tFileName),"l")) && ##class(%File).DirectoryExists(##class(%File).GetDirectory(tFileName))) && '##class(%File).DirectoryExists(tFileName) {
			Set tOK = 0
			Set pMessage = $$$FormatText($$$Text("Directory '%1' does not exist.  Please enter a directory path, file path ending in 'messages.log', or leave this setting blank.  File names other than messages.log are not permitted."),$Select(("messages.log"=$zcvt(##class(%File).GetFilename(tFileName),"l")):##class(%File).GetDirectory(tFileName),1:tFileName))
		}
	}
	ElseIf ("Config.Miscellaneous"=pConfigClass) && ($D(pProperties("ListFormat"),tFormat)) {
		If (tFormat'=0) && (tFormat'=1) {
			Set tOK = 0
			Set pMessage = $$$FormatText($$$Text("Value must be 0 or 1"))
		}
	}
	Quit tOK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
/// Subclasses may override.
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	If ..Subject = "" {
		Quit $$$OK
	}
	
	If ..Subject["Memory" {
		Set tPageName = $$$Text("Advanced Memory Settings")
	} ElseIf ..Subject["Startup" {
		Set tPageName = $$$Text("Startup Settings")
	} Else {
		Set tPageName = $$$Text("Compatibility Settings")
	}

	Set tURL = ..Link($P(..ParentURL,"?",1)_"?Subject="_..EscapeURL(..Subject))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list with parameters
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_"?Subject="_..EscapeURL(..Subject)_"&PID="_..EscapeURL(..PID)_"&ClassName="_..EscapeURL(..ClassName)))
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
