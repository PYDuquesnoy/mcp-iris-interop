/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template: New %Installer.
Class %Installer.InstallerWizard Extends %ZEN.Template.studioTemplate [ System = 4 ]
{

Parameter TEMPLATENAME = "%Installer Manifest";

Parameter TEMPLATETITLE = "%Installer Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a new %Installer Manifest.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "new";

Parameter TEMPLATEGROUP = "General";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

Parameter HELPID = "GSTU_instdist_installer";

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
	value="MyInstaller"
	onchange="zenPage.updateState();"
/>

<text label="Manifest Name:"
	id="MANIFEST"
	name="Manifest"
	size="40"
	required="true"
	labelClass="zenRequired"
	hint="Required. Name of the %Installer Manifest." hintClass="hintText"
	value="MyManifest"
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
	Write $$$TextHTML("This wizard creates a new %Installer Manifest class."),"<br/>"
	Write $$$TextHTML("Specify the properties of your new %Installer Manifest in the form below and then press Finish.")
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
	var manifest = zenTrim(zen("MANIFEST").getValue());
	
   // test for required fields
   if (package == "") {
	   	zen("PACKAGE").setValue(package);
		missingMsg = missingMsg + '\n' + $$$Text("Package Name");
   }
   if (classname == "") {
	   	zen("CLASSNAME").setValue(classname);
  		missingMsg = missingMsg + '\n' + $$$Text("Class Name");
   }
   if (manifest == "") {
	  	zen("MANIFEST").setValue(manifest);
     	missingMsg = missingMsg + '\n' + $$$Text("Manifest Name");
   }
   return missingMsg;
}

ClientMethod testValid() [ Language = javascript ]
{
  	var validMsg = '';
	var package = zenTrim(zen("PACKAGE").getValue());
	var classname = zenTrim(zen("CLASSNAME").getValue());
	var manifest = zenTrim(zen("MANIFEST").getValue());
	
   if (!this.isValidIdent(package,true)) {
      validMsg = validMsg + '\n' + $$$Text("Package Name");
   }

   if (!this.isValidIdent(classname,false)) {
      validMsg = validMsg + '\n' + $$$Text("Class Name");
   }

   if (!this.isValidIdent(manifest,false)) {
      validMsg = validMsg + '\n' + $$$Text("Manifest Name");
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
				return false;
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
	Set tManifest = ..%GetValueByName("Manifest")
	Set language = $zcvt(%request.Get("Language","cache"),"L")
 	Set isCache = $zcvt(language,"L") = "cache"

	Set cls = tPackage_"."_tClassName

	#; create content of new class definition
	Do ..%SetClassName(cls)
	
	Write "Include %occInclude",!!
	Write "/// %Installer Manifest ",cls,!
	Write "Class ",cls,!,"{",!!
	
	Write "/// "_$$$Text("Manifest Definition")_".",!
 	Write "XData ",tManifest," [ XMLNamespace = INSTALLER ]",!,"{",!
 	Write "<Manifest>",!!
 	Write "<Namespace>",!!
 	Write "<Configuration>",!!
 	Write "<Database>",!!
 	Write "<!-- Your Manifest code here -->",!!
 	Write "</Database>",!!
 	Write "</Configuration>",!!
 	Write "</Namespace>",!!
 	Write "</Manifest>",!,"}",!!
 	
 	Write "/// "_$$$Text("This is a method generator whose code is generated by XGL")_".",!
 	Write "ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]",!
 	Write "{",!
 	Write " #; "_$$$Text("Let our XGL document generate code for this method")_".",!
 	Write " Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, """,tManifest,""")",!
 	Write "}",!!,"}",!
  
	Quit $$$OK
}

}
