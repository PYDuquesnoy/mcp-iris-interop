/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// CSP DOM object that implements CSP script tag.
Class %CSP.TagCache Extends %CSP.TagMethod [ Not ProcedureBlock, System = 3 ]
{

/// Writes code into the routine builder object to render the
/// script tag.
Method RenderStartTag() As %Status
{
	New runat,language,methodNumber
	Set runat=$zcvt(..GetAttribute("RUNAT"),"u")
	If runat="" Quit $$$ERROR($$$ScriptCacheMissingAttribute,..LineNumber)
	If runat="SERVER" {
	 	Set language=$zcvt(..GetAttribute("LANGUAGE"),"L")
	 	If (language'="") && (language'="basic") && (language'="mvbasic") && (language'="cache") {
	 		Quit $$$ERROR($$$CSPInvalidLanguage,language,..LineNumber)
	 	}
	 	If (language'="") && (language'=%compiler.PageLanguage) {
	 		Quit $$$ERROR($$$CSPScriptLanguage,language,..LineNumber)
	 	}
	 	
		Quit ..RenderAsCodeServer()
	}
	If runat="COMPILER" Quit ..RenderAsCodeCompiler()
	Quit $$$ERROR($$$AttributeValueInvalid,"RUNAT",runat,..LineNumber)
}

/// Output code for runat="server"
Method RenderAsCodeServer() As %Status [ Internal ]
{
	New i,lines,line,j,text,keep
	Set text=""
	For i=1:1:..Children.Count() {
		Set lines=..Children.GetAt(i).Text
		For j=1:1:$length(lines,$$$EOL) {
			Set keep=0
			Set line=$ZStrip($p(lines,$$$EOL,j),"<W") 
			If line'="" {
				If $e(line)=":" {
					Set line=$select($ZStrip(line,"<W")'="":$extract(line,2,*),1:"")
					Set keep=1
				} Else {
					Set line="	"_line
					If $extract(line,2)="." Set keep=1
				}
			}
	 		If line'="" {
				Set line=$$resolvePP^%cspQuote(line)
				If text'="" {
					If 'keep {
						Do ..WriteServer(text)
						Set text=line
					} Else {
						Set text=text_$$$EOL_line
					}
				} Else {
					Set text=line
				}
			}
		}
	}
	If text'="" Do ..WriteServer(text)
	Quit $$$SKIPCHILDREN
}

/// Output code for runat="compiler"
Method RenderAsCodeCompiler() As %Status [ Internal, Private ]
{
	New sc,rtnname,rtntype,routine,i,j,lines
	Set rtnname="cspScriptRunAtCompiler"_$tr($j,":")_"C"
	Set rtntype=$case($zcvt(..GetAttribute("LANGUAGE"),"L"),"basic":"BAS","mvbasic":"MVI",:"MAC")
	Set routine=##class(%Routine).%New(rtnname_"."_rtntype)
	For i=1:1:..Children.Count() {
		Set lines=..Children.GetAt(i).Text
		For j=1:1:$length(lines,$$$EOL) {
			Do routine.WriteLine($p(lines,$$$EOL,j))
		}
	}
	Set sc=routine.Save()
	n qstruct m qstruct=%compiler.qstruct
	Set:$$$ISOK(sc) sc=routine.Compile(.qstruct)
	Set routine="" ; make sure routine closed.
	Do:$$$ISOK(sc) @("^"_rtnname)
	Do ##class(%Routine).Delete(rtnname_"."_rtntype)
	Quit $$$SKIPCHILDREN
}

}
