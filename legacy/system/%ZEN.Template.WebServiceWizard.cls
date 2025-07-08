/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template: New Web Service.
Class %ZEN.Template.WebServiceWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Web Service";

Parameter TEMPLATETITLE = "Web Service Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a new Web Service.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "new";

Parameter TEMPLATEGROUP = "General";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

Parameter HELPID = "GSOAP_service_create_wizard";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body">
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<tabGroup id="tabGroup">
<tab>
<vgroup labelPosition="left" cellStyle="padding: 4px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<text label="Package Name:"
	id="PACKAGE"
	name="Package"
	size="40"
	required="true"
	labelClass="zenRequired"
	hint="Required. Package name for the new class." hintClass="hintText"
	value="MyApp"
	onchange="zenPage.updateState();"
/>

<text label="Class Name:" 
	id="CLASSNAME"
	name="ClassName"
	size="40"
	required="true"
	labelClass="zenRequired"
	hint="Required. Name for the new class." hintClass="hintText"
	value="MyService"
	onchange="zenPage.updateState();"
/>

<text label="Web Service Name:"
	id="SERVICENAME"
	name="SERVICENAME"
	size="40"
	required="true"
	labelClass="zenRequired"
	hint="Required. Name of the Web Service." hintClass="hintText"
	value="MyService"
	onchange="zenPage.updateState();"
/>

<text label="Service Namespace:" 
	id="NAMESPACE"
	name="NAMESPACE"
	size="40"
	hint="URI used for the Web Service (XML) namespace." hintClass="hintText"
	value="http://tempuri.org"
	onchange="zenPage.updateState();"
/>
<textarea label="Service Methods:" 
	id="METHODS"
	name="METHODS"
	rows="4"
	cols="50"
	value="Test"
	hint="Optional list of method names, one per line." hintClass="hintText"
	onchange="zenPage.updateState();"
/>
</vgroup>
</tab>
</tabGroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard creates a new Web Service class."),"<br/>"
	Write $$$TextHTML("Specify the properties of your new Web Service in the form below and then press Finish.")
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Quit $$$OK
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	// give focus to name
	var ctrl = zen('PACKAGE');
	if (ctrl) ctrl.focus();
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return false;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	return false;
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	return this.validate();
}

ClientMethod validate() [ Language = javascript ]
{
  var errorMsg = '';
   var missingMsg = '';
   var invalidMsg = '';
   var valid;

   // test for required fields
   missingMsg = this.testRequired();

   // test for invalid fields
   invalidMsg = this.testValid();
   if ((missingMsg == '') && (invalidMsg == '')) {
      // everything is ok
      return true;
   }
   // build error message
   errorMsg  = '_______________________________________________________________\n\n';
   errorMsg += $$$Text("The form was not saved because of the following error(s).") + '\n';
   errorMsg += $$$Text("Please correct these error(s) and try again.") + '\n';
   errorMsg += '________________________________________________________________\n\n';
   if (missingMsg!= '') {
      errorMsg += $$$Text("The following required field(s) are empty:") + missingMsg + '\n';
   }
   if (invalidMsg != '') {
      errorMsg += $$$Text("The following field(s) contain invalid values:") + invalidMsg + '\n';
   }
   // display error message
   alert(errorMsg);
   return false;
}

ClientMethod testRequired() [ Language = javascript ]
{
	var missingMsg = '';
	var package = zenTrim(zen("PACKAGE").getValue());
	var classname = zenTrim(zen("CLASSNAME").getValue());
	var servicename = zenTrim(zen("SERVICENAME").getValue());
	
   // test for required fields
   if (package == "") {
	   	zen("PACKAGE").setValue(package);
		missingMsg = missingMsg + '\n' + $$$Text("Package Name");
   }
   if (classname == "") {
	   	zen("CLASSNAME").setValue(classname);
  		missingMsg = missingMsg + '\n' + $$$Text("Class Name");
   }
   if (servicename == "") {
	  	zen("SERVICENAME").setValue(servicename);
     	missingMsg = missingMsg + '\n' + $$$Text("Service Name");
   }
   return missingMsg;
}

