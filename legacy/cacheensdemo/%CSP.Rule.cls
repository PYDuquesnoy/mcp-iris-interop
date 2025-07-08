/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.Rule</b> class is the super class of all rule
/// generated classes that represent elements within the DOM model.
Class %CSP.Rule Extends %CSP.AbstractAtom [ System = 3 ]
{

/// A string specifying the rule family.
Property Family As %String;

/// A string specifying the rule name.
Property Rule As %String;

/// An array of strings containing the HTML properties associated with 
/// this tag. The array is indexed by property name and contains property values.
Property TagAttributes As array Of %String;

/// A boolean value specifying whether this element has an end tag.
Property HasEndTag As %Boolean [ InitialExpression = 0 ];

/// A boolean value specifying whether this element is self-closed.
Property Closed As %Boolean [ InitialExpression = 0 ];

/// A integer value specifying how tags are to be handled within
/// the body content of this tag:
/// TextOnly=0  Normal parsing of tags
/// TextOnly=1  Tags are ignored in the body content and 
/// always treated as text.
/// TextOnly=2  Tags are processed only if a matching rule is found.
/// Otherwise the tag is treated as text.
Property TextOnly As %Integer [ InitialExpression = 0 ];

/// If not "", this rule will start a new section named NewSection.
Property NewSection As %String;

/// This attribute speficies the line number on which this tag starts.
Property LineNumber As %Integer;

/// A list of any sub-items contained within this element.
Property Children As list Of %CSP.AbstractAtom;

/// This attribute always returns "".  Is it to be called by parent classes' InnerText() method.
Property Text As %String;

/// New method can set TagName property.
Method %OnNew(initval As %String = "") As %Status
{
	Set ..TagName=initval
	Quit $$$OK
}

/// Generate internal name to be used for a new attribute
/// whose name is given by a CSP expression.
Method NewExprName() As %String [ Internal, Private ]
{
	Set n=..TagAttributes.Count()+1
	Quit "#expr"_$extract("0000000000",1,10-$length(n))_n
}

/// Set the HTML attribute <var>name</var> for this element to <var>value</var>.
Method InitAttribute(name As %String, value As %String, order As %Integer = 0, quote As %String = "")
{
	If $e(name,1,2)'="#(",$e(name,1,3)'="##(" {
		Set NAME=$ZCVT(name,"U")
	} Else  {
		Set NAME=..NewExprName()
	}
	Do ..TagAttributes.SetAt($lb(value,name,order,quote),NAME)
	Quit
}

/// Set the HTML attribute <var>name</var> for this element to <var>value</var>.
Method SetAttribute(name As %String, value As %String)
{
	If $e(name,1,2)'="#(",$e(name,1,3)'="##(" {
		Set NAME=$ZCVT(name,"U")
			If '..TagAttributes.IsDefined(NAME) {
			Do ..TagAttributes.SetAt($lb(value,name,0,""""),NAME)
		} Else {
			Set list=..TagAttributes.GetAt(NAME)
			Set $li(list,1)=value
			Do ..TagAttributes.SetAt(list,NAME)
		}
	} Else {
		Set NAME=..NewExprName()
		Do ..TagAttributes.SetAt($lb(value,name,0,""""),NAME)
	}
	Quit
}

/// Get the value of the HTML attribute <var>name</var> for this element.
/// The value will have ##( )## and ##' '## resolved.
Method GetAttribute(name As %String, default As %String = "") As %String
{
	Set parm=$ZCVT(name,"U")
	If '..TagAttributes.IsDefined(parm) Quit default
	QUIT $$resolvePP^%cspQuote($lg(..TagAttributes.GetAt(parm),1,default))
}

/// Get the value of the HTML attribute <var>name</var> for this element.
/// Return the value as a quoted string with #()#, ##( )## and ##' '## resolved.
Method QuoteAttribute(name As %String, default As %String = "") As %String
{
	Set parm=$ZCVT(name,"U")
	If ..TagAttributes.IsDefined(parm) {
		Set value=$lg(..TagAttributes.GetAt(parm),1,default)
	} Else {
		Set value=default
	}
	Set result=$$QuoteCSP^%cspQuote(value)
	If ($get(%compiler)'="") && (%compiler.PageLanguage="mvbasic") {
		If ($extract(result)="""") && ($extract(result,$length(result))="""") {
			Set result="'"_$extract(result,2,$length(result)-1)_"'"
		}
	}
	Quit result
}

/// Return all the parameters in a ordered array.
Method GetAttributesOrdered(ByRef paramsordered)
{
	Set p="" For  Set v=..TagAttributes.GetNext(.p) Quit:p=""  Do
	. Set name=$li(v,2),order=$li(v,3),quote=$li(v,4)
	. Set new=$o(list(order,""),-1)+1
	. Set list(order,new)=$lb(name)_$li(v,1,1)_$lb(quote)
	Set k=1
	Set i="" For  Set i=$o(list(i)) Quit:i=""  Set j="" For  Set j=$o(list(i,j)) Quit:j=""  Do
	. Set paramsordered(k)=list(i,j),k=k+1
	QUIT
}

/// Indicate if HTML attribute <var>name</var> is defined.
Method IsDefined(name As %String) As %Boolean
{
	QUIT ..TagAttributes.IsDefined($ZCVT(name,"U"))
}

/// Indicate if HTML attribute <var>name</var> has a value.
Method HasValue(name As %String) As %Boolean
{
	If '..TagAttributes.IsDefined($ZCVT(name,"U")) Quit 0
	Quit $ld(..TagAttributes.GetAt($ZCVT(name,"U")))
}

/// Add an child atom to this element.
Method AddChildElement(atom As %CSP.AbstractAtom) As %Status
{
	Do ..Children.Insert(atom)
	Set atom.Parent=$this
	QUIT $$$OK
}

/// Validate that rule attributes are valid.
Method ValidateTag() As %Status
{
	If ..Rule="" Quit $$$OK
	Set sc=$$$OK
	Set attrib=$order($$$mruleAttribute(..Family,..Rule,""))
	While attrib'="" {
		If (..IsDefined(attrib)=0)&&$d($$$mruleAttributeDefault(..Family,..Rule,attrib)) {
			Do ..SetAttribute(attrib,$$$mruleAttributeDefault(..Family,..Rule,attrib))
	 	}
		If (..IsDefined(attrib)=0)&&$get($$$mruleAttributeRequired(..Family,..Rule,attrib),0) {
			Set sc=$$$ERROR($$$AttributeRequired,..TagName,attrib,..LineNumber)
			Quit
		}
		Set attrib=$order($$$mruleAttribute(..Family,..Rule,attrib))
	}
	Quit sc
}

/// Get the children of this tag as text
Method InnerText() As %String
{
	 Set text=""
	 For i=1:1:..Children.Count() Set text=text_..Children.GetAt(i).Text
	 Quit text
}

/// Exposes default rendering of tag without needing to use ##super.
/// Writes code into the routine builder object that will do the
/// default rendering for a begin tag.
Method RenderDefaultStartTag() As %Status
{
	Set sectionname=..NewSection
	If %compiler.PageLanguage="basic" {
		Set doCmd=" me."
		Set sep="&"
	} ElseIf %compiler.PageLanguage="mvbasic" {
		Set classname=$$$NormalizeClassname(%compiler.Get("%classname"))
		Set doCmd=" """_classname_"""->"
		Set sep=":"
	} Else {
		Set doCmd="	Do .."
		Set sep=","
	}
	
	If sectionname'="" {
		Do ..WriteServer(doCmd_"OnPage"_sectionname_"()")
		Do ..PushDefaultSection(sectionname)
	}
	
	If i%TagName'="" {
		If sectionname'="" Do ..PushDefaultSection(",-2")
		Set qtag=$$QuoteCSP^%cspQuote(i%TagName)
		Set line="""<"
		If $e(qtag)="""" {
			Set line=line_$e(qtag,2,$l(qtag))
		} Else {
			Set line=line_""""_sep_qtag
		}
		If ..TagAttributes.Count()>0 {
			Do ..GetAttributesOrdered(.params)
			Set i=$o(params(""))
			While i'="" {
				If '$ld(params(i),2) {
					Set qattr=..RenderOneAttribute($li(params(i),1))
				} Else {
					Set qattr=..RenderOneAttribute($li(params(i),1),$li(params(i),2),$li(params(i),3),sep)
				}
				If ($e(line,$l(line))="""")&&($e(qattr,1)="""") {
					Set line=$e(line,1,$l(line)-1)_$e(qattr,2,$l(qattr))
				} Else {
					Set line=line_sep_qattr
				}
				Set i=$o(params(i))
			}
		}
		If $e(line,$l(line))="""" {
			Set line=$e(line,1,$l(line)-1)
		} Else {
			Set line=line_sep_""""
	 	}
		If ..Closed Set line=line_"/"
		Set line=line_">"""
		Do ..WriteExpressionText(line)
	
		If sectionname'="" Do ..PopDefaultSection()
	}
	
	Quit $$$PROCESSCHILDREN
}

