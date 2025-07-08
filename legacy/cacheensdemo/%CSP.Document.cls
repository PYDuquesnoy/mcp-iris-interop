/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// The <b>%CSP.Document</b> class is the server-side representation of a CSP page.
Class %CSP.Document Extends %CSP.Rule [ Not ProcedureBlock, System = 3 ]
{

/// Deprecated property for #server that is kept for compatibility.  
/// Now has the same effect as NeedJS property.
/// If true, JavaScript for #server applet HyperEvent should included in the CSP page.
Property NeedBroker As %Boolean [ Deprecated, InitialExpression = 0 ];

/// Deprecated property for #call that is kept for compatibility.  
/// Now has the same effect as NeedJS property.
/// If true, JavaScript for #call iframe  HyperEventshould included in the CSP page.
Property NeedJSBroker As %Boolean [ Deprecated, InitialExpression = 0 ];

/// If true, JavaScript for HyperEvent should included in the CSP page.
Property NeedJS As %Boolean [ InitialExpression = 0 ];

/// Make sure that we are cleaned up.
Method %OnClose() As %Status
{
	New handle

	If $get(%builder)'="" {
		Kill %builder
	}

	If $get(%compiler)="" Quit $$$OK

	Set handle=%compiler.Get("%classhandle")
	If handle'="" {
		n qstruct m qstruct=%compiler.qstruct
		Do Close^%occMain(handle,.qstruct)
		Do %compiler.remove("%classhandle")
	}

	Quit $$$OK
}

/// The document tag for CSP acts to compile this document to a 
/// class that will render it on demand.
Method RenderStartTag() As %Status
{
	New classname,handle,%sc
	#;
	Set classname=%compiler.Get("%classname")
	n qstruct m qstruct=%compiler.qstruct
	#;
	Set classname=$$$NormalizeClassname(classname)
	If $$$defClassDefined(classname) {
		Set %sc=$$Delete^%occMain(classname,.qstruct)
		If $$$ISERR(%sc) Quit %sc
	}
	Set %sc=$$Create^%occMain(.handle,classname,.qstruct)
	If $$$ISERR(%sc) Quit %sc
	#;
	Do %compiler.Set("%classhandle",handle)
	#;
	Set %builder=##class(%CSP.PageBuilder).%New()
	Do ..PushDefaultSection("CSPROOT")
	#;
	QUIT $$$PROCESSCHILDREN
}