ClientMethod testValid() [ Language = javascript ]
{
  	var validMsg = '';
	var package = zenTrim(zen("PACKAGE").getValue());
	var classname = zenTrim(zen("CLASSNAME").getValue());
	var servicename = zenTrim(zen("SERVICENAME").getValue());
	
   if (!this.isValidIdent(package,true)) {
      validMsg = validMsg + '\n' + $$$Text("Package Name");
   }

   if (!this.isValidIdent(classname,false)) {
      validMsg = validMsg + '\n' + $$$Text("Class Name");
   }

   if (!this.isValidIdent(servicename,false)) {
      validMsg = validMsg + '\n' + $$$Text("Service Name");
   }
   
   var methods = zen("METHODS").getValue();
   var validMethods = true;
   if (methods) {
	   var a = methods.toString().split('\n');
	   for (var i=0; a.length > i; i++) {
		   if ((a[i].length > 0) && !this.isValidIdent(a[i],false)) {
			   validMethods = false;
		   }
	   }
	   if (!validMethods) {
	      validMsg = validMsg + '\n' + $$$Text("Method Name");
	   }
   }
	return validMsg;
}

ClientMethod isValidIdent(val, dot) [ Language = javascript ]
{
	for (var i=0; val.length > i; i++) {
		var c = val.charAt(i);
		
		if (!((c >= 'a') && (c <= 'z')) &&
			 !((c >= 'A') && (c <= 'Z')) &&
		    !((c >= '0') && (c <= '9')) ) {
			    
			if (!dot) {
				/// on certain enviornment we need to ignore $c(13) here and return false only if it's not
				if (c.indexOf('\r') == -1) return false;
			}
			else {
				if (c != '.') {
					return false;
				}
			}
		}
	}

	return true;
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set tPackage = ..%GetValueByName("Package")
	Set tClassName = ..%GetValueByName("ClassName")
	Set tSERVICENAME = ..%GetValueByName("SERVICENAME")
	Set tNAMESPACE = ..%GetValueByName("NAMESPACE")
	Set tMETHODS = ..%GetValueByName("METHODS")
	Set tSQL = ..%GetValueByName("SQL")
	Set language = $zcvt(%request.Get("Language","cache"),"L")
	Set isCache = $zcvt(language,"L") = "cache"
	Set isObjectscript = $zcvt(language,"L") = "objectscript" 

	Set cls = tPackage_"."_tClassName

	#; create content of new class definition
	Do ..%SetClassName(cls)
	
	Write "/// ",cls,!
	Write "Class ",cls," Extends %SOAP.WebService"
	If '(isCache || isObjectscript) Write " [ Language= "_language_" ]"
	Write !
	Write "{",!!
	Write "/// "_$$$Text("Name of the WebService")_".",!
 	Write "Parameter SERVICENAME = """,(tSERVICENAME),""";",!!

	Write "/// "_$$$Text("TODO: change this to actual SOAP namespace."),!
	Write "/// "_$$$Text("SOAP Namespace for the WebService"),!
	Write "Parameter NAMESPACE = """,(tNAMESPACE),""";",!!
 
	Write "/// "_$$$Text("Namespaces of referenced classes will be used in the WSDL."),!
	Write "Parameter USECLASSNAMESPACES = 1;",!!
 	Set methods = tMETHODS
	For i = 1:1:$length(methods,$char(13,10)) {
		Set m = $piece(methods,$char(13,10),i)

		If m '= "" {
			Write "/// "_$$$Text("TODO: add arguments and implementation."),!
			Write "/// ",m,!
			Write "Method ",m,"() As %String [ WebMethod ]",!
			Write "{",!
			If isCache {
				Write $char(9),"Quit """,m,"""",!
			} Else {
				Write $char(9),"Return """,m,"""",!
			}
			Write "}",!!
		}
	 }
 
	Write "}",!
 
	Quit $$$OK
}

}
