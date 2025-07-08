/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Import %CSP.Util

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Describes a particular pane within an AutoPage. 
/// This is an abstract class; its subclasses perform the real work.
Class %CSP.Util.Pane Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

Parameter XMLNAME = "Pane";

/// Transient: name of the pane/frame this pane is being used for
Property Name As %String(MAXLEN = 100, XMLPROJECTION = "none");

/// Test for this pane.
/// All panes include this property.
Property Text As %String(MAXLEN = 500);

/// Optional URL to display instead of this pane (for frame-pages)
Property URL As %String(MAXLEN = 256, XMLNAME = "url", XMLPROJECTION = "element");

/// Optional Style Sheet for a pane; Set to "none" to supress style-sheet for a fram
Property FrameStyle As %String(MAXLEN = 50, XMLNAME = "FrameStyle");

/// Arbitrary array of styles (name/value pairs).
/// All panes include this property.
Property Styles As array Of %String(XMLKEYNAME = "name", XMLNAME = "PaneStyle", XMLPROJECTION = "ELEMENT");

/// A list of commands; these are actions that 
/// are typically displayed along the top of the pane.
Property Commands As list Of Action;

/// Name of class used to provide an option CommandForm: a form 
/// containing command buttons.<br>
/// Note: there is no support for dynamic command forms.
Property CommandFormClass As %String(MAXLEN = 128);

/// Used to hold the object instance for the command form.
Property CommandFormObject As %RegisteredObject(XMLPROJECTION = "none");

/// Page (URL) to go to when the command form is submitted.
Property CommandSubmitPage As %String(MAXLEN = 128);

/// Suggestion for how to align this pane; Actual implementation is up
/// to the subclass doing the rendering
Property Align As %String(MAXLEN = 10, VALUELIST = ",left,right,center");

/// Overwritten by subclasses to draw anything this pane needs for the HEAD section.
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	Quit $$$OK
}

/// Overwritten by subclasses to draw anything this pane needs for the BODY section.
Method DrawBODY(pInstance As PageInstance) As %Status
{

	&html<<div class="Text1">#(##class(%CSP.Page).EscapeHTML(..LocalizeText(..Text)))#</div>>
	
	Do ..DrawCommandForm(pInstance)
	
	#; JMD269-- display error for form within frameset
	If $D(^IRIS.Temp.AutoFormError(%session.SessionId)) {
		Write $ZCVT($G(^IRIS.Temp.AutoFormError(%session.SessionId)),"O","HTML")
		Kill ^IRIS.Temp.AutoFormError(%session.SessionId)
	}

	Quit $$$OK
}

/// Generic method to draw a command form for a pane
Method DrawCommandForm(pInstance As PageInstance) As %Status
{
	// !!! Get ID Values from page and display the form object
	Merge tID = pInstance.IDValues
	
	If ($IsObject(..CommandFormObject)) {
		Do ..CommandFormObject.DrawHTMLForm(..CommandFormObject,.tID,..CommandSubmitPage)
	}	
	
	Quit $$$OK
}

/// Generic method to draw commands for a pane;
/// A subclass can override this.
Method DrawCommands(pInstance As PageInstance) As %Status
{
	Set tCount = ..Commands.Count()
	If (pInstance.Title '= "") || (tCount > 0) {
		&html<<div class="toolRibbon">
		<table border="0" cellspacing="0" cellpadding="0"><tr>>
		If (pInstance.Title'="") {
			/* If Text exists then display it in new style before creating command buttons */
			&html<<td class="ribbonTitle" valign="middle"><nobr>#(pInstance.Title)#</nobr>&nbsp;&nbsp;</td>>
		}
		&html<<td align="left" nowrap="1" valign="middle">>
	
		// display any commands for this page
		If (tCount > 0) {
			#;YSD2507 &html<<div class="DetailCommand">>
			For i = 1:1:tCount {
				Set tAction = ..Commands.GetAt(i)

				// skip if Condition is false
				If tAction.Condition'="" {
					Set true=0
					Try {
						Xecute ("(true) set true=("_tAction.Condition_")",.true)
					} Catch {}
					If 'true Continue
				}

				Set tPopup = ..LocalizeText(tAction.Popup)
				
				Kill ids
				Do tAction.GetIDValues(.ids)

				If (tAction.Type = "popup") {
					Set tURL = pInstance.MakePopupLink(tAction.HREF,.ids)
				}
				Else {
					Set tURL = pInstance.MakeLink(tAction.HREF,.ids)
				}
				If (tAction.Confirm '= "") {
					Set tConfirm = " onclick=""return confirm('" _ $ZCVT((tAction.Confirm),"O","JS") _ "');"""
				}
				Else {
					Set tConfirm = ""
				}
				
				Set tTarget = tAction.TargetFrame
				If (tTarget = "") {
					Set tTarget = "_top"
				}

				&HTML<<a class="DetailCommand"
							#(tConfirm)#
							target="#(tTarget)#"
							title="#(tPopup)#" 
							href="#(tURL)#">
							<nobr>&nbsp;#($ZCVT(tAction.Caption,"O","HTML"))#&nbsp;</nobr></A>>

				#;YSD2507 If (i < tCount) { &html<|> }
			}
			#;YSD2507&html<</div>>
			//Set spacer = ##class(%CSP.Page).Link("/csp/broker/images/spacer.gif")
			//&html<<div><img src='#(spacer)#' height="6"></div>>
		}
		
		&html<</td>
		</tr>
		</table>
		</div>>
	}
}

