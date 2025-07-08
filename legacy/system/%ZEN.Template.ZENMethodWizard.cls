/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template.<br>
/// Insert a new method to a Zen page.
Class %ZEN.Template.ZENMethodWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Method Wizard";

Parameter TEMPLATETITLE = "Zen Method Wizard";

Parameter TEMPLATEDESCRIPTION = "Add a new method to a Zen class.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "template";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
body {
	overflow: hidden;
}
</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody
{
<pane id="body">

<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc">
</html>

<text label="Method Name:" 
	id="ctrlMethodName"
	name="MethodName"
	size="40"
	required="true"
	labelClass="zenRequired"
	title="Name of the new method" 
	onchange="zenPage.updateState();"
	value="MyMethod"
/>
<label id="scope" label="Scope:" labelClass="zenRequired" />

<radioButton name="Scope" caption="is an instance method" optionValue="instance" value="instance"/>
<radioButton name="Scope" caption="is a class method" optionValue="class" />

<label id="location" label="Location:" labelClass="zenRequired" />

<radioButton name="Location" caption="runs on the client" optionValue="client" value="client" onchange="zenPage.locationChange(zenThis);"/>
<radioButton name="Location" caption="runs on the server" optionValue="server" onchange="zenPage.locationChange(zenThis);"/>
<radioButton name="Location" caption="is only available on the server" optionValue="serverOnly" onchange="zenPage.locationChange(zenThis);"/>
<radioButton name="Location" caption="is a server-side callback for a component" optionValue="serverCallback" onchange="zenPage.locationChange(zenThis);"/>

<dataCombo id="callback" 
	name="Callback"
	label="Server-side callback:" 
	queryClass="%CSP.Documatic"
	queryName="ReferencedBy"
	onchange="zenPage.callbackChange(zenThis);"
	columnHeaders="Class,Callback"
	displayColumns="1,2"
	dropdownWidth="500px"
	hidden="true">
	<parameter value="%ZEN.Datatype.delegator"/>
</dataCombo>
<hidden id="callbackMethod" name="CallbackMethod"/>
<textarea label="Description:" 
	id="ctrlDescription"
	name="Description"
	rows="4"
	cols="50"
	title="Description for the new method" 
	onchange="zenPage.updateState();"
/>
<checkbox id="ctrlTryCatch" name="TryCatch" label="Try/Catch" value="1" caption="Use Try/Catch in method"/>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	set html=%page.%GetComponentById("desc")
	set html.content=$$$TextHTML("This wizard adds a new method to a Zen class. The new method can then be further edited within your IDE.")
	set scope=%page.%GetComponentById("scope")
	set scope.value=$$$Text("This method:")
	set location=%page.%GetComponentById("location")
	set location.value=$$$Text("This method:")
	Quit $$$OK
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	// give focus to name
	var ctrl = zenPage.getComponentById('ctrlMethodName');
	if (ctrl) {
		ctrl.focus();
		ctrl.select();
	}
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	// test if method name is valid
	var mtdName = zenPage.getComponentById('ctrlMethodName').getValue();

	var msg = this.IsValidMethodName(mtdName);

	if ('' != msg) {
		alert(msg);
		return false;
	}

	return true;
}

/// This is called when the user changes the Location control(s).
ClientMethod locationChange(ctrl) [ Language = javascript ]
{
	var val = ctrl.getValue();
	var cb = zenPage.getComponentById('callback');
	cb.setHidden('serverCallback' != val);
}

/// This is called when the user changes the Callback control.
ClientMethod callbackChange(ctrl) [ Language = javascript ]
{
	var val = ctrl.getOptionText(ctrl.selectedIndex);
	var hc = zenPage.getComponentById('callbackMethod');
	hc.setValue(val);
}

