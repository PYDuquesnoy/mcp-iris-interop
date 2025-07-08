/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

IncludeGenerator %ZEN.ReportUtil

/// Defines a group within a ZEN Report.
Class %ZEN.Report.group Extends reportNode [ Deprecated, System = 3 ]
{

/// Set of nodes contained within this group.
Property children As list Of reportNode(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// XML element name used for this group.<br>
/// If not provided a default will be supplied.
Property name As %ZEN.Datatype.string [ InitialExpression = {..%ClassName(0)}, Required ];

/// Remove empty XML elments
/// If not provided a default of -1 (inherit from parent) will be supplied.
Property removeEmpty As %ZEN.Datatype.boolean [ InitialExpression = -1 ];

/// User-defined list of query parameters. These are used to supply
/// parameter values for the query associated with this group.
Property parameters As list Of %ZEN.Report.parameter(XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// (optional) Name of the class containing the class query that will
/// be used to create a <class>%ResultSet</class> object.<br>
/// This property is only used if <property>queryName<property> is defined.
/// If this property is not defined, then it is assumed that the current report
/// class contains the specified query.
Property queryClass As %ZEN.Datatype.className;

/// (optional) Name of the class query that will
/// be used to create a <class>%ResultSet</class> object.
Property queryName As %ZEN.Datatype.classMember(MEMBERTYPE = "QUERY");

/// Execute elements with report or group once, causes sql, query and resultset to be ignored
Property runonce As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// (optional) SQL statement that, if present, will be used to 
/// create a <class>%ResultSet</class> object.<br>
/// If defined, this takes precedence over 
/// <property>queryClass</property> and <property>queryName</property> and <property>sqlexpression</property>.
Property sql As %ZEN.Datatype.sql;

/// (optional) SQL statement in expression form that, if present, will be used to 
/// create a <class>%ResultSet</class> object.<br>
Property sqlexpression As %ZEN.Datatype.string(MAXLEN = "");

/// When a query is present this induces effect of "SELECT TOP ..top Query"
Property top As %ZEN.Datatype.integer;

/// When a query is present and expression filter is 0, row is skipped
Property filter As %ZEN.Datatype.integer;

Property %hasquery As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// (optional) Runtime mode applied to the <class>%ResultSet</class>
/// object used to fetch results for this report.
Property runtimeMode As %ZEN.Datatype.integer(VALUELIST = ",0,1,2") [ InitialExpression = 2 ];

/// comma separated list of fields by which the group will be sorted
Property orderby As %ZEN.Datatype.string;

/// Name of callback method to call to create a <class>%ResultSet</class> object.
/// This must be the name of an instance method within the report class.<br/>
/// An example callback would look something like this:
/// <example language="CLS!MEMBER">
/// ClassMethod RS1(ByRef pSC As %Status, ByRef pParms) As %ResultSet
/// {
/// 	 Set pSC = $$$OK
/// 	 Set tRS = ##class(%ResultSet.SQL).%Prepare("SELECT Name FROM Sample.Person WHERE Home_City = ? ORDER BY Name",.tError,"",pParms(1))
/// 	 If ($IsObject(tError)) {
/// 	 	Set pSC = tError.Status
/// 	 }
/// 	 Quit tRS
/// }
/// </example>
Property OnCreateResultSet As %ZEN.Datatype.delegator(FORMALSPEC = "*tSC:%Status,*pParameters:%String", RETURNTYPE = "%ResultSet");

/// Name of field (column) in the base query for this report that
/// supply the value for collecting members of this group.
Property breakOnField As %ZEN.Datatype.classMember(MEMBERTYPE = "SQLCOLUMN");

Property ifexpression As %ZEN.Datatype.string [ InitialExpression = 1 ];

/// Optional ObjectScript expression that can either be applied
/// to the grouping value of this group (as <var>%val</var>), or to provide an
/// arbitrary value.
Property breakOnExpression As %ZEN.Datatype.expression;

/// Internal property used to disambiguate multiple groups at the same level.
Property groupNumber As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Internal property used to get level of group
Property %level As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

Property %leftSibling As %ZEN.Report.group [ Internal ];

Property %rightSibling As %ZEN.Report.group [ Internal ];

/// first child (left most) of group of children if any
Property %leftMost As %ZEN.Report.group [ Internal ];

/// last child (right most) of group of children if any
Property %rightMost As %ZEN.Report.group [ Internal ];

Property %parent As %ZEN.Report.group [ Internal ];

/// This array, subcripted by level, is used to track the current
/// set of parent groups as each child group is proccessed.
Property %groupStack As %Integer(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// depth of group
Property %groupdepth As %Integer(XMLPROJECTION = "none") [ Internal ];

/// We use these to record namespace and namespace prefix for qualified name
Property %xmlnamespace As %String(XMLPROJECTION = "none") [ Internal ];

Property %xmlnamespaceprefix As %String(XMLPROJECTION = "none") [ Internal ];

Property %sqlcache As %String(XMLPROJECTION = "none") [ Internal ];

/// Name of fields (columns) in the base query for this report that will
/// supply the values for this item.
Property fields As %ZEN.Datatype.string(MAXLEN = 500);

/// call that will supply XML
Property call As %ZEN.Datatype.string;

/// class for call that will supply XML, can be blank in which case current class used
/// if set to 0, call is called as instance method
Property callClass As %ZEN.Datatype.string;

/// If non-null will provide an argument passed to call
Property callArgument As %ZEN.Datatype.string;

Property AggregateTag As %String(XMLPROJECTION = "none") [ Internal ];

/// True if ExcelHeaders are to be suppressed on group or report
Property suppressExcelHeaders As %ZEN.Datatype.boolean;

/// name of worksheet when group represents an Excel worksheet
Property excelSheetName As %ZEN.Datatype.string;

Method %GenerateCode(pReport As %ZEN.Report.reportNode, pCode As %CharacterStream, pLevel As %Integer, xmlns As %String, xmlprefix As %String, sqlcache As %Boolean, pAggregateTag As %String, removeNulls As %Boolean, SetProcessWideRunTimeMode As %Boolean, pAggregatesIgnoreNLS As %Boolean, pDomain As %String) As %Status [ Internal, ProcedureBlock = 0 ]
{
#define quote(%val) $zutil(144,1,%val)
	Set ..%sqlcache=sqlcache
	#; remove two comments below in order to debug XML generation
	;Set ^IRIS.Temp.Zen("DebugZen")=1
	;Set %zenreportdebug=1
	New tSC
	Set tSC = $$$OK

	Do {
		if ..name="" {
			Set tSC = $$$ERROR($$$GeneralError,"name must be non-null and non-empty")
			Quit
		}
		Set ..AggregateTag=pAggregateTag
		Do pCode.WriteLine(" ; parameters xmlns="_xmlns_" xmlprefix="_xmlprefix)

		New tDepth,tGroup,tSubGroups,tAttributes,tElements,tAggregates,tGets,tIncludes,tCalls,tCallElements
		Set tDepth = pReport.%depth

		#; sort children according to type
		Set tSC = ..%SortChildren(.tSubGroups,.tAttributes,.tElements,.tAggregates,.tGets,.tIncludes,.tCalls,.tCallElements)
		If $$$ISERR(tSC) Quit
	
		New tHasChildren
		Set tHasChildren = (tSubGroups>0)||$D(tElements)||$D(tAggregates)||$D(tGets)||$D(tIncludes)||$D(tCalls)||$D(tCallElements)

		#; establish break variable used to track current breaking value
		New tBreakVar
		Set tBreakVar = "%break("_pLevel_")"

		#; establish variable used to open tag
		New tTagVar
		Set tTagVar = "%tag("_pLevel_")"

		#; test for start/end of group	
		Do pCode.WriteLine(..%MakeTag(pReport,"Group",pLevel)_" ; "_..name)

		#; establish qualified elemented names JSL4224
	 	//Set tSC = ..%QualifyElements(pCode,.tElements,pLevel,pReport.%groupStack(pLevel),pAggregateTag,removeNulls) If $$$ISERR(tSC) Quit // JSL4224

	
		if +$g(%zenreportdebug) {
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%MakeTag(pReport,"Group",pLevel)_" processing "_..name_" -->""")
		}
		;Do pCode.WriteLine(" New %ifexpression")
		Do pCode.WriteLine(" X ""Set %ifexpression="_..ifexpression_"""")
		Do pCode.WriteLine(" If '%ifexpression {")
		if '$IsObject(..%rightSibling) Do pCode.WriteLine(" s %lastSibling("_pLevel_")=1")
		Do pCode.WriteLine(" }")
		Do pCode.WriteLine(" If '%ifexpression Goto "_..%MakeTag(pReport,"EndFetchX",pLevel)_" ;"_..name)
		#; check to see if the group has an additional query
		Set ..%hasquery=0

		#; which sibling are we?
		New tSiblingNo
		Set tSiblingNo = pReport.%groupStack(pLevel)
		
		; Set up %group of GroupEnd labels that define what true sibling is really processing
		New parent
		if (tSiblingNo=1) {
			Set parent=..%parent
			if $isObject(parent) {
				New tSubGroups2,tAttributes2,tElements2,tAggregates2,tGets2,tIncludes2,tCalls2
				Set tSC=parent.%SortChildren(.tSubGroups2,.tAttributes2,.tElements2,.tAggregates2,.tGets2,.tIncludes2,.tCalls2,.tCallElements2)
				for iSib=1:1:tSubGroups2 {
					Do pCode.WriteLine(" Set %group("_pLevel_","_iSib_")="""_tSubGroups2(iSib).%MakeGroupTag("GroupEnd",pLevel)_"""")
				}
			}
		}
		
		New tNextSibling
		Set tNextSibling = ""
		If (tSiblingNo < pReport.%groupCount(pLevel)) {
			Set tNextSibling = tSiblingNo + 1
		}

		If ((tSiblingNo > 1)&&((..breakOnField '= "")||(..breakOnExpression '= ""))) {
			Write !,$$$Text("Note: break condition is ignored for second group at same level.","%ZEN")
			Set ..breakOnField = ""
			Set ..breakOnExpression = ""
		}

		New tBreakExpr,tBreakOnField
		Set tBreakExpr = """"""
		If (..breakOnField '= "") {
			if ($e(..breakOnField)="!") {
				;Set tBreakOnField=$e(..breakOnField,2,$L(..breakOnField))
				Set tBreakOnField="%breakOnField"
			} else {
				Set tBreakOnField=""""_..breakOnField_""""
			}
			Set tBreakExpr= "$$FieldLookup^%occZENReports("_tBreakOnField_","_(pLevel-1)_","_..%sqlcache_")"
			If (..breakOnExpression'="") {
				Do pCode.WriteLine(" Set %val="_tBreakExpr)
				Set tBreakExpr = "("_..breakOnExpression_")"
			}
		}
		Else {
			If (..breakOnExpression'="") {
				Do pCode.WriteLine(" Set %val=""""")
				Set tBreakExpr = "("_..breakOnExpression_")"
			}
		}
		#; if first-time OR grouping var has changed, call start code
		#; if there is no "groupBy", then *always* call start code
		If (tBreakExpr = """""") {
			Do pCode.WriteLine(" Set tProcessGroup = 1")
			Do pCode.WriteLine(" Set %trueBreak("_pLevel_","_tSiblingNo_") = 0")
		}
		Else {
			if ..breakOnField'="",$e(..breakOnField)="!" Do pCode.WriteLine(" X ""Set %breakOnField="_$e(..breakOnField,2,$L(..breakOnField))_"""")
			Do pCode.WriteLine(" Set tBreakOnExpression="_tBreakExpr)
			Do pCode.WriteLine(" Set tProcessGroup = ('$D("_tBreakVar_")||("_tBreakVar_"'=tBreakOnExpression))")
			if (tSiblingNo=1) Do pCode.WriteLine(" Set:$D("_tBreakVar_") %trueBreak("_pLevel_","_tSiblingNo_") = ("_tBreakVar_"'=tBreakOnExpression)")
		}

		#; if we have to process this group, do it here
		#; otherwise skip
		if +$g(%zenreportdebug) {
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!-- tSiblingNo="_tSiblingNo_" processing "_..name_" -->""")
		}	
		#; Do pCode.WriteLine(" w !,""parent.%hasquery="_..%parent.%hasquery_"""")
		if +$g(%zenreportdebug) {
			Do pCode.WriteLine(" w !,""<!-- tBreakVar="_tBreakVar_"=""_$g("_tBreakVar_ ")_""-->""")
		}
		if (tSiblingNo'=1) || ('$IsObject(..%rightSibling)) Do pCode.WriteLine(" If tProcessGroup {")		
		if tSiblingNo=1,$IsObject(..%rightSibling) Do pCode.WriteLine(" If '$D("_tBreakVar_") {")

		set ..%hasquery=..CalcQuery(pReport,pCode,pLevel,SetProcessWideRunTimeMode)
		Do pCode.WriteLine("   Do "_..%MakeTag(pReport,"GroupStart",pLevel)_" ; "_..name)
		
		if (tSiblingNo=1) Do pCode.WriteLine("  Do "_..%MakeTag(pReport,"GroupBreak",pLevel))
		Do pCode.WriteLine(" }")
		Do pCode.WriteLine("   Set %switch("_pLevel_")=1")			
		Do pCode.WriteLine("   if +$g(%trueBreak("_pLevel_","_tSiblingNo_")) {")
		Do pCode.WriteLine("   } ")
		Do pCode.WriteLine("   if '$g(%trueBreak("_pLevel_","_tSiblingNo_")) {")
		if (tSiblingNo=1),$isObject(..%rightSibling) Do pCode.WriteLine("                    Do %cache("_(pLevel-1)_").%put("_(pLevel)_",1)")
		Do pCode.WriteLine("                    Goto "_..%MakeTag(pReport,"Fetch",pLevel))
		Do pCode.WriteLine("   } else {")
		Do pCode.WriteLine("   } ")
		if $IsObject(..%rightSibling) Do pCode.WriteLine(..%rightSibling.%MakeGroupTag("ReturnLabel",pLevel)_" ; "_..name)
		
		if tSiblingNo=1,$IsObject(..%rightSibling) {
			if +$g(%zenreportdebug) {
				Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%rightSibling.%MakeGroupTag("ReturnLabel",pLevel)_" processing "_..name_" -->""")
				Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!-- %trueBreak("_pLevel_","_tSiblingNo_")=""_$g(%trueBreak("_pLevel_","_tSiblingNo_"))_""-->""")
			}
			Do pCode.WriteLine(" if +$g(%trueBreak("_pLevel_","_tSiblingNo_")) Do:$D(%tag("_pLevel_")) "_..%MakeTag(pReport,"GroupEnd",pLevel))
			Do pCode.WriteLine(" if 'tSC goto Error")
			Do pCode.WriteLine(" if +$g(%trueBreak("_pLevel_","_tSiblingNo_")) || +$g(%atEnd("_pLevel_","_tSiblingNo_")) { Goto "_..%rightSibling.%MakeGroupTag("Group",pLevel) _"}")
			If ((tBreakExpr '= """""")) {
				Do pCode.WriteLine(" else { ")
				if (tSiblingNo=1),$isObject(..%rightSibling) Do pCode.WriteLine("   Do %cache("_(pLevel-1)_").%put("_(pLevel)_",1)")
				Do pCode.WriteLine("   Goto "_..%rightSibling.%MakeGroupTag("Fetch",pLevel-1))
				Do pCode.WriteLine(" }")
			} else {
				Do pCode.WriteLine(" else { ")
				if ..%hasquery Do pCode.WriteLine(" if '$g(%trueBreak("_pLevel_","_tSiblingNo_")) Goto "_..%MakeTag(pReport,"Fetch",pLevel))
				Do:'..%hasquery pCode.WriteLine(" if %cache("_pLevel_").atEnd=0 GoTo "_..%rightSibling.%MakeGroupTag("Group",pLevel))
				Do pCode.WriteLine(" }")
			}
			Do pCode.WriteLine(..%parent.%rightMost.%MakeGroupTag("ReturnFromRight",pLevel)_" ; "_..name)
			if $IsObject(..%rightSibling) Do pCode.WriteLine("   Do %cache("_(pLevel-1)_").%get("_pLevel_",0)")
			If ((tBreakExpr = """""")) {
				#; we have data but no break expression, this is a "true" break
				Do pCode.WriteLine(" Set %trueBreak("_pLevel_","_tSiblingNo_") = 0")
			}
			if +$g(%zenreportdebug) {
				Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%parent.%rightMost.%MakeGroupTag("ReturnFromRight",pLevel)_" processing "_..name_" -->""")
				Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!-- %trueBreak("_pLevel_","_tSiblingNo_")=""_$g(%trueBreak("_pLevel_","_tSiblingNo_"))_""-->""")
			}
			Do pCode.WriteLine(" Do "_..%parent.%rightMost.%MakeGroupTag("GroupEnd",pLevel))
			Do pCode.WriteLine(" if 'tSC goto Error")
			Do pCode.WriteLine(" Set %switch("_pLevel_")=0")
			#; Do pCode.WriteLine(" w !,""parent.%hasquery="_..%parent.%hasquery_"""")
			Do pCode.WriteLine(" if $g(%trueBreak("_pLevel_","_tSiblingNo_")) {")
			Do pCode.WriteLine("   Set %trueBreak("_pLevel_","_tSiblingNo_")=0") ; we've always processed a break if we've returned from the right
			do ..CalcQuery(pReport,pCode,pLevel,SetProcessWideRunTimeMode)
			Do pCode.WriteLine("   Do "_..%MakeTag(pReport,"GroupStart",pLevel))
			Do pCode.WriteLine("   Do "_..%MakeTag(pReport,"GroupBreak",pLevel))

			if (tSiblingNo=1),$isObject(..%rightSibling) Do pCode.WriteLine("  Do %cache("_(pLevel-1)_").%put("_(pLevel)_",1)")
			Do pCode.WriteLine("   Goto "_..%MakeTag(pReport,"Fetch",pLevel))
			Do pCode.WriteLine(" }")
			Do pCode.WriteLine(" Goto "_..%parent.%rightMost.%MakeGroupTag("EndFetchX",pLevel))
			Do pCode.WriteLine(..%parent.%rightMost.%MakeGroupTag("ReturnFromChild",pLevel)_" ; "_..name)
			if +$g(%zenreportdebug) {
				Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%parent.%rightMost.%MakeGroupTag("ReturnFromChild",pLevel)_" processing "_..name_" -->""")
			}
			if (pLevel=1) {
				Do pCode.WriteLine(" Goto:%endLoop=0 "_..%rightSibling.%MakeGroupTag("Fetch",pLevel-1))
				Do pCode.WriteLine(" Goto:%endLoop=1 "_..%MakeTag(pReport,"EndSiblingGroups",pLevel-1))
			} else {
				Do pCode.WriteLine(" Goto "_..%rightSibling.%MakeGroupTag("Fetch",pLevel-1))
			}

		}

		#; fetch next row logic (if this group has a query)
		Do pCode.WriteLine(..%MakeTag(pReport,"Fetch",pLevel)_" ; "_..name)
		if +$g(%zenreportdebug) {
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%MakeTag(pReport,"Fetch",pLevel)_" processing "_..name_" -->""")
		}
		
		If ..%hasquery {

 			if +$g(%zenreportdebug) {
				Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!-- %Next "_..%MakeTag(pReport,"Fetch",pLevel)_" processing "_..name_" -->""")
 			}			
			Do pCode.WriteLine(" If '$$Next^%occZENReports("_sqlcache_","_pLevel_",.tSC) Set %hasData("_pLevel_","_tSiblingNo_") = 0 Goto "_..%MakeTag(pReport,"EndFetch",pLevel))
			If ..filter'="" {
				Do ..SetFieldsValueArray(..fields, pCode, pLevel)			
				Do pCode.WriteLine(" X ""Set %filter="_..filter_"""")
				Do pCode.WriteLine(" if %filter=0 goto "_..%MakeTag(pReport,"Fetch",pLevel))
			}
			Do pCode.WriteLine(" If %noData("_pLevel_","_tSiblingNo_") = 1 Set %hasData("_pLevel_","_tSiblingNo_") = 0 GoTo "_..%MakeTag(pReport,"EndFetch",pLevel))
			Do pCode.WriteLine(" If $$$ISERR(tSC) Goto Error")
			Do pCode.WriteLine(" Set %hasData("_pLevel_","_tSiblingNo_") = 1")
			#; elements from fetch
		}
 		if +$g(%zenreportdebug) {
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!-- Generate elements "_..name_" -->""")
 		}		
 		if '..%hasquery,..filter'="" { ; Prodlog 86007
 			Do ..SetFieldsValueArray(..fields, pCode, pLevel)			
	 		Do pCode.WriteLine(" X ""Set %filter="_..filter_"""")
			Do pCode.WriteLine(" if %filter=1 { ")
 		}
 		Set tSC = ..%StoreElements(pReport,pCode,.tElements,pLevel,tSiblingNo,pAggregateTag,removeNulls,pDomain) If $$$ISERR(tSC) Quit
 		
 		Set tSC = ..%StoreCallElements(pCode,.tCallElements,pLevel,pAggregateTag) If $$$ISERR(tSC) Quit
 		
 		Set tSC = ..%StoreRowPosition(pCode,pLevel)
 		
 		if '..%hasquery,..filter'="" { ; Prodlog 86007
	 		Do pCode.WriteLine(" }")
 		}
		
 		if +$g(%zenreportdebug) {
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!-- GoTo "_..%MakeTag(pReport,"GroupDo",pLevel)_" processing "_..name_" -->""")
 		}		
		Do pCode.WriteLine(" Goto "_..%MakeTag(pReport,"GroupDo",pLevel))

		#; code to run when group breaks
		Do pCode.WriteLine(..%MakeTag(pReport,"GroupBreak",pLevel)_" ; "_..name)
 		if +$g(%zenreportdebug) {
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%MakeTag(pReport,"GroupBreak",pLevel)_" processing "_..name_" -->""")
 		}		
 		New n,tNode
		if (tSiblingNo=1) {
			Set n = $O(tAttributes(""))
			While (n'="") {
				Set tNode = tAttributes(n)
				Set tSC = ..%GetNodeField(tNode,.tNodeField,pLevel-1) If $$$ISERR(tSC) Quit
				If (tNode.expression'="") {
					Set tSC = ..%GetNodeExpr(tNode,.tNodeExpr) If $$$ISERR(tSC) Quit
				}
				Else {
					Set tNodeExpr = tNodeField
				}
	
				Set n = $O(tAttributes(n))
			}
		}
		Do pCode.WriteLine(" Quit")
		#; code to run when group starts
		Do pCode.WriteLine(..%MakeTag(pReport,"GroupStart",pLevel)_" ; "_..name)
 		if +$g(%zenreportdebug) {
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%MakeTag(pReport,"GroupStart",pLevel)_" processing "_..name_" -->""")
 		}		
		#; end previous group
 		if +$g(%zenreportdebug)	{
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!-- ending group variable = ""_$D("_tTagVar_")_"" tTagVar=""_$g("_tTagVar_")_""-->""")
 		}		
  		Do pCode.WriteLine(" If ($D("_tTagVar_")) { Do "_..%MakeTag(pReport,"GroupEnd",pLevel)_" }") 
  		Do pCode.WriteLine(" if 'tSC goto Error")
		#; get saved position
		if tSiblingNo=2 Do pCode.WriteLine(" Do %cache("_(pLevel-1)_").%put("_pLevel_",0)")
		if tSiblingNo=2 Do pCode.WriteLine(" Do %cache("_(pLevel-1)_").%get("_pLevel_",1)")

  		Do pCode.WriteLine(" Set %groupStarted("_pLevel_")= 1")
  		Do pCode.WriteLine(" Set %trueSiblingNo("_pLevel_")="_tSiblingNo)
		Do pCode.WriteLine(" Set %open("_..%MakeLabel(pLevel)_")=1")
		;Do pCode.WriteLine(" Set %opensib("_pLevel_",%trueSiblingNo("_pLevel_"))=1")
		#; set up state for this group; write out open tags, etc.
   		Do pCode.WriteLine(" Set "_..getCount(pLevel)_"=0")
   		If (tSiblingNo = 1) {
   			#; only first sibling needs to set breaking var
   			if ..breakOnField'="",$e(..breakOnField)="!" Do pCode.WriteLine(" X ""Set %breakOnField="_$e(..breakOnField,2,$L(..breakOnField))_"""")
   			//foobar
			If (..breakOnField '= "") {
				if ($e(..breakOnField)="!") {
					;Set tBreakOnField=$e(..breakOnField,2,$L(..breakOnField))
					Set tBreakOnField="%breakOnField"
				} else {
					Set tBreakOnField=""""_..breakOnField_""""
				}
				Set tBreakExpr= "$$FieldLookup^%occZENReports("_tBreakOnField_","_(pLevel-1)_","_..%sqlcache_")"
				If (..breakOnExpression'="") {
					Do pCode.WriteLine(" Set %val="_tBreakExpr)
					Set tBreakExpr = "("_..breakOnExpression_")"
				}
			}
			Else {
				If (..breakOnExpression'="") {
					Do pCode.WriteLine(" Set %val=""""")
					Set tBreakExpr = "("_..breakOnExpression_")"
				}
			}
			if ((..breakOnField="") && (..breakOnExpression'="")) {
				Do pCode.WriteLine(" Set "_tBreakVar_"=tBreakOnExpression")
			} else {
				Do pCode.WriteLine(" Set "_tBreakVar_"="_tBreakExpr)
			}
   		}
   		Do pCode.WriteLine(" Set %level="_pLevel)
   		Do pCode.WriteLine(" Set inc=$I(%node("_(pLevel)_"))")
   				#; start-level elements
		if '$IsObject(..%rightSibling) Do pCode.WriteLine(" s %lastSibling("_pLevel_")=1")
		if $IsObject(..%rightSibling) Do pCode.WriteLine(" s %lastSibling("_pLevel_")=0")
		if '$IsObject(..%leftSibling) Do pCode.WriteLine(" s %firstSibling("_pLevel_")=1")
		if $IsObject(..%leftSibling) Do pCode.WriteLine(" s %firstSibling("_pLevel_")=0")
		Do pCode.WriteLine(" Kill ^||%ISC.ZENReport.elementStore("_pLevel_","_tSiblingNo_")")
		Do pCode.WriteLine(" Kill %streamStore("_pLevel_","_tSiblingNo_")")
		Do pCode.WriteLine(" Kill %callStore("_pLevel_","_tSiblingNo_")")
  		Set tSC = ..%GenerateOpenTag(pReport,pCode,.tAttributes,pLevel,'tHasChildren&&(..call=""),.tElements,removeNulls,pDomain) If $$$ISERR(tSC) Quit

		#; init aggregates
		Set tSC = ..%ProcessAggregates(pCode,pLevel,"Start",.tAggregates,,pAggregatesIgnoreNLS) If $$$ISERR(tSC) Quit

		Do pCode.WriteLine(" Quit")

		#; accumulate values for aggregates
		Do pCode.WriteLine(..%MakeTag(pReport,"GroupAcc",pLevel)_" ; "_..name) 
 		if +$g(%zenreportdebug)	{
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%MakeTag(pReport,"GroupAcc",pLevel)_" processing "_..name_" -->""")
 		}		
		#; only accumulate for first sibling
		#; !!! if so, then depth is accurate !!!
		Do pCode.WriteLine(" if (%firstSibling("_pLevel_")=1)||(%hasQuery(%trueSiblingNo("_pLevel_"))=1) {")
		Set tSC = ..%ProcessAggregates(pCode,pLevel,"Accum",.tAggregates,..%groupdepth,pAggregatesIgnoreNLS) If $$$ISERR(tSC) Quit
		Do pCode.WriteLine(" }")
		Do pCode.WriteLine(" Quit")

		#; code to run when group ends
		Do pCode.WriteLine(..%MakeTag(pReport,"GroupEnd",pLevel)_" ; "_..name)
		Do pCode.WriteLine(" Set %count=$g(%count)+1")
		Do pCode.WriteLine(" Set tag ="""_..%MakeTag(pReport,"GroupEnd",pLevel)_"""")
		;# Do pCode.WriteLine(" w !, ""<!--tag=""_tag_""-->""")
		#; March 16, 2009, 7:34 AM
		#; Do pCode.WriteLine(" s label="""" f  s label=$o(%open(label)) q:label=""""  w !,""<!--""_label_""-->"" w ""<!--""_%open(label)_""-->""")
		Do pCode.WriteLine(" Set label=$g(%group("_pLevel_",%trueSiblingNo("_pLevel_")))")
		Do pCode.WriteLine(" if label="""" Set label=tag")
		#; Dispatch to real group GroupEnd that should handle this GroupEnd
		Do pCode.WriteLine(" if tag'=label,%count=1 Set %label=label Set %count=$g(%count)+1 goto Dispatch")
		Do pCode.WriteLine(" Set %count=0")
		;Do pCode.WriteLine(" if +$g(%open(label))=0 quit ")
		#; Do pCode.WriteLine(" w !,""<!-- entering -->""")
		Do pCode.WriteLine(" Set %open(label)=0")
 		if +$g(%zenreportdebug)	{
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%MakeTag(pReport,"GroupEnd",pLevel)_" processing "_..name_" -->""")
 		}		
		#; close out child group, if any, note we could be coming in through first sibling tag
		#; to close out child groups in later sibling
		#; we won't close out a group twice since we are guarded by %tag and its being defined
		#; to avoid closing out a group twice
		
		New tTagVar2
		Set tTagVar2 = "%tag("_(pLevel+1)_")"
		#; search for any sibling with children
		New parent,group
		Set parent=..%parent
		while ($IsObject(parent)) {
			Set group=parent.%leftMost
			while ($IsObject(group)) {
				if ($IsObject(group.%leftMost)) Do pCode.WriteLine(" If ($D("_tTagVar2_")) { Do "_group.%leftMost.%MakeGroupTag("GroupEnd",pLevel+1)_" } //"_group.%leftMost.name_" close child group") Quit
				Set group=group.%rightSibling
			}
			Set parent=parent.%rightSibling
		}
		
		#; write out elements for this group from ^||%ISC.ZENReport.elementStore
		Do pCode.WriteLine(" if $g(%tag("_pLevel_"))'="""" {")
		Do ..SetFieldsValueArray(..fields, pCode, pLevel) ; Prodlog 86007
		do ..dumpElementStore(pReport, pCode, pLevel)
		Set tSC=..DumpIncludes(pCode,.tIncludes)
		if $$$ISERR(tSC) quit
		Set tSC=..DumpGets(pCode,.tGets)
		if $$$ISERR(tSC) quit
		Set tSC=..DumpCallElements(pCode,.tCallElements,pLevel)
		if $$$ISERR(tSC) quit
		Set tSC=..DumpCalls(pReport,pCode,.tCalls,pLevel)
		if $$$ISERR(tSC) quit
		#; write out closing tag for group
		#; write out XML generated by call if this is a call group (no query, just a call)
		if ..call'="" {
			Set tCallClass = $S(..callClass="":%compiledclass.Name,1:..callClass)
			if tCallClass'=0 {
				Do pCode.WriteLine(" Do $zobjclassmethod("""_tCallClass_""","""_..call_$s(..callArgument'="":""","""_..callArgument,1:"")_""")")
			} else {
				Do pCode.WriteLine(" Do $zobjmethod($this,"""_..call_$s(..callArgument'="":""","""_..callArgument,1:"")_""")")
			}
		}

		#; finalize aggregates
		Do pCode.WriteLine(" if (%firstSibling("_pLevel_")=1)||(%hasQuery(%trueSiblingNo("_pLevel_"))=1) {")
		if $isObject(..%leftSibling) {
			#; aggregate elements
			Set tSC = ..%leftSibling.%SortChildren(.tSubGroups1,.tAttributes1,.tElements1,.tAggregates1,.tGets1,.tIncludes1,.tCalls1,.tCallElements1)
			If $$$ISERR(tSC) Quit
			Do pCode.WriteLine(" if $D(%tag("_pLevel_")),%trueSiblingNo("_pLevel_")="_(tSiblingNo-1)_"{")
			Set tSC = ..%ProcessAggregates(pCode,pLevel,"End",.tAggregates1,,pAggregatesIgnoreNLS) If $$$ISERR(tSC) Quit
			Set tSC = ..%GenerateAggregates(pCode,pLevel,.tAggregates1,pAggregateTag,pAggregatesIgnoreNLS,pDomain) If $$$ISERR(tSC) Quit
			Do pCode.WriteLine(" } else {")
			Set tSC = ..%ProcessAggregates(pCode,pLevel,"End",.tAggregates,,pAggregatesIgnoreNLS) If $$$ISERR(tSC) Quit
			Set tSC = ..%GenerateAggregates(pCode,pLevel,.tAggregates, pAggregateTag,pAggregatesIgnoreNLS,pDomain) If $$$ISERR(tSC) Quit
			Do pCode.WriteLine(" } ")
		} else {
			Set tSC = ..%ProcessAggregates(pCode,pLevel,"End",.tAggregates,,pAggregatesIgnoreNLS) If $$$ISERR(tSC) Quit
			Set tSC = ..%GenerateAggregates(pCode,pLevel,.tAggregates,pAggregateTag,pAggregatesIgnoreNLS,pDomain) If $$$ISERR(tSC) Quit
		}
		Do pCode.WriteLine(" }")

		Set tSC = ..%GenerateCloseTag(pCode,pLevel) If $$$ISERR(tSC) Quit
		Do pCode.WriteLine(" }")
		Do pCode.WriteLine(" kill %break("_pLevel_")")
		Do pCode.WriteLine(" kill:$g(%lastSibling("_pLevel_")) %trueBreak("_pLevel_","_tSiblingNo_")")
		Do pCode.WriteLine(" Quit")

		Do pCode.WriteLine(..%MakeTag(pReport,"GroupDo",pLevel)_" ; "_..name)
 		if +$g(%zenreportdebug)	{
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%MakeTag(pReport,"GroupDo",pLevel)_" processing "_..name_" -->""")
 		}		
		#; if this is inner-most group, process all aggregates,etc. ; commented out jsl 11-13-07
 		if '..%hasquery,..filter'="" { ; Prodlog 86007
 			Do ..SetFieldsValueArray(..fields, pCode, pLevel)
	 		Do pCode.WriteLine(" X ""Set %filter="_..filter_"""")
			Do pCode.WriteLine(" if %filter=1 { ")
 		}

		Do pCode.WriteLine(" Do "_..%MakeTag(pReport,"GroupAcc",pLevel)_" ; "_..name)
 		if '..%hasquery,..filter'="" { ; Prodlog 86007
			Do pCode.WriteLine(" } ")
 		}

		#; we fall through to subgroups
		#; process subgroup(s)
		Set pReport.%groupCount(pLevel+1) = +$G(tSubGroups)
		New prevSibling
		Set prevSibling=""
		For tGroup = 1:1:+$G(tSubGroups) {
			If ($IsObject($G(tSubGroups(tGroup)))) {
				if tSubGroups(tGroup).removeEmpty=-1 Set tSubGroups(tGroup).removeEmpty=..removeEmpty
				Set tSubGroups(tGroup).%groupStack(0)=1
				Set tSubGroups(tGroup).%groupStack(pLevel+1) = tGroup
				Set tSubGroups(tGroup).groupNumber = tGroup
				Set tSubGroups(tGroup).%groupdepth = ..%groupdepth+1
				Set tSubGroups(tGroup).%level = pLevel
				Set tSubGroups(tGroup).%parent = ##this
				Set tSubGroups(tGroup).%xmlnamespace=xmlns
				Set tSubGroups(tGroup).%xmlnamespaceprefix=xmlprefix
				Set tSubGroups(tGroup).%sqlcache=sqlcache

				If ($IsObject(prevSibling)) {
					Set prevSibling.%rightSibling=tSubGroups(tGroup)
				}
				Set prevSibling=tSubGroups(tGroup)
				Set ..%rightMost=tSubGroups(tGroup)
			}
		}
		New tGroup
		For tGroup = 1:1:+$G(tSubGroups) {
			Set pReport.%groupStack(pLevel+1) = tGroup
	
			If ($IsObject($G(tSubGroups(tGroup)))) {
				Set tSC = tSubGroups(tGroup).%GenerateCode(pReport,pCode,pLevel+1,xmlns,xmlprefix,sqlcache,pAggregateTag,removeNulls,SetProcessWideRunTimeMode,pAggregatesIgnoreNLS,pDomain) If $$$ISERR(tSC) Quit
			}

			If (..%hasquery) {
				If (tGroup < +$G(tSubGroups)) {
					#; go to next sibling
					;Do pCode.WriteLine(" If ($D("_tTagVar_")) { Do "_..%MakeTag(pReport,"GroupEnd",pLevel)_" }")  ; March 13, 2009
					Set pReport.%groupStack(pLevel+1) = tGroup+1
					Do pCode.WriteLine(" Goto "_..%MakeTag(pReport,"Group",pLevel+1))
				}
				Else {
					if ($IsObject(..%rightSibling)) {
						Do pCode.WriteLine(" GoTo "_..%rightSibling.%MakeGroupTag("ReturnLabel",pLevel)_" ; jsl return from right children")
					}
				}
			}
		}	
		#;if ('$IsObject(..%rightSibling)) { // 1-7-08 jsl Prodlog 62062
			
			if (..%hasquery) Do pCode.WriteLine(" Goto "_..%MakeTag(pReport,"Fetch",pLevel)_" ; jsl 11-12-07")
		#;}

		#; End fetch tag
		Do pCode.WriteLine(..%MakeTag(pReport,"EndFetch",pLevel)_" ; "_..name)
		;Do pCode.WriteLine(" w !,""<!-- current row=""_%cache("_(pLevel)_").counter.currentrow_"" -->""")
		;Do pCode.WriteLine(" w !,""<!-- totalRows=""_%cache("_(pLevel)_").counter.totalRows_"" -->""")
		If (tBreakExpr = """""") {
			Do pCode.WriteLine(" Set %trueBreak("_pLevel_","_tSiblingNo_") = 1")
		}

		Do pCode.WriteLine(" Set %noData("_pLevel_","_tSiblingNo_") = 1")
 		if +$g(%zenreportdebug) {				
			Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) w !,""<!--"_..%MakeTag(pReport,"EndFetch",pLevel)_" processing "_..name_" %switch("_(pLevel-1)_")=""_$g(%switch("_(pLevel-1)_"))_"" -->""")
 		}		
#if 1
 		If $IsObject(..%rightSibling),tSiblingNo=1 {
 			Do pCode.WriteLine(" if %cache("_(pLevel)_").counter.currentrow = %cache("_(pLevel)_").counter.totalRows GoTo "_..%rightSibling.%MakeGroupTag("Group",pLevel))
 		}
#endif	 		
#if 1
		If '$IsObject(..%leftSibling) && '$IsObject(..%rightSibling) && $IsObject(..%parent.%rightSibling) && (..%parent.groupNumber=1) && '..%hasquery { // nested group
			Do pCode.WriteLine(" if %cache("_(pLevel)_").counter.currentrow = %cache("_(pLevel)_").counter.totalRows GoTo "_..%parent.%rightSibling.%MakeGroupTag("Group",pLevel-1))
		}
#endif	
		If '$IsObject(..%leftSibling) && '$IsObject(..%rightSibling) && $IsObject(..%parent.%rightSibling) && (..%parent.groupNumber=1) { // nested group
			// search for break
			Set tLevel=pLevel
			Set queryGroup = $this
			while (queryGroup'="") {
				if (queryGroup.breakOnField=1)||(queryGroup.breakOnExpression=1) Quit
				Set tLevel=tLevel-1
				Set queryGroup = queryGroup.%parent
			}
			if queryGroup'="" {
				Do pCode.WriteLine(" Goto:$g(%trueBreak("_(tLevel)_",1)) "_..%parent.%rightSibling.%MakeGroupTag("Group",pLevel-1))
				Do pCode.WriteLine(" Goto:'$g(%trueBreak("_(tLevel)_",1)) "_queryGroup.%MakeTag(pReport,"Fetch",tLevel-1))
			}
		}

		if ('$IsObject(..%rightSibling) && $IsObject(..%parent.%rightSibling) && (..%parent.groupNumber=1)) {
			Do pCode.WriteLine(" Goto:%switch("_(pLevel-1)_") "_..%parent.%rightSibling.%MakeGroupTag("ReturnLabel",pLevel-1))
			Do pCode.WriteLine(" Goto:'%switch("_(pLevel-1)_") "_..%parent.%parent.%rightMost.%MakeGroupTag("ReturnFromChild",pLevel-1))
		} 
		elseif ('$IsObject(..%rightSibling) && (tSiblingNo > 1)) {
			if (pLevel=1) {
				Do pCode.WriteLine(" Goto:%endLoop=0 "_..%parent.%rightMost.%MakeGroupTag("ReturnFromRight",pLevel))
				Do pCode.WriteLine(" Goto:%endLoop=1 "_..%MakeTag(pReport,"EndSiblingGroups",pLevel-1))
			} else {
				Do pCode.WriteLine(" Goto:%endLoop=0 "_..%parent.%rightMost.%MakeGroupTag("ReturnFromRight",pLevel))
				
			}
		} elseif ((tSiblingNo > 1) || (pLevel > 1)) { ; fall through
			Set tLevel=pLevel
			if pLevel>1,'..%hasquery,tSiblingNo=1,(..breakOnField'=""||(..breakOnExpression'="")),$IsObject(..%rightSibling),('..%rightSibling.%hasQueryDefined()) {
				// (..breakOnField'=""||(..breakOnExpression'="")) JSL4433 - add this condition above
				Do pCode.WriteLine(" // detect whether to fall through in code generation rightSibling="_(..%rightSibling.name))
				Set rightSibling=..%rightSibling 
				while ($IsObject(rightSibling)) {
					Do pCode.WriteLine(" // rightSibling="_rightSibling.name)
					Set rightSibling = rightSibling.%rightSibling
				}
				Set parent=..%parent
				While (parent '="") {
					if parent.%hasquery Quit
					Set tLevel=tLevel-1					
					Set parent=parent.%parent
				}
				if parent'="" {
					Do pCode.WriteLine(" // go back for more data from upper level pLevel="_tLevel)
					Do pCode.WriteLine(" Goto "_..%MakeTag(pReport,"Fetch",tLevel-1)) ; 01-18-08
				} else {
					Do pCode.WriteLine(" // fall through pLevel="_tLevel)
				}
			} else {
				Do pCode.WriteLine(" // fall through pLevel="_pLevel)
			}
		} else { 
		    #; go back for more data from upper level
		    Do pCode.WriteLine(" // go back for more data from upper level pLevel="_pLevel_" (in else clause)")
			if ('..%hasquery) Do pCode.WriteLine(" Goto "_..%MakeTag(pReport,"Fetch",pLevel-1)) ; 01-18-08
			#; on 01-18-08 fall through to right sibling?
		}
		Do pCode.WriteLine(..%MakeTag(pReport,"EndFetchX",pLevel)_" ;"_..name)
		Kill pReport.%groupStack(pLevel+1)
		Kill pReport.%groupCount(pLevel+1)

	} While(0)

	Quit tSC
}

Method dumpElementStore(pReport As %ZEN.Report.reportNode, pCode As %CharacterStream, pLevel As %Integer)
{
	Do pCode.WriteLine(" new i,stream,chunksize,chunk,filteredStream,len,c,searchLITag,tag,part")
	Do pCode.WriteLine(" for i=1:1:+$g(^||%ISC.ZENReport.elementStore("_pLevel_",%trueSiblingNo("_pLevel_"))) w ^||%ISC.ZENReport.elementStore("_pLevel_",%trueSiblingNo("_pLevel_"),i),!")
	Do pCode.WriteLine(" for i=1:1:+$g(%streamStore("_pLevel_",%trueSiblingNo("_pLevel_"))) {")
	Do pCode.WriteLine("     set elemname=%streamStore("_pLevel_",%trueSiblingNo("_pLevel_"),""elemname"",i)")
	Do pCode.WriteLine("     set oid=%streamStore("_pLevel_",%trueSiblingNo("_pLevel_"),""oid"",i)")
	Do pCode.WriteLine("     set escape=%streamStore("_pLevel_",%trueSiblingNo("_pLevel_"),""escape"",i)")
	Do pCode.WriteLine("	 w !,""<""_elemname_"">""")
	Do pCode.WriteLine("     set stream=##class(%Stream.Object).%Open(oid)")
	Do pCode.WriteLine("     if stream'="""" {")
	Do pCode.WriteLine("       do stream.Rewind()")	
	Do pCode.WriteLine("       if escape'=""html"" {")
	Do pCode.WriteLine("         Set chunksize=32000")
	Do pCode.WriteLine("         While 'stream.AtEnd {")
	Do pCode.WriteLine("             Set chunk=stream.Read(chunksize)")
	Do pCode.WriteLine("             Set chunk=$tr(chunk,$c(0))")
	Do pCode.WriteLine("             w $$xml^%occZENReports(chunk,escape)")
	Do pCode.WriteLine("         }")
	Do pCode.WriteLine("       } else { ") ; more complex case of cleaning mal-formed html
	Do pCode.WriteLine("         set filteredStream=##class(%GlobalCharacterStream).%New()")
	Do pCode.WriteLine("         Set searchLITag=0")
	Do pCode.WriteLine("         while (stream.AtEnd=0) {")
	Do pCode.WriteLine("            Set c=stream.Read(1)")
	Do pCode.WriteLine("            if c=""<"",searchLITag=0 {")
	Do pCode.WriteLine("                Do filteredStream.Write(c)")
	Do pCode.WriteLine("                set tag=stream.Read(2)")
	Do pCode.WriteLine("                Do filteredStream.Write(tag)")
	Do pCode.WriteLine("                if tag=""LI""||(tag=""li"") {")
	Do pCode.WriteLine("                   Set searchLITag=1")
	Do pCode.WriteLine("                }")
	Do pCode.WriteLine("            }")
	Do pCode.WriteLine("            elseif c=""<"",searchLITag=1 {")
	Do pCode.WriteLine("               set tag=stream.Read(4)")
	Do pCode.WriteLine("               if $e(tag,1,3)=""LI>""||($e(tag,1,3)=""li>"") {")
	Do pCode.WriteLine("                  Do filteredStream.Write(""</LI>"")")
	Do pCode.WriteLine("                  Do filteredStream.Write(c)")
	Do pCode.WriteLine("                  Do filteredStream.Write(tag)")
	Do pCode.WriteLine("                  Set searchLITag=1")
	Do pCode.WriteLine("               } elseif $e(tag,1,4)=""/UL>""||($e(tag,1,4)=""/UL>"")||($e(tag,1,4)=""/OL>"")||($e(tag,1,4)=""/OL>"") {")
	Do pCode.WriteLine("                  Do filteredStream.Write(""</LI>"")")
	Do pCode.WriteLine("                  Do filteredStream.Write(c)")
	Do pCode.WriteLine("                  Do filteredStream.Write(tag)")
	Do pCode.WriteLine("                  Set searchLITag=0")
	Do pCode.WriteLine("               } elseif $e(tag,1,4)=""/LI>""||($e(tag,1,4)=""/li>"") {")
	Do pCode.WriteLine("                  Do filteredStream.Write(c)")
	Do pCode.WriteLine("                  Do filteredStream.Write(tag)")
	Do pCode.WriteLine("                  Set searchLITag=0")
	Do pCode.WriteLine("               } else {")
	Do pCode.WriteLine("                  Do filteredStream.Write(c)")
	Do pCode.WriteLine("                  Do filteredStream.Write(tag)")
	Do pCode.WriteLine("               }")
	Do pCode.WriteLine("            } else {")
	Do pCode.WriteLine("               Do filteredStream.Write(c)")
	Do pCode.WriteLine("            }")
	Do pCode.WriteLine("         }")
	Do pCode.WriteLine("         set stream=filteredStream")
	Do pCode.WriteLine("         Do stream.Rewind()")
	Do pCode.WriteLine("         set len=20000")
	Do pCode.WriteLine("         while (stream.AtEnd=0) {")
    Do pCode.WriteLine("             set part=stream.Read(.len)")
    Do pCode.WriteLine("             if ($l(part,""<"")'=$l(part,"">""))||($l(part,""&"")'=$l(part,"";"")) while (($l(part,""<"")'=$l(part,"">""))||($l(part,""&"")'=$l(part,"";"")))&&(stream.AtEnd=0) { s part=part_stream.Read(1) }")
    Do pCode.WriteLine("             w $$xml^%occZENReports(part,escape)")
    Do pCode.WriteLine("         }")
	Do pCode.WriteLine("       }")
	Do pCode.WriteLine("     }")
	Do pCode.WriteLine("	 w !,""</""_elemname_"">""")
	Do pCode.WriteLine(" }")
}

Method %AncestorHasRightSibling()
{
	Set parent=..%parent
	Set retVal=""
	while ($isObject(parent)) {
		if $IsObject(parent.%rightSibling)	Set retVal=parent
		if $isObject(retVal) quit
		Set parent=parent.%parent
	}
	Quit retVal
}

/// Given a tag name, return a string that can be used a routine label.
Method %MakeTag(pReport As %ZEN.Report.reportNode, pTag As %String, pLevel As %Integer) As %String [ Internal ]
{
	Set tExt = ""
	For i=1:1:pLevel {
		Set s = $G(pReport.%groupStack(i))
		Set s = $S(s="":"a",s>26:"Z"_s,1:$C(96+s))
		Set tExt = tExt _ i _ s
	}
	Set:tExt="" tExt = 0
	Quit pTag_..%MakeId(tExt)
}

Method %MakeGroupTag(pTag As %String, pLevel As %Integer) As %String [ Internal ]
{
	Set tExt = ""
	For i=1:1:pLevel {
		Set s = $G(..%groupStack(i))
		Set s = $S(s="":"a",s>26:"Z"_s,1:$C(96+s))
		Set tExt = tExt _ i _ s
	}
	Set:tExt="" tExt = 0
	Quit pTag_..%MakeId(tExt)
}

Method %MakeId(pExt As %String) As %String [ Internal ]
{
	if $D(%labelId(pExt)) {
		Set tId=%labelId(pExt)
	} else {
		Set %labelId=$i(%labelId)
		Set %labelId(pExt)=%labelId
		Set tId = %labelId
	}
	quit tId
}

/// Loop over child and sorts them into groups, elements, and attributes.
Method %SortChildren(Output tSubGroups, Output tAttributes, Output tElements, Output tAggregates, Output tGets, Output tIncludes, Output tCalls, Output tCallElements) As %Status [ Internal ]
{
	Set tSC = $$$OK

	Do {
		#; gather children into *buckets* according to type
		#; loop over children
		Set tSubGroups = 0
		For n = 1:1:..children.Count() {
			Set tNode = ..children.GetAt(n)

			#; some validation
			If tNode.%IsA("%ZEN.Report.report") {
				Set tSC = $$$ERROR($$$GeneralError,"A report element cannot be used within the body of a report definition.")
				Quit
			}
			ElseIf tNode.%IsA("%ZEN.Report.group") {
				Set tSubGroups=tSubGroups+1
				Set tSubGroups(tSubGroups) = tNode
			}
			ElseIf tNode.%IsA("%ZEN.Report.attribute") {
				#; place into attribute list
				Set tAttributes(n) = tNode
			}
			ElseIf tNode.%IsA("%ZEN.Report.element") {
				#; place into element list
				Set tElements(n) = tNode
			}
			ElseIf tNode.%IsA("%ZEN.Report.aggregate") {
				#; place into aggregate list
				Set tAggregates(n) = tNode
			}
			ElseIf tNode.%IsA("%ZEN.Report.get") {
				#; place into aggregate list
				Set tGets(n) = tNode
			}
			ElseIf tNode.%IsA("%ZEN.Report.include") {
				#; place into includes list
				Set tIncludes(n) = tNode
			}
			ElseIf tNode.%IsA("%ZEN.Report.call") {
				#; place into includes list
				Set tCalls(n) = tNode
			}
			ElseIf tNode.%IsA("%ZEN.Report.callelement") {
				#; place into includes list
				Set tCallElements(n) = tNode
			} Else {
				Set tSC = $$$ERROR($$$GeneralError,"Unknown reportNode type: " _ tNode)
				Quit
			}
		}
	} While(0)
	
	Quit tSC
}

/// Generate code that writes opening tag (plus attributes).
Method %GenerateOpenTag(pReport As %ZEN.Report.reportNode, pCode As %CharacterStream, ByRef tAttributes, pLevel As %Integer, pClose As %Boolean = 0, ByRef tElements, removeNulls As %Boolean, pDomain As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tSiblingNo = pReport.%groupStack(pLevel)
	Do {
		
		#; open tag for group
		;Do pCode.WriteLine(" New %name")
		Do pCode.WriteLine(" Set %name="""_$S(..name="":..%ClassName(0),1:..name)_"""")
		Do pCode.WriteLine(" if $e(%name)=""!"" {")
		Do pCode.WriteLine("     X ""Set %name=""_$e(%name,2,$L(%name))")
		Do pCode.WriteLine(" }")

		;Do pCode.WriteLine(" Set %tagname = ##class(%ZEN.Report.group).Qualify("""_$S(..name="":..%ClassName(0),1:..name)_""",%xmlprefix)")
		Do pCode.WriteLine(" Set %tagname = %name") ;##class(%ZEN.Report.group).Qualify(%name,%xmlprefix)")
		If (pClose) {
			Do pCode.WriteLine(" Set %tag("_pLevel_")=""""")
		}
		Else {
			Do pCode.WriteLine(" Set %tag("_pLevel_")=%tagname")
		}

		Do pCode.WriteLine(" Write ""<""_%tagname")

		#; invoke callback (of reportPage)
		If (pLevel = 0) {
			Do pCode.WriteLine(" Do ..%OnReportTag()")
			Do pCode.WriteLine(" Do ..%TagNameSpace(%embedXSL)")
		}
		#; write out attributes: these cannot be aggregates!
		Set n = $O(tAttributes(""))
		While (n'="") {
			Set tNode = tAttributes(n)
			#; look up one query level
			
			if ($e(tNode.field)'="!") {
				Set tSC = ..%GetNodeField(tNode,.tNodeField,pLevel-1) If $$$ISERR(tSC) Quit
			} else {
				Do pCode.WriteLine(" X ""Set %fieldvalue="_$e(tNode.field,2,$L(tNode.field))_"""")
				s quote=0 // don't quote %fieldvalue
				Set tSC=..%GetField1("%fieldvalue", .tNodeField, pLevel-1,quote)

			}
			If (tNode.expression'="") {
				Do pCode.WriteLine(" Set %val="_tNodeField)
				Do ..setTnodeValueArray(tNode, pCode, pLevel-1)			
				if (tSiblingNo=1) {
					Set tSC = ..%GetNodeExpr(tNode,.tNodeExpr) If $$$ISERR(tSC) Quit
				} else {
					Set tSC = ..%GetNodeExpr(tNode,.tNodeExpr) If $$$ISERR(tSC) Quit
				}
			}
			Else {
				Set tNodeExpr = tNodeField
			}
			Do pCode.WriteLine(" Set %filter=1")	
			if (tNode.filter'="") {
				Do pCode.WriteLine(" Set %val="_tNodeField)
				Do ..setTnodeValueArray(tNode, pCode, pLevel-1)		
				Do pCode.WriteLine(" X ""Set %filter="_tNode.filter_"""")
			}
			Set tAttrName = $S((tNode.name="")||(tNode.name=$C(0)):"unnamed",1:tNode.name)
			if (..removeEmpty)||(removeNulls) Do pCode.WriteLine(" if ("_tNodeExpr_")'="""" {")
			Do pCode.WriteLine(" Set text=$tr("_tNodeExpr_",$c(0))")
			Do pCode.WriteLine(" Write:%filter'=0 "" "_tAttrName_"='"",$s(((($F(text,"" ""))&&("""_tNode.escape_"""=""noneifspace"")))||("""_tNode.escape_"""=""none""):text,1:$ZCVT(text,""O"",""XML"")),""'""")
			if (..removeEmpty)||(removeNulls) Do pCode.WriteLine(" }")
			Set n = $O(tAttributes(n))
		}
		if (..suppressExcelHeaders'="") Do pCode.WriteLine(" Write "" suppressExcelHeaders='"_..suppressExcelHeaders_"'""")
		if ..excelSheetName'="",$e(..excelSheetName)="!" {
			Do ..SetFieldsValueArray(..fields, pCode, pLevel-1)
			Do pCode.WriteLine(" X ""Set %excelSheetName="_$e(..excelSheetName,2,$L(..excelSheetName))_"""")
			Do pCode.WriteLine(" Write "" excelSheetName='""_%excelSheetName_""'""")
		} else {
			if (..excelSheetName'="") Do pCode.WriteLine(" Write "" excelSheetName='""_..%getUniqueExcelSheetName("_..%QuoteValueL10N(..excelSheetName,pDomain)_")_""'""")
		}
		If (pClose) {
			#; close this tag here
			Do pCode.WriteLine(" Write ""/>"",!")
		}
		Else {
			Do pCode.WriteLine(" Write "">"",!")
		}
		if $$$ISERR(tSC) Quit
		
		
	} While(0)
	Quit tSC
}

/// Generate code that writes opening tag.
Method %GenerateCloseTag(pCode As %CharacterStream, pLevel As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do {
		#; close tag for group
		#; assume that %tag holds the current tag name!
		Do pCode.WriteLine(" Write:$g(%tag("_pLevel_"))'="""" ""</"",%tag("_pLevel_"),"">"",!")
		Do pCode.WriteLine(" Kill %tag("_pLevel_")")
	} While(0)
	Quit tSC
}

/// Generate code to write out non-group elements of this group.
Method %StoreElements(pReport As %ZEN.Report.reportNode, pCode As %CharacterStream, ByRef tElements, pLevel As %Integer, pSiblingNo As %Integer, pAggregateTag As %String, removeNulls As %Boolean, pDomain As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do {
		#; loop over elements
		Set n = $O(tElements(""))
		While (n'="") {
			Set tNode = tElements(n)
			if ($e(tNode.field)'="!") {
				Set tSC = ..%GetNodeField(tNode,.tNodeField,pLevel) If $$$ISERR(tSC) Quit
			} else {
				Do pCode.WriteLine(" X ""Set %fieldvalue="_$e(tNode.field,2,$L(tNode.field))_"""")
				s quote=0 // don't quote %fieldvalue
				Set tSC=..%GetField1("%fieldvalue", .tNodeField, pLevel,quote)

			}
			If (tNode.expression'="") {
				Do pCode.WriteLine(" Set %val="_tNodeField)
				Do ..setTnodeValueArray(tNode, pCode, pLevel)	
				Set tSC = ..%GetNodeExpr(tNode,.tNodeExpr) If $$$ISERR(tSC) Quit
			}
			Else {
				Set tNodeExpr = tNodeField
			}
			i $$$ISERR(tSC) Quit
			;Do pCode.WriteLine(" Set %elname = ##class(%ZEN.Report.group).Qualify("""_$S(tNode.name="":"unnamed",1:tNode.name)_""",%xmlprefix)") JSL4224
			;Do pCode.WriteLine(" Set %elname = %elname("_pLevel_","_pSiblingNo_","_n_")") // JSL4224
			Set name = $S(tNode.name="":"unnamed",1:tNode.name) // JSL4224
			//Do pCode.WriteLine(" Set %elname = %elname("""_name_""")") // JSL4224
			Do pCode.WriteLine(" Set %elname = """_name_"""") // JSL4224
			
 			if +$g(%zenreportdebug) {					
				Do pCode.WriteLine(" if $g(^IRIS.Temp.Zen(""DebugZen"")) if +$g(%groupStarted("_(pLevel+1)_")) w !,""<!-- not generating element because subgroup not finished ""_%elname_"" processing "_..name_" -->""")
 			}			
			Do pCode.WriteLine(" Set %filter=1")	
			if (tNode.filter'="") {
				Do pCode.WriteLine(" Set %val="_tNodeField)
				Do ..setTnodeValueArray(tNode, pCode, pLevel)		
				Do pCode.WriteLine(" X ""Set %filter="_tNode.filter_"""")
			}
			
			Do ..HorlogToExcelDateTime(pReport,pCode,tNode, tNodeExpr,pLevel) ; sets %excelDateTime if isExcelDate
			Do ..TimeToExcelTime(pReport,pCode,tNode, tNodeExpr,pLevel) ; sets %excelTime if isExcelTime
			if (..removeEmpty)||(removeNulls) Do pCode.WriteLine(" if ("_tNodeExpr_")'="""" {")
			if tNode.excelName'="" Do pCode.WriteLine(" Set %excelname="_..%QuoteValueL10N(tNode.excelName,pDomain)) // JSL4303
			if tNode.fieldType="literal" Do pCode.WriteLine(" Set:%filter'=0 ^||%ISC.ZENReport.elementStore("_pLevel_",%trueSiblingNo("_pLevel_"),$i(^||%ISC.ZENReport.elementStore("_pLevel_",%trueSiblingNo("_pLevel_"))))=""<""_%elname_"_$s(tNode.isExcelNumber'="":""" isExcelNumber='"_tNode.isExcelNumber_"' ""_",1:"")_$s(tNode.excelNumberFormat'="":""" excelNumberFormat='"_tNode.excelNumberFormat_"' ""_",1:"")_$s(tNode.isExcelDate'="":""" isExcelDate='"_tNode.isExcelDate_"' ""_",1:"")_$s(tNode.isExcelTime'="":""" isExcelTime='"_tNode.isExcelTime_"' ""_",1:"")_$s(tNode.excelName'="":""" excelName='""_%excelname_""'""_",1:"")_""">""_$tr($$xml^%occZENReports("_$s(tNode.isExcelDate:"%excelDateTime",1:$s(tNode.isExcelTime:"%excelTime",1:tNodeExpr))_","_""""_tNode.escape_""""_"),$c(0))_""</""_%elname_"">""")
			if tNode.fieldType="stream" Do pCode.WriteLine(" Set:%filter'=0 %streamStore("_pLevel_",%trueSiblingNo("_pLevel_"),""elemname"",$i(%streamStore("_pLevel_",%trueSiblingNo("_pLevel_"))))=%elname")
			if tNode.fieldType="stream" Do pCode.WriteLine(" Set:%filter'=0 %streamStore("_pLevel_",%trueSiblingNo("_pLevel_"),""oid"",$g(%streamStore("_pLevel_",%trueSiblingNo("_pLevel_"))))="_$s(tNode.isExcelDate:"%excelDateTime",1:tNodeExpr))
			if tNode.fieldType="stream" Do pCode.WriteLine(" Set:%filter'=0 %streamStore("_pLevel_",%trueSiblingNo("_pLevel_"),""escape"",$g(%streamStore("_pLevel_",%trueSiblingNo("_pLevel_"))))="""_tNode.escape_"""")
			if (..removeEmpty)||(removeNulls) Do pCode.WriteLine(" }")
			Set n = $O(tElements(n))
		}
	} While(0)
	Quit tSC
}

/// Generate code to write out non-group elements of this group.
Method %StoreCallElements(pCode As %CharacterStream, ByRef tCalls, pLevel As %Integer, pAggregateTag As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do {
		#; loop over elements
		Set n = $O(tCalls(""))
		While (n'="") {
			Set tNode = tCalls(n)
			if ($e(tNode.field)'="!") {
				Set tSC = ..%GetNodeField(tNode,.tNodeField,pLevel) If $$$ISERR(tSC) Quit
			} else {
				Do pCode.WriteLine(" X ""Set %fieldvalue="_$e(tNode.field,2,$L(tNode.field))_"""")
				s quote=0 // don't quote %fieldvalue
				Set tSC=..%GetField1("%fieldvalue", .tNodeField, pLevel,quote)

			}
			If (tNode.expression'="") {
				Do pCode.WriteLine(" Set %val="_tNodeField)
				Do ..setTnodeValueArray(tNode, pCode, pLevel)	
				Set tSC = ..%GetNodeExpr(tNode,.tNodeExpr) If $$$ISERR(tSC) Quit
			}
			Else {
				Set tNodeExpr = tNodeField
			}
			
			i $$$ISERR(tSC) Quit
			Do pCode.WriteLine(" Set %filter=1")	
			if (tNode.filter'="") {
				Do pCode.WriteLine(" Set %val="_tNodeField)
				Do ..setTnodeValueArray(tNode, pCode, pLevel)		
				Do pCode.WriteLine(" X ""Set %filter="_tNode.filter_"""")
			}

			Do pCode.WriteLine(" Set:%filter'=0 %callStore("_pLevel_",%trueSiblingNo("_pLevel_"),""param"",$i(%callStore("_pLevel_",%trueSiblingNo("_pLevel_"))))=$$xml^%occZENReports("_tNodeExpr_","_""""_tNode.escape_""""_")")
			Do pCode.WriteLine(" Set:%filter'=0 %callStore("_pLevel_",%trueSiblingNo("_pLevel_"),""method"",$g(%callStore("_pLevel_",%trueSiblingNo("_pLevel_"))))="""_tNode.method_"""")
			Do pCode.WriteLine(" Set:%filter'=0 %callStore("_pLevel_",%trueSiblingNo("_pLevel_"),""hasStatus"",$g(%callStore("_pLevel_",%trueSiblingNo("_pLevel_"))))="_tNode.hasStatus_"")
			
			Set n = $O(tCalls(n))
		}
	} While(0)
	Quit tSC
}

Method %StoreRowPosition(pCode As %CharacterStream, pLevel As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do {
		Do pCode.WriteLine(" if $D(%cache("_pLevel_")),$isobject(%cache("_pLevel_")) {")
		Do pCode.WriteLine("   Set %rowpos("_pLevel_")=%cache("_(pLevel)_").counter.currentrow")
		Do pCode.WriteLine(" }")
	} While(0)
	Quit tSC
}

/// Generate code to write out aggregate elements of this group.
Method %GenerateAggregates(pCode As %CharacterStream, pLevel As %Integer, ByRef tAggregates, pAggregateTag As %String, pAggregatesIgnoreNLS As %Boolean, pDomain As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do {
		#; loop over aggregates
		Set n = $O(tAggregates(""))
		#;Do pCode.WriteLine(" Write ""<!--""_%hasQuery(%trueSiblingNo("_pLevel_"))_""-->""")
		#;Do pCode.WriteLine(" Write ""<!--""_%trueSiblingNo("_pLevel_")_""-->""")
		#;Do pCode.WriteLine(" Write ""<!--""_%firstSibling("_pLevel_")_""-->""")
		Do pCode.WriteLine(" if (%firstSibling("_pLevel_")=1)||(%hasQuery(%trueSiblingNo("_pLevel_"))=1) {")
		While (n'="") {
			Set tNode = tAggregates(n)
			Do pCode.WriteLine(" Set %val="_"$G("_..getAgg(pLevel,n)_")")
			Do pCode.WriteLine(" X ""Set %filter="_tNode.filter_"""")
			Do pCode.WriteLine(" If (+%filter'=0) {")
			if tNode.format="" { 
				//Set tValue = $s(..runtimeMode=2:"$FNUMBER(",1:"")_"$G("_..getAgg(pLevel,n)_")"_$s(..runtimeMode=2:",""N"")",1:"")
				Set:tNode.ignoreNLS="" tNode.ignoreNLS=pAggregatesIgnoreNLS
				if (",SUM,AVG,MIN,MAX,"[(","_tNode.type_",")) {
					Set:tNode.preprocessValue="" tNode.preprocessValue=1
					Set:tNode.postprocessResult="" tNode.postprocessResult=1
				}
				Set tNode.runtimeMode = ..runtimeMode
				Set tValue = "$classmethod("_..getClassName(tNode)_",""%PostProcessValue"",$g("_..getAgg(pLevel,n)_"),"""_tNode.postprocessResult_""","_..runtimeMode_","""_tNode.ignoreNLS_""")"
			}
			else {
				Set tValue = tNode.format
				
			}
			//Do pCode.WriteLine(" Set %elname = ##class(%ZEN.Report.group).Project("""_$S(tNode.name="":"unnamed",1:tNode.name)_""",%xmlprefix)")
			Do pCode.WriteLine(" Set %elname = """_$S(tNode.name="":"unnamed",1:tNode.name)_"""")  // JSL4224
			if tNode.excelName'="" Do pCode.WriteLine(" Set %excelname="_..%QuoteValueL10N(tNode.excelName,pDomain)) // JSL4303
			if tNode.type'="PLACEHOLDER" Do pCode.WriteLine("   Write ""<""_%elname_"_$s(pAggregateTag'="":" "" "_pAggregateTag_"='1'""_",1:"")_$s(tNode.excelFormula'="":" "" excelFormula='"_tNode.excelFormula_"'""_",1:"")_$s(tNode.excelName'="":" "" excelName='""_%excelname_""'""_",1:"")_$s(tNode.excelNumberFormat'="":" "" excelNumberFormat='"_tNode.excelNumberFormat_"'""_",1:"")_""">"",$$xml^%occZENReports("_tValue_","_""""_tNode.escape_""""_"),""</""_%elname_"">"",!")
			if tNode.type="PLACEHOLDER" Do pCode.WriteLine("   Write ""<""_%elname_"_$s(pAggregateTag'="":" "" "_pAggregateTag_"='1'""_",1:"")_""" placeholder='1' "_$s(tNode.excelName'="":" excelName='""_%excelname_""'",1:"")_"></""_%elname_"">"",!")
			Do pCode.WriteLine(" }")
			Set n = $O(tAggregates(n))
		}
		Do pCode.WriteLine(" }")
	} While(0)
	Quit tSC
}

/// Generate code to start/accum/end aggregates.
Method %ProcessAggregates(pCode As %CharacterStream, pLevel As %Integer, pMode As %String, ByRef tAggregates, pBottomLevel As %Integer, pAggregatesIgnoreNLS As %Boolean) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Do {
		#; item counter for this level
		#dim tNode As aggregate
		If (pMode = "Start") {
			Do pCode.WriteLine(" Set "_..getCount(pLevel)_"=0")
			Do pCode.WriteLine(" Set %node("_(pLevel+1)_")=0")
			Set n = $O(tAggregates("")) // initial average counters, JSL5015
			While (n'="") {
				Set tNode = tAggregates(n)
				if tNode.type="AVG" {
					Do pCode.WriteLine(" Set "_..getCountForAvg(pLevel,n)_"=0 // initializer counter for "_tNode.name)
				}
				Set n = $O(tAggregates(n))
			}

		}
		ElseIf (pMode = "Accum") {
			Do pCode.WriteLine(" Set "_..getCount(pLevel)_"=$G("_..getCount(pLevel)_")+1")
			Set n = $O(tAggregates("")) // increment average counters, JSL5015
			While (n'="") {
				Set tNode = tAggregates(n)
				Do ..setAggValueArray(tNode, pCode, pBottomLevel) // Set %val as multidimensional array indexed by fields									if (tNode.accumIf'="") { // Don't increment count unless accumif condition is met, if accumif condition defined
				if (tNode.type="AVG") {
					if (tNode.accumIf '= "") {	
						Do pCode.WriteLine(" X ""Set %accumIf=("_tNode.accumIf_")""")
						Do pCode.WriteLine(" If %accumIf {")
					}
					Do pCode.WriteLine(" Set "_..getCountForAvg(pLevel,n)_"=$G("_..getCountForAvg(pLevel,n)_")+1 // increment count for "_tNode.name)
					if (tNode.accumIf'="") { 
						Do pCode.WriteLine(" }")
					}
				}
				Set n = $O(tAggregates(n))
				
			}

		}

		#; loop over aggregates
		Set n = $O(tAggregates(""))
		While (n'="") {
			Set tNode = tAggregates(n)
			if tNode.type="PLACEHOLDER" {
				Set n = $O(tAggregates(n))
				continue
			}
			Set tNode.runtimeMode = ..runtimeMode
			If (pMode = "Start") {
				Do $CASE(tNode.type,"COUNT":COUNTStart(n,tNode),"SUM":SUMStart(n,tNode),"AVG":AVGStart(n,tNode),"MIN":MINStart(n,tNode),"MAX":MAXStart(n,tNode),"CUSTOM":CUSTOMStart(n,tNode),"EXPRESSION":EXPRESSIONStart(n,tNode),:Unknown(n,tNode))
			}
			ElseIf (pMode = "Accum") {
				if ($e(tNode.field)'="!") {
					Set tSC = ..%GetNodeField(tNode,.tNodeField,pBottomLevel) If $$$ISERR(tSC) Quit
				} else {
					Do pCode.WriteLine(" X ""Set %fieldvalue="_$e(tNode.field,2,$L(tNode.field))_"""")
					s quote=0 // don't quote %fieldvalue
					Set tSC=..%GetField1("%fieldvalue", .tNodeField, pBottomLevel,quote)
	
				}

				Do ..setAggValueArray(tNode, pCode, pBottomLevel) // Set %val as multidimensional array indexed by fields				
				If (tNode.expression'="") {
					Set tSC = ..%GetNodeExpr(tNode,.tNodeExpr) If $$$ISERR(tSC) Quit
				}
				Else {
					Set tNodeExpr = tNodeField
				}
				Do pCode.WriteLine(" Set %val="_tNodeField)				
				if (tNode.accumIf'="") {
					Do pCode.WriteLine(" X ""Set %accumIf=("_tNode.accumIf_")""")
					Do pCode.WriteLine(" If %accumIf {")
				}
				// if in display mode tNodeExpr is an NLS expression
				Set:tNode.ignoreNLS="" tNode.ignoreNLS=pAggregatesIgnoreNLS
				if (",SUM,AVG,MIN,MAX,"[(","_tNode.type_",")) {
					Set:tNode.preprocessValue="" tNode.preprocessValue=1
					Set:tNode.postprocessResult="" tNode.postprocessResult=1
				}
				if (tNode.type'="CUSTOM") { // allow custom accumulator to pass by reference JSL4452
					Set tNodeExpr="$classmethod("_..getClassName(tNode)_",""%PreProcessValue"","_tNodeExpr_","""_tNode.preprocessValue_""","_..runtimeMode_","""_tNode.ignoreNLS_""")"
				}
				//if ..runtimeMode=2 {
				//	Set tNodeExpr="$INUMBER("_tNodeExpr_","","")"
				//}
				Do $CASE(tNode.type,"COUNT":COUNTAccum(n,tNode,tNodeExpr),"SUM":SUMAccum(n,tNode,tNodeExpr),"AVG":AVGAccum(n,tNode,tNodeExpr),"MIN":MINAccum(n,tNode,tNodeExpr),"MAX":MAXAccum(n,tNode,tNodeExpr),"CUSTOM":CUSTOMAccum(n,tNode,tNodeExpr),"EXPRESSION":EXPRESSIONAccum(n,tNode,tNodeExpr),:Unknown(n,tNode,tNodeExpr))
				if (tNode.accumIf'="") {
					Do pCode.WriteLine(" }")
				}
			}
			ElseIf (pMode = "End") {
				Do $CASE(tNode.type,"COUNT":COUNTEnd(n,tNode),"SUM":SUMEnd(n,tNode),"AVG":AVGEnd(n,tNode),"MIN":MINEnd(n,tNode),"MAX":MAXEnd(n,tNode),"CUSTOM":CUSTOMEnd(n,tNode),"EXPRESSION":EXPRESSIONEnd(n,tNode),:Unknown(n,tNode))
			
			} ElseIf (pMode = "Save") {
				if ($D(pBottomLevel)) {
					Set tSC = ..%GetNodeField(tNode,.tNodeField,pBottomLevel) If $$$ISERR(tSC) Quit
					If (tNode.expression'="") {
						Do pCode.WriteLine(" Set %val="_tNodeField)
						Do ..setTnodeValueArray(tNode, pCode, pBottomLevel) // Set %val as multidimensional array indexed by fields
						
						Set tSC = ..%GetNodeExpr(tNode,.tNodeExpr) If $$$ISERR(tSC) Quit
					}
					Else {
						Set tNodeExpr = tNodeField
					}
					Do SAVE(n,tNode,tNodeExpr)
					
				} 

			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"Unknown aggregate mode")
			}
			If $$$ISERR(tSC) Quit
			
			Set n = $O(tAggregates(n))
		}
		If $$$ISERR(tSC) Quit

	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
Unknown(n,tNode)
	Set tSC = $$$ERROR($$$GeneralError,"Invalid Aggregate type: " _ tNode.type)
	Goto Done

COUNTStart(n,tNode)
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"=0 // "_tNode.name)
	Quit
SUMStart(n,tNode)
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"=0 // "_tNode.name)
	Quit
AVGStart(n,tNode)
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"=0 // "_tNode.name)
	Quit
MINStart(n,tNode)
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"="""" // "_tNode.name)
	Quit
MAXStart(n,tNode)
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"="""" // "_tNode.name)
	Quit
EXPRESSIONStart(n,tNode)
	If (tNode.expression="") { 
        Set tSC=$$$ERROR($$$GeneralError,"No expression provided for EXPRESSION aggregate: "_tNode.name) 
        Quit 
    } 
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"="""" // "_tNode.name) ; Prodlog 86007
	Quit
CUSTOMStart(n,tNode)
	If (tNode.class="") {
		Set tSC=$$$ERROR($$$GeneralError,"No class provided for CLASS aggregate: "_tNode.name)
		Quit
	}
	If '($zobjclassmethod(tNode.class,"%IsA","%ZEN.Report.CustomAggregate")) {
		Set tSC=$$$ERROR($$$GeneralError,"Non-aggregate class provided for CLASS agregate: "_tNode.name)
		Quit
	}
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"=##class("_tNode.class_").%New() // "_tNode.name)
	Set clazz=##class(%Dictionary.CompiledClass).%OpenId(tNode.class)
	Set key=""
	do {
		Set prop=clazz.Properties.GetNext(.key)
		if (key'="") {
			set pkey=""
			set found=0
			do {
				set tParam=prop.Parameters.GetNext(.pkey)
				if (pkey'="") {
					set pvalue=prop.Parameters.GetAt(pkey)
					if (pkey="XMLPROJECTION")&&(pvalue'="") {
						set found=1
					}
				}
			} while (pkey'="")
			if (found=1){
				Set propvalue=$zobjproperty(tNode,prop.Name)
				if ('$isobject(propvalue) && (propvalue'="")) {

					Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"."_prop.Name_"="_##class(%ZEN.Report.Display.node).%QuoteValue(propvalue))
				}
			}
			
		}
	} while (key '= "")
	Quit

COUNTAccum(n,tNode,tExpr)
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"=$g("_..getAgg(pLevel,n)_")+1 // "_tNode.name)
	Quit
SUMAccum(n,tNode,tExpr)
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"=$g("_..getAgg(pLevel,n)_")+("_tExpr_ ") // "_tNode.name)
	Quit
AVGAccum(n,tNode,tExpr)
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"=$g("_..getAgg(pLevel,n)_")+("_tExpr_ ") // "_tNode.name)
	Quit
MINAccum(n,tNode,tExpr)
	Do pCode.WriteLine(" Set %dummy=+"_tExpr)
	Do pCode.WriteLine(" Set:($g("_..getAgg(pLevel,n)_")="""")||(%dummy<$g("_..getAgg(pLevel,n)_")) "_..getAgg(pLevel,n)_"=%dummy // "_tNode.name)
	Quit
MAXAccum(n,tNode,tExpr)
	Do pCode.WriteLine(" Set %dummy=+"_tExpr)
	Do pCode.WriteLine(" Set:($g("_..getAgg(pLevel,n)_")="""")||(%dummy>$g("_..getAgg(pLevel,n)_")) "_..getAgg(pLevel,n)_"=%dummy // "_tNode.name)
	Quit
EXPRESSIONAccum(n,tNode,tExpr)
#if 1 ; Prodlog 87975
	if ($e(tNode.field)'="!") {
		Set tSC = ..%GetNodeField(tNode,.tNodeField,pLevel) If $$$ISERR(tSC) Quit
	} else {
		Do pCode.WriteLine(" X ""Set %fieldvalue="_$e(tNode.field,2,$L(tNode.field))_"""")
		s quote=0 // don't quote %fieldvalue
		Set tSC=..%GetField1("%fieldvalue", .tNodeField, pLevel,quote)

	}
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"="_tNodeField_" // "_tNode.name)
#endif	
	Quit
CUSTOMAccum(n,tNode,tExpr)
	if (tExpr'="%val") {
		set var="("_tExpr_")"
	} else {
		set var=".%val"
	}
	if (tNode.field="")&&(tNode.expression="") {
		set var=".%val"
	}
	Do pCode.WriteLine(" Do "_..getAgg(pLevel,n)_".ProcessValue("_var_") // "_tNode.name)
	Quit
SAVE(n,tNode,tExpr)
	Do pCode.WriteLine(" Set %save"_pLevel_"("_n_")="_tExpr_" // "_tNode.name)
	Quit
COUNTEnd(n,tNode)
	;Do pCode.WriteLine("   Set "_..getAgg(pLevel,n)_"=+$G("_..getCount(pLevel)_") // "_tNode.name)
	if tNode.uniqueId'="" Do pCode.WriteLine(" Set %agg("""_tNode.uniqueId_""")="_..getAgg(pLevel,n))
	Quit
SUMEnd(n,tNode)
	if tNode.uniqueId'="" Do pCode.WriteLine(" Set %agg("""_tNode.uniqueId_""")="_..getAgg(pLevel,n))
	Quit
AVGEnd(n,tNode)
	Do pCode.WriteLine("   Set "_..getAgg(pLevel,n)_"=$S(+$G("_..getCountForAvg(pLevel,n)_")=0:0,1:("_..getAgg(pLevel,n)_"/"_..getCountForAvg(pLevel,n)_")) // "_tNode.name)
	if tNode.uniqueId'="" Do pCode.WriteLine(" Set %agg("""_tNode.uniqueId_""")="_..getAgg(pLevel,n))
	Quit
MINEnd(n,tNode)
	if tNode.uniqueId'="" Do pCode.WriteLine(" Set %agg("""_tNode.uniqueId_""")="_..getAgg(pLevel,n))
	Quit
MAXEnd(n,tNode)
	if tNode.uniqueId'="" Do pCode.WriteLine(" Set %agg("""_tNode.uniqueId_""")="_..getAgg(pLevel,n))
	Quit
EXPRESSIONEnd(n,tNode)
#if 1 ; Prodlog 87975
	If (tNode.expression'="") {
		Do pCode.WriteLine(" Set %val="_..getAgg(pLevel,n))
	}
#endif		
	Set expression=tNode.expression
	Set expression=$replace(expression,"""","""""")
	Do pCode.WriteLine(" X ""Set %AggExpression="_expression_"""")
	Do pCode.WriteLine(" Set "_..getAgg(pLevel,n)_"=%AggExpression")
	if tNode.uniqueId'="" Do pCode.WriteLine(" Set %agg("""_tNode.uniqueId_""")="_..getAgg(pLevel,n))
	Quit
CUSTOMEnd(n,tNode)
	if tNode.uniqueId'="" Do pCode.WriteLine(" Set %agg("""_tNode.uniqueId_""")="_..getAgg(pLevel,n))
	Do pCode.WriteLine("   if $D("_..getAgg(pLevel,n)_"),$isObject("_..getAgg(pLevel,n)_") Set "_..getAgg(pLevel,n)_".ignoreNLS="""_pAggregatesIgnoreNLS_"""") // "_tNode.name)
	Do pCode.WriteLine("   if $D("_..getAgg(pLevel,n)_"),$isObject("_..getAgg(pLevel,n)_") Set "_..getAgg(pLevel,n)_"="_..getAgg(pLevel,n)_".GetResult() // "_tNode.name)
	Quit
}

/// Compile-time method that returns an expression that
/// processes the field property of a value node.
Method %GetNodeField(tNode As valueNode, Output pExpr, pLevel As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = ..%GetField(tNode.field, .pExpr, pLevel)
	Quit tSC
}

/// Compile-time method that returns an expression that
/// processes the field property of a value node.
Method %GetField(field As %String, Output pExpr, pLevel As %Integer = 0) As %Status [ Internal ]
{
	s quote=1
	Set tSC=..%GetField1(field,.pExpr,pLevel,1)
	Quit tSC
}

/// Compile-time method that returns an expression that
/// processes the field property of a value node.
Method %GetField1(field As %String, Output pExpr, pLevel As %Integer = 0, pQuote As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pExpr = """"""
	If (field'="") {
		#; test query level
		If (pLevel < 0) {
			Set tSC = $$$ERROR($$$GeneralError,"Reference to a data source field when there is no data source in scope: " _field)
		}
		Else {
			if (pQuote) Set pExpr = "$$FieldLookup^%occZENReports("""_field_""","_pLevel_","_..%sqlcache_")"
			if ('pQuote) Set pExpr = "$$FieldLookup^%occZENReports("_field_","_pLevel_","_..%sqlcache_")"
		}
	}

	Quit tSC
}

/// Compile-time method to get the expression needed to
/// supply the value of a valueNode.
Method %GetNodeExpr(tNode As valueNode, Output pExpr) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pExpr = "%val"
	If (tNode.expression'="") {
		Set pExpr = tNode.expression
	}
	Quit tSC
}

/// Test if this group has a query defined.
Method %hasQueryDefined() As %Boolean
{
	Quit '((..sql="") && (..queryName="") && (..OnCreateResultSet="") && (..sqlexpression=""))
}

/// Test if this group has a break defined
Method %hasBreakDefined() As %Boolean
{
	Quit '((..breakOnField="") && (..breakOnExpression="") )
}

/// This internal method converts the parameter list for this group
/// into a run-time expression used to execute the query.
/// If <var>pArray</var> is defined, then it the expression will fill in
/// elements of an array named <var>pArray</var>.
Method %NormalizeParamList(pReport As %ZEN.Report.reportNode, pCode As %CharacterStream, pParameters As %ListOfObjects, pLevel As %Integer, setBreaks As %Boolean, pArray As %String = "") As %String [ Internal ]
{
#define quote(%val) $zutil(144,1,%val)
	Set tSiblingNo = ..groupNumber
	Set tCode = ""
	For n=1:1:pParameters.Count() {
		Set tParm = pParameters.GetAt(n)
		Set tValue = $ZSTRIP(tParm.value,"<>W")
		Set tExpr = ""

		If (tParm.field '= "") {
			#; value is based on a field in the current query
				Set tExpr="$$FieldLookup^%occZENReports("""_tParm.field_""","_pLevel_","_..%sqlcache_")"
		}
		Else {
			#; literal value
			Set tExpr = $$$quote(tValue)
		}

		#; test for expression
		If (tParm.expression '= "") {
			If ((tValue = "")&&(tParm.field="")) {
				#; use expression directly
				Set tExpr = "(" _ tParm.expression _ ")"
			}
			Else {
				#; replace "%val" with current expression
				if (setBreaks) {
					Set tExpr = "$$FieldLookup^%occZENReports("""_tParm.field_""","_pLevel_","_..%sqlcache_")"
				}
				
				Set expr = tParm.expression 
				Set x = ""
				For p=1:1:$L(expr,"%val") {
					Set x = x _ $S(p=1:"",1:"("_tExpr_")") _ $P(tParm.expression,"%val",p)
				}
				Set tExpr = x
			}
		}
		If (pArray = "") {
			Set tCode = tCode _ $S(tCode="":"",1:",") _ tExpr
		}
		Else {
			Set tCode = tCode _ $S(tCode="":"",1:",") _ pArray _ "(" _ n _ ")=" _ tExpr
		}
	}

	Quit tCode
}

Method %LookForRightSibling(parent As %ZEN.Report.group, pCode As %CharacterStream, pLevel As %Integer, sqlcache As %Boolean) As %Status [ Internal ]
{
	Set tSC=$$$OK		
	do { 
		Set tSC = ..%SortChildren(.tSubGroups,.tAttributes,.tElements,.tAggregates,.tGets,.tIncludes,.tCalls)
		If $$$ISERR(tSC) Quit 
		if sqlcache=0 {
			if ((+$G(tSubGroups) > 1) || $D(tElements)) Set tSC=$$$ERROR($$$GeneralError,"Must have parameter SQLCACHE=1 to support sibling groups and/or elements") Quit
		}
		If $$$ISERR(tSC) Quit
		Set prevSibling=""
		For tGroup = 1:1:+$G(tSubGroups) {
			If ($IsObject($G(tSubGroups(tGroup)))) {

				if '$IsObject(..%leftMost) Set ..%leftMost=tSubGroups(tGroup)
				Set tSubGroups(tGroup).%leftSibling=prevSibling
				s i=0
				while (i <= pLevel) {
					Set tSubGroups(tGroup).%groupStack(i)=..%groupStack(i)
					s i=i+1
				}
				Set tSubGroups(tGroup).%groupStack(pLevel+1) = tGroup
				Set tSubGroups(tGroup).groupNumber = tGroup
				Set tSubGroups(tGroup).%groupdepth = ..%groupdepth+1
				Set tSubGroups(tGroup).%level = pLevel
				Set tSubGroups(tGroup).%parent = ##this
				If ($IsObject(prevSibling)) {
					Set prevSibling.%rightSibling=tSubGroups(tGroup)
				}
				Set prevSibling=tSubGroups(tGroup)
				Set ..%rightMost=tSubGroups(tGroup)
				Set label=tSubGroups(tGroup).%MakeGroupTag("GroupEnd",pLevel+1)
				Do pCode.WriteLine(" if $g(%label)="""_label_""" k %label GoTo "_label)
				
				Set tSC = tSubGroups(tGroup).%LookForRightSibling(parent,pCode,pLevel+1,sqlcache)
				If $$$ISERR(tSC) Quit
			}
		}
		If $$$ISERR(tSC) Quit
	} while (0)
	quit tSC
}

Method CalcQuery(pReport As %ZEN.Report.reportNode, pCode As %CharacterStream, pLevel As %Integer, SetProcessWideRunTimeMode As %Boolean) As %Integer [ Internal ]
{
		If (..runonce) {
			If (..call'="")||(..queryName'="")||(..OnCreateResultSet'="") {
				Set tSC=$$$ERROR($$$GeneralError,"You can't runonce and have a query, result set or call: "_..name)
				quit
			}
		}

		#define quote(%val) $zutil(144,1,%val)
		#; establish query for this level
		Set tSiblingNo = pReport.%groupStack(pLevel)		
		set ..%hasquery=0
		Set tUpperCase=1
		If (..runonce) {
			Set ..%hasquery=1
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %hasData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)
		}
		ElseIf (..sql'="") {
			Do pCode.WriteLine(" if %setProcessWideRunTimeMode Set tRuntimeMode = $zu(115,5," _ $$$quote(..runtimeMode) _ ")")
			// convert to using %SQL.Statement
			if tSiblingNo'=1 Do pCode.WriteLine(" Set ctr=%cache("_(pLevel-1)_").%get("_(pLevel)_",1)")
			Do pCode.WriteLine(" Set tStatement=##class(%SQL.Statement).%New("_..runtimeMode_")")
			Do pCode.WriteLine(" If tStatement="""" Set tSC=%objlasterror goto Error")
			Do pCode.WriteLine("  Set tSC = tStatement.%Prepare("""_..sql_""") If $$$ISERR(tSC) Goto Error")
			Do pCode.WriteLine("  Set %query("_pLevel_") = tStatement.%Execute("_..%NormalizeParamList(pReport,pCode,..parameters,pLevel-1,0)_")")
			do pCode.WriteLine("  if %query("_pLevel_").%SQLCODE < 0 { set tSC = $$$ERROR($$$SQLCode,%query("_pLevel_").%SQLCODE,%query("_pLevel_").%Message) Goto Error }")
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %hasData("_pLevel_","_tSiblingNo_") = 0")
			if tSiblingNo'=1 Do pCode.WriteLine(" Do %cache("_(pLevel-1)_").%set(ctr)")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)
			Set ..%hasquery=1
		} 
		ElseIf (..sqlexpression'="") {
			Do pCode.WriteLine(" if %setProcessWideRunTimeMode Set tRuntimeMode = $zu(115,5," _ $$$quote(..runtimeMode) _ ")")
			// convert to using %SQL.Statement
			if tSiblingNo'=1 Do pCode.WriteLine(" Set ctr=%cache("_(pLevel-1)_").%get("_(pLevel)_",1)")
			Do pCode.WriteLine(" Set tStatement=##class(%SQL.Statement).%New("_..runtimeMode_")")
			Do pCode.WriteLine(" If tStatement="""" Set tSC=%objlasterror goto Error")
			Do pCode.WriteLine("  X "" Set %sqlexpression="_..sqlexpression_"""")
			Do pCode.WriteLine("  Set tSC = tStatement.%Prepare(%sqlexpression) If $$$ISERR(tSC) Goto Error")
			Do pCode.WriteLine("  Set %query("_pLevel_") = tStatement.%Execute("_..%NormalizeParamList(pReport,pCode,..parameters,pLevel-1,0)_")")
			do pCode.WriteLine("  if %query("_pLevel_").%SQLCODE < 0 { set tSC = $$$ERROR($$$SQLCode,%query("_pLevel_").%SQLCODE,%query("_pLevel_").%Message) Goto Error }")
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %hasData("_pLevel_","_tSiblingNo_") = 0")
			if tSiblingNo'=1 Do pCode.WriteLine(" Do %cache("_(pLevel-1)_").%set(ctr)")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)
			Set ..%hasquery=1

		}
		ElseIf (..queryName'="") {
			Set tQueryClass = $S(..queryClass="":%compiledclass.Name,1:..queryClass)
			if tSiblingNo'=1 Do pCode.WriteLine("  Set ctr=%cache("_(pLevel-1)_").%get("_(pLevel)_",1)")
			Do pCode.WriteLine("  Set tStatement=##class(%SQL.Statement).%New("_..runtimeMode_")")
			Do pCode.WriteLine("  If tStatement="""" Set tSC=%objlasterror goto Error")
			Do pCode.WriteLine("  Set tSC = tStatement.%PrepareClassQuery("""_tQueryClass_""","""_..queryName_""") If $$$ISERR(tSC) Goto Error")
			Do pCode.WriteLine("  Set %query("_pLevel_") = tStatement.%Execute("_..%NormalizeParamList(pReport,pCode,..parameters,pLevel-1,0)_")")
			do pCode.WriteLine("  if %query("_pLevel_").%SQLCODE < 0 { set tSC = $$$ERROR($$$SQLCode,%query("_pLevel_").%SQLCODE,%query("_pLevel_").%Message) Goto Error }")
			Do pCode.WriteLine("  If '$IsObject(%query("_pLevel_")) Set tSC=$$$ERROR($$$GeneralError,""Invalid query: queryClass="""_$$$quote(tQueryClass)_"""_"""" queryName="""_$$$quote(..queryName)_""""") GoTo Error")
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")			
			Do pCode.WriteLine("  Set %hasData("_pLevel_","_tSiblingNo_") = 0")
			if tSiblingNo'=1 Do pCode.WriteLine("  Do %cache("_(pLevel-1)_").%set(ctr)")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)
			Set ..%hasquery=1
			set tUpperCase=0
		}
		ElseIf (..OnCreateResultSet'="") {
			#; convert parameters to array to pass to callback
			if tSiblingNo'=1 Do pCode.WriteLine(" Set ctr=%cache("_(pLevel-1)_").%get("_(pLevel)_",1)")
			Do pCode.WriteLine("  Kill tParms")
			Set params=..%NormalizeParamList(pReport,pCode,..parameters,pLevel-1,0,"tParms")
			If $g(params)'="" Do pCode.WriteLine(" Set "_params)
			Do pCode.WriteLine("  Set %query = .."_..OnCreateResultSet_"(.tSC,.tParms)")
			Do pCode.WriteLine("  If $$$ISERR(tSC) Goto Error")
			Do pCode.WriteLine("  If '$IsObject(%query) Set tSC=$$$ERROR($$$GeneralError,""Method "_..OnCreateResultSet_" did not return a result set"") Goto Error")
			Do pCode.WriteLine("  Set %query("_pLevel_")=%query")
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %hasData("_pLevel_","_tSiblingNo_") = 0")
			if tSiblingNo'=1 Do pCode.WriteLine(" Do %cache("_(pLevel-1)_").%set(ctr)")
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)
			#; assume method sets runtime mode
			Set ..%hasquery=1
		} ElseIf (..call'="") {
			Set tCallClass = $S(..callClass="":%compiledclass.Name,1:..callClass)
			Do pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")="_..runtimeMode)
			Set ..%hasquery=0
		} Else {
			#; set query at this level to current outer query
			Do:pLevel>0 pCode.WriteLine("  Set %query("_pLevel_")=%query("_(pLevel-1)_")")
			Do pCode.WriteLine("  Set %noData("_pLevel_","_tSiblingNo_") = 0")
			Do pCode.WriteLine("  Set %hasData("_pLevel_","_tSiblingNo_") = 0")
			Do:pLevel>0 pCode.WriteLine("  Set %runtimeMode("_pLevel_","_tSiblingNo_")=$g(%runtimeMode("_(pLevel-1)_","_tSiblingNo_"))")
		}
		Do pCode.WriteLine("  Set %hasQuery("_tSiblingNo_")="_..%hasquery)
		Do pCode.WriteLine("  Set %top = """_""_..top_"""")
		if ..%sqlcache||..runonce Do pCode.WriteLine("  X:$e(%top)=""%"" ""Set %top=$e(%top,2,*) """)
		if ..%sqlcache||..runonce Do pCode.WriteLine("  Do CalcCache^%occZENReports("_pLevel_","_..%hasquery_","""_..orderby_""",%top,"_..runonce_","_tUpperCase_")")
		q ..%hasquery
}

Method getAgg(pLevel As %Integer, n As %Integer) [ Internal ]
{
	 quit "%agg"_pLevel_"(%trueSiblingNo("_pLevel_"),"_n_")"
}

Method getCount(pLevel As %Integer) [ Internal ]
{
	 quit "%count"_pLevel_"(%trueSiblingNo("_pLevel_"))"
}

Method getCountForAvg(pLevel As %Integer, n As %Integer) [ Internal ]
{
	 quit "%countForAvg"_pLevel_"(%trueSiblingNo("_pLevel_"),"_n_")"
}

ClassMethod Qualify(xpath As %String, prefix As %String)
{
	// walk xpath expression
	//if prefix="" Quit xpath
	set count=$L(xpath,"/")
	set i=1
	s tReturnValue=""
	s sep=""
	while (i<=count) {
		s name=$P(xpath,"/",i)
		if $e(name)="!" s $e(name)=""
		; parse axes
		if name["::" {
			Set tReturnValue=tReturnValue_sep
			s j=1
			s sep1=""
			s count1=$L(name,"::")
			while (j <= count1) {
				s name1=$P(name,"::",j)
				if ((j <= (count1-1)) || (prefix="") || ($e(name1)="@") || (name1="")) {
					Set tReturnValue=tReturnValue_sep1_name1
				} else {
					set tReturnValue=tReturnValue_sep1_prefix_":"_name1
				}
				set j=$i(j)
				set sep1="::"
			}
		}
		elseif ((prefix="") || ($e(name)="@") || (name="") || ($e(name)="$")) { // JSL4462 - add "$" case though /foobar/$x is not a valid xpath
			Set tReturnValue=tReturnValue_sep_name
		} else {
			set tReturnValue=tReturnValue_sep_prefix_":"_name
		}
		set i=$i(i)
		set sep="/"
	}
	quit tReturnValue
}

Method setAggValueArray(tNode, pCode As %CharacterStream, pLevel As %Integer) [ Internal ]
{
	if tNode.class'="" {
		Set clazz=##class(%Dictionary.CompiledClass).%OpenId(tNode.class)
		if $isobject(clazz) {
			Set key=""
			do {
				Set prop=clazz.Properties.GetNext(.key)
				if (key'="") {
					set found=0
					set pkey=""
					do {
						set tParam=prop.Parameters.GetNext(.pkey)
						if (pkey'="") {
							set pvalue=prop.Parameters.GetAt(pkey)
							if (pkey="REPORTFIELD")&&(pvalue=1) {
								set found=1
							}
						}
					} while (pkey'="")
		
					if (found=1){
						Set propvalue=$zobjproperty(tNode,prop.Name)
						if ('$isobject(propvalue) && (propvalue'="")) {
							Set field=$zstrip(propvalue,"<>W")
							Set tSC = ..%GetField(field,.tValue,pLevel) If $$$ISERR(tSC) Quit
							Do pCode.WriteLine(" Set %val("""_field_""")="_tValue)
						}
					}
					
				}
			} while (key '= "")
		}
	}
	Do ..SetFieldsValueArray(tNode.fields,pCode,pLevel)
}

Method setTnodeValueArray(tNode, pCode As %CharacterStream, pLevel As %Integer) [ Internal ]
{
	Do ..SetFieldsValueArray(tNode.fields,pCode,pLevel)
}

Method SetFieldsValueArray(fields As %String, pCode As %CharacterStream, pLevel As %Integer) [ Internal ]
{
		if ((fields'="") && (fields'=$c(0))) {
		for i=1:1:$L(fields,",") {
			Set field = $P(fields,",",i)
			Set field=$zstrip(field,"<>W")
			Set tSC = ..%GetField(field,.tValue,pLevel) If $$$ISERR(tSC) Quit
			Do pCode.WriteLine(" Set %val("""_field_""")="_tValue)
		}
	}
}

Method %MakeLabel(pLevel As %Integer)
{
	q """"_..%MakeGroupTag("GroupEnd",pLevel)_""""
}

ClassMethod DumpIncludes(pCode As %CharacterStream, ByRef pIncludes As %ZEN.Report.include) As %Status
{
	Set tSC=$$$OK
	Set n=""
	Set n=$o(pIncludes(n))
	while (n '= "") {
		Set include = pIncludes(n)
		Set tSC=..IncludeXdata(pCode,include.class, include.xdata)
		if $$$ISERR(tSC) quit
		Set n=$o(pIncludes(n))
	}
	Quit tSC
}

ClassMethod IncludeXdata(pCode As %CharacterStream, ClassName As %String, XdataName As %String) As %Status
{
	If ClassName="" Set ClassName=%compiledclass.Name
	Do pCode.WriteLine(" New me,data,idx")
	Do pCode.WriteLine(" Set me = ##class(%Dictionary.CompiledClass).%OpenId("""_ClassName_""")")
	Do pCode.WriteLine(" if ($isObject(me)) {")
    Do pCode.WriteLine("        Set idx = me.XDatas.FindObjectId("""_ClassName_"||"_XdataName_""")")
	Do pCode.WriteLine("     	if (idx="""") {")
	Do pCode.WriteLine("     		Do ##class(%ZEN.Report.reportPage).%LogError($$$ERROR($$$GeneralError,""Could not find XDATA.""))")
	Do pCode.WriteLine("     			Do ##class(%SYS.ZENReportServer).log($ZDT($ZTS,3,,3),""Could not find "_ClassName_"||"_XdataName_""")")
	Do pCode.WriteLine("     		;Quit $$$ERROR($$$GeneralError,""Could not find XDATA."")")

	Do pCode.WriteLine("     	}")
	Do pCode.WriteLine("     	Set data = me.XDatas.GetAt(idx).Data")
	Do pCode.WriteLine("     	if $isObject(data) {")
	Do pCode.WriteLine("     		Do data.Rewind()")
	Do pCode.WriteLine("     			Do data.OutputToDevice()")
	Do pCode.WriteLine("     	}")
	Do pCode.WriteLine(" } else {")
	Do pCode.WriteLine("   Do ##class(%ZEN.Report.reportPage).%LogError(%objlasterror)")
	Do pCode.WriteLine("   	Do ##class(%SYS.ZENReportServer).log($ZDT($ZTS,3,,3),""Could not open "_ClassName_"||"_XdataName_""")")
	Do pCode.WriteLine("   ;Quit %objlasterror")
	Do pCode.WriteLine("  }")
	Quit $$$OK
}

ClassMethod DumpGets(pCode As %CharacterStream, ByRef pGets As %ZEN.Report.include) As %Status
{
	Set tSC=$$$OK
	Set n=""
	Set n=$o(pGets(n))
	while (n '= "") {
		Set get = pGets(n)
		Set tSC=..GetXML(pCode,get.host, get.port, get.url)
		if $$$ISERR(tSC) quit
		Set n=$o(pGets(n))
	}
	Quit tSC
}

ClassMethod GetXML(pCode As %CharacterStream, host As %String, port As %String, url As %String) As %Status
{
	 Do pCode.WriteLine(" Set httprequest=##class(%Net.HttpRequest).%New()")
 	 Do pCode.WriteLine(" Set httprequest.Server="""_host_"""")
 	 Do pCode.WriteLine(" Set httprequest.Port="""_port_"""")
 	 Do pCode.WriteLine(" Set url="""_url_"""")
 	 Do pCode.WriteLine(" if $d(%session) {")
 	 Do pCode.WriteLine(" 	s sep=""?""")
 	 Do pCode.WriteLine("   i url[""?"" s sep=""&""")
 	 Do pCode.WriteLine(" 	s url=url_sep_""CSPCHD=""_%session.CSPSessionCookie_""&CSPSHARE=1""")
	 Do pCode.WriteLine(" }")
 	 Do pCode.WriteLine(" Set tSC=httprequest.Get(url)")
 	 Do pCode.WriteLine(" If $$$ISERR(tSC) d DecomposeStatus^%apiOBJ(tSC,.Err) Do ##class(%SYS.ZENReportServer).log($ZDT($ZTS,3,,3),""Could not get "_host_","_port_","_url_",""_Err)")
 	 Do pCode.WriteLine("  Do httprequest.HttpResponse.Data.OutputToDevice()")
     Quit $$$OK
}

Method DumpCalls(pReport As %ZEN.Report.reportNode, pCode As %CharacterStream, ByRef pCalls As %ZEN.Report.call, pLevel As %Integer) As %Status
{
	Set tSC=$$$OK
	Do pCode.WriteLine(" New saverow")
	Do pCode.WriteLine(" if $D(%rowpos("_pLevel_")) {")
	Do pCode.WriteLine("   Set saverow=%cache("_pLevel_").counter.currentrow")
	Do pCode.WriteLine("   Set %cache("_pLevel_").counter.currentrow=%rowpos("_pLevel_")")
	Do pCode.WriteLine(" }")
	Set n=""
	Set n=$o(pCalls(n))
	while (n '= "") {
		Set call = pCalls(n)
		Do pCode.WriteLine(" Kill tParms")
		Set params=..%NormalizeParamList(pReport,pCode,call.parameters,pLevel,0,"tParms")
		If $g(params)'="" Do pCode.WriteLine(" Set "_params)
		
		Set tSC=..GetXMLFromCall(pCode,call.method,$s($g(params)'="":"tParms", 1:""),call.hasStatus)
		if $$$ISERR(tSC) quit
		Set n=$o(pCalls(n))
	}
	Do pCode.WriteLine(" if $D(%rowpos("_pLevel_")) {")
	Do pCode.WriteLine("   Set %cache("_pLevel_").counter.currentrow=saverow")
	Do pCode.WriteLine(" }")
	Quit tSC
}

Method DumpCallElements(pCode As %CharacterStream, ByRef pCalls As %ZEN.Report.call, pLevel As %Integer) As %Status
{
	Set tSC=$$$OK
	Do pCode.WriteLine(" new i,stream,chunk,beg,end,hasStatus")
	Do pCode.WriteLine(" Set tSC=1")	
	Do pCode.WriteLine(" for i=1:1:+$g(%callStore("_pLevel_",%trueSiblingNo("_pLevel_"))) {")
	Do pCode.WriteLine("    Set method=%callStore("_pLevel_",%trueSiblingNo("_pLevel_"),""method"",i)")
	Do pCode.WriteLine("    Set param=%callStore("_pLevel_",%trueSiblingNo("_pLevel_"),""param"",i)")
	Do pCode.WriteLine("    Set hasStatus=%callStore("_pLevel_",%trueSiblingNo("_pLevel_"),""hasStatus"",i)")
	Do pCode.WriteLine("    if hasStatus {")
	Do pCode.WriteLine("        Set stream=$zobjmethod(##this,method,param,.tSC)")
	Do pCode.WriteLine("        if 'tSC quit")
	Do pCode.WriteLine("    } else {")
	Do pCode.WriteLine("        Set stream=$zobjmethod(##this,method,param)")
	Do pCode.WriteLine("    }")
	Do pCode.WriteLine("    if tSC=1,$D(stream),$isObject(stream) {")
	Do pCode.WriteLine("        Do stream.Rewind()")
	Do pCode.WriteLine("        Set chunksize=32000")
	Do pCode.WriteLine("	    While 'stream.AtEnd {")
	Do pCode.WriteLine("	        Set chunk=stream.Read(.chunksize)")
	Do pCode.WriteLine("            if $f(chunk,""<?xml"") {")
	Do pCode.WriteLine("                Set beg=$f(chunk,""<?xml"")-$L(""<?xml"")-1")
	Do pCode.WriteLine("                Set end=$f(chunk,""?>"",beg)")
	Do pCode.WriteLine("                Set chunk=$e(chunk,1,beg)_$e(chunk,end,$l(chunk))")
	Do pCode.WriteLine("            }")
	Do pCode.WriteLine("            w chunk")
	Do pCode.WriteLine("        }")
	Do pCode.WriteLine("    }")
	Do pCode.WriteLine(" }")
	Do pCode.WriteLine(" if 'tSC quit")

	Quit tSC
}

ClassMethod GetXMLFromCall(pCode As %CharacterStream, method As %String, parmName As %String, hasStatus As %Boolean) As %Status
{
	 Do pCode.WriteLine(" Set tSC=1")
	 if hasStatus {
 	 	Do pCode.WriteLine(" Set stream=.."_method_"("_$s(parmName="":"",1:"."_parmName)_",.tSC)")
	 } else {
		 Do pCode.WriteLine(" Set stream=.."_method_"("_$s(parmName="":"",1:"."_parmName)_")")
	 }
	 Do pCode.WriteLine(" if tSC=1,$D(stream),$isObject(stream) {")
	 Do pCode.WriteLine("   Do stream.Rewind()")
	 Do pCode.WriteLine("   Set chunksize=32000")
	 Do pCode.WriteLine("	While 'stream.AtEnd {")
	 Do pCode.WriteLine("	  Set chunk=stream.Read(.chunksize)")
	 Do pCode.WriteLine("     if $f(chunk,""<?xml"") {")
	 Do pCode.WriteLine("       Set beg=$f(chunk,""<?xml"")-$L(""<?xml"")-1")
	 Do pCode.WriteLine("       Set end=$f(chunk,""?>"",beg)")
	 Do pCode.WriteLine("       Set chunk=$e(chunk,1,beg)_$e(chunk,end,$l(chunk))")
	 Do pCode.WriteLine("     }")
	 Do pCode.WriteLine("     w chunk")
	 Do pCode.WriteLine("   }")
	 Do pCode.WriteLine(" }")
	 quit $$$OK
}

ClassMethod getClassName(tNode)
{
	quit $s(""""_tNode.class_""""="""""":""""_$classname(tNode)_"""",1:""""_tNode.class_"""")
}

Method HorlogToExcelDateTime(pReport, pCode, pNode, pNodeExpr, pLevel)
{
	Set tSiblingNo = pReport.%groupStack(pLevel)
	Do pCode.WriteLine(" Set %runtimeMode=$g(%runtimeMode("_pLevel_","_tSiblingNo_"))")
	if pNode.isExcelDate{
		Do pCode.WriteLine(" if ..Mode=""xlsx"","_pNodeExpr_"'="""" {")
		Do pCode.WriteLine("   If %runtimeMode=0 {   // logical")
		Do pCode.WriteLine("      Set %horlog="_pNodeExpr)
		Do pCode.WriteLine("   } elseif %runtimeMode=1 { // odbc")
		Do pCode.WriteLine("      Set %horlog=$zdateh("_pNodeExpr_",3)")
		Do pCode.WriteLine("   } elseif %runtimeMode=2 { // display")
		Do pCode.WriteLine("      Set %horlog=$zdateh("_pNodeExpr_",-1)")
		Do pCode.WriteLine("   } else {")
		Do pCode.WriteLine("      Set %horlog="_pNodeExpr)
		Do pCode.WriteLine("   }")
		Do pCode.WriteLine("   Set days=$P(%horlog,"","",1)")
		Do pCode.WriteLine("   Set seconds = 0")
		Do pCode.WriteLine("   Set:%horlog["","" seconds=$P(%horlog,"","",2)")
		Do pCode.WriteLine("   Set daysdiff = $zdateh(""1899-12-31"",3)")
		Do pCode.WriteLine("   Set excelDays = days - daysdiff + 1")
		Do pCode.WriteLine("   Set excelFraction = seconds/(360*60*60)")
		Do pCode.WriteLine("   Set %excelDateTime=excelDays_"".""_excelFraction")
		Do pCode.WriteLine(" } elseif ..Mode=""excel"","_pNodeExpr_"'="""" {")
		Do pCode.WriteLine("   If %runtimeMode=0 {   // logical")
		Do pCode.WriteLine("      Set %odbcdate=$zdate("_pNodeExpr_",3)")
		Do pCode.WriteLine("   } elseif %runtimeMode=1 { // odbc")
		Do pCode.WriteLine("      Set %odbcdate="_pNodeExpr)
		Do pCode.WriteLine("   } elseif %runtimeMode=2 { // display")
		Do pCode.WriteLine("      Set %horlog=$zdateh("_pNodeExpr_",-1)")
		Do pCode.WriteLine("      Set %odbcdate=$zdate(%horlog,3)")
		Do pCode.WriteLine("   } else {")
		Do pCode.WriteLine("      Set %odbcdate="_pNodeExpr)
		Do pCode.WriteLine("   }")
		Do pCode.WriteLine("   Set %excelDateTime=%odbcdate")
		Do pCode.WriteLine(" } else {")
		Do pCode.WriteLine("   Set %excelDateTime="_pNodeExpr)
		Do pCode.WriteLine(" }")
	} else {
		; don't set anything
	}
}

Method TimeToExcelTime(pReport, pCode, pNode, pNodeExpr, pLevel)
{
	Set tSiblingNo = pReport.%groupStack(pLevel)
	Do pCode.WriteLine(" Set %runtimeMode=$g(%runtimeMode("_pLevel_","_tSiblingNo_"))")
	if pNode.isExcelTime{
		Do pCode.WriteLine(" if "_pNodeExpr_"="""" {")
		Do pCode.WriteLine("   Set %excelTime=""""")
		Do pCode.WriteLine(" }")
		Do pCode.WriteLine(" elseif ..Mode=""xlsx"" {")
		Do pCode.WriteLine("   If %runtimeMode=0 {   // logical")
		Do pCode.WriteLine("   Set %seconds="_pNodeExpr)
		Do pCode.WriteLine("   } elseif %runtimeMode=1 { // odbc")
		Do pCode.WriteLine("   Set %seconds=$ztimeh("_pNodeExpr_")")
		Do pCode.WriteLine("   } elseif %runtimeMode=2 { // display")
		Do pCode.WriteLine("   Set %seconds=$ztimeh("_pNodeExpr_")")
		Do pCode.WriteLine("   } else {")
		Do pCode.WriteLine("   Set %seconds="_pNodeExpr)
		Do pCode.WriteLine("   }")
		Do pCode.WriteLine("   Set %excelTime=%seconds/(60*60*24)")
		Do pCode.WriteLine(" } elseif ..Mode=""excel"" {")
		Do pCode.WriteLine("   If %runtimeMode=0 {   // logical")
		Do pCode.WriteLine("   Set %seconds="_pNodeExpr)
		Do pCode.WriteLine("   } elseif %runtimeMode=1 { // odbc")
		Do pCode.WriteLine("   Set %seconds=$ztimeh("_pNodeExpr_")")
		Do pCode.WriteLine("   } elseif %runtimeMode=2 { // display")
		Do pCode.WriteLine("   Set %seconds=$ztimeh("_pNodeExpr_")")
		Do pCode.WriteLine("   } else {")
		Do pCode.WriteLine("   Set %seconds="_pNodeExpr)
		Do pCode.WriteLine("   }")
		Do pCode.WriteLine("   Set %excelTime=%seconds/(60*60*24)")
		Do pCode.WriteLine(" } else {")
		Do pCode.WriteLine("   Set %excelTime="_pNodeExpr)
		Do pCode.WriteLine(" }")
	} else {
		; don't set anything
	}
}

/// Take a value string and return a quoted string.
ClassMethod %QuoteValue(pValue As %String) [ CodeMode = expression ]
{
$S((pValue=$c(0)):"""""",$E(pValue,1,2)'="#("&&($E(pValue,$L(pValue)-1,$L(pValue))'=")#"):$TR($zu(144,1,pValue),$C(10),""),1:$TR($E(pValue,3,*-2),$C(10),""))
}

/// Take a value string and return a quoted string wrapped within a
/// $$$Text macro.<br>
/// If value starts and ends with #( )#, then return an expression
ClassMethod %QuoteValueL10N(pValue As %String, pDomain As %String)
{
	if pDomain'="" {
		Quit:$E(pValue,1,2)'="#(" "$$$Text("_..%QuoteValue(pValue)_","_..%QuoteValue(pDomain)_",$s($D(%response)&&(%response.Language'=""""):%response.Language,1:$$$DefaultLanguage))"
		Quit:$E(pValue,$L(pValue)-1,$L(pValue))'=")#" "$$$Text("_..%QuoteValue(pValue)_","_%QuoteValue(pDomain)_",$s($D(%response)&&(%response.Language'=""""):%response.Language,1:$$$DefaultLanguage))"
	}

	#; return run-time expression
	Quit ..%QuoteValue(pValue)
}

}