/// Exposes default rendering of tag without needing to use ##super.
/// Writes code into the routine builder object that will do the
/// default rendering for an end tag.
Method RenderDefaultEndTag() As %Status
{
	Set sectionname=..NewSection
	
	If (i%TagName'="")&&..HasEndTag {
		If sectionname'="" Do ..PushDefaultSection(",2")
		Do ..WriteCSPText("</"_i%TagName_">")
		If sectionname'="" Do ..PopDefaultSection()
	}
	
	If sectionname'="" {
		If $get(%builder)'="" Set %builder.GetSection().TagWritten=1
		Do ..PopDefaultSection()
	}
	
	Quit $$$OK
}

/// Render a single attribute of this CSP tag.
Method RenderOneAttribute(name, value, quote, sep) As %String [ Internal, Private ]
{
	Set line=$$QuoteCSP^%cspQuote(" "_name)
	If $d(value) Do
	. Set qval=$$QuoteCSP^%cspQuote("="_quote_value_quote)
	. If $e(line,$l(line))="""",$e(qval,1)=""""
	. If    Set line=$e(line,1,$l(line)-1)_$e(qval,2,$l(qval))
	. Else  Set line=line_sep_qval
	Quit line
}

/// Default OnMatch method for rules is to do nothing.
/// OnMatch may be overridden by user rules.
ClassMethod OnMatch(rule As %CSP.Rule) As %Status
{
	Quit $$$OK
}

/// Default rendering of the start tag is to just continue
/// RenderStartTag may be overridden by user rules.
Method RenderStartTag() As %Status
{
	Quit $select(..HasEndTag:$$$PROCESSCHILDREN,1:$$$SKIPCHILDREN)
}

/// Default rendering of the end tag is a no operation
/// RenderEndTag may be overridden by user rules.
Method RenderEndTag() As %Status
{
	Quit $$$OK
}

}
