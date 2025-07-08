/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>A pane that contains an AutoForm object.
Class %CSP.Util.FormPane Extends Pane [ ServerOnly = 1, System = 4 ]
{

/// Name of class used to provide Detail or Form view;
Property FormClass As %String(MAXLEN = 128);

/// The object that provides the details to display.
Property FormObject As %RegisteredObject(XMLPROJECTION = "none");

/// Page (URL) to go to when a form is submitted.
Property SubmitPage As %String(MAXLEN = 128);

/// TARGET attribute for submitted form.
Property SubmitTarget As %String(MAXLEN = 128);

/// How to display this Form Page.
Property Display As %String(MAXLEN = 20, VALUELIST = ",form,table");

/// If true, display this form using the Dynamic form viewer.
Property Dynamic As %Boolean;

/// An optional list of buttons displayed along the bottom of a form.
Property Buttons As list Of FormButton(XMLITEMNAME = "Button");

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As PageInstance) As %Status
{
	If (..Align '= "") {
		&html<<div align="#(..Align)#">>
	}

	Do ..DrawCommands(pInstance)

	If (..Text '= "") {
		// show descriptive text
		&html<<div class="Text1" >#(##class(%CSP.Page).EscapeHTML(..LocalizeText(..Text)))#</div><br>>
	}
	
	Do ..DrawCommandForm(pInstance)
	
	// !!! Get ID Values from page and display the form object
	Merge tID = pInstance.IDValues
	
	If ($IsObject(..FormObject)) {
		// ask form to draw itself
		If (..Display = "table") {
			If (..Dynamic) {
				Do ##class(AutoFormDynamic).DrawHTMLTable(..FormObject,.tID)
			}
			Else {
				Do ..FormObject.DrawHTMLTable(..FormObject,.tID)
			}
		}
		Else {
			If (..Dynamic) {
				Do ##class(AutoFormDynamic).DrawHTMLForm(..FormObject,.tID,..SubmitPage,,..SubmitTarget)
			}
			Else {
				Kill btn
				
				For n = 1:1:..Buttons.Count() {
					Set tButton = ..Buttons.GetAt(n)
					Set btn(n) = tButton
				}

				Do ..FormObject.DrawHTMLForm(..FormObject,.tID,..SubmitPage,.btn,..SubmitTarget)
			}
		}
	}
	
	If (..Align '= "") {
		&html<</div>>
	}

	Quit $$$OK
}

Method OnGenerateCode() As %String
{
	Set code = ""
	If (..Display '= "") {
		Set code = code _ " Set tPane.Display = " _ ..QuoteCOS(..Display) _ $$$EOL
	}
	If (..Dynamic '= "") {
		Set code = code _ " Set tPane.Dynamic = " _ +..Dynamic _ $$$EOL
	}
	If (..SubmitPage '= "") {
		Set code = code _ " Set tPane.SubmitPage = " _ ..QuoteCOS(..SubmitPage) _ $$$EOL
	}
	If (..SubmitTarget '= "") {
		Set code = code _ " Set tPane.SubmitTarget = " _ ..QuoteCOS(..SubmitTarget) _ $$$EOL
	}
	If (..FormClass '= "") {
		Set code = code _ " Set tPane.FormClass = " _ ..QuoteCOS(..FormClass) _ $$$EOL
		Set code = code _ $$$EOL
		Set code = code _ " // Create instance of object used for form" _ $$$EOL
		
		Set code = code _ " Merge tID = pInstance.IDValues" _ $$$EOL

		If (..Dynamic) {
			// create instance using %OpenId (test for persistent)
			If ($$$comClassKeyGet(..FormClass,$$$cCLASSclasstype) = "persistent") {
				Set code = code _ " Set tPane.FormObject = $classmethod(" _ ..QuoteCOS(..FormClass) _ ",""%OpenId"",$G(tID(1)))" _ $$$EOL
			}
			Set code = code _ " If ('$IsObject(tPane.FormObject)) { Set tPane.FormObject = $classmethod(" _ ..QuoteCOS(..FormClass) _ ",""%New"") }" _ $$$EOL
		}
		Else {
			Set code = code _ " Set tPane.FormObject = $classmethod(" _ ..QuoteCOS(..FormClass) _ ",""CreateInstance"",.tID)" _ $$$EOL
		}
		Set code = code _ $$$EOL
	}

	// buttons
	If (..Buttons.Count() > 0) {
		Set code = code _ " // buttons" _ $$$EOL
	}

	For i = 1:1:..Buttons.Count() {
		Set tButton = ..Buttons.GetAt(i)
		Set code = code _ tButton.GenerateCode()
		Set code = code _ " Do tPane.Buttons.Insert(tButton)" _ $$$EOL
		Set code = code _ $$$EOL
	}
	Set code = code _ $$$EOL


	Quit code
}

}
