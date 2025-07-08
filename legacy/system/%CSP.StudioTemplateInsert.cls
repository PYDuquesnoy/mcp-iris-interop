/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <CLASS>%CSP.StudioTemplateInsert</CLASS> outputs the template for CSP with certain
/// tags in front and at the end of the template so Studio can recognise
/// this template and insert it into the current document.<p>
/// This is automatically set as the superclass of the final page that generates the template
/// by the rule.<p>
/// Values can be returned to Studio by setting the %session.Data("Template") subnodes, for
/// example to set the name of the class for a new class wizard use:
/// <example>
/// Set %session.Data("Template","CLASS")="User.Test"
/// </example>
/// These %session.Data("Template") values must be set in the last page that generates the
/// actual template. We provide methods to set values into this %session.Data("Template") nodes
/// that Studio understands. These are <method>AddToProject</method> and <method>SetClassName</method>.
Class %CSP.StudioTemplateInsert Extends %CSP.StudioTemplateSuper [ Abstract, System = 3 ]
{

Parameter SECURITYRESOURCE = "%Development";

/// Error page for templates
Parameter ERRORPAGE [ Internal ] = "/csp/sys/%CSP.StudioTemplateError.cls";

/// Delimits user template output
Parameter DELIM [ Internal ] = "##www.intersystems.com:template_delimiter##";

/// Internal method to output the start of the XML data section
ClassMethod TemplateHeader() [ Internal ]
{
	Write "<?xml version=""1.0""?>",!
	Write "<template><![CDATA[BODY"_..#DELIM
	Kill %session.Data("Template")
	Quit
}

/// Write end of template output
ClassMethod OnPostHTTP() [ Internal ]
{
	Write ..#DELIM
	Set name=$order(%session.Data("Template",""))
	While name'="" {
		If name="AddToProject"||(name="AddToSourceControl") {
			Write name,..#DELIM
			Set first=1
			Set item=$order(%session.Data("Template",name,""))
			While item'="" {
				Write $select(first:"",1:",")_item
				Set item=$order(%session.Data("Template",name,item)),first=0
			}
			Write ..#DELIM
		} Else {
			Set val=$get(%session.Data("Template",name))
			If val'="" Write name,..#DELIM,val,..#DELIM
		}
		Set name=$order(%session.Data("Template",name))
	}
	Write "]]></template>",!
	Quit
}

/// Use OnHTTPHeader set content type, handle namespace write HTTP headers and begin XML.
ClassMethod OnHTTPHeader(ByRef OutputBody As %Boolean) As %Status [ Internal ]
{
	Set %response.ContentType="text/xml",%response.CharSet="UTF-8"
	Do %response.WriteHTTPHeader(.OutputBody)
	If $get(%request.Data("Namespace",1))'="" {
		Set %session.Data("Namespace")=%request.Data("Namespace",1)
		If '..#GlobalTemplate {
			Set %session.RunNamespace=%request.Data("Namespace",1)
			Do $zutil(5,%session.RunNamespace)
		}
	}
	Do ..TemplateHeader()
	Quit $$$OK
}

/// Add this named item to the current project in Studio. If you have multiple items
/// then call this method multiple times. The <var>Name</var> must contain the type of
/// the item e.g. 'User.Test.cls' is a class, and 'TEST.mac' is a MAC routine.
ClassMethod AddToProject(Name As %String) As %Status
{
	If Name="" Quit $$$OK
	Set %session.Data("Template","AddToProject",Name)=""
	Quit $$$OK
}

/// Add this item to source control. If you have multiple items then call this method
/// multiple times. The <var>Name</var> must containt eh type of the item to add e.g.
/// 'User.Test.cls'.
ClassMethod AddToSourceControl(Name As %String) As %Status
{
	If Name="" Quit $$$OK
	Set %session.Data("Template","AddToSourceControl",Name)=""
	Quit $$$OK
}

/// If you are making a new class template then Studio needs to be told the
/// name of this class. This is done by calling this method in the final
/// page passing the name of the class.
ClassMethod SetClassName(Name As %String) As %Status
{
	Set %session.Data("Template","CLASS")=Name
	Quit $$$OK
}

}
