/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Import %CSP.Util

Include %systemInclude

IncludeGenerator %systemInclude

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This class provides a mechanism to automatically generate HTML forms (using CSP).
/// Subclasses of this class can automatically generate HTML forms and tables.
Class %CSP.Util.AutoForm [ Abstract, CompileAfter = %CSP.Util.AutoFormGenerator, ServerOnly = 1, System = 4 ]
{

/// Default domain for the Portal's localization.
Parameter DOMAIN = "%Utility";

/// If true (1) then this is a specialized type of form that only 
/// displays submit buttons and no INPUT fields.
Parameter COMMANDFORM = 0;

/// Number of columns used to layout forms for this class
Parameter FORMCOLUMNS = 1;

/// Common expiration date used for cookies
/// Test if an AutoForm is being submitted
/// If so, process it and return the name of the submit button
/// or "" if there is not a submit.
/// For a AUTOFORM_CANCEL, return "$AUTOFORM_CANCEL" without processing...
ClassMethod DoSubmit() As %String
{
	Set tSubmit = ""
	
	// all autoform submit buttons start with $AUTOFORM_
	// see if we got one
	Set key = $O(%request.Data("$AUTOFORM_"))

	If ($E(key,1,9) = "$AUTOFORM") {
		// special case for cancel
		If ($D(%request.Data("$AUTOFORM_CANCEL",1))) {
			Quit "$AUTOFORM_CANCEL"
		}
		Else {
			Set tSC = ..DispatchSubmit(key)
			If ($$$ISOK(tSC)) {
				Set tSubmit = key
			}
		}
	}
	
	Quit tSubmit
}

/// This method invokes a submit on the appropriate form class.
/// Do not call this method directly; use DoSubmit instead.
ClassMethod DispatchSubmit(pSubmit As %String) As %Status
{
	Set tSC = $$$OK

	Set tSubmitClass = $G(%request.Data("$CLASS",1))
	If (tSubmitClass '= "") {
		If ($D(%request.Data("$DYNAMIC",1))) {
			// this is a submit to a dynamic form
			Set tSC = ##class(%CSP.Util.AutoFormDynamic).Submit(%request,pSubmit)
		}
		Else {
			// static form
			Set tSC = $classmethod(tSubmitClass,"Submit",%request,pSubmit)
		}
	}
	
	Quit tSC
}

/// Create an instance of the AutoForm object using the provided ID value(s).
/// This is overridden by subclasses.<br>
/// The default implementation will perform an OpenId if the AutoForm is a persistent object.
ClassMethod CreateInstance(ByRef pID As %String) As AutoForm [ CodeMode = objectgenerator ]
{
	// do not invoke this for ourself...
	If (%class.Name = "%CSP.Util.AutoForm") {
		Do %code.WriteLine(" Quit """"")
		Quit $$$OK
	}

	If (%class.ClassType = "persistent") {
		Do %code.WriteLine(" Set tObj = ..%OpenId($G(pID(1)))")
		Do %code.WriteLine(" If ('$IsObject(tObj)) { Set tObj = ..%New() }")
		Do %code.WriteLine(" Quit tObj")
	}
	Else {
		Do %code.WriteLine(" Quit ..%New()")
	}

	Quit $$$OK
}

/// This callback is called when this form is submitted.
/// <var>pID</var> is the ID value associated with the form.
/// The default implementation will perform a Save if the AutoForm is a persistent object.<br>
/// <var>pSubmit</var> is the name of the submit button (i.e., $AUTOFORM_SAVE).
Method OnSubmit(ByRef pID As %String, pSubmit As %String) As %Status [ CodeMode = objectgenerator ]
{
	// do not invoke this for ourself...
	If (%class.Name = "%CSP.Util.AutoForm") {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	If (%class.ClassType = "persistent") {
		Do %code.WriteLine(" If (pSubmit = ""$AUTOFORM_SAVE"") {")
		Do %code.WriteLine(" 	Quit ..%Save()")
		Do %code.WriteLine(" }")
	}
	Do %code.WriteLine(" Quit $$$OK")

	Quit $$$OK
}

/// Draw an HTML form for this form object.<br>
/// <var>pObj</var> is an instance of the form object that
/// provides the initial values for the form.<br>
/// <var>pActionURL</var> is the URL to submit this form to.<br>
/// <var>pButtons</var> is an array of submit buttons to display for the form. If 
/// not provided, the default <I>Save</I> and <I>Cancel</I> buttons are shown.
/// <var>pButtons</var> is an integer-subscripted array of <class>FormButton</class> objects.
ClassMethod DrawHTMLForm(pObj As %RegisteredObject, ByRef pID As %String, pActionURL As %String = "", ByRef pButtons As FormButton, pTarget As %String = "") As %Status [ CodeMode = objectgenerator ]
{
	// test if object is valid
	//Do %code.WriteLine(" If ('$IsObject(pObj)) {")
	//Do %code.WriteLine(" 	Quit $$$ERROR($$$GeneralError,""Invalid object."")")
	//Do %code.WriteLine(" }")
	
	// generate FORM/TABLE headers
	Do %code.WriteLine(" &html<<form action=""#(pActionURL)#"" method=""POST"" name=""theForm"" target=""#(pTarget)#"">>")

	Do %code.WriteLine(" Write ##class(%CSP.Page).InsertHiddenFields(pActionURL)")
	Do %code.WriteLine(" &html<<input type=""HIDDEN"" name=""$CLASS"" value=""" _ %class.Name _ """>>")
	Do %code.WriteLine(" &html<<input type=""HIDDEN"" name=""$FRAME"" value=""#(pTarget)#"">>")
	Do %code.WriteLine(" &html<<input type=""HIDDEN"" name=""$FORMURL"" value=""#(%request.URL)#"">>")
	Do %code.WriteLine(" &html<<input type=""HIDDEN"" name=""$NAMESPACE"" value=""#($ZCVT($G(%request.Data(""$NAMESPACE"",1)),""O"",""HTML""))#"">>")

	Do %code.WriteLine(" Set id = $O(pID(""""))")
	Do %code.WriteLine(" While (id '= """") {")
	Do %code.WriteLine(" 	&html<<input type=""HIDDEN"" name=""$ID#(id)#"" value=""#($ZCVT(pID(id),""O"",""HTML""))#"">>")
	Do %code.WriteLine(" 	Set id = $O(pID(id))")
	Do %code.WriteLine(" }")
	
	// do not create fields for ourself...
	If ('$G(%parameter("COMMANDFORM"))) {
		If (%class.Name '= "%CSP.Util.AutoForm") {
			Do %code.WriteLine(" &html<<table class=""AutoForm"">>")
		
			// now generate HTML for all of our properties
			Set tCol = 0
			Set sc = ##class(%CSP.Util.AutoFormGenerator).GenerateHTMLForm(%class.Name,%code,.tCol,$G(%parameter("FORMCOLUMNS"),1))
			If ($$$ISERR(sc)) {
				Quit sc
			}

			// if there is a current form error, display it
			Do %code.WriteLine(" Set tError = ..GetFormError()")
			Do %code.WriteLine(" If (tError '= """") {")
			Do %code.WriteLine("  &html<<tr><td class=""AutoFormLabel"">&nbsp;</td><td style=""border: 1px black solid; font-weight: bold; color: red; background: yellow;"">#($zconvert(tError,""O"",""HTML""))#</td></tr>>")
			Do %code.WriteLine(" }")

			Do %code.WriteLine(" &html<<tr><td class=""AutoFormLabel"">&nbsp;</td>>")
			Do %code.WriteLine(" &html<<td>>") // Do %code.WriteLine(" &html<<td class=""AutoFormButton"">>")  HCR213
		}
	}
	Else {
		// command form
	}
	
	// test for user-provided buttons method
	If $$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnDefineButtons",$$$cMETHrunnable) {
		Do %code.WriteLine(" If ('$D(pButtons)) {")
		Do %code.WriteLine(" 	Do ..OnDefineButtons(.pButtons)")
		Do %code.WriteLine(" }")
	}
	
	// button(s)
	Do %code.WriteLine(" Do ..DrawFormButtons(.pButtons)")
	
	If ('$G(%parameter("COMMANDFORM"))) {
		If (%class.Name '= "%CSP.Util.AutoForm") {
			Do %code.WriteLine(" &html<</td></tr></table>>")
		}
	}
	Do %code.WriteLine(" &html<</form>>")
	Do %code.WriteLine(" Quit $$$OK")
	
	Quit $$$OK
}