/// Return a quoted, COS version of a string.
ClassMethod QuoteCOS(pText As %String) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$zutil(144,1,pText)
}

/// Called by CSP rules engine to generate code to construct an instance
/// of this object using the current instance as a template.
Method GenerateCode() As %String
{
	Set code = ""
	Set code = code_" Set tPane = ##class(" _ $classname() _ ").%New()"_$$$EOL

	// title
	//Set code = code _ " Set tPane.Text =" _ ..QuoteCOS(..Text) _ $$$EOL
	Set code = code _ " Set tPane.Text = " _ "$$$Text("_..QuoteCOS(..Text) _")"_ $$$EOL
	If (..URL '= "") {
		Set code = code _ " Set tPane.URL =" _ ..QuoteCOS(..URL) _ $$$EOL
	}

	If (..FrameStyle '= "") {
		Set code = code _ " Set tPane.FrameStyle =" _ ..QuoteCOS(..FrameStyle) _ $$$EOL
	}

	// align
	If (..Align '= "") {
		Set code = code _ " Set tPane.Align =" _ ..QuoteCOS(..Align) _ $$$EOL
	}
	
	// styles
	Set tKey=""
	Set tStyle = ..Styles.GetNext(.tKey)
	While (tKey'="") {
		Set code = code _ " Do tPane.Styles.SetAt(" _ ..QuoteCOS(tStyle) _ "," _ ..QuoteCOS(tKey) _ ")" _ $$$EOL
		Set tStyle = ..Styles.GetNext(.tKey)
	}

	// commands
	Set code = code _ $$$EOL
	If (..Commands.Count() > 0) {
		Set code = code _ " // commands" _ $$$EOL
	}

	For i = 1:1:..Commands.Count() {
		Set tAction = ..Commands.GetAt(i)
		Set code = code _ tAction.GenerateCode()
		Set code = code _ " Do tPane.Commands.Insert(tAction)" _ $$$EOL
		Set code = code _ $$$EOL
	}

	
	// command form
	If (..CommandFormClass '= "") {
		Set code = code _ " Set tPane.CommandFormClass = " _ ..QuoteCOS(..CommandFormClass) _ $$$EOL
		Set code = code _ " Set tPane.CommandSubmitPage = " _ ..QuoteCOS(..CommandSubmitPage) _ $$$EOL
		Set code = code _ $$$EOL
		Set code = code _ " // Create instance of object used for form" _ $$$EOL
		Set code = code _ " Merge tID = pInstance.IDValues" _ $$$EOL
		Set code = code _ " Set tPane.CommandFormObject = $classmethod(" _ ..QuoteCOS(..CommandFormClass) _ ",""CreateInstance"",.tID)" _ $$$EOL
		Set code = code _ $$$EOL
	}	
	
	Set code = code _ $$$EOL

	// get specific code for subclasses
	Set code = code _ ..OnGenerateCode()

	Set code = code_" Quit tPane"_$$$EOL	
	Quit code
}

/// Subclasses override this to generate code during CSP processing
Method OnGenerateCode() As %String
{
	Quit ""
}

/// Return the localized version of the string <var>pText</var>.
/// A localizable string starts with "@[domainname:]textid@....."
/// If domainname exists then use it ; 
/// Else if pDomain passed in then use it ;
/// Else default to %Utility.
/// Also, substitute any run-time expressions of
/// the form {$ID1} with Page variables...
ClassMethod LocalizeText(pText As %String, pDomain As %String = "%Utility") As %String
{
	Set thisText = pText
	// test for TextID
	If ($E(pText,1,1) = "@") {
		Set textid = $P(pText,"@",2)
		Set thisDomain = $S(textid[":":$P(textid,":",1),1:pDomain)
		If textid [ ":" Set textid = $p(textid,":",2)
		If %response.Domain = "" Set %response.Domain = thisDomain
		// use textid to find localized text
		// if textid defined, get the translation
		If textid '= "" {
			Set pText = $$FormatMessage^%occMessages(%response.Language,thisDomain,textid,$E(thisText,$F(thisText,"@",3),*))
			// Use the next line for debugging
			// Set pText = "P@"_textid_"@"_$$FormatMessage^%occMessages(%response.Language,thisDomain,textid,$E(thisText,$F(thisText,"@",3),*))	
		} Else {
			// If pText is null to this point, use english
			Set pText = $E(pText,$F(pText,"@",3),*)
			// Use the next line for debugging
			//Set pText = "noid"_thisDomain_"+"_pText_"@"_$E(pText,$F(pText,"@",3),*)
		}
	}
	
	If (pText '[ "{") {
		// no expressions, quick return
		Quit pText
	}
	
	// search for expressions in the text
	Set tOut = ""
	Set last = 1
	Set start = $F(pText,"{",0)
	While (start '= 0) {
		Set tOut = tOut _ $E(pText,last,start-2)
		Set last = start
		Set end = $F(pText,"}",start)
		If (end = 0) {
			// no }, done
			Set tOut = tOut _ "{"
			Set start = 0
		}
		Else {
			// get expression and evaluate
			Set val = $E(pText,start,end-2)
			If (val = "$NAMESPACE") {
				Set outval = $G(%session.Data("$NAMESPACE"),$namespace)
			}
			Else {
				Set outval = $G(%request.Data(val,1))
			}

			Set tOut = tOut _ outval

			// next {
			Set start = $F(pText,"{",end)
			Set last = end
		}
	}

	Set tOut = tOut _ $E(pText,last,$L(pText))

	Quit tOut
}

}
