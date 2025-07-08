/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implement csp:text tag using a common method,
/// GetText that may be used to implement other
/// language enabled tags.
Class %CSP.TagLanguage Extends %CSP.Rule [ System = 3 ]
{

/// Call ..GetText to implement the csp:text tag.
Method RenderStartTag() As %Status
{
	If (%compiler.IsBasic) && (..GetAttribute("TEXTID")="") {
		Quit $$$ERROR($$$AttributeRequired,..TagName,"TEXTID",..LineNumber)
	}
	Set default=..InnerText()
	Do ..WriteExpressionText(..GetText($this,default),0)
	Quit $$$SKIPCHILDREN
}

/// No end tag written.
Method RenderEndTag() As %Status
{
 Quit $$$OK
}

/// Return the expression that will get localized text based on
/// the textid, domain and language attributes.  GetText should be
/// called from within a rule.<p>
/// The optional Language attribute is an RFC 1766 format language name 
/// for looking up this text.  %response.Language is used if Language is not specified.
/// The Domain attribute is the optional application domain for looking up this text.  
/// %response.Domain is used if Domain is not specified.
/// The required TextId attribute is the id that idenfies the text string.
/// Attributes ARGn, where n is an integer, are substituted for %n in the message text.
ClassMethod GetText(tag As %CSP.Rule, default As %String = "") As %String
{
	// Get arg list			
	Set key = "ARG"
	Set max = 0
	Set args = ""
	Set dot=$select((%compiler'="")&&(%compiler.PageLanguage="mvbasic"):"->",1:".")
	Do tag.TagAttributes.GetNext(.key)
	While (key'="") && ($extract(key,1,3)="ARG") {
		Set num=+$extract(key,4,$length(key))
		If (num>max) Set max=num
		Do tag.TagAttributes.GetNext(.key)
	}
	For i=1:1:max {
		Set args = args_","_tag.QuoteAttribute("ARG"_i)
		Do tag.TagAttributes.RemoveAt("ARG"_i)
	}
	// Look for simple cases, otherwise general handler.
	Set language=tag.QuoteAttribute("LANGUAGE")
	Set domain=tag.QuoteAttribute("DOMAIN")
	Set id=tag.QuoteAttribute("TEXTID")
	Set default=$$QuoteCSP^%cspQuote(default)
	If tag.GetAttribute("TEXTID")="" {
		// If textid="", then define a new message
		Set expr="$$$Text("_default_","_domain_","_language_")"
		If args'="" {
			Set expr="$$FormatText^%occMessages("_expr_args_")"
		}
	} ElseIf (%compiler'="") && ('%compiler.IsBasic) && (args="") && 
				(tag.GetAttribute("LANGUAGE")'="") && 
				(tag.GetAttribute("DOMAIN")'="") && 
				($extract(domain)="""") {
		If $extract(domain,2)="%" {
			Set expr="$$$GetSysMessage("_language_","_domain_","_id_","_default_")"
		} Else {
			Set expr="$$$GetAppMessage("_language_","_domain_","_id_","_default_")"
		}
	} Else {
		If tag.GetAttribute("DOMAIN")="" Set domain="%response"_dot_"Domain"
		If tag.GetAttribute("LANGUAGE")="" Set language="%response"_dot_"Language"
		If %compiler'="" {
			If %compiler.PageLanguage="basic" {
				Set expr="FormatMessage@%occMessages"
			} ElseIf %compiler.PageLanguage="mvbasic" {
				Set expr="""%CSP.TagLanguage""->FormatMessage"
			} Else {
				Set expr="$$FormatMessage^%occMessages"
			}
		} Else {
			Set expr="##($case(%compiler.PageLanguage,""basic"":""FormatMessage@%occMessages"",""mvbasic"":""""""%CSP.TagLanguage""""->FormatMessage"",:""$$FormatMessage^%occMessages""))##"
		}
		Set expr=expr_"("_language_","_domain_","_id_","_default_args_")"
	}
	
	// Remove CSP attributes
	Do tag.TagAttributes.RemoveAt("TEXTID")
	Do tag.TagAttributes.RemoveAt("DOMAIN")
	Do tag.TagAttributes.RemoveAt("LANGUAGE")
	Quit expr
}

/// FormatMessage wrapper for use in CSP page.
ClassMethod FormatMessage(language As %String, domain As %String, id As %String, default As %String, args...) As %String [ Final ]
{
	Quit $$FormatMessage^%occMessages(language,domain,id,default,args...)
}

}
