/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Create New Table 
Class %CSP.UI.SQL.TableForm Extends (%RegisteredObject, %CSP.Util.AutoForm) [ Inheritance = right, System = 4 ]
{

/// Schema
Property SchemaName As %String;

/// Table Name
Property TableName As %String(MAXLEN = 30);

/// Number of Columns
Property NumberOfColumns As %Integer;

/// Draw an HTML form for this form object.<BR>
/// <var>pObj</var> is an instance of the form object that
/// provides the initial values for the form.<BR>
/// <var>pActionURL</var> is the URL to submit this form to.<BR>
/// <var>pButtons</var> is an array of submit buttons to display for the form. If 
/// not provided, the default <I>Save</I> and <I>Cancel</I> buttons are shown.
/// <var>pButtons</var> is an integer-subscripted array of <class>FormButton</class> objects.
ClassMethod DrawHTMLForm(pObj As %RegisteredObject, ByRef pID As %String, pActionURL As %String = "", ByRef pButtons As FormButton, pTarget As %String = "") As %Status [ CodeMode = objectgenerator ]
{
	
	// generate FORM/TABLE headers
	Do %code.WriteLine(" &html<<FORM ACTION=""#(pActionURL)#"" METHOD=""POST"" NAME=""theForm"" TARGET=""#(pTarget)#"">>")

	Do %code.WriteLine(" &html<<INPUT TYPE=""HIDDEN"" NAME=""$CLASS"" VALUE=""" _ %class.Name _ """>>")
	Do %code.WriteLine(" &html<<INPUT TYPE=""HIDDEN"" NAME=""$FRAME"" VALUE=""#(pTarget)#"">>")

	Do %code.WriteLine(" Set id = $O(pID(""""))")
	Do %code.WriteLine(" While (id '= """") {")
	Do %code.WriteLine(" 	&html<<INPUT TYPE=""HIDDEN"" NAME=""$ID#(id)#"" VALUE=""#($ZCVT(pID(id),""O"",""HTML""))#"">>")
	Do %code.WriteLine(" 	Set id = $O(pID(id))")
	Do %code.WriteLine(" }")
	
	// do not create fields for ourself...
	If ('$G(%parameter("COMMANDFORM"))) {
		If (%class.Name '= "%CSP.Util.AutoForm") {
			Do %code.WriteLine(" &html<<TABLE CLASS=""AutoForm"">>")		
			// now generate HTML for all of our properties
			Set sc = ##class(%CSP.Util.AutoFormGenerator).GenerateHTMLForm(%class.Name,%code)
			If ($$$ISERR(sc)) {
				Quit sc
			}
			Do %code.WriteLine(" &html<<TR><TD CLASS=""AutoFormLabel"">&nbsp;</TD>>")
			Do %code.WriteLine(" &html<<TD CLASS=""AutoFormButton"">>")
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
			Do %code.WriteLine(" &html<</TD></TR></TABLE>>")
		}
	}
	Do %code.WriteLine(" &html<</FORM>>")
	Do %code.WriteLine(" Quit $$$OK")
	
	Quit $$$OK
}

ClassMethod CreateInstance(ByRef pID As %String) As AutoForm
{
	Set tObj = ..%New()
	Set tObj.SchemaName = %request.Get("$ID1")
	Set tObj.TableName = "NewTable"
	Set tObj.NumberOfColumns = "5"

	Quit tObj
}

Method OnSubmit(ByRef pID As %String, pSubmit As %String) As %Status
{

        // pID contains $ID values from URL
		$$$ChangeNamespace

		Set tMsg = ..SchemaName
        If (pSubmit = "$AUTOFORM_SAVE") {
	        //If $G(pID(1))'="" {
		        Set sAction = "Create Table "
    			Set sQueryText = sAction _ ..SchemaName_"."_..TableName _ " ( namelast char (30))"
 				Set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
	 			Set tSC = rs.Prepare(sQueryText)
				If (tSC'=1) {
					Do $System.Status.DecomposeStatus(tSC,.tMsg)
					&html<<DIV CLASS="ErrorBox" ALIGN="center"><B>Invalid query:</B><BR><BR>#($ZCVT(tMsg(1),"O","HTML"))#<BR></DIV>>
		 		//	Write "<script language='javascript'>alert(",tMsg,");</script>"
				} Else {
					Do rs.Execute()
				} 
	        //}
        }

        Quit $$$OK
}

/// define standard Login buttons
ClassMethod OnDefineButtons(ByRef pButtons As FormButton)
{
	Set pButtons(1) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(1).Name = "$AUTOFORM_SAVE"
	Set pButtons(1).Caption = " Continue "
}

}