/// Validate that the given method name is valid.<br>
/// Returns an error message if invalid.
Method IsValidMethodName(pCls As %String) As %String [ ZenMethod ]
{
	If '$ZNAME(pCls,5) {
		Quit $$$Text("The method name is invalid.","%ZEN")
	}
	Quit ""
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set tMethodName = ..%GetValueByName("MethodName")
	Set tScope = ..%GetValueByName("Scope")
	Set tLocation = ..%GetValueByName("Location")
	Set tDescription = ..%GetValueByName("Description")
	Set tCallbackClass = ..%GetValueByName("Callback")
	Set tCallbackMethod = ..%GetValueByName("CallbackMethod")
	Set tTryCatch = ..%GetValueByName("TryCatch")

	#; client methods *have* to be instance methods
	Set:tLocation="client" tScope="instance"

	#; process description
	If (tDescription = "") {
		Write "/// ",tMethodName,!
	}
	Else {
		For i = 1:1:$length(tDescription,$char(13,10)) {
			Set line = $piece(tDescription,$char(13,10),i)
			Write "/// ",line,!
		}
	}

	If (tLocation = "client") {
		Write $S(tScope="class":"ClientClassMethod ",1:"ClientMethod ")
	}
	Else {
		Write $S(tScope="class":"ClassMethod ",1:"Method ")
	}
	Write tMethodName
	
	If (tLocation = "client") {
		Write "("
		Write ")"
		Write " [Language = javascript]",!
		Write "{",!

		If (tTryCatch) {
			Write $C(9),"try {",!
			Write $C(9,9),"alert('Client Method');",!
			Write $C(9,9),"// TODO: implement",!
			Write $C(9),"}",!
			Write $C(9),"catch (ex) {",!
			Write $C(9,9),"zenExceptionHandler(ex,arguments);",!
			Write $C(9),"}",!
		}
		Else {
			Write $C(9),"// TODO: implement",!
			Write $C(9),"alert('Client Method');",!
		}

		Write "}",!
	}
	ElseIf (tLocation = "server") {
		Write "("
		Write ")"
		Write " [ZenMethod]",!
		Write "{",!
		If (tTryCatch) {
			Write $C(9),"Try {",!
			Write $C(9,9),"// TODO: implement",!
			Write $C(9,9),"&js<alert('Server Method');>",!
			Write $C(9),"}",!
			Write $C(9),"Catch(ex) {",!
			Write $C(9,9),"&js<alert('Error in Server method:\n#($ZCVT(ex.DisplayString(),""O"",""JS""))#');>",!
			Write $C(9),"}",!
			Write $C(9),"Quit",!
		}
		Else {
			Write $C(9),"// TODO: implement",!
			Write $C(9),"&js<alert('Server Method');>",!
			Write $C(9),"Quit",!
		}
		Write "}",!
	}
	ElseIf (tLocation = "serverCallback") {
		Set tSpec = $$$comMemberArrayGet(tCallbackClass,$$$cCLASSproperty,tCallbackMethod,$$$cPROPparameter,"FORMALSPEC")
		Set tRetType = $$$comMemberArrayGet(tCallbackClass,$$$cCLASSproperty,tCallbackMethod,$$$cPROPparameter,"RETURNTYPE")
		Write "("
		If (tSpec'="") {
			#; convert internal spec to external
			For p = 1:1:$L(tSpec,",") {
				Set tMod = ""
				Set tItem = $P(tSpec,",",p)
				Set tArg = $P(tItem,":",1)
				Set tType = $P(tItem,":",2)
				If ($E(tArg)="*") {
					Set tMod = "Output "
					Set tArg = $E(tArg,2,$L(tArg))
				}
				ElseIf ($E(tArg)="&") {
					Set tMod = "ByRef "
					Set tArg = $E(tArg,2,$L(tArg))
				}
				Write:p>1 ","
				Write tMod,tArg
				if tType'="" { 
					Write " As ",tType 
				}
			}
		}
		Write ")"
		If (tRetType'="") {
			Write " As " _ tRetType
		}

		Write !
		Write "{",!
		Write $C(9),"// Server-side callback for ",tCallbackClass,":",tCallbackMethod,!
		Write $C(9),"// TODO: implement",!
		Write $C(9),"Quit"
		If (tRetType="%Status") {
			Write " $$$OK"
		}
		ElseIf (tRetType="%Boolean") {
			Write " 1"
		}
		ElseIf (tRetType '= "") {
			Write " """""
		}
		Write !,"}",!
	}
	Else {
		Write "("
		Write ")"
		Write !
		Write "{",!
		Write $C(9),"// TODO: implement",!
		Write $C(9),"Quit",!
		Write "}",!
	}

	Quit $$$OK
}

}
