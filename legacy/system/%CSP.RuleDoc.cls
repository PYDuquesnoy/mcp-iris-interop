/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// CSP page that provides documentation viewer for CSP Rules.
/// 
/// It expects the following input:
/// <table cols="2">
/// <tr><td>RULE</td><td>Name of rule to display.</td></tr>
/// </table>
Class %CSP.RuleDoc Extends %CSP.Page [ Not ProcedureBlock, System = 3 ]
{

/// Override ENCODED from %CSP.Page
Parameter ENCODED = 2;

/// Override PRIVATE from %CSP.Page
Parameter PRIVATE = 1;

/// OnPage method to display CSP Rules
ClassMethod OnPage() As %Status
{
	New rule,family
	
	Set rule=%request.Get("RULE")
	Set family=%request.Get("FAMILY","csp")
	
	&html<<html>
		<head>
		<title>CSP Rule:#(rule)#</title>
	>
	
	Do ..ShowStyleSheet()
	&html<</head>
		<body>>
	
	Do:rule'="" ..ShowRule(rule,family)
	
	&html<</body>
		</html>>
	Quit $$$OK
}

/// Display the HTML Style Sheet for the lookup page.
/// <P>This has to be called within the HEAD section of the document.
ClassMethod ShowStyleSheet() [ Internal, Private ]
{
	&html<
	<style type="text/css">
	body {
		color: black; 
		background: white; 
		font-family: Verdana,Arial,Helvetica,sans-serif; }
	
	div.Title {
		color: white;
		background: #287780; 
		font-size: 24pt; 
		font-family: Verdana,Arial,Helvetica,sans-serif;
		font-weight: bold;
		padding-top: 10;
		padding-bottom: 10;
		padding-left: 10; }
	
	div.Section {
		color: black;
		background: #CBE6EB; 
		font-size: 12pt;
		font-family: Verdana,Arial,Helvetica,sans-serif;
		font-weight: bold;
		padding-left: 5; 
		margin-top: 15; 
		margin-bottom: 5; }
	
	div.Syntax {
		color: black; 
		font-family: courier,monospace;
		font-size: 12pt; 
		text-align: left; 
		margin-left: 20; 
		margin-right: 10; 
		padding-left: 5; 
		padding-top: 5; 
		padding-bottom: 5; }

	div.Match {
		color: black; 
		background: #DDDDDD;
		font-family: courier,monospace;
		font-size: 12pt; 
		text-align: left; 
		margin-left: 20; 
		margin-right: 10; 
		padding-left: 5; 
		padding-top: 5; 
		padding-bottom: 5; }
 
	.SampleCode {
		color: black; 
		background: #DDDDDD;
		font-family: courier,monospace;
		font-size: 12pt; 
		text-align: left; 
		margin-left: 20; 
		margin-right: 10; 
		padding-left: 5; 
		padding-top: 5; 
		padding-bottom: 5; }
	
	.Output { 
		color: black; 
		background: #DDDDDD;
		margin-left: 20; 
		margin-right: 10; 
		padding-left: 5; 
		padding-top: 5; 
		padding-bottom: 5; }
	
	.Language { color: black; font-weight: bold; }
	.Tag { color: purple; font-weight: bold; }
	.Attribute { color: black; font-weight: bold; }
	.Value { color: blue; font-weight: bold; }
	.Comment { color: green; }
	
	.Text { margin-left: 20; }
	.Term { font-weight: bold; }
	
	</style>>
	
	Quit
}

/// Display HTML description of rule <var>rule</var>.
ClassMethod ShowRule(rule As %String, family As %String = "csp") [ Internal, Private ]
{
	New syntax,i,req,match,tag,t1,t2,t3,indent,j,k,t,type,typelabel
	
	; check if rule exists
	If ('$D($$$mruleRoot(family,rule))) &html<<font color="red">CSPRuleDoc Error:</font> Rule <b>#(rule)#</b> not found.> Quit
	
	Set match=$$$mruleMatch(family,rule)
	Set tag=$LG($LG(match))
	
	&html<<div class="Title">&lt;#(tag)#&gt;</div>>
	
	; syntax
	&html<<br><div class="Syntax">>
	
	Set syntax="&lt;<span class=""Tag"">"_tag_"</span>"
	Set i=$Order($$$mruleAttribute(family,rule,""))
	While i'="" {
		Set t=$G($$$mruleAttributeType(family,rule,i),"STRING")
	If (t[":") {
		Set typelabel=$P(t,":",1)
		Set type=$P(t,":",2)
	} Else {
		Set typelabel="value"
		Set type=t
	}
		Set req=$G($$$mruleAttributeRequired(family,rule,i),0)
		Set syntax=syntax_" "
		Set:'req syntax=syntax_"["
		Set syntax=syntax_"<span class=""Attribute"">"_i_"</span>"
		Set:type'="BOOLEAN" syntax=syntax_"="_typelabel
		Set:'req syntax=syntax_"]"
		Set i=$Order($$$mruleAttribute(family,rule,i))
	}
	Set syntax=syntax_"&gt;"
	
	If $G($$$mruleEmpty(family,rule),0)=0 Set syntax=syntax_$S($G($$$mruleTextOnly(family,rule),0)=1:"Inner Text",1:"Inner HTML")_"&lt;<span class=""Tag"">/"_tag_"</span>&gt;"
	
	Write syntax,"</div>",$C(13,10)
	
	; description
	&html<<div class="Section">Description</div>>
	&html<<br><div class="Text">>
	Do ..ShowDescription($G($$$mruleDescription(family,rule)))
	&html<</div>>
	
	; attributes
	Set i=$Order($$$mruleAttribute(family,rule,"")) ; are there any?
	If (i'="") {
		&html<<div class="Section">Attributes</div>>
	}
	
	; loop over attributes; write out descriptions
	&html<<table class="Text" cellspacing="5">>
	Set i=$Order($$$mruleAttribute(family,rule,""))
	While i'="" {
		&html<<tr><td class="Term">#(i)#</td><td>    </td><td class="Text">#($G($$$mruleAttributeDescription(family,rule,i)))#</td></tr>>
		Set i=$Order($$$mruleAttribute(family,rule,i))
	}
	&html<</table>>
	
	; match
	&html<<div class="Section">Match</div>>
	&html<<div class="Text">This rule is fired when the following conditions are found within a <i>#(family)#</i> file:</div><div class="Match">>
	
	Set indent=0
	For i=$LL(match):-1:1 {
		Set t1=$LG(match,i)
		Set t2=$LG(t1,1) ;tagname
		Set t3=$LG(t1,2) ;match attrs
		If i=$LL(match) {
			Write "<span class=""Language"">language = ",$get($$$mruleLanguage(family,rule),"cache"),"</span><br>"
		}
		Write "<br>"
		For j=1:1:indent Write "&nbsp;"
		Write "&lt;<span class=""tag"">",$S(t2="*":"<i>any tag</i>",1:t2)
		If (t3'="") {
			For k=1:1:$LL(t3) {
				Write " <span class=""attribute"">",$LG($LG(t3,k)),$S($LG($LG(t3,k),2)'="":"</span>=<span class=""Value"">"_$LG($LG(t3,k),2)_"</span>",1:"</span>")
			}
		}
		Write "</span>&gt;"
		Set indent=indent+4
	}
	
	If $G($$$mruleEmpty(family,rule),0)=0 Write "&lt;<span class=Tag>/"_t2_"</span>&gt;"
	
	&html<</div>>
	
	; misc.
	&html<<div class="Section">Miscellaneous</div>>
	
	&html<<table class="Text" cellspacing="5">>
	&html<<tr><td>Rule Name:&nbsp;</td><td class=Term>#(rule)#</td></tr>>
	&html<<tr><td>Rule Family:</td><td class=Term>#(family)#</td></tr>>
	&html<</table>>
	
	Quit
}

/// Convert description to formatted HTML and write it out.
ClassMethod ShowDescription(text As %String) [ Internal ]
{
	Write ..GetDescription(text)
	Quit
}

/// Convert description to formatted HTML and return the string.
///  Also used by rulemgr.csp.
ClassMethod GetDescription(text As %String) As %String [ Internal ]
{
	New xml,state,attrs,a,ret
	Set ret=""
	Set xml=##class(%CSP.TokenStream).%New()
	Do xml.OpenFromString(text)
	
	; state=1 normal
	; state=2 example
	; state=3 output
	
	Set state=1
	While xml.NextToken() {
		If (state=1) {
			If xml.IsText() {
				Set ret=ret_xml.QuoteHTML(xml.Text)_$C(13,10)
			} ElseIf (xml.IsTag()) {
				If (xml.GetTag()="EXAMPLE") {
					Set state=2 Set ret=ret_"<div class=""SampleCode""><pre>"
				} ElseIf (xml.GetTag()="OUTPUT") {
					Set state=3 
					Set ret=ret_"<div class=""Output"">"
				} Else {
					Set ret=ret_xml.Text
				}
			}
		} ElseIf (state=2) {
			If xml.IsText() Set ret=ret_xml.QuoteHTML(xml.Text)
			If xml.IsComment() {
				Set ret=ret_"<span class=""Comment"">"_xml.QuoteHTML(xml.Text)_"</span>"
			} ElseIf (xml.IsTag()) {
				If (xml.GetTag()="/EXAMPLE") {
					Set state=1
					Set ret=ret_"</pre></div>"
				} Else {
					Set ret=ret_"&lt;<span class=""Tag"">"_xml.Tag_"</span>"
					Do xml.GetAttrs(.attrs)
					Set a=$Order(attrs(""))
					While a'="" {
						Set ret=ret_" <span class=""Attribute"">"_a_"</span>"_$S($D(attrs(a,"value")):"=<span class=""Value"">'"_attrs(a,"value")_"'</span>",1:"")
						Set a=$Order(attrs(a))
				}
					Set ret=ret_"&gt;"
				}
			}
		} ElseIf (state=3) {
			If xml.IsText() {
				Set ret=ret_xml.QuoteHTML(xml.Text)_$C(13,10)
			} ElseIf (xml.IsTag()) {
				If (xml.GetTag()="/OUTPUT") {
					Set state=1
					Set ret=ret_"</div>"
				} Else {
					Set ret=ret_xml.Text
				}
			}
		}
	}
	
	Quit ret
}

}
