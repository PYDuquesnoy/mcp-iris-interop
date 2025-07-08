/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleRule</b> class represents the csr:rule tag within the DOM model for a CSR page.
Class %CSP.RuleRule Extends %CSP.Document [ System = 3 ]
{

/// True indicates that a class must be created for this rule.
Property CreateClass As %Boolean [ Internal ];

/// Implement DeleteRule for a rule file.
ClassMethod OnMatch(rule As %CSP.Rule) As %Status
{
	; %deleteCSR true indicates that we are deleting all rules
	; in a rule file.  Implement by making adding DELETE and
	; TEXTONLY attributes to csr:rule.
	if %deleteCSR Do rule.SetAttribute("DELETE",1)
	; If deleting rule, then skip parsing of rule's definition.
	If rule.TagAttributes.IsDefined("DELETE") Set rule.TextOnly=1
	Quit $$$OK
}

/// Start compiling a class for this rule.
Method RenderStartTag() As %Status
{
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": start tag rendering")
	Set name=..GetAttribute("NAME")
	; DELETE attribute means delete the rule
	If ..TagAttributes.IsDefined("DELETE") {
		m qstruct=%compiler.qstruct
		Set sc=$$DeleteRule^%cspRule($$$cFAMILYDEFAULT,name,.qstruct)
		Quit $select($$$ISERR(sc):sc,1:$$$SKIPCHILDREN)
	}
	
	; Process rule attributes
	Set match=..GetAttribute("MATCH")
	Set empty=..TagAttributes.IsDefined("EMPTY")
	Set classname=..GetAttribute("CLASS")
	If classname="" {
		Set classname=$$$RuleClassName($$$cFAMILYDEFAULT,name)
		Set ..CreateClass=1
	} Else {
		; Ignore rule body and don't create class when CLASS is specified
		Set ..CreateClass=0
	}
	Set language=$zcvt(..GetAttribute("LANGUAGE"),"L")
	If language="" Set language="cache"
	Set sc=$$AddRule^%cspRule(.rulehandle,$$$cFAMILYDEFAULT,
				name,match,empty,classname,
				..TagAttributes.IsDefined("TEXTONLY"),
				..TagAttributes.IsDefined("COMPLETE"),
				language)
	If $$$ISERR(sc) Quit sc
	;
	Do %compiler.Set("%classname",classname)
	Do %compiler.Set("%rulename",name)
	Do %compiler.Set("%rulehandle",rulehandle)
	Do %compiler.Set("%rulelanguage",language)
	Do %compiler.Set("%methodindex",1)
	;
	Kill %builder
	If ..CreateClass {
		m qstruct=%compiler.qstruct
		If $$$defClassDefined(classname) {
			Set sc=$$Delete^%occMain(classname,.qstruct)
			If $$$ISERR(sc) Quit sc
		}
		Set sc=$$Create^%occMain(.handle,classname,.qstruct)
		If $$$ISERR(sc) Quit sc
		;
		Do %compiler.remove("%cspclass.IMPORT")
		Do %compiler.remove("%cspclass.INCLUDES")
		Do %compiler.remove("%cspclass.SUPER")
		Do %compiler.Set("%classhandle",handle)
		;
		Set builder=##class(%CSP.PageBuilder).%New()
		Do %compiler.Set("%pagebuilder",builder)
		;
		Do builder.PushDefaultSection("Start")
		; Set element var for compatability
		If %compiler.PageLanguage="basic" {
			Set line=" element=me"
		} ElseIf %compiler.PageLanguage="mvbasic" {
			Set line=" element=%this"
		} Else {
			Set line="	New element Set element=$this"
		}
		Do builder.GetSection().WriteLine(line,0)
		If ..TagAttributes.IsDefined("NEWSECTION") {
			set tag=$$$matchGame($$$gameTagName($$$mruleMatch("csp",name)),1)
			Do builder.GetSection().WriteLine($case(%compiler.PageLanguage,"basic":" me.","mvbasic":" %this->",:"	Set ..")_"NewSection="""_tag_"""",0)
		}
	} Else {
		Do %compiler.remove("%pagebuilder")
	}
	Quit $$$PROCESSCHILDREN
}

/// Finish compiling a class for this rule.
Method RenderEndTag() As %Status
{
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": end tag rendering")
	; DELETE attribute means delete the rule
	If ..TagAttributes.IsDefined("DELETE") Quit $$$OK
	
	Set sc=$$$OK
	
	; Create the rule class
	If ..CreateClass {
		Set %builder=%compiler.Get("%pagebuilder")
		; Add Quit to current section
		If $piece(%builder.DefaultSection,",",1)="Start" {
			; No End section.  Finish Start section
			; Don't process children since no csr:defrault or
			; csr:children tag encountered.
			If %compiler.IsBasic {
				Do ..WriteServer(" Return "_$$$SKIPCHILDREN)
			} Else {
				Do ..WriteServer("	Quit $$$SKIPCHILDREN")
			}
		} Else {
			; Finish End section.
			If %compiler.IsBasic {
				Do ..WriteServer(" Return "_$$$OK)
			} Else {
				Do ..WriteServer("	Quit $$$OK")
			}
		}
		;
		Set handle=%compiler.Get("%classhandle")
		m qstruct=%compiler.qstruct
		;
		Set sc=$$SetClass^%occModify(handle,$$$cCLASSimport,$tr(%compiler.Get("%cspclass.IMPORT","User"),$c(32,9,13,10),"")) If $$$ISERR(sc) Quit sc
		Set inc=$tr(%compiler.Get("%cspclass.INCLUDES"),$c(32,9,13,10),"")
		If inc'="" Set sc=$$SetClass^%occModify(handle,$$$cCLASSincludecode,inc) If $$$ISERR(sc) Quit sc
		Set sc=$$SetClass^%occModify(handle,$$$cCLASSsuper,$tr(%compiler.Get("%cspclass.SUPER","%CSP.Rule"),$c(32,9,13,10),"")) If $$$ISERR(sc) Quit sc
		Set sc=$$SetClass^%occModify(handle,$$$cCLASSlanguage,%compiler.PageLanguage) If $$$ISERR(sc) Quit sc
		Set sc=$$SetClass^%occModify(handle,$$$cCLASSgeneratedby,%compiler.Get("%pagename")) If $$$ISERR(sc) Quit sc
		Set sc=$$AddParameter^%occModify(handle,"CSRURL") If $$$ISERR(sc) Quit sc
		Set sc=$$SetParameter^%occModify(handle,"CSRURL",$$$cPARAMdefault,%compiler.Get("%pagename")) If $$$ISERR(sc) Quit sc
		If $$$qualifierGetValue(qstruct,"csphidden") Set sc=$$SetClass^%occModify(handle,$$$cCLASShidden,1) If $$$ISERR(sc) Quit sc
		;
		For name="Start","End" {
			Set section=%builder.Sections.GetAt(name)
			Set:section'="" sc=..ProcessSection(section,handle,"Render"_name_"Tag")
			If $$$ISERR(sc) Quit
		}
		;
		Kill %builder
		;
		If $$$ISOK(sc) Do Save^%occMain(handle)
		Do Close^%occMain(handle,.qstruct)
		Do %compiler.remove("%classhandle")
		Set classname=%compiler.Get("%classname")
		// Set language to cache for the class compile so &html works in cache method
		Set %compiler.IsBasic=0,%compiler.PageLanguage="cache"
		If $$$ISERR(sc) Quit sc
		If $$$qualifierGetValue(qstruct,"cspcompileclass") {
			Do Compile^%occCompile(classname,.qstruct,.error)
			If $get(error) Quit $$$ERROR($$$FailedToCreateClass,classname,$get(error(1)))
		} Else {
			Set $$$tCLSLOADED(classname)=""
		}
	}
	;
	Set rulename=%compiler.Get("%rulename")
	If %compiler.IsDefinedByKey("%CSPRules",rulename) {
		Do %compiler.SetByKey("%CSPRule","duplicate",rulename)
	} Else {
		Do %compiler.SetByKey("%CSPRules",rulename,"")
	}
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
	Quit $$$OK
}

/// Add method for section or part of a section
ClassMethod AddSectionMethod(handle As %String, name As %String, return As %String = "%Status", args As %String = "", language As %String = "") As %Status [ Internal ]
{
	Set sc=$$$OK
	If args'="" Set sc=$$SetMethod^%occModify(handle,name,$$$cMETHformalspec,args)
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetMethod^%occModify(handle,name,$$$cMETHreturntype,return)
	If $$$ISERR(sc) Quit sc
	Set sc=$$SetMethod^%occModify(handle,name,$$$cMETHcodemode,$$$cMETHCODEMODECODE)
	If $$$ISERR(sc) Quit sc
	If language'="" Set sc=$$SetMethod^%occModify(handle,name,$$$cMETHlanguage,language)
	Quit sc
}

}