/// The document tag for CSP acts to compile this document.
/// Finish building the class and cleanup.
Method RenderEndTag() As %Status
{
	New handle,classname,error,inc,name,section,param,linesOut,pagelanguage,language,doCmd,sc
	Set sc=$$$OK
	Set handle=%compiler.Get("%classhandle")
	Set pagelanguage=%compiler.PageLanguage
	Set classname=%compiler.Get("%classname")
	Set language=pagelanguage
	If pagelanguage="basic" {
		Set doCmd=" me."
	} ElseIf pagelanguage="mvbasic" {
		Set doCmd=" """_$$$NormalizeClassname(classname)_"""->"
	} Else {
		Set doCmd="	Do .."
		Set language="cache"
	}
	#;
	Set sc=$$SetClass^%occModify(handle,$$$cCLASSimport,$tr(%compiler.Get("%cspclass.IMPORT","User"),$c(32,9,13,10),""))
	If $$$ISERR(sc) Quit sc
	Set inc=$tr(%compiler.Get("%cspclass.INCLUDES"),$c(32,9,13,10),"")
	If inc'="" Set sc=$$SetClass^%occModify(handle,$$$cCLASSincludecode,inc)
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetClass^%occModify(handle,$$$cCLASSsuper,$tr(%compiler.Get("%cspclass.SUPER","%CSP.Page"),$c(32,9,13,10),""))
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetClass^%occModify(handle,$$$cCLASSlanguage,language)
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetClass^%occModify(handle,$$$cCLASSgeneratedby,%compiler.Get("%pagename"))
	If $$$ISERR(sc) Quit sc
	If %compiler.IsDefined("%cspclass.DESCRIPTION") Set sc=$$SetClass^%occModify(handle,$$$cCLASSdescription,%compiler.Get("%cspclass.DESCRIPTION"))
	If $$$ISERR(sc) Quit sc
	Set param="%cspparam."
	For  {
		 Set param=%compiler.Next(param)
		 If $extract(param,1,$l("%cspparam."))'="%cspparam." Quit
		 Set sc=$$AddParameter^%occModify(handle,$piece(param,".",2,*))
		 If $$$ISERR(sc) Quit
		 Set sc=$$SetParameter^%occModify(handle,$piece(param,".",2,*),$$$cPARAMdefault,%compiler.Get(param))
		 If $$$ISERR(sc) Quit
	}
	If $$$ISERR(sc) Quit sc
	Set sc=$$AddParameter^%occModify(handle,"CSPFILE")
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetParameter^%occModify(handle,"CSPFILE",$$$cPARAMdefault,%compiler.Get("%filename"))
	If $$$ISERR(sc) Quit sc
	Set sc=$$AddParameter^%occModify(handle,"CSPURL")
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetParameter^%occModify(handle,"CSPURL",$$$cPARAMdefault,%compiler.Get("%pagename"))
	If $$$ISERR(sc) Quit sc
	Set sc=$$AddParameter^%occModify(handle,"FileTimestamp")
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetParameter^%occModify(handle,"FileTimestamp",$$$cPARAMdefault,$$$FileDateModifiedUTC(%compiler.Get("%filename"),1)) If $$$ISERR(sc) Quit sc
	If %compiler.Get("%cspXHTML") {
		Set sc=$$AddParameter^%occModify(handle,"CSPXHTML")
		If $$$ISERR(sc) Quit sc
		Set sc=$$SetParameter^%occModify(handle,"CSPXHTML",$$$cPARAMdefault,1)
		If $$$ISERR(sc) Quit sc
	}
	If %compiler.Get("%cspHTML4STRICT") {
		Set sc=$$AddParameter^%occModify(handle,"CSPSTRICT")
		If $$$ISERR(sc) Quit sc
		Set sc=$$SetParameter^%occModify(handle,"CSPSTRICT",$$$cPARAMdefault,1)
		If $$$ISERR(sc) Quit sc
	}
	If %compiler.Get("%includes")'="" {
		Set sc=$$AddParameter^%occModify(handle,"CSPINCLUDES")
		If $$$ISERR(sc) Quit sc
		Set sc=$$SetParameter^%occModify(handle,"CSPINCLUDES",$$$cPARAMdefault,%compiler.Get("%includes"))
		If $$$ISERR(sc) Quit sc
	}

	#;
	If ..NeedBroker||..NeedJSBroker||..NeedJS,'%compiler.Get("%cspSuppressBrokerJS") {
		Do ..AddEventBroker()
	}
	#; If no HEAD tag in the page then put any text put in the
	#; HEAD section into HTML or CSPROOT.
	#; This is to handle code generated by CSP rules for HEAD section 
	#; when no HEAD tag is present
	Set section=%builder.Sections.GetAt("HEAD")
	If (section'="")&&('section.TagWritten) {
		Do ..PushDefaultSection($select(%builder.Sections.GetAt("HTML")'="":"HTML",1:"CSPROOT")_",-2")
		Do ..WriteServer(doCmd_"OnPageHEAD()")
		Do ..PopDefaultSection()
	}
	#;
	$$$cspStartMethodImplementation(handle,"OnPage")
	Set linesOut=0
	If %builder.Sections.GetAt("PREHTML")'="" {
		Set linesOut=linesOut+1
		$$$cspAddMethodLine(handle,"OnPage",linesOut,doCmd_"OnPagePREHTML()")
	}
	If %builder.Sections.GetAt("CSPROOT")'="" {
		Set linesOut=linesOut+1
		$$$cspAddMethodLine(handle,"OnPage",linesOut,doCmd_"OnPageCSPROOT()")
	}
	If %builder.Sections.GetAt("POSTHTML")'="" {
		Set linesOut=linesOut+1
		$$$cspAddMethodLine(handle,"OnPage",linesOut,doCmd_"OnPagePOSTHTML()")
	}
	Set linesOut=linesOut+1
	$$$cspAddMethodLine(handle,"OnPage",linesOut,$select(pagelanguage["basic":" Return "_$$$OK,1:"	Quit $$$OK"))
	$$$cspFinishMethodImplementation(handle,"OnPage",linesOut)
	Set sc=..AddSectionMethod(handle,"OnPage","%Status",,$select(pagelanguage="mvbasic":"mvbasic",1:""))
	#;
	Set name="" Set section=%builder.Sections.GetNext(.name)
	While $$$ISOK(sc) && (name'="") {
		If name="NULL" Quit  ; skip NULL section
		Set sc=..ProcessSection(section,handle,"OnPage"_name)
		Set section=%builder.Sections.GetNext(.name)
	}
	Kill %builder
	#;
	n qstruct m qstruct=%compiler.qstruct
	If $$$qualifierGetValue(qstruct,"csphidden") Set sc=$$SetClass^%occModify(handle,$$$cCLASShidden,1) If $$$ISERR(sc) Quit sc
	If $$$ISOK(sc) Do Save^%occMain(handle,,25)
	$$$defClassKeyKill(classname,$$$cCLASSclasstype)
	Do Close^%occMain(handle,.qstruct)
	Do %compiler.remove("%classhandle")
	// Set language to cache for the class compile so &html works in cache method
	Set %compiler.IsBasic=0,%compiler.PageLanguage="cache"
	If $$$ISERR(sc) Quit sc
	If $$$qualifierGetValue(qstruct,"cspcompileclass") {
		Do Compile^%occCompile(classname,.qstruct,.error)
		If $get(error) Quit $$$ERROR($$$FailedToCreateClass,classname,$get(error(1)))
		If $$$qualifierGetValue(qstruct,"cspdeployclass") {
			Set sc=$$MakeClassDeployed^%apiOBJ(classname,.qstruct,.error,1)
			IF $$$ISERR(sc) Quit sc
		}
	}
	#;
	QUIT $$$OK
}

/// Process all sections of this CSP or CSR class.
Method ProcessSection(section As %CSP.PageSection, handle As %String, methodname As %String) As %Status [ Internal ]
{
	New cblevel,index,block,numlines,linenum,linesOut,spaces,
		i,num,indent,line,textblock
	Set spaces="" Set $p(spaces," ",81)=""
	Set index=section.Index
	Set block=$order(^||%CSP.PageSection(index,""),1,numlines)
	Set linenum=1
	Set cblevel=0
	$$$cspStartMethodImplementation(handle,methodname)
	Set linesOut=0
	While block'="" {
		Set textblock=^||%CSP.PageSection(index,block,linenum)
	
		Set num=$length(textblock,$$$EOL)
		For i=1:1:num {
			Set line=$piece(textblock,$$$EOL,i)
			Set indent=cblevel
			If (line["{")||(line["}") {
				Set cblevel=cblevel+..cbdelta(line)
				Set indent=indent+..indentdelta(line)
			}
			Set linesOut=linesOut+1
			Set line=$select($e(line)=" ":$e(spaces,1,indent*4),1:"")_line
			$$$cspAddMethodLine(handle,methodname,linesOut,line)
		}
		Set linenum=linenum+1
		If linenum>numlines {
			Set block=$order(^||%CSP.PageSection(index,block),1,numlines)
			if block'="" Set linenum=1
		}
	}
	$$$cspFinishMethodImplementation(handle,methodname,linesOut)
	Quit ..AddSectionMethod(handle,methodname,,,$select(%compiler.PageLanguage="mvbasic":"mvbasic",1:""))
}

/// This method parses a line, and return the changes in curly brace level.
/// This method does not handle multi-line comment yet.
Method cbdelta(line) As %Integer [ Internal, Private ]
{
	New pline,i
	If line["""" For i=1:2:$length(line,"""") Set pline=$g(pline)_$p(line,"""",i)
	Else  Set pline=line
	Set pline=$p(pline,"//",1)
	Quit $length(pline,"{")-$length(pline,"}")
}

/// This method scans a line and returns the change 
/// in indent level for this line.  This line's indent
/// may only be changed by leading left curly brace, 
/// otherwise the indent is adjusted on the next line.
Method indentdelta(line As %String) As %Integer [ Internal, Private ]
{
 	New delta,i
	Set delta=0
	For i=1:1:$length(line,"}")-1 {
		if $zstrip($piece(line,"}",i),"<W")'="" Quit
		Set delta=delta-1
	}
	Quit delta
}

/// Add method for section or part of a section
ClassMethod AddSectionMethod(handle As %String, name As %String, return As %String = "%Boolean", args As %String = "", language As %String = "") As %Status [ Internal ]
{
	Set sc=$$SetMethod^%occModify(handle,name,$$$cMETHclassmethod,1)
	If $$$ISERR(sc) Quit sc
	If args'="" Set sc=$$SetMethod^%occModify(handle,methodname,$$$cMETHformalspec,args)
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetMethod^%occModify(handle,name,$$$cMETHreturntype,return)
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetMethod^%occModify(handle,name,$$$cMETHcodemode,$$$cMETHCODEMODECODE)
	If $$$ISERR(sc) Quit sc
	If language'="" Set sc=$$SetMethod^%occModify(handle,name,$$$cMETHlanguage,language)
	Quit sc
}

/// Insert event broker code into the head section to load hyperevent .js files.
Method AddEventBroker() As %Status [ ProcedureBlock = 1 ]
{
	If %compiler.PageLanguage="basic" {
		Set self="me."
	} ElseIf %compiler.PageLanguage="mvbasic" {
		Set self="""%CSP.Page""->"
	} Else {
		Set self=".."
	}

	Do ..PushDefaultSection("HEAD,1")
	Do ..WriteText("",1)
	set opt=%compiler.Get("%cspOptionalBrokerJS")
	if opt'="" set opt=","_opt
	Do ..WriteExpressionText("("_self_"HyperEventHead(0,"_''%compiler.Get("%cspHTML4STRICT")_opt_"))",0)
	Do ..PopDefaultSection()
	Quit $$$OK
}

}