/// Subclasses can override this to redefine the buttons for a form
ClassMethod OnDefineButtons(ByRef pButtons As FormButton) [ Abstract ]
{
}

/// Draw the buttons for a form...
ClassMethod DrawFormButtons(ByRef pButtons As FormButton)
{
	If ('$D(pButtons)) {
		// default
		Set lSave = $ZCVT($$$GetSysMessage($$$SessionLanguage,"%CSPSearch","SaveBtn","Save"),"O","HTML")
		Set lCancel = $ZCVT($$$GetSysMessage($$$SessionLanguage,"%CSPSearch","CancelBtn","Cancel"),"O","HTML")
		&html<<input class="AutoFormButton" TYPE="SUBMIT" name="$AUTOFORM_SAVE" value="#(lSave)#">&nbsp;>
		&html<<input class="AutoFormButton" TYPE="SUBMIT" name="$AUTOFORM_CANCEL" value="#(lCancel)#">>
	} Else {
		// display contents of button array
		Set n = "" For { Set n = $O(pButtons(n))  Quit:""=n
			Set tButton = pButtons(n)
			If ($IsObject(tButton)) {
				Set tOnClick = ""
				Set tType = "submit"

				If ((tButton.Type = "popup") && (tButton.HREF '= "")) {
					// popup
					If (tButton.Confirm = "") {
						Set tType = "button"
						Set tOnClick = "onclick=""launchPopupWindow(" _ ##class(%CSP.Page).QuoteJS(tButton.HREF) _ ");"""
					} Else {
						// popup & confirm
						Set tOnClick = "onclick=""if (confirm(" _ ##class(%CSP.Page).QuoteJS(tButton.Confirm) _ ")) { launchPopupWindow(" _ ##class(%CSP.Page).QuoteJS(tButton.HREF) _ "); return true; } else { return false; }"""
					}
				} Else {
					// std button
					If (tButton.Confirm = "") {
						Set tOnClick = ""
					} Else {
						Set tOnClick = "onclick=""return confirm(" _ ##class(%CSP.Page).QuoteJS(tButton.Confirm) _ ");"""
					}
				}
				// test for OnClick
				If ((tOnClick = "") && (tButton.OnClick '= "")) {
					Set tOnClick = "onclick=" _ ##class(%CSP.Util.Pane).QuoteCOS(tButton.OnClick)
					Set tType = "button"
				}
				Set tButtonCaption = $ZCVT(tButton.Caption,"O","HTML")
				&html<<input class="AutoFormButton" type="#(tType)#" 
						name="#(tButton.Name)#" 
						value="#(tButtonCaption)#" #(tOnClick)#>&nbsp;>
			}
		}
	}
}

/// Draw an HTML detail table for this form object.<br>
/// <var>pObj</var> is an instance of the form object that
/// provides the values for the table.
ClassMethod DrawHTMLTable(pObj As %RegisteredObject, ByRef pID As %String) As %Status [ CodeMode = objectgenerator ]
{
	// do not invoke this for ourself...
	If (%class.Name = "%CSP.Util.AutoForm") {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	// test type of object
	Do %code.WriteLine(" If ('$IsObject(pObj)) {")
	Do %code.WriteLine(" 	Quit $$$ERROR($$$GeneralError,""Invalid object."")")
	Do %code.WriteLine(" }")

	Do %code.WriteLine(" &html<<table class=""AutoFormTable"" border=""0"" cellspacing=""0"" cellpadding=""0"">>")
	// Do %code.WriteLine(" &html<<tr class=""AutoFormTableTitle""><th colspan=""2"">Property</th><th>Value</th></tr>>")
	
	// now generate HTML for all of our properties
	Set sc = ##class(%CSP.Util.AutoFormGenerator).GenerateHTMLTable(%class.Name,%code)
	If ($$$ISERR(sc)) {
		Quit sc
	}

	// footer
	Do %code.WriteLine(" &html<</table>>")
	Do %code.WriteLine(" Quit $$$OK")

	Quit $$$OK
}

/// Construct an HTML string defining a combo box for the given query.<br>
/// <var>pName</var> is the name to use for the SELECT control.<br>
/// <var>pValue</var> is the current value of the property.<br>
/// Returns the HTML to display.<br>
ClassMethod GetComboBoxHTML(pValue As %String, pName As %String, pClass As %String, pQuery As %String, pCaptionColumn As %String, pValueColumn As %String = "", pP1 As %String = "", pP2 As %String = "", pP3 As %String = "") As %String
{
	Set tSC = $$$OK
	Set tHTML = ""
	
	If (pValueColumn = "") {
		Set pValueColumn = pCaptionColumn
	}
	
	Do {
		Set tRS = ##class(%ResultSet).%New()
		Set tRS.ClassName = pClass
		Set tRS.QueryName = pQuery

		If (pP3 '= "") {	
			Set tSC = tRS.Execute(pP1,pP2,pP3)
		}
		ElseIf (pP2 '= "") {	
			Set tSC = tRS.Execute(pP1,pP2)
		}
		ElseIf (pP1 '= "") {	
			Set tSC = tRS.Execute(pP1)
		}
		Else {
			Set tSC = tRS.Execute()
		}

		If ($$$ISERR(tSC)) Quit
		
		Set tHTML = "<select name="""_ pName _ """><option value="""">"
		
		While (tRS.Next() && ($L(tHTML)<30000)) {
			Set tVal = $G(tRS.Data(pValueColumn))
			Set tCaption = $G(tRS.Data(pCaptionColumn))
			Set tHTML = tHTML _ "<option " _ $S(tVal = pValue:"selected ",1:"") _ "value=""" _ $ZCVT(tVal,"O","HTML") _ """>" _ $ZCVT(tCaption,"O","HTML")
		}

		Set tHTML = tHTML _ "</select>"
		
	} While (0)
	
	If ($$$ISERR(tSC)) {
		Set tHTML = "Invalid Query"
	}
	
	Quit tHTML
}

/// Called by the page handler when a form is submitted.<br>
/// <var>pSubmit</var> is the name of the submit button (i.e., $AUTOFORM_SAVE).
ClassMethod Submit(pRequest As %CSP.Request, pSubmit As %String) As %Status
{
	// get ID values from request
	If ($IsObject($G(pRequest))) {
		Set n = 1
		While ($D(pRequest.Data("$ID"_n,1))) {
			Set tID(n) = pRequest.Data("$ID"_n,1)
			Set n = n + 1
		}
	}

	Set tSC = $$$OK
	Do {
		// copy request vars into object instance
		Set obj = ..ProcessSubmit(pRequest,.tID,.tErrorMsg)
		If ($G(tErrorMsg) '= "") {
			// throw error
			Set tSC = $$$ERROR($$$GeneralError,"Invalid values in form: "_tErrorMsg)
			Quit
		}
	
		// call user callback
		If ($IsObject(obj)) {
			Set tSC = obj.OnSubmit(.tID,pSubmit)
			If $$$ISERR(tSC) {
				Set tMsg = ""
				Do $System.Status.DecomposeStatus(tSC,.tErr)
				Set n = $Order(tErr(""))
				While (n '= "") {
					Set tMsg = tMsg _ $S(tMsg="":"",1:"<br>") _ $P(tErr(n),":",2)
					Set n = $Order(tErr(n))
				}
				Do ..SetFormError(tMsg)
			}
		}

	} While(0)
	
	Quit tSC
}

/// Takes submitted data for a form and returns an instance of AutoForm object
ClassMethod ProcessSubmit(pRequest As %CSP.Request, ByRef pID As %String = "", Output pErrorMsg As %String) As AutoForm [ CodeMode = objectgenerator ]
{
	// do not invoke this for ourself...
	If (%class.Name = "%CSP.Util.AutoForm") {
		Do %code.WriteLine(" Quit """"")
		Quit $$$OK
	}

	Do %code.WriteLine(" Set error = """"")
	Do %code.WriteLine(" Set tObj = ..CreateInstance(.pID)")
	Do %code.WriteLine(" If ('$IsObject(tObj)) { Quit """" } ")

	// Generate code to get values from submit
	Set sc = ##class(%CSP.Util.AutoFormGenerator).GenerateSubmitCode(%class.Name,%code)
	If ($$$ISERR(sc)) {
		Quit sc
	}
	
	// test for error found by submit code
	Do %code.WriteLine(" If ($G(error) '= """") {")
	// get rid of \n in error message
	Do %code.WriteLine(" 	Set tMsg = """"")
	Do %code.WriteLine(" 	For n=1:1:$L(error,""\n"") {")
	Do %code.WriteLine(" 	 Set tMsg = tMsg _ $S(tMsg="""":"""",1:""<br>"") _ $P(error,""\n"",n)")
	Do %code.WriteLine(" 	}")
	
	Do %code.WriteLine(" 	Do ..SetFormError(tMsg)")
	Do %code.WriteLine(" 	Set pErrorMsg = tMsg")
	Do %code.WriteLine(" }")

	Do %code.WriteLine(" Do tObj.%NormalizeObject()")
	Do %code.WriteLine(" Quit tObj")

	Quit $$$OK
}

/// Set a error message to be displayed within an AutoForm.
ClassMethod SetFormError(pMsg As %String)
{
	// place message into URL to survive re-submit
	Set %response.Context("$AUTOFORMERROR") = pMsg

	// force redirect back to page with error
	Set %response.Redirect = $G(%request.Data("$FORMURL",1))
	
	// make sure we do not lose submitted values
	Set key = $O(%request.Data(""))
	While (key '= "") {
		If ($E(key,1,1) '= "$") {
			Set %response.Context(key) = $G(%request.Data(key,1))
		}
		Set key = $O(%request.Data(key))
	}
}

/// Get error message to be displayed within an AutoForm.
ClassMethod GetFormError() As %String [ CodeMode = expression ]
{
$G(%request.Data("$AUTOFORMERROR",1))
}

}
