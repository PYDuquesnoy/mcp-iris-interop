/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This is a version of AutoForm that generates its dialog and forms <I>dynamically</I>,
/// that is, it calculates what properties to display at run-time using
/// the meta-information for the provided object.<br>
/// This is not as efficient as the generated case, but is useful for some
/// applications.
Class %CSP.Util.AutoFormDynamic Extends (%RegisteredObject, %CSP.Util.AutoForm) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// Draw an HTML table for an arbitary object.<br>
/// <var>pObj</var> is an instance of object that
/// provides the definition and values for the table.<br>
/// This table is dynamic in that the table to display is calculated at runtime.
ClassMethod DrawHTMLTable(pObj As %RegisteredObject, ByRef pID As %String) As %Status
{
	// header
	&html<<table class="AutoFormTable" border="0" cellspacing="0" cellpadding="0">>
	// &html<<tr class="AutoFormTableTitle"><th colspan="2">Property</th><th>Value</th></tr>>

	If ('$IsObject(pObj)) {
		Quit $$$ERROR($$$GeneralError,"Invalid Object")
	}
	Set tClassName = pObj.%ClassName(1)
		
	Set sc = ##class(%CSP.Util.AutoFormGenerator).GenerateHTMLTable(tClassName,"",pObj)
	Quit:$$$ISERR(sc) sc

	// footer
	&html<</table>>
	&html<</div>>
	Quit $$$OK
}

/// Draw an HTML form for this form object.<br>
/// <var>pObj</var> is an instance of the form object that
/// provides the initial values for the form.
ClassMethod DrawHTMLForm(pObj As %RegisteredObject, ByRef pID As %String, pActionURL As %String = "", ByRef pButtons As FormButton, pTarget As %String = "") As %Status
{
	If ('$IsObject(pObj)) {
		Quit $$$ERROR($$$GeneralError,"Invalid Object")
	}
	Set tClassName = pObj.%ClassName(1)

	&html<<form action="#(pActionURL)#" method="POST" name="theForm" target="#(pTarget)#">>
	&html<<input type="hidden" name="$DYNAMIC" value="1">>
	&html<<input type="hidden" name="$CLASS" value="#(tClassName)#">>
	&html<<input type="hidden" name="$FRAME" value="#(pTarget)#">>
	Set id = "" For { Set id=$O(pID(id))  Quit:""=id
		&html<<input type="hidden" name="$ID#(id)#" value="#($ZCVT(pID(id),"O","HTML"))#">>
	}
	&html<<table class="AutoForm">>
	
	// write out properties
	Set tCol = 0
	Set sc = ##class(%CSP.Util.AutoFormGenerator).GenerateHTMLForm(tClassName,"",.tCol,..#FORMCOLUMNS,pObj)
	Quit:$$$ISERR(sc) sc

	// Draw the buttons for a form...
	&html<<tr><td class="AutoFormLabel">&nbsp;</td><td>>
	If ('$D(pButtons)) {
		// create default buttons
		#; Set lSave = $ZCVT($$$GetSysMessage($$$SessionLanguage,"%CSPSearch","SaveBtn","Save"),"O","HTML")
		Set lSave = ##class(%CSP.Util.AutoFormGenerator).LocalizeText("@%Utility:Save@Save")
		#; Set lCancel = $ZCVT($$$GetSysMessage($$$SessionLanguage,"%CSPSearch","CancelBtn","Cancel"),"O","HTML")
		Set lCancel = ##class(%CSP.Util.AutoFormGenerator).LocalizeText("@%Utility:Cancel@Cancel")
		// submit button
			&html<<input class="AutoFormButton" type="SUBMIT" name="$AUTOFORM_SAVE" value="#(lSave)#">&nbsp;
			<input class="AutoFormButton" type="SUBMIT" name="$AUTOFORM_CANCEL" value="#(lCancel)#">>
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
	&html<</td></tr>>
	&html<</table>>
	&html<</form>>
	Quit $$$OK
}

ClassMethod Submit(pRequest As %CSP.Request, pSubmit As %String) As %Status
{
	Merge tID = pRequest.Data("$ID")
	Set sc = $$$OK

	Set obj = ..ProcessSubmit(pRequest,.tID)
	
	If ($IsObject(obj) && (pSubmit = "$AUTOFORM_SAVE")) {
		Set sc = obj.%Save()
	}
	Quit sc
}

/// Takes submitted data for a form and returns an instance of AutoForm object
ClassMethod ProcessSubmit(pRequest As %CSP.Request, ByRef pID As %String = "", Output pErrorMsg As %String, pPersistentOnly As %Boolean = 1) As AutoForm
{
	// get class name from submit data
	Set tClassName = pRequest.Data("$CLASS",1)
	
	Set tClsType = $$$comClassKeyGet(tClassName,$$$cCLASSclasstype)

	// create object instance
	Set tObj = $$$NULLOREF
	If (tClsType = "persistent") {
		Set tObj = $classmethod(tClassName,"%OpenId",$G(pID(1)))
	}
	If ('$IsObject(tObj)) {
		Set tObj = $classmethod(tClassName,"%New")
	}
	If ('$IsObject(tObj)) {
		Quit $$$NULLOREF
	}
	// get values from %request object
	Set sc = ##class(%CSP.Util.AutoFormGenerator).GenerateSubmitCode(tClassName,"",tObj)
	Do tObj.%NormalizeObject()

	// do not return the object unless it can be saved: default implementation cannot handle it.
	Quit:pPersistentOnly&&(tClsType="persistent") ""
	Quit tObj
}

}
