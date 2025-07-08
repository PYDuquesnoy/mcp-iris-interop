/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// Implements script tag within a CSR rule.
Class %CSP.RuleCache Extends %CSP.RuleElement [ System = 3 ]
{

/// Writes code into the routine builder object that will 
/// add outputing of the specified code to this rule class.
Method RenderStartTag() As %Status
{
	Set runat=$zcvt($this.GetAttribute("RUNAT"),"u")
	If runat="" Quit $$$ERROR($$$ScriptCacheMissingAttribute,..LineNumber)
	If runat="SERVER" {
	 	Set language=$zcvt(..GetAttribute("LANGUAGE"),"L")
	 	If (language'="basic") && (language'="mvbasic") && (language'="cache") {
	 		Quit $$$ERROR($$$CSPInvalidLanguage,language,..LineNumber)
	 	}
	 	Set rulelanguage=%compiler.Get("%rulelanguage")
	 	Set indent=""
	 	If rulelanguage="any" {
		 	Set indent="	"
		 	If %compiler.PageLanguage="basic" {
				Do ..WriteServer(" If %compiler.PageLanguage="""_language_""" Then")
		 	} ElseIf %compiler.PageLanguage="mvbasic" {
				Do ..WriteServer(" If %compiler->PageLanguage="""_language_""" Then")
		 	} Else {
				Do ..WriteServer(" If %compiler.PageLanguage="""_language_""" {")
		 	}
	 	} ElseIf (rulelanguage'=language) {
		 	Quit $$$ERROR($$$CSPScriptLanguage,language,..LineNumber)
	 	}
		Do ..RenderAsCodeServer(indent)
	 	If rulelanguage="any" {
		 	If %compiler.PageLanguage="basic" {
				Do ..WriteServer(" End If")
		 	} ElseIf %compiler.PageLanguage="mvbasic" {
				Do ..WriteServer(" End")
		 	} Else {
				Do ..WriteServer("	}")
		 	}
	 	}
		Quit $$$SKIPCHILDREN
	}
	If runat="COMPILER" Quit ..RenderAsCodeCompiler()
	Quit $$$ERROR($$$AttributeValueInvalid,"RUNAT",runat)
}

/// Output code for runat="server"
Method RenderAsCodeServer(indent) As %Status [ Internal, Private ]
{
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
	Set keepTogether=0
	For i=1:1:..Children.Count() {
		Set lines=..Children.GetAt(i).Text
		For j=1:1:$l(lines,$$$EOL) {
			Set line=$ZStrip($p(lines,$$$EOL,j),"<W")
			If line'="" {
				If $e(line)=":" {
					Set line=$e(line,2,*) 
					Set:$ZStrip(line,"<W")="" line=""
				} Else {
					Set line="	"_line
				}
			}
			If line'="" {
				Do ..WriteServer(indent_$case(%compiler.PageLanguage,"basic":" me.","mvbasic":" %this->",:"	Do ..")_"WriteCSPServer("_$$Quote^%cspQuote(line)_","_keepTogether_")")
				Set keepTogether=1
			}
		}
	}
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
	Quit $$$SKIPCHILDREN
}

/// Output code for runat="compiler"
Method RenderAsCodeCompiler() As %Status [ Internal, Private ]
{
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
	Set pagelanguage=%compiler.PageLanguage
	Set handle=%compiler.Get("%classhandle")
	; Call method for runat=compiler code
	Set index=%compiler.Get("%methodindex",1)
	Set methodname="CompilerMethod"_index
	If pagelanguage="basic" {
		Do ..WriteServer(" %statuscode="_$$$OK)
		Do ..WriteServer(" me."_methodname_"()")
	} ElseIf pagelanguage="mvbasic" {
		Do ..WriteServer(" %statuscode="_$$$OK)
		Do ..WriteServer(" %this->"_methodname_"()")
	} Else {
		Do ..WriteServer("	Set %statuscode=$$$OK Do .."_methodname_"()")
	}
	Do %compiler.Set("%methodindex",index+1)
	; Get code
	$$$cspStartMethodImplementation(handle,methodname)
	Set linesOut=0
	For i=1:1:..Children.Count() Do
	. Set lines=..Children.GetAt(i).Text
	. For j=1:1:$l(lines,$$$EOL) Do
	. . Set line=$ZStrip($p(lines,$$$EOL,j),"<W") Quit:line=""
	. . If $e(line)=":" Set line=$e(line,2,*) Quit:$ZStrip(line,"<W")=""
	. . Else  Set line="	"_$p(lines,$$$EOL,j)
	. . Set linesOut=linesOut+1
	. . $$$cspAddMethodLine(handle,methodname,linesOut,line)
	; Generate the method
	$$$cspFinishMethodImplementation(handle,methodname,linesOut)
	Set sc=##class(%CSP.RuleRule).AddSectionMethod(handle,methodname,"","",$zcvt(..GetAttribute("LANGUAGE"),"L"))
	If $$$ISERR(sc) Quit sc
	If pagelanguage="basic" {
		Do ..WriteServer(" If (System.Status.IsError(%statuscode)) Then Return %statuscode")
	} ElseIf pagelanguage="mvbasic" {
		Do ..WriteServer(" If (""%SYSTEM.Status""->IsError(%statuscode)) Then Return %statuscode")
	} Else {
		Do ..WriteServer("	Quit:$$$ISERR(%statuscode) %statuscode")
	}
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
	Quit $$$SKIPCHILDREN
}

}
