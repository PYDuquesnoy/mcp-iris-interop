/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

IncludeGenerator %ZEN.ReportUtil

/// Defines a report within a ZEN Report.
Class %ZEN.Report.report Extends group [ Deprecated, System = 3 ]
{

/// to suppress generation of root tag (for instance becasue one is injecting XML into the report) set suppressRotTag to "1" or "true".
Property suppressRootTag As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Depths of the this report structure.
Property %depth As %Integer(XMLPROJECTION = "none") [ Internal ];

/// This array, subcripted by level, is used to track the number
/// of sibling groups at each level.
Property %groupCount As %Integer(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Generate code for this node.
Method %GenerateCode(pReport As %ZEN.Report.reportNode, pCode As %CharacterStream, pLevel As %Integer, xmlns As %String, xmlprefix As %String, sqlcache As %Boolean, pAggregateTag As %String, removeNulls As %Boolean, SetProcessWideRunTimeMode As %Boolean, pAggregatesIgnoreNLS As %Boolean, pDomain As %String) As %Status [ Internal, ProcedureBlock = 0 ]
{
#define quote(%val) $zutil(144,1,%val)
	New tSC
	Set tSC = $$$OK
	Set ..%xmlnamespace = xmlns
	Set ..%xmlnamespaceprefix = xmlprefix
	Set %zenreportdebug=0
	Set ..%sqlcache=sqlcache
	Do pCode.WriteLine(" ; report level parameters xmlns="_xmlns_" xmlprefix="_xmlprefix)
	Set:..removeEmpty=-1 ..removeEmpty=0 ; we are top level so don't inherit from parent
	Do {
		if ..name="" {
			Set tSC = $$$ERROR($$$GeneralError,"name must be non-null and non-empty")
			Quit
		}

		#; find depth of our "graph"
		#; this is only used for first siblings...
		New tGroup,tDepth,tParent,tSubGroups,tAttributes,tElements,tAggregates,tGets,tIncludes,tCalls,tCallElements
		New n,tNode,foundGroup
		Set tDepth = 0
		Set tGroup = ##this
		Do ..FindMaxDepth(tGroup,.tDepth)
		Set ..%depth = tDepth
		Do pCode.Write(" New i,stream,%dummy,%query,%node,%level,%break,%tag,%save,%breakValue,%trueBreak,%switch,%endLoop,%noData,%lastSibling,%firstSibling,%trueSiblingNo,%hasQuery,%groupStarted,%deferredElements,%hasData,%embedXSL,%xmlns,%xmlprefix,%tagname,%elname,%currentrow,%orderby,%cache,%rowpos,%indices,%endFlag,%val,%streamStore,%callStore,%open,%group, %label, %name, %ifexpression, tProcessGroup, tag, label, tBreakOnExpression, %filter, %name, text, inc, %agg, %AggExpression, %setProcessWideRunTimeMode, %top, %sqlexpression, %labelId, tStatement, SQLCODE, %excelSheetNames, err, %excelDateTime, %horlog, %odbcDate, %seconds, %excelTime, %runtimeMode, %excelName, %mode, days, daysdiff, excelDays, excelFraction, seconds, %count, %excelname,ctr,tParms")
		New d
		For d=0:1:tDepth {
			Do pCode.Write(",%agg"_d_",%count"_d_",%countForAvg"_d)
		}
		
		Set ..groupNumber=1
		#; sort children according to type
		Set tSC = ..%SortChildren(.tSubGroups,.tAttributes,.tElements,.tAggregates,.tGets,.tIncludes,.tCalls,.tCallElements)
		If $$$ISERR(tSC) Quit
		if sqlcache=0 {
			if ((tSubGroups > 1) || $D(tElements)) Set tSC=$$$ERROR($$$GeneralError,"Must have parameter SQLCACHE=1 to support sibling groups and/or elements") Quit
		}
		if $$$ISERR(tSC) Quit

		#; set up context and state variables

		Do pCode.WriteLine("")
		Do pCode.WriteLine(" Kill ^||%ISC.ZENReport.elementStore")
		Do %code.WriteLine(" Set %embedXSL = embedXSL")
		Do %code.WriteLine(" Set %setProcessWideRunTimeMode = setProcessWideRunTimeMode")
		Do %code.WriteLine(" Set %mode = $g(pMode)")
		if xmlns="" {
			Do pCode.WriteLine(" if %embedXSL'=0 Set %xmlns=""http://www.intersytems.com/mydefaultnamespace""")
			Do pCode.WriteLine(" else  Set %xmlns=""""")
		} else {
			Do pCode.WriteLine(" Set %xmlns="""_xmlns_"""")
		}
		if xmlprefix="" { 
			Do pCode.WriteLine(" if %embedXSL'=0 Set %xmlprefix=""my""")
			Do pCode.WriteLine(" else  Set %xmlprefix=""""")
		} else {
			Do pCode.WriteLine(" Set %xmlprefix="""_xmlprefix_"""")
		}
		Do pCode.WriteLine(" Set %endLoop=0")
		Do pCode.WriteLine(" Set %firstSibling(0)=1")
		Do pCode.WriteLine(" Set %lastSibling(0)=1")
		Do pCode.WriteLine(" Set %trueSiblingNo(0)=1")
		Set ..%groupStack(0) = 1

		Set ..%groupCount(0) = 1
		Set ..%groupCount(pLevel+1) = 1
		Set tSiblingNo=1
		Set ..%hasquery=0
		#; if user has *not* set run-time mode, set it to display mode
		Do pCode.WriteLine(" Set %groupStarted("_(pLevel)_") = 1")
		Do pCode.WriteLine(" Set %groupStarted("_(pLevel+1)_") = 0")
		Set tUpperCase=1
		If (..runonce) {
			If (..call'="")||(..queryName'="")||(..OnCreateResultSet'="") {
				Set tSC=$$$ERROR($$$GeneralError,"You can't runonce and have a query, result set or call: "_..name)
				quit
			}
		}
		If (..runonce) {
			Set ..%hasquery=1
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %hasData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)

		}
		ElseIf (..sql'="") {
			Do pCode.WriteLine(" if %setProcessWideRunTimeMode Set tRuntimeMode = $zu(115,5," _ $$$quote(..runtimeMode) _ ")")
			Do pCode.WriteLine("  Set tStatement=##class(%SQL.Statement).%New("_..runtimeMode_")")
			Do pCode.WriteLine("  If tStatement="""" Set tSC=%objlasterror goto Error")
			Do pCode.WriteLine("  Set tSC = tStatement.%Prepare("""_..sql_""") If $$$ISERR(tSC) Goto Error")
			Do pCode.WriteLine("  Set %query("_pLevel_") = tStatement.%Execute("_..%NormalizeParamList(pReport,pCode,..parameters,pLevel-1,0)_")")
			do pCode.WriteLine("  if %query("_pLevel_").%SQLCODE < 0 { set tSC = $$$ERROR($$$SQLCode,%query("_pLevel_").%SQLCODE,%query("_pLevel_").%Message) Goto Error }")
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)
			Set ..%hasquery=1
		}
		ElseIf (..sqlexpression'="") {
			Do pCode.WriteLine(" if %setProcessWideRunTimeMode Set tRuntimeMode = $zu(115,5," _ $$$quote(..runtimeMode) _ ")")
			Do pCode.WriteLine(" Set tStatement=##class(%SQL.Statement).%New("_..runtimeMode_")")
			Do pCode.WriteLine(" If tStatement="""" Set tSC=%objlasterror goto Error")
			Do pCode.WriteLine("  X "" Set %sqlexpression="_..sqlexpression_"""")
			Do pCode.WriteLine("  Set tSC = tStatement.%Prepare(%sqlexpression) If $$$ISERR(tSC) Goto Error")
			Do pCode.WriteLine("  Set %query("_pLevel_") = tStatement.%Execute("_..%NormalizeParamList(pReport,pCode,..parameters,pLevel-1,0)_")")
			do pCode.WriteLine("  if %query("_pLevel_").%SQLCODE < 0 { set tSC = $$$ERROR($$$SQLCode,%query("_pLevel_").%SQLCODE,%query("_pLevel_").%Message) Goto Error }")
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)
			Set ..%hasquery=1

		}
		ElseIf (..queryName'="") {
			Set tQueryClass = $S(..queryClass="":%compiledclass.Name,1:..queryClass)
			Do pCode.WriteLine("  Set tStatement=##class(%SQL.Statement).%New("_..runtimeMode_")")
			Do pCode.WriteLine("  If tStatement="""" Set tSC=%objlasterror goto Error")
			Do pCode.WriteLine("  Set tSC = tStatement.%PrepareClassQuery("""_tQueryClass_""","""_..queryName_""") If $$$ISERR(tSC) Goto Error")
			Do pCode.WriteLine("  Set %query("_pLevel_") = tStatement.%Execute("_..%NormalizeParamList(pReport,pCode,..parameters,pLevel,0)_")")
			Do pCode.WriteLine("  If '$IsObject(%query("_pLevel_")) Set tSC=$$$ERROR($$$GeneralError,""Invalid query: queryClass="""_$$$quote(tQueryClass)_"""_"""" queryName="""_$$$quote(..queryName)_""""") GoTo Error")
			do pCode.WriteLine("  if %query("_pLevel_").%SQLCODE < 0 { set tSC = $$$ERROR($$$SQLCode,%query("_pLevel_").%SQLCODE,%query("_pLevel_").%Message) Goto Error }")
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)
			Set ..%hasquery=1
			Set tUpperCase=0
		}
		ElseIf (..OnCreateResultSet'="") {
			#; convert parameters to array to pass to callback
			Do pCode.WriteLine(" Kill tParms")
			Set params=..%NormalizeParamList(pReport,pCode,..parameters,pLevel-1,0,"tParms")
			If $g(params)'="" Do pCode.WriteLine(" Set "_params)
			Do pCode.WriteLine(" Set %query = .."_..OnCreateResultSet_"(.tSC,.tParms)")
			Do pCode.WriteLine(" If $$$ISERR(tSC) Goto Error")
			Do pCode.WriteLine(" If '$IsObject(%query) Set tSC=$$$ERROR($$$GeneralError,""Method "_..OnCreateResultSet_" did not return a result set"") Goto Error")
			Do pCode.WriteLine(" Set %query("_pLevel_")=%query")
			Do pCode.WriteLine(" Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)			
			Set ..%hasquery=1
			#; assume method sets runtime mode
		} ElseIf (..call'="") {
			Set tCallClass = $S(..callClass="":%compiledclass.Name,1:..callClass)
			Set ..%hasquery=0
		}
		Else {
			Set tSC=$$$ERROR($$$GeneralError,"No query defined for report: "_..name)
			Do pCode.WriteLine(" Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Quit
		}
		Do pCode.WriteLine("  Set %top = """_""_..top_"""")
		if ..%sqlcache||..runonce Do pCode.WriteLine("  X:$e(%top)=""%"" ""Set %top=$e(%top,2,*) """)
		if ..%sqlcache||..runonce Do pCode.WriteLine("  Do CalcCache^%occZENReports("_pLevel_","_..%hasquery_","""_..orderby_""",%top,"_..runonce_","_tUpperCase_")")
		#; init aggregates
		Set tSC = ..%ProcessAggregates(pCode,pLevel,"Start",.tAggregates,,pAggregatesIgnoreNLS) If $$$ISERR(tSC) Quit

		#; open tag for report
		if '..suppressRootTag {
			Set tSC = ..%GenerateOpenTag(pReport,pCode,.tAttributes,pLevel,0,.tElements,removeNulls,pDomain)
			If $$$ISERR(tSC) Quit
		}

		#; fetch next row logic
		Do pCode.WriteLine(..%MakeTag(##this,"Fetch",pLevel))
		if +$g(%zenreportdebug) {		
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!-- %Next "_..%MakeTag(pReport,"Fetch",pLevel)_" processing "_..name_" -->""")
		}
		Do pCode.WriteLine(" If '$$Next^%occZENReports("_sqlcache_","_pLevel_",.tSC) Goto EndLoop")
		If ..filter'="" {
				Do ..SetFieldsValueArray(..fields, pCode, pLevel)			
				Do pCode.WriteLine(" X ""Set %filter="_..filter_"""")
				Do pCode.WriteLine(" if %filter=0 goto "_..%MakeTag(##this,"Fetch",pLevel))
		}

		Do pCode.WriteLine(" Do "_..%MakeTag(pReport,"GroupAcc",pLevel)_" ; jsl 11-15-07")
		Do pCode.WriteLine(" If $$$ISERR(tSC) Goto Error")

		#; start-level elements
		Set tSC = ..%StoreElements(pReport,pCode,.tElements,pLevel,1, pAggregateTag,removeNulls,pDomain) If $$$ISERR(tSC) Quit
		Set tSC = ..%StoreCallElements(pCode,.tCallElements,pLevel,pAggregateTag) If $$$ISERR(tSC) Quit
		New prevSibling
		If (+$G(tSubGroups) = 0) {
			#; no children, keep fetching
			Do pCode.WriteLine(" Goto "_..%MakeTag(##this,"Fetch",pLevel))
		}
		Else {
			Do pCode.WriteLine("Dispatch")
			Set prevSibling=""
			For tGroup = 1:1:+$G(tSubGroups) {
				;if +$G(tSubGroups) > 1 Set tSC=$$$ERROR($$$GeneralError,"Sibling groups are not allowed!") Quit
				If ($IsObject($G(tSubGroups(tGroup)))) {
					;Set label=tSubGroups(tGroup).%MakeGroupTag("GroupEnd",pLevel)
					;Do pCode.WriteLine(" if tag="_label_" GoTo "_label)
					if '$IsObject(..%leftMost) Set ..%leftMost=tSubGroups(tGroup)
					Set tSubGroups(tGroup).%leftSibling=prevSibling
					set i=0
					while (i <= pLevel) {
						Set tSubGroups(tGroup).%groupStack(i)=$g(pReport.%groupStack(i))
						set i=i+1
					}
					if tSubGroups(tGroup).removeEmpty=-1 Set tSubGroups(tGroup).removeEmpty=..removeEmpty
					Set tSubGroups(tGroup).%groupStack(pLevel+1) = tGroup	
					Set tSubGroups(tGroup).groupNumber = tGroup
					Set tSubGroups(tGroup).%level = pLevel
					Set tSubGroups(tGroup).%parent = ##this
					Set tSubGroups(tGroup).%groupdepth = 1
					Set tSubGroups(tGroup).%xmlnamespace=xmlns
					Set tSubGroups(tGroup).%xmlnamespaceprefix=xmlprefix
					Set tSubGroups(tGroup).%sqlcache=sqlcache
					If ($IsObject(prevSibling)) {
						Set prevSibling.%rightSibling=tSubGroups(tGroup)
					}
					Set prevSibling=tSubGroups(tGroup)
					Set ..%rightMost=tSubGroups(tGroup)
					Set label=tSubGroups(tGroup).%MakeGroupTag("GroupEnd",pLevel+1)
					Do pCode.WriteLine(" if $g(%label)="""_label_""" k %label GoTo "_label)

					Set tSC = tSubGroups(tGroup).%LookForRightSibling(pReport,pCode,pLevel+1,sqlcache)
					If $$$ISERR(tSC) Quit
				}
			}
			if $$$ISERR(tSC) Quit
			;Set tTagVar = "%tag("_(pLevel+1)_")"
			For tGroup = 1:1:+$G(tSubGroups) {
				Set ..%groupStack(pLevel+1) = tGroup

				If ($IsObject($G(tSubGroups(tGroup)))) {
					Set tSC = tSubGroups(tGroup).%GenerateCode(pReport,pCode,pLevel+1,xmlns,xmlprefix,sqlcache,pAggregateTag,removeNulls,SetProcessWideRunTimeMode,pAggregatesIgnoreNLS,pDomain)
					If $$$ISERR(tSC) Quit
				}
				Else {
					#; no grouping
				}
#if 1				
				If (tGroup < +$G(tSubGroups)) {
					#; go to next sibling
					;Do pCode.WriteLine(" If ($D("_tTagVar_")) { Do "_..%MakeTag(pReport,"GroupEnd",pLevel+1)_" }")  ; March 13, 2009
					Set ..%groupStack(pLevel+1) = tGroup+1
					Do pCode.WriteLine(" Goto "_..%MakeTag(##this,"Group",pLevel+1))
				}
				Else {
					
					Do pCode.WriteLine(" Goto "_..%MakeTag(##this,"Fetch",pLevel))
				}
#else				
				If (tGroup = 1) {
					#; go to next sibling
					;Do pCode.WriteLine(" If ($D("_tTagVar_")) { Do "_..%MakeTag(pReport,"GroupEnd",pLevel+1)_" }")  ; March 13, 2009					
					Set ..%groupStack(pLevel+1) = tGroup+1
					Do pCode.WriteLine(" Goto "_..%MakeTag(##this,"Group",pLevel+1))
				}
				Else {
					Do pCode.WriteLine(" Goto "_..%MakeTag(##this,"Fetch",pLevel))
				}
#endif				

			}

			if $$$ISERR(tSC) Quit
		}
		if $$$ISERR(tSC) Quit
		#; accumulate values top-level aggregates
		Do pCode.WriteLine(..%MakeTag(##this,"GroupAcc",pLevel))
		Set tSC = ..%ProcessAggregates(pCode,pLevel,"Accum",.tAggregates,0,pAggregatesIgnoreNLS) If $$$ISERR(tSC) Quit
		Do pCode.WriteLine(" Quit")

		#; end-of-loop code
		Do pCode.WriteLine("EndLoop")
		Do pCode.WriteLine(" Set %endLoop=1")
		if +$g(%zenreportdebug) {		
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!-- "_..%MakeTag(pReport,"EndLoop",pLevel)_" processing "_..name_" -->""")
		}
		Do pCode.WriteLine(" Set %endFlag("_(pLevel+1)_")=1")
				
		#; close open groups
		If (tDepth > 0) {
			if $D(tSubGroups(1)),$IsObject(tSubGroups(1)) {
				Do pCode.WriteLine(" If ($D(%break(1))) { Do "_tSubGroups(1).%MakeGroupTag("GroupEnd",pLevel+1)_" }")
			}
		}

		#; finalize aggregates
		Set tSC = ..%ProcessAggregates(pCode,pLevel,"End",.tAggregates,,pAggregatesIgnoreNLS) If $$$ISERR(tSC) Quit

		#; process siblings
 		#; following line 5-05-09 JSL2727
 		Do pCode.WriteLine(" if $D(%cache("_pLevel_")) if %cache("_pLevel_").counter.totalRows=0 Goto "_..%MakeTag(pReport,"ExitEndSiblingGroups",pLevel)) 

		set tGroup=2
		Set group=$G(tSubGroups(tGroup))
		Do pCode.WriteLine(" if $g(%lastSibling("_(pLevel+1)_"))'=1 { ; if we processed last sibling we are done with siblings at end of report")		
		If ($IsObject(group)) {
			Do pCode.WriteLine(" GoTo "_group.%MakeGroupTag("Group",pLevel+1))
		}
		Do pCode.WriteLine(" }")		
		If ($IsObject(group)) {
			Do pCode.WriteLine(..%MakeTag(pReport,"EndSiblingGroups",pLevel))
		}
		if (+$G(tSubGroups)>1) {
			Set lastgroup=$G(tSubGroups(tSubGroups))
			#;Do pCode.WriteLine(" w !,""<!--lastgroup=""_$g(%tag("_(pLevel+1)_"))_""-->""")
			#;Do pCode.WriteLine(" w !,""<!--lastgroup=""_$g(%open("_(lastgroup.%MakeLabel(pLevel+1))_"))_""-->""")
			#;Do pCode.WriteLine(" if $D(%tag("_(pLevel+1)_")) Set %open("_lastgroup.%MakeLabel(pLevel+1)_")=1")
			Do pCode.WriteLine(" Do:$D(%tag("_(pLevel+1)_")) "_lastgroup.%MakeGroupTag("GroupEnd",pLevel+1))
		}
		Do pCode.WriteLine(..%MakeTag(pReport,"ExitEndSiblingGroups",pLevel))
		#; write out elements for this report from ^||%ISC.ZENReport.elementStore
		do ..dumpElementStore(pReport, pCode, pLevel)
		Set tSC=..DumpIncludes(pCode,.tIncludes)
		if $$$ISERR(tSC) quit
		Set tSC=..DumpGets(pCode,.tGets)
		if $$$ISERR(tSC) quit
		Set tSC=..DumpCallElements(pCode,.tCallsElements, pLevel)
		if $$$ISERR(tSC) quit
		Set tSC=..DumpCalls(pReport,pCode,.tCalls, pLevel)
		if $$$ISERR(tSC) quit

		#; aggregate elements
		Set tSC = ..%GenerateAggregates(pCode,pLevel,.tAggregates,pAggregateTag,pAggregatesIgnoreNLS,pDomain) If $$$ISERR(tSC) Quit

		#; if ..call is set do ..call
		if ..call'="" {
			Set tCallClass = $S(..callClass="":%compiledclass.Name,1:..callClass)
			if tCallClass'=0 {
				Do pCode.WriteLine(" Do $zobjclassmethod("""_tCallClass_""","""_..call_$s(..callArgument'="":""","""_..callArgument,1:"")_""")")
			} else {
				Do pCode.WriteLine(" Do $zobjmethod($this,"""_..call_$s(..callArgument'="":""","""_..callArgument,1:"")_""")")
			}
		}
		#; close tag for report
		if '..suppressRootTag {
			Set tSC = ..%GenerateCloseTag(pCode,pLevel)
			If $$$ISERR(tSC) Quit
		}

		Do pCode.WriteLine(" Goto Done")
		
	} While(0)
	Quit tSC
}

Method FindMaxDepth(tGroup, ByRef tMax As %Integer)
{
	if '$IsObject(tGroup) Return
	Set tDepth=tMax
	Set tParent = tGroup
	Set foundGroup=0
	For n=1:1:tParent.children.Count() {
		Set tNode = tParent.children.GetAt(n)
		If (tNode.%IsA("%ZEN.Report.group")&&('foundGroup)) {
			Set foundGroup=1
			Set tDepth = tDepth + 1
		}
		Do:tNode.%IsA("%ZEN.Report.group") ..FindMaxDepth(tNode,.tDepth)
		if tDepth>tMax Set tMax=tDepth
	}
}

}
