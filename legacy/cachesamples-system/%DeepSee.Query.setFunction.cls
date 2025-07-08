/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a "set" function within a DeepSee query.<br/>
/// A set function takes the form:
/// FUNC(a,b,c).
Class %DeepSee.Query.setFunction Extends function [ System = 3 ]
{

/// Used to indicate which class of functions this class supports.
Parameter FUNCTIONCLASS = "set";

/// Format string to apply to this member.
Property formatString As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Test if function metadata is in the DeepSeeFunctionGLVN global.
/// If not, put it there.
ClassMethod %BuildFunctionMetaData() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tClass = ..#FUNCTIONCLASS
		Set tVersion = ..%GetFunctionVersionNo()

		If (+$G($$$DeepSeeFunctionGLVN(tClass))'=tVersion) {
			Kill $$$DeepSeeFunctionGLVN(tClass)
			Set $$$DeepSeeFunctionGLVN(tClass) = tVersion

			// (class,function,variety) = $LB(implemented,return,$LB(argtypes),$LB(argdesc))
			// argtype is $$$dstSet etc.
			// argdesc describes the argument:
			// 0: optional, 1: required, N:repeating
			// M: first argument is member function is applied to
			// S: the (required) argument is modified and returned by the function
			// 	(e.g. HEAD)
			// X: the (required) argument should not have its children processed
			// 	(e.g. FILTER)
			// possible flag values are encoded in the argdesc: 1:F1,F2,F3
			Set $$$DeepSeeFunctionGLVN(tClass,"UNION") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstSet,$$$dstFlag),$LB("S",1,"0:ALL"))
			Set $$$DeepSeeFunctionGLVN(tClass,"INTERSECT") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstSet,$$$dstFlag),$LB("S",1,"0:ALL"))
			Set $$$DeepSeeFunctionGLVN(tClass,"EXCEPT") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstSet,$$$dstFlag),$LB("S",1,"0:ALL"))
			Set $$$DeepSeeFunctionGLVN(tClass,"DISTINCT") = $LB(1,$$$dstSet,$LB($$$dstSet),$LB("S"))
			Set $$$DeepSeeFunctionGLVN(tClass,"HEAD") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstInteger,$$$dstFlag),$LB("S",0,"0:FULL,SAMPLE"))		// DTB326 - Special flag added for Analyzer sample
			Set $$$DeepSeeFunctionGLVN(tClass,"SUBSET") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstInteger,$$$dstInteger),$LB("S",1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"TAIL") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstInteger),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"CROSSJOIN") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstSet,$$$dstFlag),$LB("S",1,"0:HIDE_CHILDREN"))
			Set $$$DeepSeeFunctionGLVN(tClass,"NONEMPTYCROSSJOIN") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstSet,$$$dstFlag),$LB("S",1,"0:HIDE_CHILDREN"))
			Set $$$DeepSeeFunctionGLVN(tClass,"GENERATE") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstSet,$$$dstFlag),$LB("S",1,"0:ALL"))
			Set $$$DeepSeeFunctionGLVN(tClass,"EXTRACT") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstDimension),$LB("S","N"))

			// dimensional functions
			Set $$$DeepSeeFunctionGLVN(tClass,"MEMBERS") = $LB(0,$$$dstString,$LB($$$dstMember),$LB(1))
			Set $$$DeepSeeFunctionGLVN(tClass,"ADDCALCULATEDMEMBERS") = $LB(0,$$$dstSet,$LB($$$dstSet),$LB(1))
			Set $$$DeepSeeFunctionGLVN(tClass,"STRIPCALCULATEDMEMBERS") = $LB(0,$$$dstSet,$LB($$$dstSet),$LB(1))
			Set $$$DeepSeeFunctionGLVN(tClass,"DESCENDANTS") = $LB(1,$$$dstSet,$LB($$$dstMember,$$$dstLevel,$$$dstFlag),$LB(1,1,"0:SELF,AFTER,BEFORE,BEFORE_AND_AFTER,SELF_AND_AFTER,SELF_AND_BEFORE,SELF_BEFORE_AFTER"))		// DTB162 - Mark as implemented
			Set $$$DeepSeeFunctionGLVN(tClass,"PERIODSTODATE") = $LB(1,$$$dstSet,$LB($$$dstLevel,$$$dstMember),$LB(1,1))
			Set $$$DeepSeeFunctionGLVN(tClass,"WTD") = $LB(0,$$$dstSet,$LB($$$dstMember),$LB(0))
			Set $$$DeepSeeFunctionGLVN(tClass,"MTD") = $LB(0,$$$dstSet,$LB($$$dstMember),$LB(0))
			Set $$$DeepSeeFunctionGLVN(tClass,"QTD") = $LB(0,$$$dstSet,$LB($$$dstMember),$LB(0))
			Set $$$DeepSeeFunctionGLVN(tClass,"YTD") = $LB(0,$$$dstSet,$LB($$$dstMember),$LB(0))
			Set $$$DeepSeeFunctionGLVN(tClass,"LASTPERIODS") = $LB(0,$$$dstSet,$LB($$$dstInteger,$$$dstMember),$LB(1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"COUSIN") = $LB(1,$$$dstMember,$LB($$$dstMember,$$$dstMember),$LB(1,1))
			Set $$$DeepSeeFunctionGLVN(tClass,"PARALLELPERIOD") = $LB(1,$$$dstMember,$LB($$$dstLevel,$$$dstInteger,$$$dstMember),$LB(1,1,1))
			Set $$$DeepSeeFunctionGLVN(tClass,"ANCESTOR") = $LB(1,$$$dstMember,$LB($$$dstMember,$$$dstLevel),$LB(1,1))
			Set $$$DeepSeeFunctionGLVN(tClass,"OPENINGPERIOD") = $LB(1,$$$dstMember,$LB($$$dstLevel,$$$dstMember),$LB(1,1))
			Set $$$DeepSeeFunctionGLVN(tClass,"CLOSINGPERIOD") = $LB(1,$$$dstMember,$LB($$$dstLevel,$$$dstMember),$LB(1,1))

			// aggregation functions
			Set $$$DeepSeeFunctionGLVN(tClass,"AGGREGATE") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"AVG") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"CORRELATION") = $LB(0,$$$dstValue,$LB($$$dstSet,$$$dstExpression,$$$dstExpression),$LB(1,1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"COUNT") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstFlag),$LB("S","0:INCLUDEEMPTY,EXCLUDEEMPTY"))
			Set $$$DeepSeeFunctionGLVN(tClass,"COVARIANCE") = $LB(0,$$$dstValue,$LB($$$dstSet,$$$dstExpression,$$$dstExpression),$LB(1,1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"COVARIANCEN") = $LB(0,$$$dstValue,$LB($$$dstSet,$$$dstExpression,$$$dstExpression),$LB(1,1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"LINEREGINTERCEPT") = $LB(0,$$$dstValue,$LB($$$dstSet,$$$dstExpression,$$$dstExpression),$LB(1,1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"LINEREGPOINT") = $LB(0,$$$dstValue,$LB($$$dstExpression,$$$dstSet,$$$dstExpression,$$$dstExpression),$LB(1,1,1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"LINEREGR2") = $LB(0,$$$dstValue,$LB($$$dstSet,$$$dstExpression,$$$dstExpression),$LB(1,1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"LINEREGSLOPE") = $LB(0,$$$dstValue,$LB($$$dstSet,$$$dstExpression,$$$dstExpression),$LB(1,1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"LINEREGVARIANCE") = $LB(0,$$$dstValue,$LB($$$dstSet,$$$dstExpression,$$$dstExpression),$LB(1,1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"MAX") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"MEDIAN") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			//Set $$$DeepSeeFunctionGLVN(tClass,"MODE") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"MIN") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"PERCENTILE") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression,$$$dstInteger),$LB("S",0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"PERCENTILERANK") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression,$$$dstInteger),$LB("S",0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"STDEV") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"STDDEV") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"STDEVP") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"STDDEVP") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"SUM") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"VAR") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"VARIANCE") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"VARP") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"VARIANCEP") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"%LIST") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))

			Set $$$DeepSeeFunctionGLVN(tClass,"%FIRST") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"%LAST") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstExpression),$LB("S",0))
			
			// **internal** function used to implement COUNT
			Set $$$DeepSeeFunctionGLVN(tClass,"%DISTINCT") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstFlag),$LB("S","0:INCLUDEEMPTY,EXCLUDEEMPTY"))

			// **internal** function used to implement variant of COUNT:
			// count results *after* consolidation
			Set $$$DeepSeeFunctionGLVN(tClass,"%POSTCOUNT") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstFlag),$LB("S","0:INCLUDEEMPTY,EXCLUDEEMPTY"))

			// various database functions
			// These take an extra, optional, cube name used by compound cubes
			Set $$$DeepSeeFunctionGLVN(tClass,"FILTER") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstExpression,$$$dstString),$LB("S","X",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"BOTTOMCOUNT") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstInteger,$$$dstExpression,$$$dstString),$LB("S",1,0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"TOPCOUNT") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstInteger,$$$dstExpression,$$$dstString),$LB("S",1,0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"BOTTOMPERCENT") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstValue,$$$dstExpression,$$$dstString),$LB("S",1,0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"TOPPERCENT") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstValue,$$$dstExpression,$$$dstString),$LB("S",1,0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"BOTTOMSUM") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstValue,$$$dstExpression,$$$dstString),$LB("S",1,0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"TOPSUM") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstValue,$$$dstExpression,$$$dstString),$LB("S",1,0,0))

			// various ordering functions
			Set $$$DeepSeeFunctionGLVN(tClass,"ORDER") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstExpression,$$$dstFlag,$$$dstString),$LB("S","X","0:ASC,DESC,BASC,BDESC",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"RANK") = $LB(1,$$$dstInteger,$LB($$$dstMember,$$$dstSet,$$$dstExpression,$$$dstString),$LB("S","X",0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"HIERARCHIZE") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstFlag),$LB("S","0:POST"))
			Set $$$DeepSeeFunctionGLVN(tClass,"HIERARCHISE") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstFlag),$LB("S","0:POST"))

			// various drill-related functions
			Set $$$DeepSeeFunctionGLVN(tClass,"DRILLDOWNLEVEL") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstLevel),$LB(1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"DRILLDOWNLEVELBOTTOM") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstInteger,$$$dstLevel,$$$dstExpression),$LB(1,1,0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"DRILLDOWNLEVELTOP") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstInteger,$$$dstLevel,$$$dstExpression),$LB(1,1,0,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"DRILLDOWNMEMBER") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstSet,$$$dstFlag),$LB(1,1,"0:RECURSIVE"))
			Set $$$DeepSeeFunctionGLVN(tClass,"DRILLDOWNMEMBERBOTTOM") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstSet,$$$dstInteger,$$$dstFlag),$LB(1,1,1,"0:RECURSIVE"))
			Set $$$DeepSeeFunctionGLVN(tClass,"DRILLDOWNMEMBERTOP") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstSet,$$$dstInteger,$$$dstFlag),$LB(1,1,1,"0:RECURSIVE"))
			Set $$$DeepSeeFunctionGLVN(tClass,"DRILLUPLEVEL") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstLevel),$LB(1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"DRILLUPMEMBER") = $LB(0,$$$dstSet,$LB($$$dstSet,$$$dstSet),$LB(1,0))
			Set $$$DeepSeeFunctionGLVN(tClass,"VISUALTOTALS") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstString),$LB("S",0))

			// subquery
			// query,parmName,parmValue,... [parmName can be %CONTEXT, parmValue can be "rows","columns","filters","all"]
			Set $$$DeepSeeFunctionGLVN(tClass,"%MDX") = $LB(1,$$$dstValue,$LB($$$dstValue,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression),$LB(1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))

			// kpiName,property,series,parmName,parmValue,... [parmName can be %CONTEXT|%MEASURE, parmValue can be "rows","columns","filters","all" | measureName]
			// JMD1390: increase number of arguments
			// (we can't use variable args as the types alternate between string and expression)
			Set $$$DeepSeeFunctionGLVN(tClass,"%KPI") = $LB(1,$$$dstValue,$LB($$$dstString,$$$dstString,$$$dstString,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression,$$$dstString,$$$dstExpression),$LB(1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))

			// time window: %TimeWindow(periods,startTime,endTime)
			Set $$$DeepSeeFunctionGLVN(tClass,"%TIMEWINDOW") = $LB(1,$$$dstSet,$LB($$$dstSet,$$$dstMember,$$$dstMember),$LB(1,1,0))

			// JMD1041
			// time range: %TimeRange(startTime,endTime,[INCLUSIVE|EXCLUSIVE])
			Set $$$DeepSeeFunctionGLVN(tClass,"%TIMERANGE") = $LB(1,$$$dstSet,$LB($$$dstMember,$$$dstMember,$$$dstFlag),$LB(0,0,"0:INCLUSIVE,EXCLUSIVE"))

			// external ref: %Cube(cubeName,"set",dimName...)
			Set $$$DeepSeeFunctionGLVN(tClass,"%CUBE") = $LB(1,$$$dstSet,$LB($$$dstString,$$$dstString,$$$dstString),$LB(1,1,"N"))

			// logic functions
			Set $$$DeepSeeFunctionGLVN(tClass,"IIF") = $LB(1,$$$dstValue,$LB($$$dstExpression,$$$dstExpression,$$$dstExpression),$LB(1,1,1))

			// "spreadsheet" functions
			Set $$$DeepSeeFunctionGLVN(tClass,"%CELL") = $LB(1,$$$dstValue,$LB($$$dstInteger,$$$dstInteger,$$$dstString),$LB(1,1,0))
			// coerces null into 0
			Set $$$DeepSeeFunctionGLVN(tClass,"%CELLZERO") = $LB(1,$$$dstValue,$LB($$$dstInteger,$$$dstInteger,$$$dstString),$LB(1,1,0))

			// "label" function: %LABEL(expr,pattern,[format],[solve_order],[style],[header-style])
			Set $$$DeepSeeFunctionGLVN(tClass,"%LABEL") = $LB(1,$$$dstValue,$LB($$$dstSet,$$$dstString,$$$dstString,$$$dstInteger,$$$dstString,$$$dstString),$LB("S",0,0,0,0,0))

			// "space" function: %SPACE() (same as %LABEL(" "," "))
			Set $$$DeepSeeFunctionGLVN(tClass,"%SPACE") = $LB(1,$$$dstValue,$LB(),"")

			// %OR - perform logical OR of members from same level
			Set $$$DeepSeeFunctionGLVN(tClass,"%OR") = $LB(1,$$$dstMember,$LB($$$dstSet),$LB("S"))

			// %TERMLIST - create a set from all the elements of a TermList
			// if INCLUDE, then create a set, if EXCLUDE, create a tuple of mbr.%NOT
			Set $$$DeepSeeFunctionGLVN(tClass,"%TERMLIST") = $LB(1,$$$dstSet,$LB($$$dstString,$$$dstFlag),$LB(1,"0:INCLUDE,EXCLUDE"))

			// JMD1062
			// %LOOKUP - lookup a value from a termlist:
			// %LOOKUP(termlist,key,[field],[default])
			Set $$$DeepSeeFunctionGLVN(tClass,"%LOOKUP") = $LB(1,$$$dstValue,$LB($$$dstString,$$$dstString,$$$dstString,$$$dstValue),$LB(1,1,0,0))

			// other extensions
			// %ADDPARENTS adds distinct parent members to a set.
			// This is used in the subquery needed for the ORDER function
			Set $$$DeepSeeFunctionGLVN(tClass,"%ADDPARENTS") = $LB(1,$$$dstSet,$LB($$$dstSet),$LB("S"))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert this node to its text representation.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	Set tText = $$$UPPER(..function) _ "("
	Set tCount = ..children.Count()
	For n = 1:1:tCount {
		Set tChild = ..children.GetAt(n)
		Set tText = tText _ $S(n>1:",",1:"") _ tChild.%ToString(.pSC)
		If $$$ISERR(pSC) Quit
	}
	Set tText = tText _ ")"
	Quit tText
}

/// Execute the pre-processing logic for this node.
Method %PreProcess(pIsSlicer As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	
	Try {
		// first process our children
		Set tSC = ##super(pIsSlicer)
		If $$$ISERR(tSC) Quit

		// JMD1280 do not use %DISTINCT for relationship
		If ($$$UPPER(..function)="%DISTINCT") {
			Set tChild = ..children.GetAt(1)
			If ($IsObject(tChild)) {
				If (tChild.%IsA("%DeepSee.Query.memberSpec") && $IsObject(tChild.%member) && (tChild.%member.%IsA("%DeepSee.Query.memberRelationship"))) {
					Set ..function = "%POSTCOUNT"
				}
				ElseIf (tChild.%IsA("%DeepSee.Query.setFunction") && ((tChild.function="CROSSJOIN")||(tChild.function="NONEMPTYCROSSJOIN"))) {
					// JMD1458: test for CJ(relation)
					Set tChild1 = tChild.children.GetAt(1)
					Set tChild2 = tChild.children.GetAt(2)
					If ($IsObject(tChild1) && $IsObject(tChild2)) {
						If (tChild1.%IsA("%DeepSee.Query.memberSpec") && $IsObject(tChild1.%member) && (tChild1.%member.%IsA("%DeepSee.Query.memberRelationship"))) {
							Set ..function = "%POSTCOUNT"
						}
						ElseIf (tChild2.%IsA("%DeepSee.Query.memberSpec") && $IsObject(tChild2.%member) && (tChild2.%member.%IsA("%DeepSee.Query.memberRelationship"))) {
							Set ..function = "%POSTCOUNT"
						}
					}
				}
			}
		}

		// now test for functions that require preprocessing (e.g. Filter)
		Set tSC = $Case($$$UPPER(..function),
			"%MDX":..PreMDX(pIsSlicer),
			"%CUBE":..PreFilter(pIsSlicer),
			"%KPI":..PreKPI(pIsSlicer),
			"%TIMEWINDOW":..PreTimeWindow(pIsSlicer),
			"%TIMERANGE":..PreTimeRange(pIsSlicer),
			"%OR":..PreOR(pIsSlicer),
			"FILTER":..PreFilter(pIsSlicer),
			"ORDER":..PreFilter(pIsSlicer),
			"RANK":..PreFilter(pIsSlicer),
			"TOPCOUNT":..PreFilter(pIsSlicer),
			"BOTTOMCOUNT":..PreFilter(pIsSlicer),
			"TOPPERCENT":..PreFilter(pIsSlicer),
			"BOTTOMPERCENT":..PreFilter(pIsSlicer),
			"TOPSUM":..PreFilter(pIsSlicer),
			"BOTTOMSUM":..PreFilter(pIsSlicer),
			"CROSSJOIN":..PreCrossjoin(pIsSlicer),
			"NONEMPTYCROSSJOIN":..PreCrossjoin(pIsSlicer),
			:$$$OK)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute and build the axes output for this axis.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK

	Try {
		Set pNewNodeNo = ""
		Set tFunction = $$$UPPER(..function)
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tExists =..%GetFunctionInfo(tFunction,.tIsImplemented,.tArgCount,.tReturn,.tArgs,.tArgDesc)
		
		Do:$G(%dstrace) ##class(%DeepSee.Utils).%WriteToLog("Trace",$$$dsCurrentMethod _ ":" _ tCubeIndex _ ":" _ $CLASSNAME() _ ":" _ ..%ToString())
		
		If ('tExists) {
			Set tSC = $$$ERROR($$$GeneralError,"Function does not exist: "_tFunction)
			Quit
		}
		If ('tIsImplemented) {
			Set tSC = $$$ERROR($$$GeneralError,"Function is not implemented: "_tFunction)
			Quit
		}

		Do $I(%SetOpDepth(pKey))		// DP-424589

		// dispatch to some functions directly
		If (tFunction="IIF") {
			Set tSC = ..IIF(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo,pParent,pVisible)
			Quit
		}

		// JMD1129 test for HEAD()
		If (tFunction="HEAD") {
			// optimization: pass on count to any children we process
			Set tHeadSet = ..children.GetAt(1)
			Set tHeadCount = ..children.GetAt(2)
			Set tHeadMode = ..children.GetAt(3)
			// DTB326 - Only pass restriction to children if running in SAMPLE mode
			If ($IsObject(tHeadMode)&&($$$UPPER(tHeadMode.%GetValue())="SAMPLE")&&$IsObject(tHeadCount)&&tHeadCount.%IsA("%DeepSee.Query.constant")) {
				New %dsHeadCount
				Set %dsHeadCount = tHeadCount.%GetValue()
			}
		}
		
		If (tFunction="HEAD")||(tFunction="TAIL")||(tFunction="SUBSET") {
			// DTB327 - Signal the subset function that processing should be delayed. Per-crossjoin truncation
			// can result in extra reduction in the results when the full intersection is processed. do not
			// bother with this if the HEAD function's SAMPLE flag is in play.
			
			//Pull APV097 out of the setFunction condition below to make it generally applicable if related-cube
			//terms exist in the slicer of a query that contains a subset function in the SELECT clause.
			If $IsObject(%query.slicer) && ##class(%DeepSee.Query.query).%HasRelations(pCube,%query.slicer){
				Set tDelaySubset=1
			}
			Else{
				Set tSet = ..children.GetAt(1)
				If '$G(%dsHeadCount)&&tSet.%IsA("%DeepSee.Query.setFunction") {
					If (tSet.function["CROSSJOIN") {
						Set tSetChild1 = tSet.children.GetAt(1)
						Set tSetChild2 = tSet.children.GetAt(2)
						
						If (tSetChild1.%IsA("%DeepSee.Query.setFunction")&&(tSetChild1.function["CROSSJOIN")) ||
							(tSetChild2.%IsA("%DeepSee.Query.setFunction")&&(tSetChild2.function["CROSSJOIN")) {
							Set tDelaySubset = 1
						}
						ElseIf (tSetChild1.%IsA("%DeepSee.Query.setFunction")&&((tSetChild1.function="HEAD")||(tSetChild1.function="TAIL")||(tSetChild1.function="SUBSET"))) ||
								(tSetChild2.%IsA("%DeepSee.Query.setFunction")&&((tSetChild2.function="HEAD")||(tSetChild2.function="TAIL")||(tSetChild2.function="SUBSET"))) {
							// DTB357 - Account for HEAD( CJ( HEAD(set),HEAD(set) ) )
							Set tDelaySubset = 1
						}
						
					}
					ElseIf ((tSet.function="HEAD")||(tSet.function="TAIL")||(tSet.function="SUBSET")) {
						Set tDelaySubset = 1
					}
				}
			}
		}

		// test for crossjoin: there are special cases for this
		Set tIsCrossJoin = (tFunction="CROSSJOIN")||(tFunction="NONEMPTYCROSSJOIN")

		// check if required args are present
		Set tChildCount = ..children.Count()
		If (tChildCount < tArgCount) {
			Set tSC = $$$ERROR($$$GeneralError,"Function is missing one or more required parameters: "_..%GetFunctionSignature(..function))
			Quit
		}

		// the number of child nodes to process depends on
		// what function is in play. Only last arg can be of type "X"
		If ($LG(tArgDesc,$LL(tArgDesc))="X") {
			If (tChildCount '= $LL(tArgDesc)) {
				Set tSC = $$$ERROR($$$GeneralError,"Wrong number of parameters supplied to function: "_tFunction)
				Quit
			}
			Set tChildCount = $LL(tArgDesc) - 1
		}

		// see if first node will be return value as well (type "S")
		// only *first* argument can be of type "S"
		Set tUseFirstSet = 0
		If ($LG(tArgDesc,1)="S") {
			Set tUseFirstSet = 1
		}

		Set tParentNode = pParent
		Set tSetNode = pParent
		Set (tTempRoot,tTempNode) = ""
		If ((tUseFirstSet && (tChildCount>1)) || ('tUseFirstSet && (tChildCount>0))) {
			// add temp node to axis tree to hold children while we work on them
			// (with no parent)
			// This must be removed later
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("?",0,0)
			Set tTempRoot = pNodeNo // top temp node to be deleted
			Set tTempNode = pNodeNo
		}

		Set tChildrenVisible = 1
		Set tOptimizedCrossJoin = 0	// Optimized CrossJoin

		// Get arguments for function; check types;
		Set tChildrenVisible = tChildrenVisible&pVisible

		Set tRepeatType = "" // repeating arg flag

		// special check for [NONEMPTY] CROSSJOIN of Members from the same hierarchy
		// -- in this case we use an optimized flavor of CROSSJOIN to avoid Le Product du de Cartes
		If (tIsCrossJoin) {
			Set tArg1 = ..children.GetAt(1)
			Set tArg2 = ..children.GetAt(2)
			Set tFunc1 = ""
			Set tFunc2 = ""

			If ($IsObject(tArg1)&&$IsObject(tArg2)) {
				// JMD844
				Set fj = ..%FindCrossJoinInfo(tArg1,.d1,.h1,.l1)
				If (fj=0) {
					Set tArg1 = ""
				}
				ElseIf (fj=2) {
					Set tOptimizedCrossJoin = 1
				}

				If ($IsObject(tArg1) && tArg2.%IsA("%DeepSee.Query.memberFunction")) {
					Set tFunc2 = $$$UPPER(tArg2.function)
					If ((tFunc2="MEMBERS")||(tFunc1="ALLMEMBERS")||(tFunc2="%TOPMEMBERS")) {
						Set tArg2A = tArg2.children.GetAt(1)
						Set d2 = $S(tArg2A:tArg2A.%member.%dimNumber,1:"")
						Set h2 = $S(tArg2A:tArg2A.%member.%hierNumber,1:"")
						Set l2 = $S(tArg2A:tArg2A.%member.%levelNumber,1:"")
					}
					Else {
						Set tArg2 = ""
					}
				}
				If ($IsObject(tArg1)&&$IsObject(tArg2)) {
					If (($G(d1)'="")&&($G(d1)=$G(d2))&&($G(h1)=$G(h2))&&($G(l1)<=$G(l2))) {
						// this can use the specialized cross join
						Set tOptimizedCrossJoin = 1
					}
				}
			}
		}

		// JMD: test for %OR(relatedMembers)
		// if found, combine the OR branches here
		If (tFunction = "%OR") {
			Set tTargetNode = ""
			Set tOrSet = ..children.GetAt(1)
			If $IsObject(tOrSet) {
				// tOrSet could be a range-- we can leave it alone in this case
				If (tOrSet.%IsA("%DeepSee.Query.set")) {
					Set tAddrCount = 0		// DTB187 - Keep track of how many distinct level specs this has
					For n=1:1:tOrSet.children.Count() {
						Set tTest = tOrSet.children.GetAt(n)
						If ($IsObject(tTest)&&tTest.%IsA("%DeepSee.Query.memberSpec")&&$IsObject(tTest.%member)&&tTest.%member.%IsA("%DeepSee.Query.memberRelationship")) {
							Set tTestAddr = tTest.%member.%dimNumber_":"_tTest.%member.%hierNumber_":"_tTest.%member.%levelNumber
							If '$D(tSetAddrs(tTestAddr)) {
								Set tSetAddrs(tTestAddr)=""
								Set tAddrCount = $I(tAddrCount)
							}
						}
					}
					
					// JMD1453: if this is a heterogenous set, ignore it!
					// DTB187: tAddrCount=1 ==> tOrSet is homogeneous
					If tAddrCount=1 {
						For n=1:1:tOrSet.children.Count() {
							Set tTest = tOrSet.children.GetAt(n)
							If ($IsObject(tTest)&&tTest.%IsA("%DeepSee.Query.memberSpec")&&$IsObject(tTest.%member)&&tTest.%member.%IsA("%DeepSee.Query.memberRelationship")) {
								Set tTestAddr = tTest.%member.%dimNumber_":"_tTest.%member.%hierNumber_":"_tTest.%member.%levelNumber
								
								If (n=1) {
									Set tTargetNode = tTest
									Set tTargetAddr = tTestAddr
								}
								ElseIf ($IsObject(tTargetNode)) {
									// same relation?
									If (tTestAddr = tTargetAddr) {
										// merge into first node and delete
										Set tSC = tTargetNode.%member.%MergeOR(tTest.%member)
										If $$$ISERR(tSC) Quit
										Do tOrSet.children.RemoveAt(n)
									}
								}
							}
						}
					}
				}
			}
			If $$$ISERR(tSC) Quit
		}

		For n=1:1:tChildCount {
			Set tFuncArgs(n) = ..children.GetAt(n)
			If (tFuncArgs(n)="") Quit
			Set tFuncArgType = tFuncArgs(n).%GetType()
			Set tArgType = $LG(tArgs,n,tRepeatType)
			Set tArgD = $P($LG(tArgDesc,n),":",1)
			If (tArgD = "N") {
				Set tRepeatType = tArgType
			}
			ElseIf ((tRepeatType="") && (tArgD="")) {
				Set tSC = $$$ERROR($$$GeneralError,"Extra parameters supplied to function: "_tFunction)
				Quit
			}

			// tArgType is the formal expected type
			// tFuncArgType is the actual type passed in

			Set tTypeCast = 0
			If (tFuncArgType'=tArgType) {
				// type mismatch:
				// if function expects a set, and argument is not a set,
				// we can wrap it with a set (in some cases)
				If (tArgType = $$$dstSet) {
					Set tTypeCast = 1
					Set:n=1 tFirstArgType = tFuncArgType
					Set tFuncArgType = $$$dstSet

					If (tUseFirstSet && (n=1)) {
						Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("set",0,0,tParentNode,,%SetOpDepth(pKey),$className()_":"_$$$dsCurrentMethod)		// DP-424589 - Add SetOpDepth
						Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tParentNode,"ch",pNodeNo) = ""
						Set pNewNodeNo = pNodeNo
						Set tParentNode = pNodeNo
						Set tSets(n) = pNodeNo
						Set tSetNode = pNodeNo
					}
					Else {
						Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("set",0,0,tTempNode,,%SetOpDepth(pKey),$className()_":"_$$$dsCurrentMethod)		// DP-424589 - Add SetOpDepth
						Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tTempNode,"ch",pNodeNo) = ""
						Set tTempNode = pNodeNo
						Set tSets(n) = pNodeNo
					}
				}
				ElseIf ((tArgType = $$$dstFlag) && (tFuncArgType=$$$dstString)) {
					// strings can be used as flags
				}
				ElseIf ((tArgType = $$$dstValue) && (tFuncArgType=$$$dstString)) {
					// strings can be used as values
				}
				ElseIf ((tArgType = $$$dstValue) && (tFuncArgType=$$$dstInteger)) {
					// integers can be used as numbers
				}
				ElseIf ((tArgType = $$$dstExpression) && ((tFuncArgType=$$$dstString)||(tFuncArgType=$$$dstValue)||(tFuncArgType=$$$dstInteger)||(tFuncArgType=$$$dstMember)||(tFuncArgType=$$$dstMeasure))) {
					// we can treat other items as expressions
				}
				Else {
					// some functions are overloaded; we *should* handle it in the table
					// but we do it here
					If (tFuncArgs(n).%IsA("%DeepSee.Query.memberFunction")&&($$$UPPER(tFuncArgs(n).function)="CURRENTMEMBER")&&($$$UPPER(tFuncArgs(n).%cmbrQualifier)["PROPERTIES(")) {
						// ok
					}
					ElseIf (((tFunction="ANCESTOR")||(tFunction="DESCENDANTS"))&&(n=2)&&(tFuncArgType=$$$dstInteger)) {
						// ok
					}
					ElseIf ((tFunction="%KPI")&&((tFuncArgType=$$$dstInteger)||(tFuncArgType=$$$dstValue))) {
						// ok
					}
					ElseIf ((tArgType=$$$dstString)&&((tFuncArgType=$$$dstInteger)||(tFuncArgType=$$$dstValue))) {
						// ok: use value as string!
					}
					ElseIf ((tFunction="%LABEL")&&(n=4)&&(tFuncArgType=$$$dstString)) {
						// ok
					}
					Else {
						Set tSC = $$$ERROR($$$GeneralError,"Wrong type of argument supplied to function: " _ ..function _ "(" _ tFuncArgs(n).%ToString() _ ")    Expected: "_ ..%TypeFlagToString(tArgType) _ ", Got: " _ ..%TypeFlagToString(tFuncArgType))
						Quit
					}
				}
			}

			If (tFuncArgType = $$$dstFlag) {
				// get value directly
				// this *must* be a literal flag, not a return from a function
				Set tArgValue(n) = tFuncArgs(n).%GetValue()

				// validate
				Set tFlags = $P($LG(tArgDesc,n),":",2)
				If ((","_tFlags_",") '[ (","_tArgValue(n)_",")) {
					Set tSC = $$$ERROR($$$GeneralError,"Invalid flag supplied to function: "_tFunction _ "(" _ tArgValue(n) _ ")")
					Quit
				}
			}
			ElseIf (tFuncArgType = $$$dstLevel) {
				// pass object along
				Set tArgValue(n) = tFuncArgs(n)
			}
			ElseIf (tFunction="DESCENDANTS")&&(tFuncArgType = $$$dstMember) {
				// DTB162 - pass object along
				// process child further
				Set tSC = tFuncArgs(n).%ProcessAxes(pCube,pKey,.pNodeNo, .tNewNodeNo, tTempNode, tChildrenVisible)
				If $$$ISERR(tSC) Quit
				If ('tTypeCast) {
					Set tSets(n) = tNewNodeNo
				}
				Set tArgValue(n) = tFuncArgs(n)
			}
			ElseIf ((tArgType'=$$$dstExpression) && ((tFuncArgType = $$$dstString)
				||(tFuncArgType = $$$dstValue)
				||(tFuncArgType = $$$dstInteger))) {

				Kill tRetValue
				If ('tFuncArgs(n).%IsA("%DeepSee.Query.constant")) {
					// if not a constant, we have to test the return type and process the node
					If ((tArgType '= tFuncArgs(n).%GetType())) {
						Set ft = tFuncArgs(n).%GetType()
						If ((tArgType=$$$dstString)&&(ft=$$$dstValue)) {
							// ok: use value as string!
						}
						Else {
							Set tSC = $$$ERROR($$$GeneralError,"Wrong type of argument supplied to function: " _ ..function _ "(" _ tFuncArgs(n).%ToString() _ ")    Expected: "_ ..%TypeFlagToString(tArgType) _ ", Got: " _ ..%TypeFlagToString(tFuncArgs(n).%GetType()))
							Quit
						}
					}
					Set tSC = tFuncArgs(n).%ProcessAxes(pCube,pKey,.pNodeNo, .tArgNode, tParentNode, tChildrenVisible)
					If $$$ISERR(tSC) Quit

					// see if there is a value created by processing this node
					// (e.g. %KPI(a,b,memberExpr))
					If $D($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tArgNode)) {
						Set tRetNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tArgNode))
						If ($LG(tRetNode,1)="lit") {
							Set tRetValue = $LG(tRetNode,6)
						}
					}
					// prune results
					Set tSC = ..%DeleteNode(tCubeIndex,pKey,%axis,tArgNode)
					If $$$ISERR(tSC) Quit
				}
				Set tArgValue(n) = $G(tRetValue,tFuncArgs(n).%GetValue())
			}
			Else {
				If (tUseFirstSet && (n=1)) {
					Set tSC = tFuncArgs(n).%ProcessAxes(pCube,pKey,.pNodeNo, .tNewNodeNo, tParentNode, tChildrenVisible)
					If $$$ISERR(tSC) Quit
					If (pNewNodeNo = "") {
						Set pNewNodeNo = tNewNodeNo
					}
					If ('tTypeCast) {
						Set tSets(n) = tNewNodeNo
						Set tSetNode = tNewNodeNo
					}
				}
				ElseIf ('tOptimizedCrossJoin) {
					// process child further
					Set tSC = tFuncArgs(n).%ProcessAxes(pCube,pKey,.pNodeNo, .tNewNodeNo, tTempNode, tChildrenVisible)
					If $$$ISERR(tSC) Quit
					If ('tTypeCast) {
						Set tSets(n) = tNewNodeNo
					}
				}

			}
		}
		If $$$ISERR(tSC) Quit

		// reduce children
		Set n = $O(tSets(""))
		While (n'="") {
			Set tSC = ..%ReduceNode(tCubeIndex,pKey,tSets(n))
			If $$$ISERR(tSC) Quit
			Set n = $O(tSets(n))
		}
		If $$$ISERR(tSC) Quit


		If ((tFunction = "PERCENTILE")||(tFunction = "PERCENTILERANK")) {
			// User can skip 2nd argument!
			// tPercentile is value for PERCENTILERANK
			Set tPercentile = $S(tFunction = "PERCENTILE":50,1:0)

			// get arg values
			Set:$IsObject($G(tFuncArgs(2))) tArgValue(2) = tFuncArgs(2).%GetValue()
			Set:$IsObject($G(tFuncArgs(3))) tArgValue(3) = tFuncArgs(3).%GetValue()

			If ($G(tArgValue(3))="") {
				If $IsValidNum($G(tArgValue(2))) {
					Set tPercentile = tArgValue(2)
					// JMD1136
					Kill tSets(2)
				}
			}
			Else {
				Set tPercentile = $G(tArgValue(3))
				// JMD1244 - Kill tSets(2) if arg2 is not a memberSpec
				If (tFuncArgs(2).%ClassName(1) '= "%DeepSee.Query.memberSpec") {
					Kill tSets(2)
				}
			}

			// JMD1136
			Set:tPercentile>100 tPercentile = 100
			Set:tPercentile<0 tPercentile = 0
		}

		// +DTB400 - Look at the tSets array and see if it needs to be translated to chained aggregate addresses
		Set tSetNo = $O(tSets(""),1,tSetAddr)
		While (tSetNo'="") {
			If ($$$dsAxisNodeAggParentGet($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetAddr))'="") {
				Set tSets(tSetNo) = $$$dsAxisNodeAggParentGet($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetAddr))
			}

			Set tSetNo = $O(tSets(tSetNo),1,tSetAddr)
		}
		// -DTB400

		// Process Functions
		Set tSC = $Case(tFunction,
			"NONEMPTYCROSSJOIN":..CrossJoin(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tSets(2)),1,tOptimizedCrossJoin,$G(tArgValue(3))),
			"CROSSJOIN":..CrossJoin(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tSets(2)),0,tOptimizedCrossJoin,$G(tArgValue(3))),
			"DISTINCT":..Distinct(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1))),
			"UNION":..Union(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tSets(2)),$G(tArgValue(3))),
			"INTERSECT":..Intersect(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tSets(2)),$G(tArgValue(3))),
			"EXCEPT":..Intersect(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tSets(2)),$G(tArgValue(3)),1),
			"HEAD":..HeadsOrTails(tFunction,pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),1,0,$G(tArgValue(2)),+$G(tDelaySubset)),
			"TAIL":..HeadsOrTails(tFunction,pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),-1,0,$G(tArgValue(2)),+$G(tDelaySubset)),
			"SUBSET":..HeadsOrTails(tFunction,pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),1,$G(tArgValue(2)),$G(tArgValue(3)),+$G(tDelaySubset)),
			"COUSIN":..Cousin(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo, tSetNode,$G(tSets(1)),$G(tSets(2))),
			"ANCESTOR":..Ancestor(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2))),
			"DESCENDANTS":..Descendants(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo, tSetNode, $G(tSets(1)),$G(tArgValue(1)),$G(tArgValue(2)),$G(tArgValue(3))),		// DTB162
			"FILTER":..Filter(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets),
			"ORDER":..Order(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(3))),
			"RANK":..Rank(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets),
			"HIERARCHIZE":..Hierarchize(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2))),
			"HIERARCHISE":..Hierarchize(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2))),
			"TOPCOUNT":..TopFunction(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2)),tFunction),
			"BOTTOMCOUNT":..TopFunction(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2)),tFunction),
			"TOPPERCENT":..TopFunction(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2)),tFunction),
			"BOTTOMPERCENT":..TopFunction(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2)),tFunction),
			"TOPSUM":..TopFunction(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2)),tFunction),
			"BOTTOMSUM":..TopFunction(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2)),tFunction),
			"MAX":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"MIN":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"AVG":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"COUNT":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction,$G(tArgValue(2))),
			"AGGREGATE":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"PERCENTILE":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction,tPercentile),
			"PERCENTILERANK":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction,tPercentile),
			"SUM":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"STDEV":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"STDDEV":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"STDEVP":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"STDDEVP":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"VAR":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"VARIANCE":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"VARP":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"VARIANCEP":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"MEDIAN":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			//"MODE":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"VISUALTOTALS":..VisualTotals(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2))),
			"%LIST":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"%FIRST":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"%LAST":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction),
			"%DISTINCT":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction,$G(tArgValue(2))),
			"%POSTCOUNT":..Aggregate(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,.tSets,tFunction,$G(tArgValue(2))),
			"%CELL":..CellFunction(pCube,tCubeIndex,pKey,.pNodeNo, .pNewNodeNo, tSetNode,.tArgValue,tFunction),
			"%CELLZERO":..CellFunction(pCube,tCubeIndex,pKey,.pNodeNo, .pNewNodeNo, tSetNode,.tArgValue,tFunction),
			"%ADDPARENTS":..AddParents(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1))),
			"%LABEL":..Label(pCube,tCubeIndex,pKey,.pNodeNo, tSetNode,$G(tSets(1)),$G(tArgValue(2)),$G(tArgValue(3)),$G(tArgValue(4)),$G(tArgValue(5)),$G(tArgValue(6))),
			"%SPACE":..Space(pCube,tCubeIndex,pKey,.pNodeNo, .pNewNodeNo, tSetNode),
			"%TERMLIST":..TermList(pCube,tCubeIndex,pKey,.pNodeNo, .pNewNodeNo, tSetNode,$G(tArgValue(1)),$G(tArgValue(2))),
			"%LOOKUP":..TermList(pCube,tCubeIndex,pKey,.pNodeNo, .pNewNodeNo, tSetNode,$G(tArgValue(1)),,$G(tArgValue(2)),$G(tArgValue(3)),$G(tArgValue(4))),
			"PERIODSTODATE":..PeriodsToDate(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo, tSetNode,$G(tArgValue(1)),$G(tSets(2))),
			"PARALLELPERIOD":..ParallelPeriod(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo, tSetNode,$G(tArgValue(1)),$G(tArgValue(2)),$G(tSets(3))),
			"OPENINGPERIOD":..OpenClosePeriod(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo, tSetNode,$G(tArgValue(1)),$G(tSets(2)),0),
			"CLOSINGPERIOD":..OpenClosePeriod(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo, tSetNode,$G(tArgValue(1)),$G(tSets(2)),1),
			"%OR":..ORSET(pCube,tCubeIndex,pKey,.pNodeNo, .pNewNodeNo,tSetNode,$G(tSets(1))),
			"%CUBE":..CUBE(pCube,tCubeIndex,pKey,.pNodeNo, .pNewNodeNo, tSetNode,.tArgValue),
			"%MDX":..MDX(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo,tSetNode,.tArgValue,.tSets),
			"%KPI":..KPI(pCube,tCubeIndex,pKey,.pNodeNo,.pNewNodeNo,tSetNode,.tArgValue,.tSets),

			:$$$ERROR($$$GeneralError,"Unimplemented SET function: " _ tFunction))
		If $$$ISERR(tSC) Quit

		If (pNewNodeNo = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Internal error in setFunction, node not created: "_tFunction)
			Quit
		}
		// remove temp nodes
		If (tTempRoot '= "") {
			Set tSC = ..%DeleteNode(tCubeIndex,pKey,%axis,tTempRoot)
			If $$$ISERR(tSC) Quit
		}

		// apply format, if needed
		If ((tSetNode'="")&&(..formatString'="")) {
			Set $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode),12) = ..formatString
		}

		// for %LABEL, return same type as first arg
		// JMD1361: simplify %OR as well
		// JMD1365: only simplify if we are within a tuple!
		If (((tFunction="%OR")&&$IsObject(..parent)&&(..parent.%IsA("%DeepSee.Query.tuple")))
			||(((tFunction="%LABEL")||(tFunction="%SPACE"))&&(($G(tFirstArgType)=$$$dstMember)||($G(tFirstArgType)=$$$dstMeasure)))) {

			// JMD1453: but not if we have an "orset"
			If ($LG($G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode)),1)'="orset") {

				// convert set to member
				Set tChildNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode,"ch",""))
				If (tChildNo'="") {
					Set tNode1 = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode))
					Set tNode2 = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tChildNo))
					If ($LG(tNode2,24)="") {
						// DTB713 - Move the child node up if it is not tracking the aggregate parent
						Set $List(tNode2,4) = $LG(tNode1,4)	// parent
						Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode) = tNode2

						// move children over
						Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode,"ch")
						Merge $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode,"ch") = $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tChildNo,"ch")
						Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tChildNo)

						// JMD855-make sure that the children of the moved node refer to the new parent
						Set kc = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode,"ch",""))
						While (kc'="") {
							Set $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",kc),4) = tSetNode
							Set kc = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode,"ch",kc))
						}

						// only set "all" if already present!
						If $D($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",tChildNo)) {
							Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",tSetNode) = ""
							Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",tChildNo)
						}

						// move cmbr marker
						If $D($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"cmbr",tChildNo)) {
							Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"cmbr",tSetNode) = ""
							Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"cmbr",tChildNo)
						}
					}
					Else {
						// DTB713 - Snip the "set" node out of the chain, keep all child nodes in place
						Set tSetParent = $LG(tNode1,4)
						Set $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tChildNo),4) = tSetParent
						Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetParent,"ch",tSetNode)
						Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetParent,"ch",tChildNo) = ""
						
						// Remove the previous set node
						Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode)
					}

				}
			}
		}
		ElseIf ((tFunction="%LOOKUP")) {
			// JMD1062: simplify results of lookup
			Set tIsLiteral = 0
			Set tSetNode = pNewNodeNo
			Set tChildNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode,"ch",""))
			If (tChildNo'="") {
				Set tCanSimplify = 1
				If ($O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode,"ch",tChildNo))'="") {
					// more than 1
					Set tCanSimplify = 0
				}
			}
			If (tCanSimplify) {
				// move child to top
				Set tNode1 = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode))
				Set tNode2 = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tChildNo))
				Set $List(tNode2,4) = $LG(tNode1,4)	// parent
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode) = tNode2

				// kill children
				Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode,"ch")
				Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tChildNo)

				// only set "all" if already present!
				If $D($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",tChildNo)) {
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",tSetNode) = ""
					Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",tChildNo)
				}
			}
		}

		Do $I(%SetOpDepth(pKey),-1)		// DP-424589
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// JMD844: Utility function.
/// For an argument to a CROSSJOIN, find the element reference (d,h,l) and return whether
/// it is a candidate for optimized crossjoin (0 no, 1 perhaps, 2 yes).
Method %FindCrossJoinInfo(pArg As %DeepSee.Query.node, Output pDim As %Integer, Output pHier As %Integer, Output pLevel As %Integer) As %Boolean [ Internal ]
{
	Set tRet = 1
	Set pDim = ""
	Set pHier = ""
	Set pLevel = ""

	If (pArg.%IsA("%DeepSee.Query.memberSpec")) {
		// if there is a specific member we can restrict by it
		Set pDim = $S(pArg.%member:pArg.%member.%dimNumber,1:"")
		Set pHier = $S(pArg.%member:pArg.%member.%hierNumber,1:"")
		Set pLevel = $S(pArg.%member:pArg.%member.%levelNumber,1:"")
	}
	ElseIf (pArg.%IsA("%DeepSee.Query.memberFunction")) {
		Set tFunc1 = $$$UPPER(pArg.function)
		If ((tFunc1="MEMBERS")||(tFunc1="ALLMEMBERS")||(tFunc1="%TOPMEMBERS")) {
			Set tArg1 = pArg.children.GetAt(1)
			Set pDim = $S(tArg1:tArg1.%member.%dimNumber,1:"")
			Set pHier = $S(tArg1:tArg1.%member.%hierNumber,1:"")
			Set pLevel = $S(tArg1:tArg1.%member.%levelNumber,1:"")
		}
		ElseIf (tFunc1="CURRENTMEMBER") {
			// pass on to crossjoin function to process second arg's children
			Set tRet = 2
		}
		Else {
			Set tRet = 0
		}
	}
	ElseIf (pArg.%IsA("%DeepSee.Query.setFunction")) {
		Set tFunc1 = $$$UPPER(pArg.function)
		If ((tFunc1="CROSSJOIN")||(tFunc1="NONEMPTYCROSSJOIN")) {
			Set tArg1 = pArg.children.GetAt(1)
			// recurse
			Set tRet = ..%FindCrossJoinInfo(tArg1,.pDim,.pHier,.pLevel)
		}
		Else {
			Set tRet = 0
		}
	}
	Quit tRet
}

/// Utility function. Test if a node or any of its children have "cmbr" nodes.
/// Returns a list of all cmbrs nodes found.
/// No longer used.
Method %TestForCMBR(pCubeIndex As %String, pKey As %String, pNodeNo As %Integer, Output pCmbrNode As %List) As %Boolean [ Internal ]
{
	Set tHasCurrentMbr = 0
	Kill pCmbrNode
	Set pCmbrNodeNo = ""

	Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo))
	Set tType = $LG(tNode,1)
	If (tType="cmbr") {
		Set tHasCurrentMbr = 1
		Set pCmbrNode(pNodeNo) = tNode
	}
	ElseIf $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo)) {
		// look at children
		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",""))
		While (k'="") {
			Set tChildNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k))
			If (..%TestForCMBR(pCubeIndex,pKey,k,.tXNode)) {
				Set tHasCurrentMbr = 1
				Merge pCmbrNode = tXNode
			}
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",k))
		}
	}
	Quit tHasCurrentMbr
}

/// Perform a pre-Crossjoin operation. This prepares crossjoins for more optimal slicer behavior 
Method PreCrossjoin(pIsSlicer As %Boolean = 0) As %Status [ Internal ]
{
	// Method added by DP-421810
	Set tSC = $$$OK
	Try {
		If pIsSlicer&&(%query.slicer'="") {
			// While the axis cache is unable to support deeply nested AND/OR statements, this step needs to be skipped if it is going to trigger
			// a "Depth > 2" error.
			Set tRoomForOR = 1
			For n=1:1:%query.slicer.children.Count() {
				Set tSC = ..AnalyzeORNode(%query.slicer.children.GetAt(n),.tStructure,,,.tSlicerMaxDepth)
				If $$$ISERR(tSC) Quit

			 	Set:(tSlicerMaxDepth>=2) tRoomForOR=0 
			}
			If 'tRoomForOR Quit
			
			For n=1:1:..children.Count() {
				Set tChild = ..children.GetAt(n)

				// If the child is considered a set, collapse it into the smallest number of members possible using an %OR
				// Check to see if there is any reason not to wrap this child set in a %OR
				// Reason 1: The child must be a set or a function that produces a set. Note a tuple tests as %IsA("set")
				// Reason 2: The child must not contain a measure
				// Reason 3: The child is already a %OR function
				If (tChild.%GetType()=$$$dstSet) &&
						'##class(%DeepSee.Query.query).%HasMeasure(tChild,.tSC) &&
						'(tChild.%IsA("%DeepSee.Query.setFunction")&&(tChild.function="%OR")) {
					Set tNewChild = ##class(%DeepSee.Query.setFunction).%New("%OR")
					Do tNewChild.children.Insert(tChild)
					
					Set tSC = ..AnalyzeORNode(tNewChild,.tStructure,,,.tMaxDepth)
					If $$$ISERR(tSC) Quit

					Set tNewKids(n) = $S((tMaxDepth<=2):tNewChild,1:tChild)
				}
				Else {
					Set tNewKids(n) = tChild
				}
			}

			Do ..children.Clear()
			Set tChildNo = $O(tNewKids(""),1,tNewChild)
			While (tChildNo'="") {
				Do ..children.Insert(tNewChild)
				Set tChildNo = $O(tNewKids(tChildNo),1,tNewChild)
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a Pre-Filter operation. This creates the subquery needed for certain functions.
Method PreFilter(pIsSlicer As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFunction = $$$UPPER(..function)
		Set tSet = ""
		Set tExpr = ""
		Set tFlag = "ASC"
		Set tCube = %query.cube
		Set tRowExpression = ""

		// Make sure subquery gets original values of constants in %MDX/%KPI functions
		New %dsUseOrigValue
		Set %dsUseOrigValue = 1

		// Test for non empty along this axis
		Set tNonEmpty = $S($IsObject($G(%axisObject))&&%axisObject.nonEmpty:1,1:0)

		// Get children of this node: depending on function
		If ((tFunction = "FILTER")||(tFunction = "ORDER")) {
			Set tSet = ..children.GetAt(1)
			Set tExpr = ..children.GetAt(2)
			If (tFunction = "ORDER") {
				If $IsObject(..children.GetAt(3)) {
					Set tFlag = ..children.GetAt(3).%GetValue()
				}
			}

			If ('$IsObject(tExpr)) {
				Set tSC = $$$ERROR($$$GeneralError,"Missing Expression for function: " _ ..function)
				Quit
			}
		}
		ElseIf ((tFunction = "TOPCOUNT")||(tFunction = "BOTTOMCOUNT")||
				(tFunction = "TOPPERCENT")||(tFunction = "BOTTOMPERCENT")||
				(tFunction = "TOPSUM")||(tFunction = "BOTTOMSUM")) {
			Set tSet = ..children.GetAt(1)
			Set tExpr = ..children.GetAt(3)
		}
		ElseIf (tFunction = "RANK") {
			Set tSet = ..children.GetAt(2)
			Set tExpr = ""
		}
		ElseIf (tFunction = "%CUBE") {
			Set tChild1 = ..children.GetAt(1)
			If '$IsObject(tChild1) {
				Set tSC = $$$ERROR($$$GeneralError,"Missing Cube argument for function: " _ ..function)
				Quit
			}
			Set tChild2 = ..children.GetAt(2)
			If '$IsObject(tChild2) {
				Set tSC = $$$ERROR($$$GeneralError,"Missing Expression argument for function: " _ ..function)
				Quit
			}
			Set tCube = tChild1.%GetValue()
			Set tRowExpression = tChild2.%GetValue()
			Set tExpr = ""
		}

		If ('$IsObject(tSet) && (tRowExpression="")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing SET for function: " _ ..function)
			Quit
		}

		// do not use slicer for functions within the slicer!
		Set tSlicer = $S('pIsSlicer&&$IsObject(%query.slicer):%query.slicer,1:"")
		Set tIsLiteral = 0

		If $IsObject(tExpr) {
			Set tColExpression = tExpr.%ToString()
			If (tExpr.%IsA("%DeepSee.Query.constant")) {
				Set tIsLiteral = 1
			}
		}
		ElseIf (tExpr'="") {
			// literal
			Set tColExpression = tExpr
			Set tIsLiteral = 1
		}
		Else {
			Set tColExpression = ""
		}

		// JMD860
		// There may be a 3rd axis containing restrictions;
		// If so, fold into COLUMNS
		Set tAxisCount = %query.axes.Count()
		If ((tAxisCount>2)&&$IsObject(%query.axes.GetAt(3))) {
			If (tColExpression'="") {
				If ('tIsLiteral) {
					// don't bother for literal expression
					Set tColExpression = "CROSSJOIN("_tColExpression_","_%query.axes.GetAt(3).%ToString()_")"
				}
			}
			Else {
				Set tColExpression = %query.axes.GetAt(3).%ToString()
			}
		}

		Set:tColExpression'="" tColExpression = tColExpression _ " ON 0, "

		If ((tFunction = "ORDER")&&((tFlag="ASC")||(tFlag="DESC"))) {
			Set tRowExpression = "%ADDPARENTS("_tSet.%ToString()_")"
		}
		ElseIf (tFunction = "RANK") {
			Set tSortExpr = ..children.GetAt(3)
			If $IsObject(tSortExpr) {
				Set tSort = tSortExpr.%ToString()
				Set tColExpression = tSort _ " ON 0, "
				Set tRowExpression = "ORDER("_tSet.%ToString()_","_tSort_",BDESC)"
			}
			Else {
				// if no expression, we find rank within the set
				// Set tSort = "[Measures].%COUNT"
				Set tColExpression = ""
				Set tRowExpression = tSet.%ToString()
			}
		}
		ElseIf ((tRowExpression="") && $IsObject(tSet)) {
			Set tRowExpression = tSet.%ToString()
		}

		// Pass NON EMPTY along
		// PFS042 - Add non empty if this is the slicer to reflect behavior added by JMD1403
		If (tNonEmpty || pIsSlicer) {
			Set tRowExpression = "NON EMPTY " _ tRowExpression
		}

		If ..%IsOrderingFunction(tFunction)&&%query.%isCompoundMember {
			// DTB260 - If there is an ordering function, this needs to be dispatched to the overarching compound cube
			Set tFromCube = $$$UPPER(%query.parentCube)			// DTB428 - Make upper case index for global reference
			If $IsObject(tExpr) { 		// DTB339 - Make sure there is an expression to add to the subquery
				If tExpr.%IsA("%DeepSee.Query.calculatedMember") {
					// DTB306 - This is an ordering function using a calculated measure.
					// The original definition in the WITH text will be required to properly resolve
					// it in the context of the compound cube.
					Set tExpressionName = tExpr.memberName
					Set tOrderingWITHText = %query.parentWITHText
					
					// DTB358 - Replace the tColExpression according to each particular case
					Set tColExpression = "[MEASURES].["_tExpressionName_"] ON 0,"
				}
				ElseIf tExpr.%IsA("%DeepSee.Query.expression") {
					// DTB358 - Do not reset the tColExpression for expressions
					If (tExpr.operator="NOP")&&tExpr.children.GetAt(1).%IsA("%DeepSee.Query.memberFunction")&&(tExpr.children.GetAt(1).%cmbrQualifier["PROPERTIES") {
						// This is the case when sorting on a <property>. Do nothing.
					}
					Else {
						// If this contains relabeled measures, reject it as the argument of an ordering function with an error. 
						// Without digging into the expression and resetting to the compound context (see the Else case below),
						// this gives an inconsistent result!
						If tColExpression["%LABEL([MEASURES]." {
							Set tSC = $$$ERROR($$$GeneralError,"Ordering functions in compound cubes cannot resolve measure expressions")
							Quit
						}
					}
				}
				Else {
					// Standard measures have been wrapped in %LABEL. Remove the label to get back to the original 
					// measure in the context of the compound cube query
					Set tSC = %query.%RemoveLabel(tExpr,.tLabel,.tInner)
					
					// +DTB314 - The %LABEL is maintaining the shape of results across subcubes.
					// This label is the display caption of the measure. There is no reverse lookup 
					// for captioned measures, so search their definitions for the right caption.
					Set tExpressionCaption = $$$UPPER(tLabel.children.GetAt(2).value)
					
					Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(tFromCube)
					
					Set tExpressionName = ""
					Set tMeasureNo = $O($$$DeepSeeMetaGLVN("cubes",tFromCube,"mbr#",0,0))
					While ((tMeasureNo'="")&&(tExpressionName="")) {
						Set tMeasureName = $LG($$$DeepSeeMetaGLVN("cubes",tFromCube,"mbr#",0,tMeasureNo,0),3)
						Set tTestCaption = $classmethod(tClassName,"%GetMemberCaption","MEASURES",tMeasureName)
						
						If ($$$UPPER(tTestCaption)=$$$UPPER(tExpressionCaption)) {
							Set tExpressionName = tMeasureName
							Quit
						}
						
						Set tMeasureNo = $O($$$DeepSeeMetaGLVN("cubes",tFromCube,"mbr#",0,tMeasureNo))
					}
					// -DTB314
					
					// DTB358 - Replace the tColExpression according to each particular case
					Set tColExpression = "[MEASURES].["_tExpressionName_"] ON 0,"
				}
			}
		}
		ElseIf (tFunction="FILTER")&&%query.%isCompoundMember {
			// DTB493 - A filtering function also needs to reference the overarching compound cube
			Set tFromCube = %query.parentCube
			
			If $IsObject(tExpr) { 
				If tExpr.%IsA("%DeepSee.Query.expression") {
					Set tSC = %query.%RemoveLabelsInFilterExpression(tExpr,.tCompoundExpr,tFromCube)
					
					Set tColExpression = tCompoundExpr.%ToString() _ " ON 0,"
				}
			}
		}
		Else {
			Set tFromCube = tCube
		}

		// check for different target name!
		// this should be the last argument to the function
		If (tFunction'["%") {
			Set tClass = ..#FUNCTIONCLASS
			Set tMeta = $G($$$DeepSeeFunctionGLVN(tClass,tFunction))
			Set tArgNum = +$LL($LG(tMeta,4))
		}

		If (+$G(tArgNum) > 0) {
			Set tTarget = ..children.GetAt(tArgNum)
			If ($IsObject(tTarget)&&(tTarget.%GetValue()'="")) {
				Set tFromCube = tTarget.%GetValue()
			}
		}

		// now create subquery
		// SELECT <EXPR> ON COLUMNS, <CURRSET> ON ROWS FROM <CUBE> WHERE <SLICER>
		// (If we are in a slicer, then do not add a slicer to the query)
		Set tMDX = "SELECT "_tColExpression_tRowExpression_" ON 1 FROM " _ "["_tFromCube_"]"
		If ($G(tOrderingWITHText)'="") {
			// DTB306 - If the original WITH clause is used, signal %RegisterSubquery to skip
			// processing the calculated members into a subquery WITH clause.
			Set tSkipSubqueryWith = 1
			Set tMDX = "WITH " _ tOrderingWITHText _ " " _ tMDX
		}
		
		If ($IsObject(tSlicer)) {
			If (tFunction '= "%CUBE") {
				Set tAddSlicer = 1
				If ##class(%DeepSee.Query.query).%HasMeasure(tSlicer) {
					// DTB125 - Prepare the subquery constructed thus far to test the rows
					// and columns for measures. If a measure collision would occur, do not add
					// the slicer.
					Set tTempRS = ##class(%DeepSee.ResultSet).%New()
					Set tSC = tTempRS.%PrepareMDX(tMDX)
					Set tTempQuery = tTempRS.%GetQuery()
					For a = 1:1:tTempQuery.axes.Count() {
						Set tAddSlicer = tAddSlicer && '##class(%DeepSee.Query.query).%HasMeasure(tTempQuery.axes.GetAt(a)) 
					}
				}
				Kill tTempRS,tTempQuery
				
				If tAddSlicer {
					// DP-433396- Add component filters instead of the overall slicer to prevent implicit filterAxis terms from
					// creeping into subqueries.
					For {
						Set tFilter = %query.filters.GetNext(.f)
						Quit:(f="")

						Set:(tFilter.context'="filterAxis") tMDX = tMDX _ " %FILTER " _ tFilter.%ToString()
					}
				}
			}
		}

		// look for unresolved CMBR references in the subquery
		// and convert *back* to .CurrentMember!
		If $IsObject($G(%axisObject)) {
			Set k = $O(%axisObject.%cmbrIndex(""))
			While (k'="") {
				Set tMDX = $Replace(tMDX,k,%axisObject.%cmbrIndex(k)_".CurrentMember")
				Set k = $O(%axisObject.%cmbrIndex(k))
			}
		}
		if ($IsObject(tSlicer)) { // JSL4428, the slicer may not be axis and may have unresolved CMBR reference
			Set k = $O(tSlicer.%cmbrIndex(""))
			While (k'="") {
				Set tMDX = $Replace(tMDX,k,tSlicer.%cmbrIndex(k)_".CurrentMember")
				Set k = $O(tSlicer.%cmbrIndex(k))
			}
		}
		If +$G(%dsflags("SUBQUERY")) {
			$$$DSWRITELN($C(13,10)_"PREFILTER SUBQUERY ("_..function_"): "_tMDX)
		}

		// register this subquery with the cube
		// if this subquery is within a calc mbr then it could have already
		// been registered.
		If (..subqueryKey = "") {
			Set tSC = %query.%RegisterSubQuery(tMDX,.tKey,%axisObject,+$G(tSkipSubqueryWith))
			If $$$ISERR(tSC) Quit

			Set ..subqueryKey = tKey
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Kill %dsUseOrigValue

	Quit tSC
}

/// Utility method. Test if there is a currentMember reference within the query node.
Method %HasCurrentMember(pSet As %DeepSee.Query.node) As %Boolean [ Internal ]
{
	Set tHasMbr = 0

	If (pSet.%IsA("%DeepSee.Query.memberFunction")) {
		If ($$$UPPER(pSet.function)="CURRENTMEMBER") {
			Set tHasMbr = 1
		}
	}

	If ('tHasMbr) {
		If (pSet.%IsA("%DeepSee.Query.group")) {
			For n = 1:1:pSet.children.Count() {
				Set t = ..%HasCurrentMember(pSet.children.GetAt(n))
				If (t) {
					Set tHasMbr = 1
					Quit
				}
			}
		}
	}
	Quit tHasMbr
}

/// Perform a Filter operation the given items in <var>pSets</var>.
/// The first item is a set and the second item is an expression.
Method Filter(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, ByRef pSets As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// Get ResultSet for the subquery
		Set tSC = %query.%GetSubQuery(..subqueryKey,.tRS)
		If $$$ISERR(tSC) Quit

		If (tRS.%GetQueryKey()="") {
			// should not happen!
			Set tSC = $$$ERROR($$$GeneralError,"Internal Error in Filter()")
			Quit
		}

		// Use SubQuery results to remove items from the Sets
		// Get array of values from subquery indexed by internal tuple (fact/key...)
		Set tSC = ##class(%DeepSee.Query.Engine).%GetAxisValues(.tTempIndex,tRS.%GetCubeName(),tRS.%GetQueryKey())
		If $$$ISERR(tSC) Quit

		Set k = $O(pSets(""))
		While (k '= "") {
			Set tSC = ..%ApplyFilterToSet(pCube,pCubeIndex,pKey,pSets(k),tTempIndex)
			Set k = $O(pSets(k))
		}

		// Kill temp data
		Kill ^||DeepSee.Temp(tTempIndex)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a Rank operation the given items in <var>pSets</var>.
Method Rank(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, ByRef pSets As %Integer) As %Status [ Internal ]
{
	// n.b.: the %RANK memberFunction is a duplicate version of this
	Set tSC = $$$OK
	Try {
		Set tTupleNodeNo = $G(pSets(1))
		If (tTupleNodeNo="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing tuple for RANK function")
			Quit
		}

		Set tTupleNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tTupleNodeNo))
		Set tTupleType = $$$dsAxisNodeTypeGet(tTupleNode)
		Set tTupleName = "Rank" // replaced below

		// Get ResultSet for the subquery
		Set tSC = %query.%GetSubQuery(..subqueryKey,.tRS)
		If $$$ISERR(tSC) Quit

		If (tRS.%GetQueryKey()="") {
			// should not happen!
			Set tSC = $$$ERROR($$$GeneralError,"Internal Error in Rank()")
			Quit
		}

		// incoming tuple (argument 1) can be: cmbr,mbr, or tuple
		// ??? is cmbr code still used?
		If (tTupleType = "cmbr") {
			// calculated member:
			// modify the qualifier of this node and resolve this later!
			Set tQualifier = $$$dsAxisNodeKeyGet(tTupleNode)
			Set tQualifier = tQualifier _ $S(tQualifier="":"",1:".")_ "%Rank("_$$$quote(tRS.%GetQueryKey())_")"
			Set $$$dsAxisNodeKey(tTupleNode) = tQualifier
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tTupleNodeNo) = tTupleNode
			Quit
		}
		ElseIf (tTupleType = "tuple") {
			// put pieces of tuple together, assume a direct chain of child nodes
			Set tHasCmbr = 0
			Set tChild = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tTupleNodeNo,"ch",""))
			While (tChild '= "") {
				Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChild))
				Set tType = $$$dsAxisNodeTypeGet(tNode)
				If (tType = "mbr") {
					Set tKey = $$$dsAxisNodeKeyGet(tNode)
					Set tFact = $$$dsAxisNodeFactGet(tNode)
					Set tTupleName = $$$dsAxisNodeLabelGet(tNode)
					If (tFact '= "") {
						Set tFacts(tFact) = tKey
					}
				}
				ElseIf (tType = "cmbr") {
					Set tHasCmbr = 1
					// calculated member:
					// modify the qualifier of this node and resolve this later!
					Set tQualifier = $$$dsAxisNodeKeyGet(tTupleNode)
					Set tQualifier = tQualifier _ $S(tQualifier="":"",1:".")_ "%Rank("_$$$quote(tRS.%GetQueryKey())_")"
					Set $$$dsAxisNodeKey(tNode) = tQualifier
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChild) = tNode
					Quit
				}
				Set tChild = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChild,"ch",""))
			}
			If (tHasCmbr) {
				Set tSC = $$$ERROR($$$GeneralError,"CurrentMember not supported for tuples within the RANK function")
				Quit
			}
		}
		ElseIf (tTupleType = "mbr") {
			// mbr *is* the tuple
			Set tKey = $$$dsAxisNodeKeyGet(tTupleNode)
			Set tFact = $$$dsAxisNodeFactGet(tTupleNode)
			If (tFact '= "") {
				Set tFacts(tFact) = tKey
			}
			Else {
				Set tFacts("*") = "" // ALL level
			}
			Set tTupleName = $$$dsAxisNodeLabelGet(tTupleNode)
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"First argument for RANK function must be a tuple")
			Quit
		}

		// Use SubQuery results to find the ranking of the given tuple.
		// Get array of values from subquery indexed by internal tuple (fact/key...)
		Set tSC = ##class(%DeepSee.Query.Engine).%GetAxisValues(.tTempIndex,tRS.%GetCubeName(),tRS.%GetQueryKey(),,1)
		If $$$ISERR(tSC) Quit

		// find tuple in result set
		Set tFound = 0
		Set tRank = $O(^||DeepSee.Temp(tTempIndex,""))
		While (tRank '= "") {
			Set k = $O(^||DeepSee.Temp(tTempIndex,tRank,""))
			While (k '= "") {
				// pull apart k and test against facts
				Set tFound = 1
				For p=1:1:$L(k,$C(2)) {
					Set t = $P(k,$C(2),p)
					Set f = $P(t,":",1)
					Set v = $P(t,":",2)
					If (f'="") {
						If ($G(tFacts(f))'=v) {
							Set tFound = 0
							Quit
						}
					}
					Else { // ALL Level
						If ('$D(tFacts("*"))) {
							Set tFound = 0
							Quit
						}
					}
				}
				If tFound Quit
				Set k = $O(^||DeepSee.Temp(tTempIndex,tRank,k))
			}
			If tFound Quit
			Set tRank = $O(^||DeepSee.Temp(tTempIndex,tRank))
		}

		// Not found, return 0
		Set:tRank="" tRank=0

		// Paste answer into tuple node
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tTupleNodeNo) = $LB("lit",1,1,$lg(tTupleNode,4),tTupleName,tRank)
		If (tTupleType = "tuple") {
			// insert all node
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",tTupleNodeNo) = ""
			Set leaf = $I(%leafCount)
		}

		// also remember answer in node
		Set ..value = tRank

		// remove children of the tuple node: they will not be needed!
		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tTupleNodeNo,"ch",""))
		While (k '= "") {
			Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,k)
			If $$$ISERR(tSC) Quit
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tTupleNodeNo,"ch",k))
		}

		// Kill temp data
		Kill ^||DeepSee.Temp(tTempIndex)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform an Hierarchize operation on the given items in node <var>pSet</var>.
Method Hierarchize(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet As %Integer, pFlag As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pSet="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing argument for HIERARCHIZE function")
			Quit
		}

		// implement as ORDER but sort by name
		// n.b., we *should* find the sort key for each member
		Set tTempIndex = $I(^||DeepSee.Temp)

		// visit each top-level member of the set
		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
		While (k '="") {
			Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k))
			Set tName = $LG(tNode,5)
			Set tKey = $LG(tNode,6)
			Set tFact = $LG(tNode,7)

			If (tFact'="") {
				// use name as sort key
				Set ^||DeepSee.Temp(tTempIndex,tFact_":"_tKey) = $$$UPPER(tName)
			}
			// next node
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",k))
		}

		Set tSort = "ASC"
		Set tPostFlag = (pFlag="POST")
		Set tSC = ..%ApplyOrderToSet(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,tTempIndex,tSort,tPostFlag)
		If $$$ISERR(tSC) Quit

		// remove temp data
		Kill ^||DeepSee.Temp(tTempIndex)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform an Order operation on the given items in node <var>pSet</var>.
Method Order(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet As %Integer, pSort As %String = "ASC") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pSet="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing argument for ORDER function")
			Quit
		}

		// Get ResultSet for the subquery
		Set tSC = %query.%GetSubQuery(..subqueryKey,.tRS)
		If $$$ISERR(tSC) Quit

		// + DTB870 - Make sure the subquery has its results completed	
		Set tStatus = tRS.%GetStatus()
		Set tSC = tRS.%UpdatePendingResults(.tPending)
		If $$$ISERR(tSC) Quit
		
		Set tTries = 0
		Set tIncomplete = ((tStatus<100) || ((tStatus>=100) && tPending))		// DTB989 - Check to see if polling is necessary
		
		While tIncomplete && (tTries<51) {
			Hang $S((tTries<11):0.05,(tTries<26):0.1,1:0.5)		// DTB989 - Use a progressive interval wait which still totals 15 seconds
			
			Set tStatus = tRS.%GetStatus()
			Set tSC = tRS.%UpdatePendingResults(.tPending)
			
			Set tTries = tTries+1
			Set tIncomplete = ((tStatus<100) || ((tStatus>=100) && tPending))
		}
		
		If tIncomplete {
			Set tSC = $$$ERROR($$$GeneralError,"Ordering subquery could not be completed in 15 seconds: " _ tRS.%GetCubeName() _ ":" _ tRS.%GetQueryKey())
			Quit
		}
		// - DTB870

		If (tRS.%GetQueryKey()="") {
			// should not happen!
			Set tSC = $$$ERROR($$$GeneralError,"Internal Error in Order()")
			Quit
		}

		// Use SubQuery results to sort items in the Sets
		// Get array of values from subquery indexed by internal tuple (fact/key...)
		Set tSC = ##class(%DeepSee.Query.Engine).%GetAxisValues(.tTempIndex,tRS.%GetCubeName(),tRS.%GetQueryKey())

		If ((pSort="BASC")||(pSort="BDESC")) {
			Set tSC = ..%ApplyBreakingOrderToSet(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,tTempIndex,pSort)
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tSC = ..%ApplyOrderToSet(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,tTempIndex,pSort,0)
			If $$$ISERR(tSC) Quit
		}

		Kill ^||DeepSee.Temp(tTempIndex)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform one of the top operations on the given items in node <var>pSet</var>.
/// These include TOPCOUNT,BOTTOMCOUNT,TOPPERCENT,BOTTOMPERCENT,TOPSUM, and BOTTOMSUM.
Method TopFunction(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet As %Integer, pIndex As %Integer, pFunction As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pSet="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing argument for function: " _ pFunction)
			Quit
		}

		// Get ResultSet for the subquery
		Set tSC = %query.%GetSubQuery(..subqueryKey,.tRS)
		If $$$ISERR(tSC) Quit

		If (tRS.%GetQueryKey()="") {
			// should not happen!
			Set tSC = $$$ERROR($$$GeneralError,"Internal Error in TopFunction()")
			Quit
		}

		// Use SubQuery results to sort items in the Sets
		// Get array of values from subquery indexed by fact/key
		Set tSC = ##class(%DeepSee.Query.Engine).%GetAxisValues(.tTempIndex,tRS.%GetCubeName(),tRS.%GetQueryKey(),.tSetTotal)

		Set tSortFlag = $Case(pFunction,
							"TOPCOUNT":"BDESC",
							"TOPPERCENT":"BDESC",
							"TOPCOUNT":"BDESC",
							"BOTTOMCOUNT":"BASC",
							"BOTTOMPERCENT":"BASC",
							"BOTTOMSUM":"BASC",
							:"BDESC"
							)

		Set tSC = ..%ApplyBreakingOrderToSet(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,tTempIndex,tSortFlag,.tNodeValues)
		If $$$ISERR(tSC) Quit
		
		// prune unwanted members
		If ((pFunction="TOPCOUNT")||(pFunction="BOTTOMCOUNT")) {
			Set tCount = 0
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
			While (k '= "") {
				Set tCount = tCount + 1
				If (tCount > pIndex) {
					Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,k)
					If $$$ISERR(tSC) Quit
				}
				Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",k))
			}
		}
		ElseIf ((pFunction="TOPPERCENT")||(pFunction="BOTTOMPERCENT")) {
			// JMD915: include member crossing the "threshold" in TOP case
			Set tIsTop = (pFunction="TOPPERCENT")
			Set tLastPct = 0
			Set tOverLimit = 0
			Set tSum = 0
			
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
			While (k '= "") {
				// DTB324 - Treat the null replacement 1E-14 as 0 for the total
				Set tNodeValue = $G(tNodeValues(k))
				Set tSum = tSum + $S((tNodeValue=1E-14):0,1:tNodeValue)
				Set tPct = $S(tSetTotal=0:100,1:100*(tSum/tSetTotal))
				If (tPct > pIndex) {
					// JMD915: don't delete the first item over the top limit
					If ('tIsTop || tOverLimit || (tLastPct=pIndex)) {
						Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,k)
						If $$$ISERR(tSC) Quit
					}
					Set tOverLimit = 1
				}
				Set tLastPct = tPct
				Set k = $O($$$DeepSeeAxisGLVN(pCube,pKey,"axes",pSet,"ch",k))
			}
		}
		If ((pFunction="TOPSUM")||(pFunction="BOTTOMSUM")) {
			Set tSum = 0
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
			While (k '= "") {
				// DTB324 - Treat the null replacement 1E-14 as 0 for the total
				Set tNodeValue = $G(tNodeValues(k))
				Set tSum = tSum + $S((tNodeValue=1E-14):0,1:tNodeValue)
				If (tSum > pIndex) {
					Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,k)
					If $$$ISERR(tSC) Quit
				}
				Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",k))
			}
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Process an IIF function.<br/>
Method IIF(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// create expression node to wrap set2 and set 3
		Set tLabel = $S(..label'="":..label,1:"IIF")
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("exp",pVisible,1,pParent,tLabel,"IIF")
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
		Set pNewNodeNo = pNodeNo
		Set leaf = $I(%leafCount)
		Set tSetNode = pNodeNo

		Set:..formatString'="" $List($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo),12) = ..formatString

		// there should be 3 children
		Set tChildCount = ..children.Count()
		If (tChildCount'=3) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for IIF function")
			Quit
		}

		Set tShowIntermediate = 0 // debug flag
		For n=1:1:tChildCount {
			Set tChild = ..children.GetAt(n)
			Set tType = tChild.%GetType()

			Set tSC = tChild.%ProcessAxes(pCube,pKey,.pNodeNo,.tNewNodeNo,tSetNode,tShowIntermediate)
			If $$$ISERR(tSC) Quit

			// check type
			If ((tType'=$$$dstMeasure)&&(tType'=$$$dstInteger)&&(tType'=$$$dstValue)&&(tType'=$$$dstString)&&(tType'=$$$dstMember)&&(tType'=$$$dstExpression)) {
				Set tSC = $$$ERROR($$$GeneralError,"Wrong type of argument supplied to IIF: " _ ..%TypeFlagToString(tType))
			}
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// JMD785: force visible flag to 0 for all children
		Set tChildNode = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tSetNode,"ch",""))
		While (tChildNode'="") {
			Set $List($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode),2)=0
			Set tChildNode = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tSetNode,"ch",tChildNode))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Process the given cell function:
/// A cell function calculated values based on the actual
/// cells in the final result. (e.g. %CELL).
Method CellFunction(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, ByRef pNewNodeNo As %Integer, pParent As %Integer, ByRef pArgs As %Integer, pFunction As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFunction = $$$UPPER(..function)

		// add cell function node
		Set tLabel = $CASE(tFunction,
					"%CELL":$G(pArgs(3)),
					"%CELLZERO":$G(pArgs(3)),
					:"CELL")
		
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("cell",1,1,pParent,tLabel,tFunction)
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
		Set leaf = $I(%leafCount)
		Set pNewNodeNo = pNodeNo

		// push args into node tree
		Set tArg = $O(pArgs(""))
		While (tArg'="") {
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("lit",0,1,pNewNodeNo,"",pArgs(tArg))
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNewNodeNo,"ch",pNodeNo) = ""
			Set tArg = $O(pArgs(tArg))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Apply the given aggregate function, <var>pFunction</var>, to the members of the given set.
Method Aggregate(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, ByRef pSets As %Integer, pAggregate As %String, pFlag As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pAggregate="COUNT") {
			// second argument is a flag
			Set tExclude = (pFlag="EXCLUDEEMPTY")
		}
		ElseIf (pAggregate="PERCENTILE") {
			// argument is the percentile value
			Set tPercentile = +pFlag
		}
		ElseIf (pAggregate="PERCENTILERANK") {
			// argument is the value
			Set tPercentile = +pFlag
		}
		ElseIf (pAggregate="%DISTINCT") {
			// second argument is a flag
			Set tExclude = (pFlag="EXCLUDEEMPTY")
		}
		ElseIf (pAggregate="%POSTCOUNT") {
			// second argument is a flag
			Set tExclude = (pFlag="EXCLUDEEMPTY")
		}
		If $G(pSets(2)) {
			// there is an "expression" set for the aggregate
			// wrap the expression within a set
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("set",0,0)
			Set tTempNode = pNodeNo
		
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tTempNode,"ch",pSets(2)) = ""
			Set tNode = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSets(2))
			Set $List(tNode,4) = tTempNode

			// CrossJoin the set and expression
			Set tSC = ..CrossJoin(pCube, pCubeIndex,pKey, .pNodeNo, pParent, pSets(1), tTempNode)
			If $$$ISERR(tSC) Quit

			// make sure top nodes are calculated
			Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSets(1),"ch",""))
			While (s1 '="") {
				Set tNode = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1)
				Set tNodeType = $LG(tNode,1)
				If ((tNodeType'="exp")&&(tNodeType'="mbr")&&(tNodeType'="cmbr")&&(tNodeType'="orset")) {		// DTB462 - Add orset exemption
					Set $List(tNode,1) = "eq"
				}
				Set $List(tNode,2) = 1
				Set $List(tNode,3) = 1
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1) = tNode
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",s1) = ""

				// hide node and its children
				Set tSC = ..%HideNode(pCubeIndex,pKey,%axis,s1)
				If $$$ISERR(tSC) Quit

				Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSets(1),"ch",s1))
			}

			// remove temp nodes
			If (tTempNode '= "") {
				Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tTempNode)
				If $$$ISERR(tSC) Quit
			}
		}
		Else {
			// hide children
			Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSets(1),"ch",""))
			While (s1 '="") {
				Set tNode = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1)

				// Do not process the distinct set during cell execution
				// We will resolve these during consolidation
				If (pAggregate="%DISTINCT") {
					Set $List(tNode,2) = 0
					Set $List(tNode,3) = 0
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1) = tNode
					Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",s1)
				}
				ElseIf $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1,"ch")) {
					Set tNodeType = $LG(tNode,1)
					If ((tNodeType'="exp")&&(tNodeType'="mbr")&&(tNodeType'="cmbr")&&(tNodeType'="orset")) {		// DTB462 - Add orset exemption
						Set $List(tNode,1) = "eq"
					}
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1) = tNode
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",s1) = ""
				}

				Set tSC = ..%HideNode(pCubeIndex,pKey,%axis,s1)
				If $$$ISERR(tSC) Quit
				Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSets(1),"ch",s1))
			}
		}
		// mark our node as an aggregate expression based on the aggregate function
		// this will be computed during the Consolidate phase
		Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSets(1)))
		If (tNode="") || ($$$IsDeepSeeNullAxisNode(tNode)) {		// DTB832 - Also test for literal null if the node does exist
			// nothing to count; place a literal 0 in the node
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $$$DeepSeeLitAxisNode(pParent,"AGG",0)		// DTB832 - Use new macro
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
			Set leaf = $I(%leafCount)
		}
		Else {
			// mark our node as an aggregate expression based on the aggregate function
			// this will be computed during the Consolidate phase
			If (..label'="") {
				Set tLabel=..label
			}
			ElseIf (pAggregate="%DISTINCT") {
				Set tLabel = "COUNT"
			}
			ElseIf (pAggregate="%POSTCOUNT") {
				Set tLabel = "COUNT"
			}
			ElseIf (pAggregate="PERCENTILE") {
				// special labels for percentile
				Set tLabel = tPercentile_" Percentile"
			}
			ElseIf (pAggregate="PERCENTILERANK") {
				// special labels for percentile rank
				Set tLabel = "Rank of "_tPercentile
			}
			Else {
				Set tLabel = ..function
				If ($E(tLabel,1)="%") {
					// strip off leading %
					Set tLabel = $E(tLabel,2,$L(tLabel))
				}
			}

			Set $List(tNode,1) = "agg"
			Set $List(tNode,2) = 1
			Set $List(tNode,3) = 1
			Set $List(tNode,5) = tLabel
			Set $List(tNode,6) = $$$UPPER(..function)

			If ($$$UPPER(..function)="COUNT") {
				If ($G(tExclude)) {
					Set $List(tNode,7) = "EXCLUDEEMPTY"
				}
			}
			ElseIf ($$$UPPER(..function)="%DISTINCT") {
				If ($G(tExclude)) {
					Set $List(tNode,7) = "EXCLUDEEMPTY"
				}
			}
			ElseIf ($$$UPPER(..function)="%POSTCOUNT") {
				If ($G(tExclude)) {
					Set $List(tNode,7) = "EXCLUDEEMPTY"
				}
			}
			ElseIf ($$$UPPER(..function)="PERCENTILE") {
				// stash value in here!
				Set $List(tNode,7) = "PERCENTILE"
				Set $List(tNode,8) = tPercentile
			}
			ElseIf ($$$UPPER(..function)="PERCENTILERANK") {
				// stash value in here!
				Set $List(tNode,7) = "VALUE"
				Set $List(tNode,8) = tPercentile
			}
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSets(1)) = tNode
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pSets(1)) = ""
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Remove node <var>pNode</var> and its children from the axis tree.
/// <var>pTempIndex</var> is the subscript in temp global containing the filter data set.
Method %ApplyFilterToSet(pCube As %String, pCubeIndex As %String, pKey As %String, pNodeNo As %Integer, pTempIndex As %Integer) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK

	// see if this node is filtered
	Set tInclude = 1
	Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo))
	Set tCalc = $LG(tNode,3)
	If (tCalc) {
		// construct internal tuple for this node
		Set tIndex = ""
		Set tType = $LG(tNode,1)
		While ((tType'="axis")&&(tType'="")) {
			Set tDimNo = $LG(tNode,9)		// DTB493
			If (tType = "mbr")&&(tDimNo'="") {
				Set tKey = $LG(tNode,6)
				Set tFact = $LG(tNode,7)
				
				// +DTB493 - Look for sharesFrom index. If this fact is shared, look up the original fact number to match with
				//    pIndex in the ^||DeepSee.Temp sorting global.
				If (($IsObject($G(%query))&&%query.%isCompoundMember)||##class(%DeepSee.Utils).%IsCubeCompound(pCube)) {
					Set tHierNo = $LG(tNode,10)
					Set tLevelNo = $LG(tNode,11)
					Set tDimName = $LG($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"mbr#",tDimNo,0,0),2)
					Set tSharesFromCubeIndex = $O($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"sharesFrom",""))
					While tSharesFromCubeIndex'="" { 
						If $D($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"sharesFrom",tSharesFromCubeIndex,$$$UPPER(tDimName))) {
							// Get the fact number from the original cube
							Set tSharedDim = $LG($$$DeepSeeMetaGLVN("cubes",tSharesFromCubeIndex,"mbrs",$$$UPPER(tDimName)),1)
							Set tFact = $LG($$$DeepSeeMetaGLVN("cubes",tSharesFromCubeIndex,"mbr#",tSharedDim,tHierNo,tLevelNo),5)
						}
						Set tSharesFromCubeIndex = $O($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"sharesFrom",tSharesFromCubeIndex))
					}
				}
				// -DTB493
				
				If (tFact '= "") {
					Set tIndex = tFact_":"_tKey _ $S(tIndex="":"",1:$C(2)) _ tIndex
				}
			}
			Set tParent = $LG(tNode,4) // go to parent
			If (tParent="") {
				Set tType = ""
			}
			Else {
				Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParent))
				Set tType = $LG(tNode,1)
			}
		}
		If (tIndex'="") {
			Set tInclude = +$G(^||DeepSee.Temp(pTempIndex,tIndex))
		}
	}

	If ('tInclude) {
		Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo))
		Set tParent = $LG(tNode,4)
		Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo)
		Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParent,"ch",pNodeNo)
		Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo)
		Set %leafCount = %leafCount - 1
	}

	// Process child nodes
	Set tChildCount = 0
	Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",""))
	While (k '= "") {
		Set tSC = ..%ApplyFilterToSet(pCube,pCubeIndex,pKey,k,pTempIndex)
		If $$$ISERR(tSC) Quit
		Set tChildCount = tChildCount + 1
		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",k))
	}

	Set tPostChildCount = 0
	Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",""))
	While (k '= "") {
		Set tPostChildCount = tPostChildCount + 1
		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",k))
	}

	If ((tChildCount>0)&&(tPostChildCount=0)) {
		// we *had* children, but they were filtered out
		Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo))
		If ($LG(tNode,1)'="set") {
			Set tParent = $LG(tNode,4)
			Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo)
			Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParent,"ch",pNodeNo)
			Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo)
			Set %leafCount = %leafCount - 1
		}
	}
	Quit tSC
}

/// Apply ordering to node <var>pSet</var> and its children within the axis tree.<br/>
/// This ordering breaks the hierarchy of the set: all children are sorted together.<br/>
/// On return, <var>pNodeValue</var> contains, by node, the value used to sort the nodes.
Method %ApplyBreakingOrderToSet(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet As %Integer, pTempIndex As %Integer, pSortFlag As %String, Output pNodeValues As %Double) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK

	Try {
		Set tDir = $CASE(pSortFlag,"BASC":1,"BDESC":-1,:1)
		Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet))
		Set tSortedListIndex = ""

		// visit each member of the Set, flattening as we go
		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
		While (k '= "") {
			Set tOriginalSet(k) = ""
			Set tSC = ..%ProcessNodesForBreakingOrder(pCube,pCubeIndex,pKey,pTempIndex,k,"",.tSortedListIndex)
			If $$$ISERR(tSC) Quit
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",k))
		}
		If $$$ISERR(tSC) Quit

		// rebuild child nodes using sort list
		If (tSortedListIndex="") Quit

		Set k = ""
		Set i = $O(^||DeepSee.Temp(tSortedListIndex,""),tDir)
		While (i '= "") {
			Set j = $O(^||DeepSee.Temp(tSortedListIndex,i,""),tDir)
			While (j '= "") {
				Set tNodeNo = j
				Kill tLocalTuple
				Set t = 0
				While (tNodeNo'=pSet) {
					Set tNode = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo)
					Set tType = $LG(tNode,1)
					If ((tType = "mbr")||(tType = "msr")) {
						Set t = t + 1
						Set tLocalTuple(t) = tNode
					}
					Set tNodeNo = $LG(tNode,4) // follow parent
				}

				// rebuild node using local tuple
				Set tParent = pParent
				Set tc = 0
				Set t = $O(tLocalTuple(""),-1)
				While (t '= "") {
					Set tc = tc + 1
					Set tLocalNode = tLocalTuple(t)
					Set $List(tLocalNode,4) = tParent
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tLocalNode
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParent,"ch",pNodeNo) = ""
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
					Set leaf = $I(%leafCount)
					Set tParent = pNodeNo
					If (tc=1) {
						Set pNodeValues(pNodeNo) = i
					}
					Set t = $O(tLocalTuple(t),-1)
				}
				Set j = $O(^||DeepSee.Temp(tSortedListIndex,i,j),tDir)
			}
			Set i = $O(^||DeepSee.Temp(tSortedListIndex,i),tDir)
		}

		// delete original members of the set
		Set k = $O(tOriginalSet(""))
		While (k '= "") {
			Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,k)
			If $$$ISERR(tSC) Quit
			Set k = $O(tOriginalSet(k))
		}
		If $$$ISERR(tSC) Quit

		// Kill temp set
		Kill ^||DeepSee.Temp(tSortedListIndex)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// This allows the caller to immediately set the local function property by providing the 
/// function name in the call to <method>%New</method>.
Method %OnNew(pFunction As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
	// Added by DP-429168
	Set ..function = pFunction
	Quit $$$OK
}

/// This is used by %ApplyBreakingOrderToSet to visit child nodes recursively.
Method %ProcessNodesForBreakingOrder(pCube As %String, pCubeIndex As %String, pKey As %String, pTempIndex As %Integer, pNodeNo As %Integer, pIndex As %Binary, ByRef pSortedListIndex) [ Internal, Private ]
{
	Set tSC = $$$OK
	Try {
		If ($G(pSortedListIndex)="") {
			Set pSortedListIndex = $I(^||DeepSee.Temp)
		}

		Set tChildNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo))
		Set tType = $LG(tChildNode,1)
		If ((tType="mbr")||(tType="msr")) {
			Set tVisible = $LG(tChildNode,2)
			Set tId = $LG(tChildNode,6)
			Set tFact = $LG(tChildNode,7)
			
			// +DTB260 - Look for sharesFrom index. If this fact is shared, look up the original fact number to match with
			//    pIndex in the ^||DeepSee.Temp sorting global.
			If %query.%isCompoundMember {
				Set tDimNo = $LG(tChildNode,9)
				Set tHierNo = $LG(tChildNode,10)
				Set tLevelNo = $LG(tChildNode,11)
				Set tDimName = $LG($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"mbr#",tDimNo,0,0),2)
				Set tSharesFromCubeIndex = $O($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"sharesFrom",""))
				While tSharesFromCubeIndex'="" { 
					If $D($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"sharesFrom",tSharesFromCubeIndex,$$$UPPER(tDimName))) {
						// Get the fact number from the original cube
						Set tSharedDim = $LG($$$DeepSeeMetaGLVN("cubes",tSharesFromCubeIndex,"mbrs",$$$UPPER(tDimName)),1)
						Set tFact = $LG($$$DeepSeeMetaGLVN("cubes",tSharesFromCubeIndex,"mbr#",tSharedDim,tHierNo,tLevelNo),5)
					}
					Set tSharesFromCubeIndex = $O($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"sharesFrom",tSharesFromCubeIndex))
				}
			}
			// -DTB260
			
			Set pIndex = pIndex _ $S(pIndex="":"",1:$C(2)) _ tFact _ ":" _ tId
			If (tVisible && (pIndex'="")) {
				Set tSortVal = $G(^||DeepSee.Temp(pTempIndex,pIndex))
				Set:tSortVal="" tSortVal = 1E-14
				Set ^||DeepSee.Temp(pSortedListIndex,tSortVal,pNodeNo) = ""
			}
		}
		Set ch = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",""))
		While (ch'="") {
			Set tSC = ..%ProcessNodesForBreakingOrder(pCube,pCubeIndex,pKey,pTempIndex,ch,pIndex,.pSortedListIndex)
			If $$$ISERR(tSC) Quit
			Set ch = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",ch))
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit $$$OK
}

/// Apply ordering to node <var>pSet</var> and its children within the axis tree.<br/>
/// This ordering preserves the hierarchy of the set.
Method %ApplyOrderToSet(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet As %Integer, pTempIndex As %Integer, pSortFlag As %String, pPostFlag As %Boolean = 0, pNestedSortKey As %String = "") As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Try {

		Set tDir = $CASE(pSortFlag,"ASC":1,"BASC":1,"DESC":-1,"BDESC":-1,:1)

		If (pSet="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing set for VISUALTOTALS function")
			Quit
		}
		
		Set tEverFoundParent = 0 // WAL265

		// visit each top-level member of the set
		// assemble sorted listed by dimension/level
		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
		While (k '="") {
			Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k))
			Set tType = $LG(tNode,1)
			Set tName = $LG(tNode,5)
			Set tKey = $LG(tNode,6)
			Set tFact = $LG(tNode,7)
			Set tDimNo = $LG(tNode,9)
			Set tHierNo = $LG(tNode,10)
			Set tLevelNo = $LG(tNode,11)

			// this node
			If ((tType="mbr")&&(tKey'="")) {
				// +DTB260 - Look for sharesFrom index. If this fact is shared, look up the original fact number to match with
				//    pIndex in the ^||DeepSee.Temp sorting global.
				Set tDimName = $LG($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"mbr#",tDimNo,0,0),2)
				Set tSharesFromCubeIndex = $O($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"sharesFrom",""))
				While tSharesFromCubeIndex'="" { 
					If $D($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"sharesFrom",tSharesFromCubeIndex,$$$UPPER(tDimName))) {
						// Get the fact number from the original cube
						Set tSharedDim = $LG($$$DeepSeeMetaGLVN("cubes",tSharesFromCubeIndex,"mbrs",$$$UPPER(tDimName)),1)
						Set tFact = $LG($$$DeepSeeMetaGLVN("cubes",tSharesFromCubeIndex,"mbr#",tSharedDim,tHierNo,tLevelNo),5)
					}
					Set tSharesFromCubeIndex = $O($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"sharesFrom",tSharesFromCubeIndex))
				}
				// -DTB260
				
				Set tSortKey = tFact_":"_tKey
				Set tSortKey2 = tSortKey
				Set:pNestedSortKey'="" tSortKey2 = pNestedSortKey _ $C(2) _ tSortKey2
				Set tSortVal = $G(^||DeepSee.Temp(pTempIndex,tSortKey2))
				Set:tSortVal="" tSortVal = 1E-14
				Set tFactToNode(tFact,tKey) = k
			}
			ElseIf ((tLevelNo=1)&&(tKey="")) {
				// ALL
				Set tSortKey = "0"_":"_tDimNo
				Set tSortVal = 1E14				
				Set tFactToNode(0,tDimNo) = k
			}

			// get parent member(s), assemble level and graph indices
			//  tLevelIndex(tParentLevelNo,tParentSortKey) = ""
			// -- this is used to find the topmost level
			// sort key is: fact:key
			// tGraph is:
			//  tGraph(parentSortKey) = ""
			//  tGraph(tParentSortKey,tSortKey) = tSortVal
			// -- this is used to drive the output

			Set tStartingLevelNo = tLevelNo
			While (tLevelNo > 0) {
				Kill tSet
				Set tSC = ..%GetParentMember(pCube,tDimNo, tHierNo, tLevelNo, pParent,.tSet,tKey,tName)
				If $$$ISERR(tSC) Quit

				Set tParentNode = $G(tSet(1))
				Set tParentName = $LG(tParentNode,5)
				Set tParentType = $LG(tParentNode,1)
				Set tParentKey = $LG(tParentNode,6)
				Set tParentFact = $LG(tParentNode,7)
				Set tParentLevelNo = $LG(tParentNode,11)
				Set tParentSortKey = ""

				// + WAL086 -- If there is no parent node, just pretend we just saw an ALL level 
				//             This is needed because the sorting logic below assumes there is a parent level
				If ((tParentNode'="")) {
					Set tEverFoundParent = 1	// WAL265
				}
				ElseIf ((tParentNode = "")&&(tEverFoundParent=0)) { // WAL265
				//If (tParentNode = "") {
					Set tParentLevelNo = 1
					Set tParentKey = ""	
				}
				// - WAL086
	
				If ((tParentLevelNo = 1)&&(tParentKey="")) {
					// ALL level
					Set tParentSortKey = "0"_":"_tDimNo
					Set tLevelIndex(1,tParentSortKey) = ""
					Set tGraph(tParentSortKey) = ""
				}
				ElseIf ((tParentType="mbr")&&(tParentKey'="")) {
					Set tParentSortKey = tParentFact_":"_tParentKey
					Set tParentSortKey2 = tParentSortKey
					Set:pNestedSortKey'="" tParentSortKey2 = pNestedSortKey _ $C(2) _ tParentSortKey2
					Set tParentSortVal = $G(^||DeepSee.Temp(pTempIndex,tParentSortKey2))
					Set:tParentSortVal="" tParentSortVal = 1E-14
					Set tLevelIndex(tParentLevelNo,tParentSortKey) = ""
					Set tGraph(tParentSortKey) = tParentSortVal
				}
				If (tParentSortKey'="") {
					Set tGraph(tParentSortKey,tSortKey) = tSortVal
				}
				
				Set tLevelNo = tLevelNo - 1
				Set tName = tParentName
				Set tKey = tParentKey
				Set tSortKey = tParentSortKey
				Set tSortVal = $G(tParentSortVal,1E-14)
			}

			// next node
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",k))
		}
		
		// walk over top-most members
		Set tTopLevel = $O(tLevelIndex(""))
		If (tTopLevel="") Quit

		// first sort top-most members into tSort
		Set pk = $O(tLevelIndex(tTopLevel,""))
		While (pk'="") {
			Set tSortVal = $G(tGraph(pk))
			Set:tSortVal="" tSortVal = 1E-14
			Set tSort(tSortVal,pk) = ""
			Set pk = $O(tLevelIndex(tTopLevel,pk))
		}

		// now visit sorted top-most items
		Set v = $O(tSort(""),tDir)
		While(v'="") {
			Set pk = $O(tSort(v,""))
			While (pk'="") {
				Set tParentFact = $P(pk,":",1)
				Set tParentKey = $P(pk,":",2)
				If $D(tFactToNode(tParentFact,tParentKey)) {
					Set tParentNodeNo = tFactToNode(tParentFact,tParentKey)
					Set tParentNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParentNodeNo))
					Set tType = $LG(tParentNode,1)
					Set tName = $LG(tParentNode,5)
				}
				Set tSC = ..%ProcessNodesForOrder(pCube,pCubeIndex,pKey,.pNodeNo,pParent,.tGraph,.tFactToNode,pTempIndex,pk,tDir,pPostFlag)
				If $$$ISERR(tSC) Quit

				Set pk = $O(tSort(v,pk))
			}

			Set v = $O(tSort(v),tDir)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// This is used by %ApplyOrderToSet to visit child nodes recursively.
Method %ProcessNodesForOrder(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, ByRef pGraph, ByRef pFactToNode, pTempIndex As %Integer, pSortKey As %Integer, pSortDir As %Integer, pPostFlag As %Boolean = 0, pLevel As %Integer = 0) [ Internal, Private ]
{
	Set tSC = $$$OK
	Try {
		Set tFact = $P(pSortKey,":",1)
		Set tKey = $P(pSortKey,":",2)
		Set tName = ""

		// dispatch based on POST flag		
		If (pPostFlag) {
			Do CHILDREN
			Do PARENT
		}
		Else {
			Do PARENT
			Do CHILDREN
		}
		Goto DONE
PARENT
		If $D(pFactToNode(tFact,tKey)) {
			Set tNodeNo = pFactToNode(tFact,tKey)
			Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo))
			Set tType = $LG(tNode,1)
			Set tName = $LG(tNode,5)

			// process our child nodes, if any
			If $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo,"ch")) {
				Set tSC = ..%ApplyOrderToSet(pCube,pCubeIndex,pKey,.pNodeNo,tNodeNo, tNodeNo,pTempIndex,$S(pSortDir=1:"ASC",1:"DESC"),pSortKey)
				If $$$ISERR(tSC) Quit
			}

			// add new copy of this node
			Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,pParent,tNodeNo)
			If $$$ISERR(tSC) Quit
			
			// point index to new node, just in case
			Set pFactToNode(tFact,tKey) = pNodeNo

			// delete original
			Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tNodeNo)
			If $$$ISERR(tSC) Quit
		}
		Quit
CHILDREN
		// sort children
		Set ch = $O(pGraph(pSortKey,""))
		While(ch'="") {
			Set tSortVal = $G(pGraph(pSortKey,ch))
			Set:tSortVal="" tSortVal = 1E-14
			Set tSort(tSortVal,ch) = ""
			Set ch = $O(pGraph(pSortKey,ch))
		}

		// process sorted children
		Set v = $O(tSort(""),pSortDir)
		While(v'="") {
			Set ch = $O(tSort(v,""))
			While(ch'="") {
				Set tSC = ..%ProcessNodesForOrder(pCube,pCubeIndex,pKey,.pNodeNo,pParent,.pGraph,.pFactToNode,pTempIndex,ch,pSortDir,pPostFlag,pLevel + 1)
				If $$$ISERR(tSC) Quit
				Set ch = $O(tSort(v,ch))
			}
			Set v = $O(tSort(v),pSortDir)
		}
		Quit
DONE
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a Distinct on a set: remove any duplicate items.<br/>
Method Distinct(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet1 As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pSet1="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing argument for DISTINCT function")
			Quit
		}

		Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",""))
		While (s1 '="") {
			Set tNode1 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1))

			Set tSC = ..%NodeToText(pCubeIndex,pKey,s1,.tText)
			If $$$ISERR(tSC) Quit
			If $D(tDistinct(tText)) {
				// remove duplicate
				Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,s1)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set tDistinct(tText) = ""
			}
			Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",s1))
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a Union on 2 sets.<br/>
/// If <var>pAllFlag</var> = "ALL", include all members otherwise remove duplicates.
Method Union(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet1 As %Integer, pSet2 As %Integer, pAllFlag As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If ((pSet1="")||(pSet2="")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for UNION function")
			Quit
		}

		Set tAll = (pAllFlag = "ALL")

		// if not all, get values of first set 
		If ('tAll) {
			Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",""))
			While (s1 '="") {
				Set tNode1 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1))

				Set tSC = ..%NodeToText(pCubeIndex,pKey,s1,.tText)
				If $$$ISERR(tSC) Quit
				If ('tAll) {
					If (tText '= "") {
						If $D(tDistinct(tText)) {
							// duplicate: delete it from set1
							Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,s1)
							If $$$ISERR(tSC) Quit
						}
						Else {
							Set tDistinct(tText) = ""
						}
					}
				}
				Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",s1))
			}
		}

		// copy members of set2 into set1
		Set s2 = $O($$$DeepSeeAxisGLVN(pCube,pKey,"axes",pSet2,"ch",""))
		While (s2 '="") {
			Set tNode2 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s2))

			Set tCopy = 1
			If ('tAll) {
				Set tSC = ..%NodeToText(pCubeIndex,pKey,s2,.tText)
				If $$$ISERR(tSC) Quit
				If (tText'="") {
					If $D(tDistinct(tText)) {
						Set tCopy = 0
					}
					Else {
						Set tDistinct(tText) = ""
					}
				}
			}

			If (tCopy) {
				Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,pParent,s2)
				If $$$ISERR(tSC) Quit
			}

			Set s2 = $O($$$DeepSeeAxisGLVN(pCube,pKey,"axes",pSet2,"ch",s2))
		}
		
		// Delete original Set2
		Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pSet2)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform an Intersect or Except on 2 sets.<br/>
/// If <var>pAllFlag</var> = "ALL", include all members otherwise remove duplicates in the first set.<br/>
/// If <var>pExcept</var> is true, then perform an Except otherwise perform an Intersect.
Method Intersect(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet1 As %Integer, pSet2 As %Integer, pAllFlag As %String = "", pExcept As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If ((pSet1="")||(pSet2="")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for INTERSECT function")
			Quit
		}

		Set tAll = (pAllFlag = "ALL")

		// build list of distinct items in set2
		Set s2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet2,"ch",""))
		While (s2 '="") {
			Set tNode2 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s2))
			Set tSC = ..%NodeToText(pCubeIndex,pKey,s2,.tText)
			If $$$ISERR(tSC) Quit
			If (tText '= "") {
				Set tDistinct2(tText) = ""
			}
			Set s2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet2,"ch",s2))
		}

		// test each item in set1 and see if it is in set2
		Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",""))
		While (s1 '="") {
			Set tNode1 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1))

			Set tSC = ..%NodeToText(pCubeIndex,pKey,s1,.tText)
			If $$$ISERR(tSC) Quit

			Set tSkip = 0
			If ('tAll) {
				If $D(tDistinct(tText)) {
					// remove duplicate member of set1
					Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,s1)
					If $$$ISERR(tSC) Quit
					Set tSkip = 1
				}
				Else {
					Set tDistinct(tText) = ""
				}
			}
			If ('tSkip) {
				If (('pExcept&&'$D(tDistinct2(tText)))||(pExcept&&$D(tDistinct2(tText)))) {
					// item not in set2, remove
					Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,s1)
					If $$$ISERR(tSC) Quit
				}
			}
			Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",s1))
		}
		
		// Delete original Set2
		Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pSet2)
		If $$$ISERR(tSC) Quit

		// DP-421810 - If this is in the slicer, wrap this new set in an orset in the axis
		If ($LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1),1)="slicer") {
			Set tSC = ..ORSET(pCube,pCubeIndex,pKey,.pNodeNo,.pNodeNo,pParent,pSet1)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a Head,Tail, or SubSet on the given sets.<br/>
/// If <var>pDirection</var> = 1, move forward through the set, if -1, move backwards.<br/>
/// <var>pStartIndex</var> is index number if the first item to include.
/// <var>pCount</var> is number of items in the resulting set.
Method HeadsOrTails(pFunction As %String, pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet1 As %Integer, pDirection As %Integer, pStartIndex As %Integer, pCount As %Integer, pDelaySubset = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pSet1="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for function: " _ pFunction)
			Quit
		}

		// defaults are different for each function
		If (pFunction = "SUBSET") {
			Set:pCount<0 pCount = 0
			Set:pStartIndex<0 pStartIndex = 0
			Set tEndIndex = $S(pCount="":1E100,1:pStartIndex + pCount - 1)
		}
		Else {
			Set:pCount="" pCount = 1
			Set:pCount<0 pCount = 0
			Set:pStartIndex<0 pStartIndex = 0
			Set tEndIndex = pStartIndex + pCount - 1
		}

		If pDelaySubset {
			// DTB327 - Do not limit the set at this time. Mark the axis cache with the current function and
			// instructions on how to limit the results.
			Set tFunctionCount = $I($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"subset",pSet1))		// DTB328 - Multiple truncations for the same set are possible
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"subset",pSet1,tFunctionCount) = $LB(pFunction,$S(pFunction="SUBSET":pStartIndex,1:""),pCount)
			Quit
		}
		
		// JMD1129: loop over set; only count bottom, visible nodes
		Set tLevel = 1
		Set tItemNo = 0

		Set tNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",""),pDirection)
		While (tNodeNo'="") {
			// see if node is visible
			Set tNodeInfo = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo))
			If ($LG(tNodeInfo,2)) {
				If ((tItemNo < pStartIndex)||(tItemNo > tEndIndex)) {
					// remove node
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"truncated") = 1
					Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tNodeNo)
					If $$$ISERR(tSC) Quit
				}
				Set tItemNo = tItemNo + 1
			}

			// now find next node
			Set tFound = 0
			Do {
				// children first
				Set tNextNode = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo,"ch",""),pDirection)
				If (tNextNode'="") {
					Set tFound = 1
					Set tLevel = tLevel + 1
					Quit
				}

				// now sibling
				Set tParent = $LG(tNodeInfo,4)
				While (tParent'="") {
					Set tNextNode = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParent,"ch",tNodeNo),pDirection)
					If (tNextNode'="") {
						Set tFound = 1
						Quit
					}
					// go up
					Set tNodeNo = tParent
					Set tLevel = tLevel - 1
					If (tLevel<1) {
						Set tNextNode = ""
						Quit
					}
					Set tParent = $LG($G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParent)),4)
				}
			} While(0)
			If $$$ISERR(tSC) Quit

			If (tFound) {
				Set tNodeNo = tNextNode
			}
			Else {
				Set tNodeNo = ""
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a Cousin function on 2 members.<br/>
/// COUSIN(member,ancestor) finds a new member under *ancestor* with the same relationship to
/// *ancestor* that *member* has to the *ancestor* level.
Method Cousin(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pMemberNo As %Integer, pAncestorNo As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pNewNodeNo = ""
		If ((pMemberNo="")||(pAncestorNo="")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for COUSIN(member,ancestor) function")
			Quit
		}

		Set tMemberNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pMemberNo))
		Set tAncestorNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pAncestorNo))

		Set tMbrKey = $LG(tMemberNode,6)
		Set tMbrName = $LG(tMemberNode,5)
		Set tMbrDim = $LG(tMemberNode,9)
		Set tMbrHier = $LG(tMemberNode,10)
		Set tMbrLvl = $LG(tMemberNode,11)
		Set tAncKey = $LG(tAncestorNode,6)
		Set tAncDim = $LG(tAncestorNode,9)
		Set tAncHier = $LG(tAncestorNode,10)
		Set tAncLvl = $LG(tAncestorNode,11)

		If ((tMbrDim '= tAncDim)||(tMbrHier '= tAncHier)) {
			Set tSC = $$$ERROR($$$GeneralError,"Both arguments for COUSIN function must be members of the same hierarchy")
			Quit
		}

		If (tMbrLvl <= tAncLvl) {
			Set tSC = $$$ERROR($$$GeneralError,"Second argument for COUSIN function must be an ancestor of the first")
			Quit
		}

		// find provider for the member
		Set tSC = ..%ConstructMemberProvider(pCube,tMbrDim,tMbrHier,tMbrLvl,.tMember,tMbrKey)
		If $$$ISERR(tSC) Quit

		// work up levels, find offsets
		Set tKey = tMbrKey
		For tLevel = tMbrLvl:-1:tAncLvl {
			Set tMember.%levelNumber = tLevel
			Set tSC = tMember.%GetMemberOffset(.tOffset,tKey,.tParentKey)
			If $$$ISERR(tSC) Quit
			Set tPath(tLevel) = tOffset
			Set tKey = tParentKey
		}
		If $$$ISERR(tSC) Quit

		// now work *down* levels, apply offsets to Ancestor
		Set tParentKey = tAncKey
		Set tNoCousin = 0
		For tLevel = tAncLvl:1:tMbrLvl-1 {
			Kill tSet
			Set tOffset = tPath(tLevel+1)
			Set tSC = tMember.%GetNthChild(pCube,tMember.%dimNumber, tMember.%hierNumber, tLevel, pParent,.tSet,tParentKey,tOffset+1)
			If $$$ISERR(tSC) Quit

			Set tChildNo = $O(tSet(""))
			If (tChildNo = "") { // no matching cousin
				Set tNoCousin = 1
				Quit
			}
			Set tParentKey = $LG(tSet(tChildNo),6)
		}
		If $$$ISERR(tSC) Quit

		Set pNewNodeNo = pNodeNo
		If (tNoCousin) Quit

		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tSet(tChildNo)
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
		Set pNewNodeNo = pNodeNo
		Set leaf = $I(%leafCount)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a CrossJoin on a pair sets.<br/>
/// If <var>pNonEmpty</var> is true, remove empty tuples from the results.<br/>
/// If <var>pOptimized</var> is true, then both sets are from the same hierarchy and we will
/// restrict members of the second set against the current member of the first.
/// If <var>pHideChildren</var> is true, remove labels for the second set.<br/>
Method CrossJoin(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet1 As %Integer, pSet2 As %Integer, pNonEmpty As %Boolean = 0, pOptimized As %Boolean = 0, pHideChildren As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// JMD1340
		New %memberContext

		Do $I(%SetOpDepth(pKey))		// DP-424589

		Set tDebug = +$G(%dsflags("CROSSJOIN"))

		// JMD1129
		Set tMaxNodes = +$G(%dsHeadCount)

		Set tStart = $ZH
		Set tHideChildren = (pHideChildren="HIDE_CHILDREN")

		// JMD1045: count number of output nodes and missing nodes
		Set tNodeCount = 0
		Kill tMissingNodes

		// JMD1059
		Set tSetIsRelation1 = 0
		Set tSetIsRelation2 = 0
		Set tSetFact1 = ""
		Set tSetFact2 = ""
		Set tDependIndex = ""
		Set tDependInverted = 0 // test (A,B) or (B,A)
		Set tRemoteCube1 = ""
		Set tRemoteCube2 = ""

		// JMD1453
		Set tORSet1 = 0

		If (pOptimized) {
			If (pSet1="") {
				Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for CROSSJOIN function")
				Quit
			}
			// Find type of set1
			Set tNode1 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1))
			Set tType1 = $LG(tNode1,1)
		}
		Else {
			If ((pSet1="")||(pSet2="")) {
				Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for CROSSJOIN function")
				Quit
			}
			// Find type of each set
			Set tNode1 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1))
			Set tNode2 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet2))
			Set tType1 = $$$dsAxisNodeTypeGet(tNode1)
			Set tDepth1 = $$$dsAxisNodeSetOpDepthGet(tNode1)
			Set tType2 = $$$dsAxisNodeTypeGet(tNode2)
			Set tDepth2 = $$$dsAxisNodeSetOpDepthGet(tNode2)

			// find top child of each set
			// see if we are joining relationships
			Set tChild1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",""))
			// JMD1099: look at *all* children
			While (tChild1'="") {
				Set tChildNode1 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChild1))
				If $$$IsDeepSeeNullAxisNode(tChildNode1) {
					Set tNoData = 1
					Quit
				}

				Set tSetFact1 = $$$dsAxisNodeFactGet(tChildNode1)
				If ($$$dsAxisNodeRelSpecGet(tChildNode1)'="") {
					Set tSetIsRelation1 = 1
					Set tRelName = ""
					Set tRelFact = $$$dsAxisNodeFactGet(tChildNode1)
					Set:tRelFact'="" tRelName = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"rel#",tRelFact)))
					Set:tRelName'="" tRemoteCube1 = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"relations",$$$UPPER(tRelName),"relatedCube")))
					Set tChild1 = ""
				}
				Else {
					Set tChild1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChild1,"ch",""))
				}
			}
			Set tChild2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet2,"ch",""))
			While (tChild2'="")&&'$G(tNoData) {
				Set tChildNode2 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChild2))
				If $$$IsDeepSeeNullAxisNode(tChildNode2) {
					// DP-421810 - If child2 is a null axisNode, the entire crossjoin can't have a value
					Set tNoData = 1
					Quit
				}
				Set tSetFact2 = $$$dsAxisNodeFactGet(tChildNode2)
				If ($$$dsAxisNodeRelSpecGet(tChildNode2)'="") {
					Set tSetIsRelation2 = 1
					Set tRelName = ""
					Set tRelFact = $$$dsAxisNodeFactGet(tChildNode2)
					Set:tRelFact'="" tRelName = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"rel#",tRelFact)))
					Set:tRelName'="" tRemoteCube2 = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"relations",$$$UPPER(tRelName),"relatedCube")))
					Set tChild2 = ""
					Quit
				}
				Else {
					Set tChild2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChild2,"ch",""))
				}
			}
			If $G(tNoData) {
				// This entire crossjoin can't have a value
				// - Read parent node of Set1 (already have it, tChildNode1 is a local variable)
				Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pSet1)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
				// - Reset Set1 as a null axisNode with original parent
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1) = $$$DeepSeeNullAxisNode($LG(tChildNode1,4))
				Quit
			}

			// Do not intersect relationships unless there is a depends on
			If (pNonEmpty && (tSetIsRelation1 || tSetIsRelation2)) {
				Set pNonEmpty = 0
				// JMD1059: is there a dependsOn index in play?
				If ((tSetFact1'="")&&(tSetFact2'="")) {
					If $D($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"factDepends",tSetFact1,tSetFact2)) {
						Set pNonEmpty = 1
						Set tDependIndex = tSetFact1_"&"_tSetFact2
						Set tDependInverted = 0
					}
					ElseIf $D($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"factDepends",tSetFact2,tSetFact1)) {
						Set pNonEmpty = 1
						Set tDependIndex = tSetFact2_"&"_tSetFact1
						Set tDependInverted = 1
					}
				}
			}
			ElseIf (pNonEmpty) {
				// test for depends on index; non-relation case
				// JMD1059: is there a dependsOn index in play?
				If ((tSetFact1'="")&&(tSetFact2'="")) {
					If $D($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"factDepends",tSetFact1,tSetFact2)) {
						Set tDependIndex = tSetFact1_"&"_tSetFact2
						Set tDependInverted = 0
					}
					ElseIf $D($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"factDepends",tSetFact2,tSetFact1)) {
						Set tDependIndex = tSetFact2_"&"_tSetFact1
						Set tDependInverted = 1
					}
				}
			}

			If ((tType1="")||(tType2="")) {
				// should not happen!
				Set tSC = $$$ERROR($$$GeneralError,"Internal Error processing CROSSJOIN")
				Quit
			}
		}
		// + WAL039
		If (..children.GetAt(2).%IsA("%DeepSee.Query.setFunction")) {
			Set tSecondChildIsOrderingFunction = $Case($$$UPPER(..children.GetAt(2).function),
					"ORDER":1,
					"TOPCOUNT":1,
					"BOTTOMCOUNT":1,
					"TOPPERCENT":1,
					"BOTTOMPERCENT":1,
					"TOPSUM":1,
					"BOTTOMSUM":1,
					:0)
		}
		// - WAL039
		// + WAL067 -- Copy pSet2 to another node to deal with destructive ordering
		If ($G(tSecondChildIsOrderingFunction)) {			
			Set tNewSet2NodeNo = $I(pNodeNo)
			Set pNodeNo = $I(pNodeNo)
			Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,tNewSet2NodeNo,pSet2)
			If $$$ISERR(tSC) Quit
			Set tOriginalSet2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNewSet2NodeNo,"ch",""))
		}
		// - WAL067

		// find first bottom node of Set1
		// hide every node in Set1
		Set tDepth = 1
		Set tStackS1(tDepth) = pSet1
		While ($D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tDepth),"ch"))) {
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tDepth),"ch",""))
			If (k '= "") {
				// JMD1453: test for "orset" in set1
				Set tKType = $$$dsAxisNodeTypeGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k))
				Set tFunc = $$$dsAxisNodeKeyGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k))
				If (tKType="orset") {
					Set tORSet1 = 1
					Set tORSet1Depth = $$$dsAxisNodeSetOpDepthGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k))		// DP-429168 - Note the depth of this orset term
				}
				If (tKType="agg")&&(tFunc'="%MDX")&&(tFunc'="%KPI") {		
					// DTB666 - Do not hide aggregate nodes, but do log its presence to hide children later
					Set tAggregateNodes(k) = ""
				}
				Else {
					Do HideNode(k)
				}
				Set tDepth = tDepth + 1
				Set tStackS1(tDepth) = k
			}
			Else {
				Quit
			}
		}

		// now visit every bottom node
		While ((tDepth > 1) && (tStackS1(tDepth)'="")) {
			Set tSkip = 0
			Do HideNode(tStackS1(tDepth))
			Set tNode1 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tDepth)))
			Set tChildrenAdded = 0

			Set tType1 = $$$dsAxisNodeTypeGet(tNode1)
			Set tKey1 = $$$dsAxisNodeKeyGet(tNode1)
			Set tFact1 = $$$dsAxisNodeFactGet(tNode1)

			// find hierarchy of first set
			Set tDim1 = $$$dsAxisNodeDimGet(tNode1)
			Set tHier1 = $$$dsAxisNodeHierGet(tNode1)
			Set tLevel1 = $$$dsAxisNodeLevelGet(tNode1)

			If (pNonEmpty) {
				// see if s1 exists
				// JMD1040 Add test for "NO MEMBER"
				// JMD1059 do not test relation
				If ('tSetIsRelation1&&(tType1'="msr")&&(tFact1'="")&&(tKey1'="")&&(tKey1'="NO MEMBER")) {
					If 'tORSet1&&('##class(%DeepSee.Query.Engine).%IntersectExists(pCube,tFact1,tKey1)) {
						// DTB521 - Do not skip the actual intersection work if this is an orset
						Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tStackS1(tDepth))
						Set tSkip = 1
						Write:tDebug "S1 DOES NOT EXIST: ",tKey1," ",$LG(tNode1,5),!
					}
				}
			}
			If $$$ISERR(tSC) Quit

			If ('tSkip) {
				If (pOptimized) {
					// set up context for %GetMembers
					If (tKey1'="") {
						Set %memberContext = $LB(tLevel1,tKey1)
					}

					// materialize set2 for each member of set1
					// This must be removed later
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("?",0,0)
					Set tTempRoot = pNodeNo // top temp node to be deleted
					Set tTempNode = pNodeNo

					If '$G(tSecondChildIsOrderingFunction,0) {
						// DTB260 - Ordering functions as set2 require special handling, skip it here
						Set tSC = ..children.GetAt(2).%ProcessAxes(pCube,pKey,.pNodeNo, .tNewNodeNo, tTempNode, 1)
						If $$$ISERR(tSC) Quit

						Set tSC = ..%ReduceNode(pCube,pKey,tNewNodeNo)
						If $$$ISERR(tSC) Quit

						Set pSet2 = tNewNodeNo
					}
				}
				// + WAL039
				If ($G(tSecondChildIsOrderingFunction)) {			
					// + WAL067 -- replace pSet2 with clean copy in case previous ordering function deleted nodes
					Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pSet2)
					Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,pSet2,tOriginalSet2)
					// - WAL067
					Set tSC = ..DispatchOrderingFunction(pCubeIndex,pCubeIndex,pKey,.pNodeNo,..children.GetAt(2).function, tStackS1(tDepth),pSet2,pSet2)
				}
				If $$$ISERR(tSC) Quit
				// - WAL039
				// loop over every (top) member of set2
				Set s2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet2,"ch",""))
				While (s2'="") {
					// JMD1129
					If ((tMaxNodes>0)&&(tNodeCount>=tMaxNodes)) {
						// mark axis as truncated
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"truncated") = 2
						Quit
					}
					Set tIntersect = 1
					If (pNonEmpty) {
						Set tNode2 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s2))
						// DP-424589 - If a tuple is encountered, drop through to the next child in search of an actual member
						If $$$dsAxisNodeIsTuple(tNode2) {
							Set s2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s2,"ch",""))
							Continue
						}
						
						Set tORSet2 = $$$dsAxisNodeIsOrset(tNode2)

						Set tType2 = $$$dsAxisNodeTypeGet(tNode2)
						Set tKey2 = $$$dsAxisNodeKeyGet(tNode2)
						Set tFact2 = $$$dsAxisNodeFactGet(tNode2)
						
						Set tDim2 = $$$dsAxisNodeDimGet(tNode2)
						Set tHier2 = $$$dsAxisNodeHierGet(tNode2)
						Set tLevel2 = $$$dsAxisNodeLevelGet(tNode2)

						// WAL021
						Set tDepends1 = 0
						Set tDepends2 = 0
						If ((tFact1 = tSetFact1) || (tFact1 = tSetFact2)) { set tDepends1 = 1}
						If ((tFact2 = tSetFact1) || (tFact2 = tSetFact2)) { set tDepends2 = 1}
						If ((tDependIndex'="") && (tDepends1 = 1) && (tDepends2 = 1)) {
							// JMD1059 Check depends index
							Set tIntersect = 1
							Set tTestKey1 = tKey1
							Set tTestKey2 = tKey2
							If ((tKey1'="")&&(tKey2'="")) {
								// JMD1069 Use method
								If (tDependInverted) {
									Set tIntersect = ..%CheckDepends(pCubeIndex,tDependIndex,tKey2,tKey1,tRemoteCube2,tRemoteCube1)
								}
								Else {
									Set tIntersect = ..%CheckDepends(pCubeIndex,tDependIndex,tKey1,tKey2,tRemoteCube1,tRemoteCube2)
								}
							}
						}
						// WAL021
						ElseIf (tSetIsRelation1 || tSetIsRelation2) {
							Set tIntersect = 1
						}
						ElseIf ((tType1="msr")||(tType2="msr")) {
							Set tIntersect = 1
						}
						ElseIf ((tType2="agg")) {
							// JMD856:  NONEMPTYCJ(A,AGG(B)) does not need to test for intersection
							Set tIntersect = 1
						}
						ElseIf ((tFact1="")||(tFact2="")) {
							Set tIntersect = 1
						}
						ElseIf ((tFact2'="")&&(tKey2="NO MEMBER")) {
							// JMD917: empty member! treat as intersection
							// JMD1058: with JMD1045 logic, we can treat this as no intersect
							Set tIntersect = 0
						}
						ElseIf ((tKey1="")||(tKey2="")) {
							Set tIntersect = 0
						}
						ElseIf ('tORSet1&&(tFact1=tFact2)&&(tKey1'=tKey2)) {
							// n.b., is this correct for list-members?
							// JMD985: Nope; we have to test!
							// DP-429168 - This test is not relevant if the first set is an orset
							Set tIsList = 0
							Set tFactName = $G($$$DeepSeeMetaGLVN("cubes",pCube,"fact#",tFact1))
							If (tFactName'="") {
								Set tIsList = +$G($$$DeepSeeMetaGLVN("cubes",pCube,"fact","prop",tFactName,"list"))
							}
							// if either key is a NOT, let them pass
							If (($E(tKey1)="!")||($E(tKey2)="!")) {
								Set tInterSect = 1
							}
							ElseIf ((tKey1["|")||(tKey2["|")) {
								// JMD1282: treat OR as a possible intersection
								Set tInterSect = 1
							}
							//DP-401988: Check if either of the members is a computed dimension
							ElseIf ( $classmethod($LG($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"mbr#",tDim1,tHier1,tLevel1),6), "%IsA", "%DeepSee.ComputedDimension.Base") || $classmethod($LG($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"mbr#",tDim2,tHier2,tLevel2),6), "%IsA", "%DeepSee.ComputedDimension.Base")){
								Set tIntersect=1
							}
							Else {
								Set tIntersect = tIsList
							}
						}
						Else {
							If (tORSet1) {
								// DTB248 - Set 1 is a heterogeneous %OR chain, a node of type "orset".
								// The entire chain must be processed to test for intesection.
								Set tInterSect = ##class(%DeepSee.Query.Engine).%IntersectOrset(pCubeIndex,pKey,tStackS1(tDepth),s2)
							}
							ElseIf (tORSet2) {
								// DP-424589 - Check the "orset" chain in set2 against the current set1 term.
								Set tORSet2Leaf = s2
								While $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tORSet2Leaf,"ch"))\10 {
									Set tORSet2Leaf = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tORSet2Leaf,"ch",""))
								}
								Set tIntersect = ##class(%DeepSee.Query.Engine).%IntersectOrset(pCubeIndex,pKey,tORSet2Leaf,tStackS1(tDepth))
							}
							Else {
								// JMD779: optimization
								// if both sets are from same hierarchy, then we only
								// test the lowest level for existence
								// n.b. we already know that the member from the first set exists
								// DP-415899 - The member from the second set only needs to be tested for existence at this stage
								If ((tDim1=tDim2)&&(tHier1=tHier2)) {
									If (tLevel2>tLevel1) {
										Set tIntersect = ##class(%DeepSee.Query.Engine).%IntersectExists(pCube,tFact2,tKey2)
										Write:tDebug "INTERSECT s2: ",?30,tKey2," => ",?50,tIntersect,!
									}
								}
								// JMD1045: if JMD779 test passes, we still need to test both
								// as we could have the Asia->Brasil case1
								If (tIntersect) {
									Set tIntersect = ##class(%DeepSee.Query.Engine).%IntersectExists(pCube,tFact1,tKey1,tFact2,tKey2)
									Write:tDebug "INTERSECT s1 x s2: ",?30,tKey1," x ",tKey2," => ",?50,tIntersect,!
								}
							}
						}
					}
					If (tIntersect) {
						Set $$$dsAxisNodeNECJ($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo)) = +pNonEmpty // APV095
						// remove label from S2 nodes
						Set:tHideChildren $List($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s2),5) = ""
						// JMD792: if we are in the slicer, hide the parent of the node
						// to avoid extra "slices" to compute
						Set tS2Type = $LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s2),1)
						Set tHideParent = +$G(%dsIsSlicer)
						If ('tHideParent) {
							// JMD1453: we need to also "hide" parent for "tuples" and "orset"
							// this keeps extra items out of the "all" list
							If ((tS2Type="tuple")||(tS2Type="ortuple")||(tS2Type="orset")) {
								Set tHideParent = 1
							}
						}

						// JMD1453 If s1 is an "orset", then wrap s2 within a tuple
						If (tORSet1 && (tS2Type="mbr")) {
							Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,tStackS1(tDepth),s2,tHideParent,"tuple",tORSet1Depth)		// DP-429168 - Tag s2 with the same depth as s1
							If $$$ISERR(tSC) Quit
						}
						ElseIf (tORSet1 && (tS2Type="orset")) {
							// DTB695 - Convert this into an explicit tuple of orsets
							
							// Create a new "tuple" node to place the crossjoin under
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("tuple",0,0,pSet1,,$G(%SetOpDepth(pKey)),$$$dsCurrentMethod)		// DP-424589 - Add depth to tuple describing this entire CJ 
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",pNodeNo) = ""
							
							// Copy the current set one into the new tuple and remove the original copy and
							// reset tStackS1 to reflect the copied nodes under the new "tuple" node
							Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,pNodeNo,tStackS1(2),tHideParent)
							If $$$ISERR(tSC) Quit
							Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tStackS1(2))
							If $$$ISERR(tSC)

							// DP-421810 - Remove the "all" node for set1, which was set by the pNodeNo passed to %CopyNode
							Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1,"all",pNodeNo)
							
							Kill tStackS1
							Set tOrsetDepth = 0
							Set tStackS1($I(tOrsetDepth)) = pSet1
							Set tNextChild = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tOrsetDepth),"ch",""))
							While tNextChild {
								Set tStackS1($I(tOrsetDepth)) = tNextChild
								
								Set tNextChild = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tOrsetDepth),"ch",tNextChild))
							}
							Set tDepth=tOrsetDepth
							
							// Now perform the original copy operation to complete the crossjoin chain
							// DP-424589 - Insert a "tuple" node in this case which has depth one greater than the tuple added above to make everything after the "orset"
							// behave like a single term
							Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,tStackS1(tOrsetDepth),s2,tHideParent,"tuple",%SetOpDepth(pKey)+1)
							If $$$ISERR(tSC) Quit
						}
						Else {
							Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,tStackS1(tDepth),s2,tHideParent)
							If $$$ISERR(tSC) Quit
						}

						// JMD1045
						Set tNodeCount = tNodeCount + 1
						Set tChildrenAdded = tChildrenAdded + 1
					}
					Else {
						// JMD1045
						If ('$D(tMissingNodes)) {
							// make a copy of node 2
							Set tNode2Copy = tNode2
							//  convert S2 node to NO MEMBER
							Set $$$dsAxisNodeKey(tNode2) = "NO MEMBER"
							Set $$$dsAxisNodeValue(tNode2) = "NO MEMBER"
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s2) = tNode2
							Set tHideParent = +$G(%dsIsSlicer)
							Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,tStackS1(tDepth),s2,tHideParent)
							If $$$ISERR(tSC) Quit

							// restore node2
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s2) = tNode2Copy

							Set tMissingNodes(pNodeNo) = ""
							// mark as child added to avoid premature delete
							Set tChildrenAdded = tChildrenAdded + 1
						}
					}
					Set s2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet2,"ch",s2))
				}
				If $$$ISERR(tSC) Quit
				If (pOptimized) {
					Kill %memberContext

					// remove temp nodes
					If (tTempRoot '= "") {
						Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tTempRoot)
						If $$$ISERR(tSC) Quit
					}
				}
			} // skip

			// JMD1045: if no child added, remove s1 member
			If (pNonEmpty && (tChildrenAdded=0)) {
				If $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tDepth))) {
					Write:tDebug "DELETE S1 NODE ",tStackS1(tDepth)," ",$LG(tNode1,5),!
					Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tStackS1(tDepth))
					If $$$ISERR(tSC) Quit
				}
			}

			// get next node
			While (tDepth > 1) {
				Set tStackS1(tDepth) = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tDepth-1),"ch",tStackS1(tDepth)))
				If (tStackS1(tDepth)'="") {
					// find bottom of this node
					While ($D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tDepth),"ch"))) {
						Set tType = $LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tDepth)),1)
						Set tFunc = $LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tDepth)),6)
						If (tType="agg")&&(tFunc'="%MDX")&&(tFunc'="%KPI") {
							// DTB666 - Store the aggregate node number
							Set tAggregateNodes(tStackS1(tDepth)) = ""
						}
						
						Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tStackS1(tDepth),"ch",""))
						If (k '= "") {
							Do HideNode(k)
							Set tDepth = tDepth + 1
							Set tStackS1(tDepth) = k
						}
						Else {
							Quit
						}
					}
					Quit
				}
				Else {
					Set tDepth = tDepth - 1
				}
			}
		}
		If $$$ISERR(tSC) Quit

		// JMD1045: clean up output
		// make sure there is always at least one node and no extra empty nodes
		If (pNonEmpty) {
			If (tNodeCount=0) {
				Write:tDebug "ADD EMPTY NODE",!

				// replace s1 with empty node; remove children
				Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",""))
				While (k'="") {
					// mark as missing
					Set $$$dsAxisNodeLabel($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k)) = ""
					Set $$$dsAxisNodeKey($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k)) = "NO MEMBER"
					Set $$$dsAxisNodeValue($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k)) = "NO MEMBER"
					// remove children
					Set k2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k,"ch",""))
					While (k2'="") {
						Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,k2)
						If $$$ISERR(tSC) Quit
						Set k2 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k,"ch",k2))
					}
					// DTB072 - mark this node as the leaf node now that children are removed
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1,"all",k) = ""
					
					Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1,"ch",k))
				} 
			}
			ElseIf ((tNodeCount>0)&&$D(tMissingNodes)) {
				Write:tDebug "REMOVE MISSING NODES",!
				// remove missing nodes
				Set k = $O(tMissingNodes(""))
				While (k'="") {
					Set tNodeX = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k))
					Write:tDebug "DELETE ",k," ",$LG(tNodeX,5),!
					Set tNodeParent = $LG(tNodeX,4)
					Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,k)
					If $$$ISERR(tSC) Quit

					// if our parent is now empty, delete it too
					While (tNodeParent'="") {
						If '$D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeParent,"ch")) {
							Set tNodeX = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeParent))

							Write:tDebug "DELETE PARENT ",tNodeParent," ",$LG(tNodeX,5),!
							Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tNodeParent)
							If $$$ISERR(tSC) Quit

							Set tNodeParent = $LG(tNodeX,4)
						}
						Else {
							Set tNodeParent = ""
						}
					}

					// next missing
					Set k = $O(tMissingNodes(k))
				}
			}
		}

		// + WAL067 -- Clean up temp nodes used for ordering
		If ($G(tSecondChildIsOrderingFunction)) {
			// Swallow errors -- this is just cleanup to make the
			// axis more readable
			Do ..%DeleteNode(pCubeIndex,pKey,%axis,pSet2)
			Do ..%DeleteNode(pCubeIndex,pKey,%axis,tOriginalSet2)
		}
		// - WAL067

		// add to query stats
		If ($D(%query) && $D(%axisNo)) {
			Set %query.%Statistics("CrossJoin "_%axisNo) = $G(%query.%Statistics("CrossJoin "_%axisNo)) + ($ZH - tStart)
		}
		
		// +DTB666 - Run through the children of aggregate nodes and hide them
		If $D(tAggregateNodes) {
			Set tAggNode = $O(tAggregateNodes(""))
			
			While tAggNode {
				Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tAggNode,"ch",""))
				While (s1 '="") {
					
					Set tNode = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1)
					Set tNodeType = $$$dsAxisNodeType(tNode)
					If ((tNodeType'="exp")&&(tNodeType'="mbr")&&(tNodeType'="cmbr")&&(tNodeType'="orset")) {		// DTB462 - Add orset exemption
						Set $$$dsAxisNodeType(tNode) = "eq"
					}
					
					Set $$$dsAxisNodeVisible(tNode) = 1
					Set $$$dsAxisNodeCompute(tNode) = 1
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1) = tNode
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",s1) = ""

					// hide node and its children
					Set tSC = ..%HideNode(pCubeIndex,pKey,%axis,s1)
					If $$$ISERR(tSC) Quit

					Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tAggNode,"ch",s1))
				}
				
				Set tAggNode = $O(tAggregateNodes(tAggNode))
			}
		}
		// -DTB666

		Do $I(%SetOpDepth(pKey),-1)		// DP-424589
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC

HideNode(x)
	Set tNodeX = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",x))
	Set $$$dsAxisNodeVisible(tNodeX) = 0
	Set $$$dsAxisNodeCompute(tNodeX) = 0
	Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",x) = tNodeX
	If $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",x)) {
		Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",x)
		Set %leafCount = %leafCount - 1
	}
	Quit
}

Method DispatchOrderingFunction(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pFunction As %String, pContextNode As %Integer, pParent As %Integer, pSet As %Integer) As %Status [ Internal ]
{
	// Method added by WAL039
	Set tSC = $$$OK
	Try {
		// Crossjoin looks like CJ(A,B)
		// In this case, B is an "Ordering Function" (ORDER, TOPCOUNT, etc.)
		// The context node is the current member of set A for the crossjoin
		Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pContextNode))
		Do {
			Set tParent = $LG(tNode,4)
			Set tName = $LG(tNode,5)
			Set tDim = $LG(tNode,9)
			Set tHier = $LG(tNode,10)
			Set tLevel = $LG(tNode,11)
			Set tRelSpec = $LG(tNode,14)
			
			// Assemble filter for subquery from current A member context
			If (tRelSpec'="") {
				Set tRelFact = $LG(tNode,7)
				Set:tRelFact'="" tRelName = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"rel#",tRelFact)))
				Set tFilter = "[" _ tRelName _ "]." _ tRelSpec
			}
			Else {
				Set tSC = ##class(%DeepSee.Utils).%GetDimensionSpec(pCubeIndex,.tSpec,tDim,tHier,tLevel)
				Set tFilter = tSpec _ ".[" _ tName _ "]"
				If $$$ISERR(tSC) Quit
			}
			
			Set tFilterSpec = $G(tFilterSpec) _ " %FILTER " _ tFilter
			
			// Next parent node; use all available context
			Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParent))
		}
		While ($LG(tNode,1)="mbr")

		// Get the base subquery used by set B
		Set tChildSubqueryKey = ..children.GetAt(2).subqueryKey
		Set tSC = %query.%GetSubQuery(tChildSubqueryKey,.tRS)
		If $$$ISERR(tSC) Quit

		If (tRS.%GetQueryKey()="") {
			// should not happen!
			Set tSC = $$$ERROR($$$GeneralError,"Internal Error in DispatchOrderingFunction()")
			Quit
		}

		// Get base MDX from set B subquery
		Set tMDX = tRS.%GetQueryText()
		
		// Add filter to MDX for new subquery
		Set tMDX = tMDX _ tFilterSpec
		
		Set tHasWITH = ($P(tMDX,"SELECT") [ "WITH ")		// DTB740 - Check to see if the query already has a WITH clause
		
		// Make subquery available to ordering functions
		Set tSC = %query.%RegisterSubQuery(tMDX,.tKey,%axisObject,tHasWITH)
		If $$$ISERR(tSC) Quit
		
		Set ..subqueryKey = tKey

		Set tRS = %query.subqueries.GetAt(tKey)
		Set tSC = tRS.%ExecuteAsynch(.tQueryKey,.tParmValues,1)		// DTB704 - Always use %ExecuteAsynch
		If $$$ISERR(tSC) Quit
		
		Set tSecondChild = ..children.GetAt(2)
		Set tFunction = tSecondChild.function
		
		If ((tFunction = "ORDER")) {
			If $IsObject(tSecondChild.children.GetAt(3)) {
				Set tFlag = tSecondChild.children.GetAt(3).%GetValue()
			}
		}
		ElseIf ((tFunction = "TOPCOUNT")||(tFunction = "BOTTOMCOUNT")||
			(tFunction = "TOPPERCENT")||(tFunction = "BOTTOMPERCENT")||
			(tFunction = "TOPSUM")||(tFunction = "BOTTOMSUM")) {
			If $IsObject(tSecondChild.children.GetAt(2)) {
				Set tIndex = tSecondChild.children.GetAt(2).%GetValue()
			}
		}
		Set tSC = $Case($$$UPPER(tFunction),
					"ORDER":..Order(pCubeIndex,pCubeIndex,pKey,.pNodeNo,pParent,pSet,$G(tFlag)),
					/*
					"RANK":1,
					*/
					"TOPCOUNT":..TopFunction(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,$G(tIndex),$G(tFunction)),
					"BOTTOMCOUNT":..TopFunction(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,$G(tIndex),$G(tFunction)),
					"TOPPERCENT":..TopFunction(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,$G(tIndex),$G(tFunction)),
					"BOTTOMPERCENT":..TopFunction(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,$G(tIndex),$G(tFunction)),
					"TOPSUM":..TopFunction(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,$G(tIndex),$G(tFunction)),
					"BOTTOMSUM":..TopFunction(pCube,pCubeIndex,pKey,.pNodeNo,pParent,pSet,$G(tIndex),$G(tFunction)),
					:0)	
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given dependsOn index contains the combination of pKey1 and pKey2.
/// pRCube1 and pRCube2 are set if there are relationships.
Method %CheckDepends(pCubeIndex As %String, pDependIndex As %String, pKey1 As %String, pKey2 As %String, pRCube1 As %String, pRCube2 As %String = "") As %Boolean [ Internal ]
{
	$$$dsSetLogging		// DTB981
	
	// JMD1108 skip this optimization for OR lists
	If ((pKey1["|")||(pKey2["|")) {
		Quit 1
	}

	// JMD1231 skip this optimization for NOT
	If ((pKey1["!")||(pKey2["!")) {
		Quit 1
	}

	// JMD1069
	Kill tKey1, tKey2
	If (pRCube1'="") {
		// If this is an OR list, skip this optimization
		If (pKey1["|") {
			Quit 1
		}
		Set tRemoteCubeIndex = pRCube1

		// pull apart remote query key
		Set x2=$E(pKey1,2,*)
		Set tQueryKey = $P(x2,"-",1)
		Set tNodeNo = $P(x2,"-",2)
		Set tRFactNo = $P(x2,"-",3)

		Set tResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",""))
		While (tResultSlot '= "") {
			If ($G(tNodeNo) = "") {
				Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,""))
			}
			Else {
				Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tNodeNo,""))
			}

			// loop over remote chunks
			While (tChunk '= "") {
				Set tOffset = (tChunk-1)*64000

				If ($G(tNodeNo) = "") {
					Set tMask = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tChunk))
				}
				Else {
					Set tMask = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tNodeNo,tChunk))
				}

				// get remote ids from bitmap
				$$$dsBitFind(tMask,1,tBit)		// DTB981
				While (tBit > 0) {
					Set tRemoteId = tOffset + tBit - 1
					Set tKey1(tRemoteId) = ""
					$$$dsBitFindNext(tMask,1,tBit+1,tBit)		// DTB981
				}

				// next chunk
				If ($G(tNodeNo) = "") {
					Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tChunk))
				}
				Else {
					Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tNodeNo,tChunk))
				}
			}

			// next result slot
			Set tResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot))
		}
	}
	Else {
		Set tKey1(pKey1) = ""
	}

	If (pRCube2'="") {
		// If this is an OR list, skip this optimization
		If (pKey2["|") {
			Quit 1
		}
		Set tRemoteCubeIndex = pRCube2

		// pull apart remote query key
		Set x2=$E(pKey2,2,*)
		Set tQueryKey = $P(x2,"-",1)
		Set tNodeNo = $P(x2,"-",2)
		Set tRFactNo = $P(x2,"-",3)

		Set tResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",""))
		While (tResultSlot '= "") {
			If ($G(tNodeNo) = "") {
				Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,""))
			}
			Else {
				Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tNodeNo,""))
			}

			// loop over remote chunks
			While (tChunk '= "") {
				Set tOffset = (tChunk-1)*64000

				If ($G(tNodeNo) = "") {
					Set tMask = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tChunk))
				}
				Else {
					Set tMask = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tNodeNo,tChunk))
				}

				// get remote ids from bitmap
				$$$dsBitFind(tMask,1,tBit)		// DTB981
				While (tBit > 0) {
					Set tRemoteId = tOffset + tBit - 1
					Set tKey2(tRemoteId) = ""
					$$$dsBitFindNext(tMask,1,tBit+1,tBit)		// DTB981
				}

				// next chunk
				If ($G(tNodeNo) = "") {
					Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tChunk))
				}
				Else {
					Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot,tNodeNo,tChunk))
				}
			}

			// next result slot
			Set tResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tResultSlot))
		}
	}
	Else {
		Set tKey2(pKey2) = ""
	}

	// test each combination of keys
	Set tFound = 0
	Set k1 = $O(tKey1(""))
	While ('tFound&&(k1'="")) {
		Set k2 = $O(tKey2(""))
		While (k2'="") {
			If ($D($$$DeepSeeIndexGLVN(pCubeIndex,pDependIndex,k1,k2))) {
				Set tFound = 1
				Quit
			}
			Set k2 = $O(tKey2(k2))
		}
		Set k1 = $O(tKey1(k1))
	}
	Set tIntersect = tFound
	Quit tIntersect
}

/// Convert an axis node to a text representation.
/// This is used for duplicate elimination.
Method %NodeToText(pCubeIndex As %String, pKey As %String, pNodeNo As %Integer, Output pText As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pText = ""
		Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo))
		Set tType = $LG(tNode,1)
		Set tKey = $LG(tNode,6)
		Set tFact = $LG(tNode,7)
		Set pText = $Case(tType,
			"exp":tKey_";",
			"lit":tKey_";",
			"mbr":tFact_":"_tKey_";",
			"msr":tFact_";",
			:"")

		Set ch = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",""))
		While (ch '= "") {
			Set tSC = ..%NodeToText(pCubeIndex,pKey,ch,.tText)
			If $$$ISERR(tSC) Quit
			Set pText = pText _ tText
			Set ch = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",ch))
		}
		If $$$ISERR(tSC) Quit

		// JMD954: prevent long string values
		If ($L(pText)>200) {
			Set pText = $ZCRC(pText,7)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform VisualTotals on a set.<br/>
Method VisualTotals(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet As %Integer, pPattern As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pSet="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing set for VISUALTOTALS function")
			Quit
		}

		// make sure ** is handled correctly
		Set tPattern = $Replace(pPattern,"**",$C(1))

		// visit each member of the set in reverse order
		// for each, find out if the following members are descendants
		// if so, then replace the member with a SUM of its descendants
		Set tCurrDim = ""
		Set tCurrHier = ""

		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""),-1)
		While (k '="") {
			Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k))
			Set tName = $LG(tNode,5)
			Set tFact = $LG(tNode,7)
			Set tKey = $LG(tNode,6)
			Set tDimNo = $LG(tNode,9)
			Set tHierNo = $LG(tNode,10)
			Set tLevelNo = $LG(tNode,11)

			// make sure that all members are from the same dimension and hierarchy
			If (tCurrDim = "") {
				Set tCurrDim = tDimNo
				Set tCurrHier = tHierNo
			}
			ElseIf ((tCurrDim'=tDimNo)||((tDimNo'=0)&&(tCurrHier'=tHierNo))) {
				// note: dim=0 for measures
				If (tDimNo'="") {
					Set tSC = $$$ERROR($$$GeneralError,"All members passed to VISUALTOTALS must be from the same dimension.")
					Quit
				}
			}

			// now look at all nodes following this one
			// and see if we depend on them or not
			Set j = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",k))
			While (j '="") {
				Set tNode2 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",j))
				If $D(tCalculate(j)) {
					Set tName2 = $LG(tCalculate(j),1)
					Set tKey2 = $LG(tCalculate(j),2)
					Set tFact2 = $LG(tCalculate(j),3)
					Set tLevelNo2 = $LG(tCalculate(j),4)
				}
				Else {
					Set tName2 = $LG(tNode2,5)
					Set tKey2 = $LG(tNode2,6)
					Set tFact2 = $LG(tNode2,7)
					Set tLevelNo2 = $LG(tNode2,11)
				}
				If (tLevelNo<tLevelNo2) {
					// this is a child node, so node k may need to be computed from it
					// see if k is a parent of j

					Set tIsChild = 0
					While (tLevelNo<tLevelNo2) {
						Set tSC = ..%GetParentMember(pCube,tDimNo, tHierNo, tLevelNo2, pParent,.tSet,tKey2,tName2)
						If $$$ISERR(tSC) Quit

						Set tParentNode = $G(tSet(1))
						Set tParentName = $LG(tParentNode,5)
						Set tParentKey = $LG(tParentNode,6)
						Set tParentFact = $LG(tParentNode,7)
						Set tParentLevelNo = $LG(tParentNode,11)

						Set tLevelNo2 = tLevelNo2 - 1
						Set tName2 = tParentName
						Set tKey2 = tParentKey
						Set tFact2 = tParentFact
					}
					If $$$ISERR(tSC) Quit

					If ((tKey=tKey2)&&(tFact=tFact2)) {
						// this is a child, calculate: remember original details about this node
						Set tCalculate(k) = $LB(tName,tKey,tFact,tLevelNo)
						Set tDepends(k,j) = ""
					}
				}
				Else {
					// this node is above node k, stop processing node k
					Quit
				}
				Set j = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",j))
			}

			If ($D(tDepends(k))) {
				If (tPattern="") {
					Set tLabel = tName
				}
				Else { // apply pattern
					Set tLabel = $Replace(tPattern,"*",tName)
					Set tLabel = $Replace(tLabel,$C(1),"*")
				}

				// turn this node into a SUM
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k) = $LB("agg",1,1,$LG(tNode,4),tLabel,"SUM")

				// add dependencies to SUM
				Set j = $O(tDepends(k,""))
				While (j'="") {
					If ('$D(tCalculate(j))) {
						Set tNode2 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",j))
						Set $List(tNode2,2) = 0
						Set $List(tNode2,4) = k
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode2
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k,"ch",pNodeNo) = ""
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
					}
					Set j = $O(tDepends(k,j))
				}
			}

			// next node
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",k),-1)
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a %AddParents on a set: add the (distinct) parent member of each member to the set.<br/>
/// If called on a set with multiple dimensions, add parents at each level and add parent
/// nodes without children.
Method AddParents(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pSet="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing argument for %ADDPARENTS function")
			Quit
		}

		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
		While (k '="") {
			Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k))

			Set tSC = ..%NodeToText(pCubeIndex,pKey,k,.tText)
			If $$$ISERR(tSC) Quit

			If ((tText'="")&&('$D(tDistinct(tText)))) {
				Set tDistinct(tText) = ""
				// get spec for this member
				Set tType = $LG(tNode,1)
				Set tName = $LG(tNode,5)
				Set tKey = $LG(tNode,6)
				Set tDimNo = $LG(tNode,9)
				Set tHierNo = $LG(tNode,10)
				Set tLevelNo = $LG(tNode,11)
				
				If (tDimNo > 0) {

					// get parent member
					Kill tSet
					Set tSC = ..%GetParentMember(pCube,tDimNo, tHierNo, tLevelNo, pParent,.tSet,tKey,tName)
					If $$$ISERR(tSC) Quit
				
					Set tNewNode = $G(tSet(1))
					Set tNewType = $LG(tNewNode,1)
					Set tNewKey = $LG(tNewNode,6)
				
					If ((tNewType="mbr")&&(tNewKey'="")) { // do not include ALL
						Set $List(tNewNode,4) = pParent
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tNewNode
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""

						Set tSC = ..%NodeToText(pCubeIndex,pKey,pNodeNo,.tText2)
						If $$$ISERR(tSC) Quit

						If ('$D(tDistinct(tText2))) {
							Set tDistinct(tText2) = ""
						}
						Else {
							Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pNodeNo)
							If $$$ISERR(tSC) Quit
						}
					}

					// process our child nodes, if any
					If $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",k,"ch")) {
						// inject this node without children
						If ((tType="mbr")&&(tKey'="")) {
							Set tCopyNode = tNode
							Set $List(tCopyNode,2) = 1
							Set $List(tCopyNode,3) = 1
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tCopyNode
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""

							Set tSC = ..%NodeToText(pCubeIndex,pKey,pNodeNo,.tText3)
							If $$$ISERR(tSC) Quit

							If ('$D(tDistinct(tText3))) {
								Set tDistinct(tText3) = ""
							}
							Else {
								Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pNodeNo)
								If $$$ISERR(tSC) Quit
							}
						}

						// recurse
						Set tSC = ..AddParents(pCube,pCubeIndex,pKey,.pNodeNo,k,k)
						If $$$ISERR(tSC) Quit
					}
				}
			}

			// next child
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",k))
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Find the parent member for given member.<br/>
/// This is a helper function used by some of the set functions.
Method %GetParentMember(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pParent As %Integer, Output pSet As %List, pKey As %String, pName As %String) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..%ConstructMemberProvider(pCube,pDimNo,pHierNo,pLevelNo,.tMember,pKey,pName)
		If $$$ISERR(tSC) Quit

		// get parent member, put it into pSet
		Kill pSet
		Set tSC = tMember.%GetParentMember(pCube,pDimNo, pHierNo, pLevelNo, pParent,.pSet,pKey)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Construct a member provider for given member.<br/>
/// This is a helper function used by some of the set functions.
Method %ConstructMemberProvider(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, Output pMember As %DeepSee.Query.member, pKey As %String, pName As %String = "") As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Try {
		Set pMember = ""
		Set tInfo = $$$DeepSeeMetaGLVN("cubes",pCube,"mbr#",pDimNo,pHierNo,pLevelNo)
		Set tSpec = "["_$LG(tInfo,2)_"].["_$LG(tInfo,3)_"].["_$LG(tInfo,4)_"]"
		If (pName '= "") {
			Set tSpec = tSpec _ ".["_pName_"]"
		}
		ElseIf (pKey '= "") {
			// use key
			Set tSpec = tSpec _ ".&["_pKey_"]"
		}
		Set tSC = ##class(%DeepSee.Query.memberSpec).%ConstructMemberSpec(tSpec,.tMemberSpec)
		If $$$ISERR(tSC) Quit

		Set pMember = tMemberSpec.%GetMemberProvider()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Apply the %LABEL function to the given expression.
Method Label(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pSet As %Integer, pLabel As %String, pFormat As %String, pSolveOrder As %Integer = 0, pStyle As %String = "", pHeaderStyle As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// make sure ** is handled correctly
		Set tPattern = $Replace(pLabel,"**",$C(1))

		// visit top nodes within set
		// apply label and format
		Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
		While (k '="") {
			Set tNodeNo = k
			Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo))
			Set tType = $LG(tNode,1)
			If (tType="tuple") {
				// find bottom of tuple
				Set tChild = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo,"ch",""))
				While (tChild'="") {
					Set tNodeNo = tChild
					Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo))
					Set tChild = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChild,"ch",""))
					// JMD1097 remove non-bottom name from label
					If (tChild'="") {
						Set $List($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo),5) = ""
					}
				}
			}

			Set tName = $LG(tNode,5)
			If (tPattern="") {
				Set tLabel = tName
			}
			Else { // apply pattern
				Set tLabel = $Replace(tPattern,"*",tName)
				Set tLabel = $Replace(tLabel,$C(1),"*")
			}
			Set $List(tNode,5) = tLabel
			If (pFormat'="") {
				Set $List(tNode,12) = pFormat
			}
			If (+pSolveOrder>0) {
				Set $List(tNode,15) = pSolveOrder
			}
			If (pStyle'="") {
				Set $List(tNode,18) = pStyle
			}
			If (pHeaderStyle'="") {
				Set $List(tNode,19) = pHeaderStyle
			}

			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tNodeNo) = tNode
			Set k = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Apply the %SPACE function to the current axis (adds an empty " " to it).
Method Space(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("lit",1,1,pParent,""," ")
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
		Set leaf = $I(%leafCount)
		Set pNewNodeNo = pNodeNo
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a PeriodsToDate function.<br/>
Method PeriodsToDate(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pLevel1 As %DeepSee.Query.node, pSet2 As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (('$IsObject(pLevel1))||(pSet2="")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for PERIODSTODATE function")
			Quit
		}

		Set tMember = pLevel1.%member
		If ('$IsObject(tMember)||('tMember.%IsA("%DeepSee.Query.memberTime"))) {
			Set tSC = $$$ERROR($$$GeneralError,"PERIODSTODATE function can only be used on TIME dimensions")
			Quit
		}
		
		// look at member argument
		Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet2))
		If (($LG(tNode,9)'=tMember.%dimNumber)||($LG(tNode,10)'=tMember.%hierNumber)) {
			Set tSC = $$$ERROR($$$GeneralError,"Arguments for PERIODSTODATE function must come from same hierarchy")
			Quit
		}

		// find level number for pLevel
		Set tLevelNo = tMember.%levelNumber

		Set tArgType = $LG(tNode,1)
		Set tArgLevel = $LG(tNode,11)
		Set tArgVal = $LG(tNode,5)
		Set tArgKey = $LG(tNode,6)

		If (tArgLevel <= tLevelNo) {
			// just return member
			Set tStartKey = tArgKey
		}
		Else {
			// go up to ancestor of member within pLevel
			Set tParentKey = ""
			Set tKey = tArgKey
			Set tLvl = tArgLevel
			While (tLvl>tLevelNo) {
				Set tSC = tMember.%GetParentMember(pCube,tMember.%dimNumber, tMember.%hierNumber, tLvl, pParent,.tSet,tKey)
				If $$$ISERR(tSC) Quit
				Set tParentKey = $LG($G(tSet(1)),13)
				Set tKey = tParentKey
				Set tLvl = tLvl - 1
				Kill tSet
			}

			// go down to first member at bottom level
			Set tStartKey = ""
			Set tKey = tParentKey
			Set tLvl = tLevelNo
			While (tLvl < tArgLevel) {
				Set tSC = tMember.%GetNthChild(pCube,tMember.%dimNumber, tMember.%hierNumber, tLvl, pParent,.tSet,tKey,1)
				If $$$ISERR(tSC) Quit

				Set tLvl = tLvl + 1
				Set tStartKey = $LG($G(tSet(1)),13)
				Set tKey = tStartKey
				Kill tSet
			}
		}

		// construct set of members from start to end
		Set tSC = tMember.%GetLevelClass(pCube,tMember.%dimNumber,tMember.%hierNumber,tArgLevel,.tArgLevelClass)
		If $$$ISERR(tSC) Quit

		// convert to level values
		// JMD1301: use keys
		//Set tRange(1) = $zobjclassmethod(tArgLevelClass,"%KeyToValue",tStartKey)
		//Set tRange(2) = $zobjclassmethod(tArgLevelClass,"%KeyToValue",tArgKey)
		Set tRange(1) = tStartKey
		Set tRange(2) = tArgKey
		
		// create set to hold results
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("set",0,0,pParent)
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set tParent = pNodeNo
		Set pNewNodeNo = pNodeNo

		Set tSetNodeNo = pNodeNo		// DTB832 - Remember the starting point before adding members
		Set tSC = tMember.%GetMembers(pCube,tMember.%dimNumber,tMember.%hierNumber,tArgLevel,"",tParent,pKey,.pNodeNo,0,.tRange)
		If $$$ISERR(tSC) Quit
		
		If (pNodeNo=tSetNodeNo) {
			// DTB832 - %GetMembers has not added any members. Doube-check the set for children. If
			// none are found, assign a literal null to this node.
			Set tChildExists = +$O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tSetNodeNo))
			If 'tChildExists {
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tSetNodeNo) = $$$DeepSeeNullAxisNode(pParent)
			}
		}

		// Delete original Set2
		Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pSet2)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a ParallelPeriod function.<br/>
Method ParallelPeriod(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pLevel As %DeepSee.Query.node, pIndex As %Integer, pSet1 As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// This is equivalent to:
		// Cousin(member, Ancestor(member, level).Lag(index))

		If (('$IsObject(pLevel))||(pIndex="")||(pSet1="")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for PARALLELPERIOD(level,index,member) function")
			Quit
		}

		Set tMember = pLevel.%member
		If ('$IsObject(tMember)||('tMember.%IsA("%DeepSee.Query.memberTime"))) {
			Set tSC = $$$ERROR($$$GeneralError,"PARALLELPERIOD function can only be used on TIME dimensions")
			Quit
		}
		
		// look at member argument
		Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet1))
		If (($LG(tNode,9)'=tMember.%dimNumber)||($LG(tNode,10)'=tMember.%hierNumber)) {
			Set tSC = $$$ERROR($$$GeneralError,"Arguments for PARALLELPERIOD function must come from same hierarchy")
			Quit
		}
		
		// + WAL046
		If ($IsObject($G(%axisObject))) {
			Set tNonEmpty = %axisObject.nonEmpty
			Set %axisObject.nonEmpty = 0	
		}
		// - WAL046

		Set tArgType = $LG(tNode,1)
		Set tArgLevel = $LG(tNode,11)
		Set tArgVal = $LG(tNode,5)
		Set tArgKey = $LG(tNode,6)

		// compute Ancestor(member, level)
		Set tParent = pParent
		Set tSC = ..Ancestor(pCube, pCubeIndex, pKey, .pNodeNo, .tNewNodeNo, tParent, pSet1, pLevel)
		If $$$ISERR(tSC) Quit
		Set tTempSet = tNewNodeNo

		// compute Lag(index) from ancestor
		If (pIndex'=0) {
			// find provider for the ancestor member
			Set tAncestorNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tTempSet))

			Set tAncKey = $LG(tAncestorNode,6)
			Set tAncDim = $LG(tAncestorNode,9)
			Set tAncHier = $LG(tAncestorNode,10)
			Set tAncLvl = $LG(tAncestorNode,11)

			Set tSC = ..%ConstructMemberProvider(pCube,tAncDim,tAncHier,tAncLvl,.tMember,tAncKey)
			If $$$ISERR(tSC) Quit

			Set tKey = $LG($G(tMember.%memberSpec(tMember.%levelNumber)),2)

			// find our rollup key, if any, so we can restrict by it
			Set tSC = tMember.%GetRollupKey(tMember.%levelNumber,tKey,.tRollupKey)
			If $$$ISERR(tSC) Quit

			Set tSC = tMember.%GetRelatedMember(pCube,tMember.%dimNumber, tMember.%hierNumber, tMember.%levelNumber,tRollupKey, pParent,.tLagSet,tKey,"lag",pIndex)
			If $$$ISERR(tSC) Quit

			// replace ancestor with lag node
			Set x = $O(tLagSet(""))
			If (x'="") {
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tTempSet) = tLagSet(x)
			}
		}

		// compute Cousin(member,lag)
		Set tSC = ..Cousin(pCube,pCubeIndex,pKey,.pNodeNo,.tNewNodeNo, tParent,pSet1,tTempSet)
		If $$$ISERR(tSC) Quit
		Set pNewNodeNo = tNewNodeNo

		// Delete tempnode for ancestor
		Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tTempSet)
		If $$$ISERR(tSC) Quit
		
		// + WAL046
		If ($G(tNonEmpty)'="") {
			Set %axisObject.nonEmpty = tNonEmpty
		}
		// - WAL046
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform an Ancestor function.<br/>
/// ANCESTOR(member,level) returns the ancestor of *member* at the same level as *level*.<br/>
/// *level* can also be a number specifying distance from *member*.
Method Ancestor(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pMemberNo As %Integer, pLevelArg As %DeepSee.Query.node) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {

		Set pNewNodeNo = ""
		If ((pMemberNo="")||(pLevelArg="")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for ANCESTOR(member,level) function")
			Quit
		}

		Set tMemberNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pMemberNo))

		Set tMbrType = $LG(tMemberNode,1)
		Set tMbrKey = $LG(tMemberNode,6)
		Set tMbrName = $LG(tMemberNode,5)
		Set tMbrDim = $LG(tMemberNode,9)
		Set tMbrHier = $LG(tMemberNode,10)
		Set tMbrLvl = $LG(tMemberNode,11)

		If ($IsObject(pLevelArg)) {
			Set tLevelMember = pLevelArg.%member
			Set tLevelDim = tLevelMember.%dimNumber
			Set tLevelHier = tLevelMember.%hierNumber
			Set tLevelLvl = tLevelMember.%levelNumber
		}
		Else {
			// pLevelArg is distance
			Set tLevelDim = tMbrDim
			Set tLevelHier = tMbrHier
			Set tLevelLvl = tMbrLvl-pLevelArg
			Set:tLevelLvl<1 tLevelLvl = 1
		}

		If ((tMbrDim '= tLevelDim)||(tMbrHier '= tLevelHier)) {
			Set tSC = $$$ERROR($$$GeneralError,"Both arguments for ANCESTOR function must be members of the same hierarchy")
			Quit
		}

		If ($IsObject(pLevelArg)) {
			If (tMbrLvl <= tLevelLvl) {
				Set tSC = $$$ERROR($$$GeneralError,"Second argument for ANCESTOR function must be an ancestor of the first")
				Quit
			}
		}

		// find provider for the member
		Set tSC = ..%ConstructMemberProvider(pCube,tMbrDim,tMbrHier,tMbrLvl,.tMember,tMbrKey)
		If $$$ISERR(tSC) Quit

		// work up levels to find ancestor
		Set tKey = tMbrKey
		Set tNodeNo = ""
		For tLevel = tMbrLvl:-1:tLevelLvl+1 {
			Set tMember.%levelNumber = tLevel
			Kill tSet
			Set tSC = ..%GetParentMember(pCube,tMbrDim, tMbrHier, tLevel, pParent,.tSet,tKey,"")
			If $$$ISERR(tSC) Quit
	
			Set tNodeNo = $O(tSet(""))
			If (tNodeNo'="") {
				Set tKey = $LG(tSet(tNodeNo),6)
			}
		}
		If $$$ISERR(tSC) Quit

		Set pNewNodeNo = pNodeNo
		If (tNodeNo'="") {
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tSet(tNodeNo)
		}
		Else {
			// use original
			Set $List(tMemberNode,4) = pParent
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tMemberNode
		}
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
		Set pNewNodeNo = pNodeNo
		Set leaf = $I(%leafCount)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a Descendants function.<br/>
/// DESCENDANTS(member,level) returns the descendants of *member* at the same level as *level*.<br/>
/// *level* can also be a number specifying distance from *member*.
Method Descendants(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pMemberNo As %Integer, pMemberArg As %DeepSee.Query.node, pLevelArg As %DeepSee.Query.node, pFlag = "") [ Internal ]
{
	// Method added by DTB162
	Set pFlag = $$$UPPER(pFlag)
	If pFlag="" Set pFlag="SELF"
	Set tSC = $$$OK
	Try {
		Set pNewNodeNo = ""
		If ((pMemberArg="")||(pLevelArg="")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for DESCENDANTS(member,level) function")
			Quit
		}

		Set tMemberNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pMemberNo))

		Set tMbrType = $LG(tMemberNode,1)
		Set tMbrKey = $LG(tMemberNode,6)
		Set tMbrName = $LG(tMemberNode,5)
		Set tMbrDim = $LG(tMemberNode,9)
		Set tMbrHier = $LG(tMemberNode,10)
		Set tMbrLvl = $LG(tMemberNode,11)
		
		// Set the numbers for the reference level based on the second argument
		If ($IsObject(pLevelArg)) {
			Set tLevelMember = pLevelArg.%member
			Set tLevelDim = tLevelMember.%dimNumber
			Set tLevelHier = tLevelMember.%hierNumber
			Set tLevelLvl = tLevelMember.%levelNumber
		}
		Else {
			// pLevelArg is distance
			If (pLevelArg<1) {
				Set tSC = $$$ERROR($$$GeneralError,"Second argument for DESCENDANTS function must resolve to a descendant of the first")
				Quit
			}
			
			Set tLevelDim = tMbrDim
			Set tLevelHier = tMbrHier
			Set tLevelLvl = tMbrLvl+pLevelArg
			Set:tLevelLvl<1 tLevelLvl = 1
		}
		
		Set tFinalLvl = $O($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"mbr#",tLevelDim,tLevelHier,""),-1)
		Set:(tLevelLvl>tFinalLvl) tLevelLvl=tFinalLvl
		
		If ((tMbrDim '= tLevelDim)||(tMbrHier '= tLevelHier)) {
			Set tSC = $$$ERROR($$$GeneralError,"Both arguments for DESCENDANTS function must be members of the same hierarchy")
			Quit
		}
		If ($IsObject(pLevelArg)) {
			If (tMbrLvl >= tLevelLvl) {
				Set tSC = $$$ERROR($$$GeneralError,"Second argument for DESCENDANTS function must be a descendant of the first")
				Quit
			}
		}
		
		// create set to hold results
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("set",0,0,pParent)
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set tParent = pNodeNo
		Set pNewNodeNo = pNodeNo
		
		// Reset the parent of the original member to be the new set in case it ends up
		// as one of its members!
		Set $LI(tMemberNode,4) = tParent
		
		// find provider for the level
		Set tSC = ..%ConstructMemberProvider(pCube,tMbrDim,tMbrHier,tMbrLvl,.tMember,,tMbrName)
		If $$$ISERR(tSC) Quit
		
		// Time and data dimensions are handled differently
		Set tIsTime = (tMember.%ClassName(1)["%DeepSee.Query.memberTime")
		Set tIsData = (tMember.%ClassName(1)["%DeepSee.Query.memberData")
		
		If tIsTime&&(pFlag="SELF") {
			// For time levels using only the SELF flag, it is enough to find the first and last descendant of the 
			// reference member within the target level. Take advantage of this as an optimization.
			Set tFirstKey = $LG(tMember.%memberSpec(tMbrLvl),2)
			Set tLastKey = $LG(tMember.%memberSpec(tMbrLvl),2)
			
			// Walk down the levels to find the first and last descendants
			For tRefLevel=tMbrLvl:1:(tLevelLvl-1) {
				Set tSC = tMember.%GetNthChild(pCube,tLevelDim,tLevelHier,tRefLevel,tParent,.tFirstMemberSet,tFirstKey,1)
				Set tSC = tMember.%GetNthChild(pCube,tLevelDim,tLevelHier,tRefLevel,tParent,.tLastMemberSet,tLastKey,-1)
				
				Set x = $O(tFirstMemberSet(""),-1,tFirstNode)
				Set x = $O(tLastMemberSet(""),-1,tLastNode)
				
				Set tFirstKey = $LG(tFirstNode,13)
				Set tLastKey = $LG(tLastNode,13)
			}
			
			Set tRange(1) = tFirstKey
			Set tRange(2) = tLastKey	
			Set tSC = tMember.%GetMembers(pCube,tLevelDim,tLevelHier,tLevelLvl,"",tParent,pKey,.pNodeNo,0,.tRange,.tMembers)
			If $$$ISERR(tSC) Quit
		}
		ElseIf tIsData&&(pFlag="SELF") {
			// Store the top node of the decendants graph
			Set tMemberSet(tMbrLvl,1) = tMemberNode
			
			// Walk down the levels to find descendents
			For tRefLevel=tMbrLvl:1:(tLevelLvl-1) {				
				// Data levels need to keep track of all children at each level to arrive at the proper descendents
				Set tMemberIdx = $O(tMemberSet(tRefLevel,""))
				Kill tChildSet
				Set tChildSet=0
				While tMemberIdx'="" {
					Set n = 0
					Do {
						Set n=n+1
						set c=tChildSet
						Set tSC = tMember.%GetNthChild(pCube,tLevelDim,tLevelHier,tRefLevel,tParent,.tChildSet,$LG(tMemberSet(tRefLevel,tMemberIdx),6),n)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
						
						// Keep an index for sorting purposes
						Set tChildSort(tRefLevel+1,$LG(tChildSet(tChildSet),5)) = tChildSet
					} While (tChildSet>c)
				
					Set tMemberIdx = $O(tMemberSet(tRefLevel,tMemberIdx))	
				}
				
				// Remember these children for the next pass
				Merge tMemberSet(tRefLevel+1) = tChildSet		
			}
			
			// Write the descendants directly into the axis
			Set tDescendantName = $O(tChildSort(tLevelLvl,""),1,tDescendantIdx)
			Set tSortGrandChildren = 0
			While tDescendantName'="" {
				Set $$$DeepSeeAxisGLVN(pCube,pKey,"axes",$I(pNodeNo)) = tMemberSet(tLevelLvl,tDescendantIdx)
				Set $$$DeepSeeAxisGLVN(pCube,pKey,"axes",tParent,"ch",pNodeNo) = ""
				Set $$$DeepSeeAxisGLVN(pCube,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)
				
				Set tDescendantName = $O(tChildSort(tLevelLvl,tDescendantName),1,tDescendantIdx)
			}
		}
		Else {
			// Build a graph out of all levels of the hierarchy
			Set tGraphIdx = 1
			Set tGraph=1
			Set tGraph(tGraphIdx) = tMemberNode
			
			// Walk down the levels to find descendents, only building the necessary levels of the graph
			Set tLastLevel = $S(pFlag["AFTER":tFinalLvl-1,pFlag["SELF":tLevelLvl-1,1:tLevelLvl-2)
			For tRefLevel=tMbrLvl:1:(tLastLevel) {	
				While tGraphIdx'="" {
					Set n=0
					If tIsTime {
						// Some time functions are not very good at finding the last child using iteration
						// Record the endpoint for reference
						Kill tTimeLastChild
						Set tSC = tMember.%GetNthChild(pCube,tLevelDim,tLevelHier,$LG(tGraph(tGraphIdx),11),tParent,.tTimeLastChild,$LG(tGraph(tGraphIdx),6),-1)
					}
					
					Set tMoreChildren = 1	
					While tMoreChildren {
						Kill tNthChild		// Only let this array be of size 0 (no child found at position n) or 1
						Set tSC = tMember.%GetNthChild(pCube,tLevelDim,tLevelHier,$LG(tGraph(tGraphIdx),11),tParent,.tNthChild,$LG(tGraph(tGraphIdx),6),$I(n))

						If $D(tNthChild) {
							// Add the child to the graph
							Set tGraph($I(tGraph)) = tNthChild(1)
							Set tGraph(tGraphIdx,"ch",tGraph) = ""
							If tIsTime&&($LG(tNthChild(1),6)=$LG(tTimeLastChild(1),6)) {
								// Escape the loop for time dimensions since the NthChild 
								// return may be outside the parent level
								Set tMoreChildren = 0
							}
						}
						Else {
							//Done with the children of this member
							Set tMoreChildren = 0
						}
					}

					Set tGraphIdx = $O(tGraph(tGraphIdx))
				}
			}
			
			// Interpret the graph and place it in the axis cache.
			Set tGraphNodeNo = $O(tGraph(""))
			While +tGraphNodeNo {
				Do ..%ProcessDescendantsGraphNode(.tGraph,tGraphNodeNo,pCube,pKey,.pNodeNo,tParent,pFlag,tLevelLvl)
				Set tGraphNodeNo = $O(tGraph(""))		// Intentionally $O from "" each time
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Recursively process a member graph for the DESCENDANTS function. This places all members of
/// the provided pGraph into the axis cache under a single parent. Each branch of the tree is 
/// completely written before moving to the next branch.
Method %ProcessDescendantsGraphNode(ByRef pGraph, pGraphNodeNo, pCube, pKey, ByRef pNodeNo, pParent, pFlag, pSelfLevelNo) [ Internal, Private ]
{
	// Method added by DTB162
	Set tNode = pGraph(pGraphNodeNo)
	Set tNodeLvl = $LG(tNode,11)
	If ((pFlag["BEFORE")&&(tNodeLvl<pSelfLevelNo)) ||
			((pFlag["SELF")&&(tNodeLvl=pSelfLevelNo)) ||
			((pFlag["AFTER")&&(tNodeLvl>pSelfLevelNo)) {
		Set $$$DeepSeeAxisGLVN(pCube,pKey,"axes",$I(pNodeNo)) = tNode
		Set $$$DeepSeeAxisGLVN(pCube,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set $$$DeepSeeAxisGLVN(pCube,pKey,"axes",%axis,"all",pNodeNo) = ""
		Set leaf = $I(%leafCount)
	}
	
	// Remove the recorded node from the graph and look for children
	ZKill pGraph(pGraphNodeNo)
	If $D(pGraph(pGraphNodeNo,"ch")) {
		Set tGraphNodeNo = $O(pGraph(pGraphNodeNo,"ch",""))
		While +tGraphNodeNo {
			ZKill pGraph(pGraphNodeNo,"ch",tGraphNodeNo)
			Do ..%ProcessDescendantsGraphNode(.pGraph,tGraphNodeNo,pCube,pKey,.pNodeNo,pParent,pFlag,pSelfLevelNo)
			Set tGraphNodeNo = $O(pGraph(pGraphNodeNo,"ch",""))		// Intentionally $O from "" each time
		}
	}
}

/// Perform a Opening/ClosingPeriod function (determined by <var>pClosing</var>).<br/>
Method OpenClosePeriod(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pLevel1 As %DeepSee.Query.node, pSet2 As %Integer, pClosing As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (('$IsObject(pLevel1))||(pSet2="")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for function: " _ ..function)
			Quit
		}

		Set tMember = pLevel1.%member

		// look at member argument
		Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet2))
		If (($LG(tNode,9)'=tMember.%dimNumber)||($LG(tNode,10)'=tMember.%hierNumber)) {
			Set tSC = $$$ERROR($$$GeneralError,"Arguments for function must come from same hierarchy: " _ ..function)
			Quit
		}

		// find level number for pLevel
		Set tLevelNo = tMember.%levelNumber

		Set tArgType = $LG(tNode,1)
		Set tArgLevel = $LG(tNode,11)
		Set tArgVal = $LG(tNode,5)
		Set tArgKey = $LG(tNode,6)

		If (tArgLevel <= tLevelNo) {
			// just return member
			Set tStartKey = tArgKey
		}
		Else {
			// go up to ancestor of member within pLevel
			Set tParentKey = ""
			Set tKey = tArgKey
			Set tLvl = tArgLevel
			While (tLvl>tLevelNo) {
				Set tSC = tMember.%GetParentMember(pCube,tMember.%dimNumber, tMember.%hierNumber, tLvl, pParent,.tSet,tKey)
				If $$$ISERR(tSC) Quit
				Set tParentKey = $LG($G(tSet(1)),13)
				Set tKey = tParentKey
				Set tLvl = tLvl - 1
				Kill tSet
			}

			// go down to first/last member at bottom level
			Set tStartKey = ""
			Set tKey = tParentKey
			Set tLvl = tLevelNo
			While (tLvl < tArgLevel) {
				Kill tSet
				Set tSC = tMember.%GetNthChild(pCube,tMember.%dimNumber, tMember.%hierNumber, tLvl, pParent,.tSet,tKey,$S(pClosing:-1,1:1))
				If $$$ISERR(tSC) Quit

				Set tLvl = tLvl + 1
				Set tStartKey = $LG($G(tSet(1)),13)
				Set tKey = tStartKey
				Set tNodeNo = $O(tSet(""))
			}
		}

		// emit member
		If ($G(tNodeNo)'="") {
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tSet(tNodeNo)
		}
		Else {
			// use original
			Set $List(tNode,4) = pParent
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
		}

		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
		Set pNewNodeNo = pNodeNo
		Set leaf = $I(%leafCount)

		// Delete original Set2
		Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pSet2)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Pre-MDX: preprocessing for MDX() function.
Method PreMDX(pIsSlicer As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// this query must always be recomputed as subquery may yield different values
		If $IsObject($G(%query)) {
			Set %query.%mustCompute = 1
		}

		// If there are non-literal parameters for the statement, then we defer to the consolidation phase
		// JMD900: or if there are any %CONTEXT directives
		If (..children.Count()>1) {
			Set tHasNonLiteral = 0
			For n=2:1:..children.Count() {
				Set tChild = ..children.GetAt(n)
				If ('(tChild.%IsA("%DeepSee.Query.constant"))) {
					Set tHasNonLiteral = 1
				}
				Else {
					// test parm names only
					If ((n#2)=0) {
						Set tValue = tChild.%GetValue()
						If ((tValue="%CONTEXT")) {
							Set tHasNonLiteral = 1
						}
					}
				}
			}
			If (tHasNonLiteral) {
				Quit
			}
		}

		// otherwise, run the statement now and substitute its value in the query
		Set tChild = ..children.GetAt(1)
		If $IsObject(tChild) {
			If (tChild.finalValue) {
				// query has already been run
				Quit
			}

			// get parm values
			Set tParmName = ""
			For n=2:1:..children.Count() {
				If ((n#2)=0) {
					Set tParmName = ..children.GetAt(n).%GetValue()
				}
				ElseIf (tParmName'="") {
					Set tParmValue = ..children.GetAt(n).%GetValue()
					Set:tParmValue'="" tParms(tParmName) = tParmValue
					Set tParmName = ""
				}
			}

			Set tResult = ""

			// execute query
			// note: we currently do not support pivot variables within the 
			// %MDX function; these are replaced by the container query!
			Set tMDX = tChild.value
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareMDX(tMDX)
			If $$$ISERR(tSC) {
				// return error as value of cell
				Set tChild.origValue = tChild.value
				Set tChild.value = $System.Status.GetErrorText(tSC)
				Set tChild.finalValue = 1
				Set tSC = $$$OK
				Quit
			}
			
			// DTB348 - This will always be a subquery, log the parentQueryKey to prevent reservation contention on the
			// axes.
			Set tRS.%Query.parentQueryKey = $S(%query.parentQueryKey'="":%query.parentQueryKey,1:%query.%QueryKey)

			Set tSC = tRS.%Execute(.tParms)
			If $$$ISERR(tSC) {
				// return error as value of cell
				Set tSC = $$$OK
				Set tChild.origValue = tChild.value
				Set tChild.value = $System.Status.GetErrorText(tSC)
				Set tChild.finalValue = 1
				Quit
			}

			// +DTB458 - Log the subquery keys in the results global if a related cube is involved
			Set tSubqueryCube = tRS.%CubeKey
			Set tSubqueryKey = tRS.%GetQueryKey()
			If ($G(%cubeIndex)'="") && (tSubqueryCube'=$$$UPPER(%cubeIndex)) && (%query.%QueryKey'="") && (tSubqueryCube'="") && (tSubqueryKey'="") {
				Set $$$DeepSeeResultsGLVN($$$UPPER(%cubeIndex),%query.%QueryKey,"subquery",tSubqueryCube,tSubqueryKey) = "(8)"
			}
			// -DTB458

			// get value of top,left cell
			Set tAxisCount = tRS.%GetAxisCount()
			Set tResult = $Case(tAxisCount,
				1:tRS.%GetOrdinalValue(1),
				:tRS.%GetOrdinalValue(1,1))

			// place result value
			Set tChild.origValue = tChild.value
			Set tChild.value = tResult
			Set tChild.finalValue = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a %MDX (subquery) operation.
Method MDX(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, ByRef pNewNodeNo As %Integer, pParent As %Integer, ByRef pArgValue As %String, ByRef pSets As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFirstChild = ..children.GetAt(1)
		If ($IsObject(tFirstChild)&&tFirstChild.%IsA("%DeepSee.Query.constant")&&tFirstChild.finalValue) {
			// answer has already been computed
			// insert value into axis as literal
			Set tLabel = "Results"
			Set tNode = $LB("lit",1,1,pParent,tLabel,$G(pArgValue(1)))

			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
			Set pNewNodeNo = pNodeNo
			Set leaf = $I(%leafCount)
			Quit
		}
		
		// pArgValue holds the literal values passed to the function (query and parm names)
		// pSets holds the subnodes providing the parameter values for the query (which could be in pArgValues if literal!)

		// insert query into axis as aggregate, with query as "flag"
		Set tLabel = "Results"
		Set tNode = $LB("agg",1,1,pParent,tLabel,"%MDX","query",$G(pArgValue(1)))

		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
		Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo),24) = pNodeNo		// DTB400 - Stamp this its own reference
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		
		Set pNewNodeNo = pNodeNo
		Set leaf = $I(%leafCount)
		Set tArgCount = 0			// DTB400
		Set tMDXNode = pNodeNo		// DTB400

		// push args into node tree
		Set tArg = 2
		While (1) {
			If ((tArg#2)=0) {
				If '$D(pArgValue(tArg)) Quit
				// parm name
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("lit",0,1,pNewNodeNo,"",pArgValue(tArg))
				Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo),24) = tMDXNode			// DTB400 - Stamp this with its parent aggregate node
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNewNodeNo,"ch",pNodeNo) = ""
				
				Set x = $I(tArgCount)		// DTB400 - Count function arguments
			}
			Else {
				// parm value
				If $D(pSets(tArg)) {
					// add new copy of this node
					Set tNewNode = pNodeNo + 1
					Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,pNewNodeNo,pSets(tArg),,"chain")
					If $$$ISERR(tSC) Quit

					Set tCopiedNodeNo = pNodeNo
					While tCopiedNodeNo >= tNewNode {
						Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",tCopiedNodeNo)		// DTB400 - Delete after the copy
						// DTB400 - Copied nodes could be a chain. Stamp all nodes not already assigned an aggregate parent with this aggregate parent.
						// If the node is already stamped, it is already a child of another aggregate, leave it alone.
						If '$LD($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tCopiedNodeNo),24,tSubAggNode) {
							Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tCopiedNodeNo),24) = tMDXNode
						}
						ElseIf (tSubAggNode=tCopiedNodeNo) {
							//Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tCopiedNodeNo),24) = tMDXNode
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",tCopiedNodeNo) = ""
						}
						
						Set x = $I(tArgCount)		// DTB400 - Count function arguments
						Set tCopiedNodeNo = $LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tCopiedNodeNo),4)
					}

					// hide new node
					Set tSC = ..%HideNode(pCubeIndex,pKey,%axis,tNewNode)
					If $$$ISERR(tSC) Quit
				}
				ElseIf $D(pArgValue(tArg)) {
					// must be a literal
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("lit",0,1,pNewNodeNo,"",pArgValue(tArg))
					Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo),24) = tMDXNode			// DTB400 - Stamp this with its parent aggregate node
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNewNodeNo,"ch",pNodeNo) = ""
					
					Set x = $I(tArgCount)		// DTB400 - Count function arguments
				}
				Else {
					Quit
				}
			}
			Set tArg = tArg+1
			
			Set pNewNodeNo = pNodeNo		// DTB400 - Chain arguments instead of branching
		}
		
		// +DTB400 - Do this after the chain is complete
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",tMDXNode) = ""
		// -DTB400
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Pre-KPI: preprocessing for KPI() function.
Method PreKPI(pIsSlicer As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// this query may need to be recomputed as subquery may yield different values
		If $IsObject($G(%query)) {
			Set %query.%mustCompute = 1
			// JMD945: for cacheable KPI, we can test the KPI timestamp and cache!
			Set tChild = ..children.GetAt(1)
			If $IsObject(tChild) {
				// WAL/JMD1163
				If (tChild.finalValue) {
					// kpi has already been computed
					Quit
				}
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tChild.value)
				If (tKPIClass="") {
					Set tSC = $$$ERROR($$$GeneralError,"Invalid or missing KPI name: "_tChild.value)
					Quit
				}
			}
		}

		// If there are non-literal parameters for the statement, then we defer to the consolidation phase

		// JMD900: variable parameters: see if there is a %CONTEXT in play
		If (..children.Count()>1) {
			Set tHasNonLiteral = 0
			For n=2:1:..children.Count() {
				Set tChild = ..children.GetAt(n)
				If ('(tChild.%IsA("%DeepSee.Query.constant"))) {
					Set tHasNonLiteral = 1
				}
				Else {
					// test parm names only
					If ((n>3)&&((n#2)=0)) {
						Set tValue = tChild.%GetValue()
						If ((tValue="%CONTEXT")) {
							Set tHasNonLiteral = 1
						}
					}
				}
			}
			If (tHasNonLiteral) {
				Quit
			}
		}

		// otherwise, compute the value now and substitute its value in the query
		Set tChild = ..children.GetAt(1)
		If $IsObject(tChild) {
			If (tChild.finalValue) {
				// kpi has already been computed
				Quit
			}
			// JMD900: get parm values: these are passed as filter values to KPI
			Set tParmName = ""
			For n=4:1:..children.Count() {
				If ((n#2)=0) {
					Set tParmName = ..children.GetAt(n).%GetValue()
				}
				ElseIf (tParmName'="") {
					Set tParmValue = ..children.GetAt(n).%GetValue()
					Set:tParmValue'="" tParms(tParmName) = tParmValue
					Set tParmName = ""
				}
			}

			Set tResult = ""
			Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tChild.value)

			// If KPI is ASYNC, defer
			If $classmethod(tKPIClass,"%IsAsync") {
				Quit
			}

			Set tSeries = 1
			Set tProp = ""
			Set tArg2 = ..children.GetAt(2)
			If $IsObject(tArg2) {
				Set tProp = tArg2.%GetValue()
			}
			Set tArg3 = ..children.GetAt(3)
			If $IsObject(tArg3) {
				Set tSeries = tArg3.%GetValue()
			}

			// JMD949: localize caption
			// JMD1390: move until *after* we have got tProp
			Set tChild2 = ..children.GetAt(2)
			If ($IsObject(tChild2)&&tChild2.%IsA("%DeepSee.Query.constant")) {
				Set tChild2.value = $classmethod(tKPIClass,"%GetKPIPropertyCaption",tChild2.%GetValue())
			}

			Try {
				If '$D(tParms("%cube")) {
					// JMD1124: quote logical cube name
					Set tParms("%cube") = "["_$$$UPPER($G(%cube))_"]"
				}

				// JMD1390: test for missing property
				If (tProp="") {
					Set tChild.origValue = tChild.value
					Set tChild.value = "MISSING KPI PROPERTY"
					Set tChild.finalValue = 1
					Quit
				}
				Else {
					// should we test for bad KPI property name?
					Set tSC = $Classmethod(tKPIClass,"%GetKPIValue",tChild.value,.tResult,tProp,tSeries,.tParms)
					If $$$ISERR(tSC) {
						// return error as value of cell
						Set tChild.origValue = tChild.value
						Set tChild.value = $System.Status.GetErrorText(tSC)
						Set tChild.finalValue = 1
						Set tSC = $$$OK
						Quit
					}
				}
			}
			Catch(ex) {
				// return error as value of cell
				Set tChild.origValue = tChild.value
				Set tChild.value = "Invalid KPI"
				Set tChild.finalValue = 1
				Set tSC = $$$OK
			}

			If (tChild.finalValue) {
				Quit
			}

			// place result value
			Set tChild.origValue = tChild.value
			Set tChild.value = tResult
			Set tChild.finalValue = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a %KPI (lookup KPI) operation.
Method KPI(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, ByRef pNewNodeNo As %Integer, pParent As %Integer, ByRef pArgValue As %String, ByRef pSets As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFirstChild = ..children.GetAt(1)

		If ($IsObject(tFirstChild)&&tFirstChild.%IsA("%DeepSee.Query.constant")&&tFirstChild.finalValue) {
			// answer has already been computed
			// insert value into axis as literal
			// JMD949
			Set tLabel = $G(pArgValue(2),"KPI")
			Set tNode = $LB("lit",1,1,pParent,tLabel,$G(pArgValue(1)))

			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
			Set pNewNodeNo = pNodeNo
			Set leaf = $I(%leafCount)
			Quit
		}
		
		// pArgValue holds the literal values passed to the function (kpi name, property, series)
		// pSets holds the subnodes providing the parameter values for the query (which could be in pArgValues if literal!)

		// insert query into axis as aggregate, with kpi as "flag"
		Set tKPI = $G(pArgValue(1))
		Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tKPI)
		Set tLabel = $classmethod(tKPIClass,"%GetKPIPropertyCaption",$G(pArgValue(2)))
		Set:tLabel="" tLabel="KPI"
		Set tNode = $LB("agg",1,1,pParent,tLabel,"%KPI","kpi",tKPI)
		
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
		Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo),24) = pNodeNo		// DTB400 - Stamp this with its own reference
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		
		Set pNewNodeNo = pNodeNo
		Set leaf = $I(%leafCount)
		Set tArgCount = 0			// DTB400
		Set tKPINode = pNodeNo		// DTB400

		// push args into node tree
		Set tArg = 2
		While (1) {
			If ((tArg>3)&&((tArg#2)=0)) {
				If '$D(pArgValue(tArg)) Quit
				// parm name
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("lit",0,1,pNewNodeNo,"",pArgValue(tArg))
				Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo),24) = tKPINode			// DTB400 - Stamp this with its parent aggregate node	
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNewNodeNo,"ch",pNodeNo) = ""
				
				Set x = $I(tArgCount)		// DTB400 - Count function arguments
			}
			Else {
				// parm value: this is either 
				// in the pArgValue array if it is a literal
				// or in the pSets array for an expression
				If $D(pSets(tArg)) {
					// add new copy of this node
					Set tNewNode = pNodeNo + 1
					Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,pNewNodeNo,pSets(tArg),,"chain")		// DTB400
					If $$$ISERR(tSC) Quit

					Set tCopiedNodeNo = pNodeNo
					While tCopiedNodeNo >= tNewNode {
						Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",tCopiedNodeNo)		// DTB400 - Delete after the copy
						// DTB400 - Copied nodes could be a chain. Stamp all nodes not already assigned an aggregate parent with this aggregate parent.
						// If the node is already stamped, it is already a child of another aggregate, leave it alone.
						If '$LD($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tCopiedNodeNo),24,tSubAggNode) {
							Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tCopiedNodeNo),24) = tKPINode
						}
						ElseIf (tSubAggNode=tCopiedNodeNo) {
							//Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tCopiedNodeNo),24) = tKPINode
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",tCopiedNodeNo) = ""
						}
						
						Set x = $I(tArgCount)		// DTB400 - Count function arguments
						Set tCopiedNodeNo = $LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tCopiedNodeNo),4)
					}
					// hide new node
					Set tSC = ..%HideNode(pCubeIndex,pKey,%axis,tNewNode)
					If $$$ISERR(tSC) Quit
				}
				ElseIf $D(pArgValue(tArg)) {
					// must be a literal
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("lit",0,1,pNewNodeNo,"",pArgValue(tArg))
					Set $LI($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo),24) = tKPINode			// DTB400 - Stamp this with its parent aggregate node
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNewNodeNo,"ch",pNodeNo) = ""
					
					Set x = $I(tArgCount)		// DTB400 - Count function arguments
				}
				Else {
					Quit
				}
			}
			Set tArg = tArg+1
			
			Set pNewNodeNo = pNodeNo		// DTB400 - Chain arguments instead of branching
		}
		
		// +DTB400 - Do this after the chain is complete
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",tKPINode) = ""
		// -DTB400
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Pre-TimeWindow: preprocessing for %TimeWindow() function.
Method PreTimeWindow(pIsSlicer As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		New %axis,%leafCount

		Set tCubeIndex = $$$DeepSeeIndex(%cube)

		// check argument types
		Set tSetObj = ..children.GetAt(1)
		Set tStart = ..children.GetAt(2)
		Set tEnd = ..children.GetAt(3)

		If '$IsObject(tSetObj) {
			Set tSC = $$$ERROR($$$GeneralError,"%TimeWindow must define a time period")
			Quit
		}

		// materialize time period
		Set %axis = 1
		// materialize set of members
		Set tLocalNodeNo = 1
		Set tLocalKey = -$R(10000000000) // use random key to avoid conflict
		Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)

		Set tSC = tSetObj.%PreProcess(pIsSlicer)
		If $$$ISERR(tSC) Quit
		
		Set tSC = tSetObj.%ProcessAxes(%cube, tLocalKey, .tLocalNodeNo,,1)
		If $$$ISERR(tSC) Quit

		// copy members over
		Set tPeriodDim = ""
		Set tPeriodHier = ""
		Set tPeriodLevel = ""
		Set n = 0
		Set k = $O($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",1,"all",""))
		While (k'="") {
			Set tInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",k))
			Set tDim = $LG(tInfo,9)
			Set tHier = $LG(tInfo,10)
			Set tLevel = $LG(tInfo,11)
			If (tPeriodDim = "") {
				Set tPeriodDim = tDim
				Set tPeriodHier = tHier
				Set tPeriodLevel = tLevel
			}
			ElseIf ((tPeriodDim '= tDim)||(tPeriodHier '= tHier)||(tPeriodLevel '= tLevel)) {
				Set tSC = $$$ERROR($$$GeneralError,"All members of the %TimeWindow period must be from the same hiearchy and level")
				Quit
			}
			Set tPeriodList($I(n)) = tInfo

			Set k = $O($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",1,"all",k))
		}

		Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)
		If $$$ISERR(tSC) Quit

		If '$IsObject(tStart) {
			Set tSC = $$$ERROR($$$GeneralError,"%TimeWindow must have a starting value")
			Quit
		}
		Set tSC = tStart.%PreProcess(pIsSlicer)
		If $$$ISERR(tSC) Quit

		If $IsObject(tEnd) {
			Set tSC = tEnd.%PreProcess(pIsSlicer)
			If $$$ISERR(tSC) Quit
		}

		// find member providers for start and end
		// JMD1041 fix undefined
		Set tStartMember = ""
		If (tStart.%IsA("%DeepSee.Query.memberSpec")) {
			Set tStartMember = tStart.%GetMemberProvider()
		}
		ElseIf (tStart.%IsA("%DeepSee.Query.memberFunction")) {
			Set tSC = $$$ERROR($$$GeneralError,"Member function not allowed within %TimeWindow")
			Quit
		}
		If ('$IsObject(tStartMember)||('tStartMember.%IsA("%DeepSee.Query.memberTime"))) {
			Set tSC = $$$ERROR($$$GeneralError,"Starting value for %TimeWindow is of wrong type")
			Quit
		}

		If ((tStartMember.%dimNumber '= tPeriodDim) ||
			(tStartMember.%hierNumber '= tPeriodHier)) {
			Set tSC = $$$ERROR($$$GeneralError,"Period, start, and end for %TimeWindow must all refer to same hierarchy.")
			Quit
		}

		If ((tStartMember.%levelNumber < tPeriodLevel)) {
			Set tSC = $$$ERROR($$$GeneralError,"Start time for %TimeWindow cannot be an ancestor of the time period.")
			Quit
		}

		Set tEndMember = ""
		If $IsObject(tEnd) {
			If (tEnd.%IsA("%DeepSee.Query.memberSpec")) {
				Set tEndMember = tEnd.%GetMemberProvider()
			}
			ElseIf (tEnd.%IsA("%DeepSee.Query.memberFunction")) {
				Set tSC = $$$ERROR($$$GeneralError,"Member function not allowed within %TimeWindow")
				Quit
			}
			If ('$IsObject(tEndMember)||('tEndMember.%IsA("%DeepSee.Query.memberTime"))) {
				Set tSC = $$$ERROR($$$GeneralError,"Ending value for %TimeWindow is of wrong type")
				Quit
			}
		}

		If ($IsObject(tEndMember)) {
			If ((tStartMember.%dimNumber '= tEndMember.%dimNumber) ||
				(tStartMember.%hierNumber '= tEndMember.%hierNumber)) {
				Set tSC = $$$ERROR($$$GeneralError,"Start and end for %TimeWindow must refer to same hierarchy.")
				Quit
			}
			If ((tStartMember.%memberId = "") || (tEndMember.%memberId = "")||(tStartMember.%memberId = "NO MEMBER")||(tEndMember.%memberId = "NO MEMBER")) {
				Set tSC = $$$ERROR($$$GeneralError,"Start and end for %TimeWindow must refer to specific members.")
				Quit
			}
			If ((tEndMember.%levelNumber < tPeriodLevel)) {
				Set tSC = $$$ERROR($$$GeneralError,"End time for %TimeWindow cannot be an ancestor of the time period.")
				Quit
			}
		}
		Else {
			If ((tStartMember.%memberId = "")||(tStartMember.%memberId = "NO MEMBER")) {
				Set tSC = $$$ERROR($$$GeneralError,"Start for %TimeWindow must refer to a specific member.")
				Quit
			}
			Set tEndMember = tStartMember
		}

		// find range of values as $H
		Set tSC = ##class(%DeepSee.Query.memberTime).%GetBaseRange(tStartMember,tEndMember,.tStartTime,.tEndTime)
		If $$$ISERR(tSC) Quit

		// construct set of members within the range
		// find finest grained member
		Set tFinestMember = $S(tStartMember.%levelNumber>tEndMember.%levelNumber:tStartMember,1:tEndMember)

		// get members within range from finest member
		Set tSC = tFinestMember.%GetMembersInWindow(tStartTime,tEndTime,.tMemberList)
		If $$$ISERR(tSC) Quit

		// construct base spec for hierarchy
		Set tDimName = 0
		Set tMbrInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(%cube),"mbr#",tPeriodDim,tPeriodHier,0))
		Set tBaseSpec = "["_$LG(tMbrInfo,2)_"].["_$LG(tMbrInfo,3)_"]"

		// turn this node into range of time values (with COUSIN around each time)
		// HEAD({time1,time2,time3...},10000)
		Set ..function = "HEAD"

		Do ..children.Clear()
		Set tSet = ##class(%DeepSee.Query.set).%New()
		Do ..children.Insert(tSet)

		Set tLiteral = ##class(%DeepSee.Query.constant).%New()
		Set tLiteral.value = 10000
		Do ..children.Insert(tLiteral)

		// now add each time wrapped in the COUSIN function
		Set p = $O(tPeriodList(""))
		While (p'="") {
			Set tInfo = tPeriodList(p)
			Set tPeriodKey = $LG(tInfo,6)
			Set tPeriodLevel = $LG(tInfo,11)

			Set k = $O(tMemberList(""))
			While (k'="") {
				Set tMemberLevel = $LG(tMemberList(k),1)
				Set tMemberKey = $LG(tMemberList(k),2)
				
				If (tMemberLevel <= tPeriodLevel) {
					// use period value
					Set tNode = ##class(%DeepSee.Query.memberSpec).%New()
					Set tNode.spec = tBaseSpec _ "." _ "&[" _ tPeriodKey _ "]"
					Do tNode.%PreProcess(pIsSlicer)
					Do tSet.children.Insert(tNode)
				}
				Else {
					// use COUSIN function to find actual member
					Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)
					Set tLocalNodeNo = 5

					// mbr
					Set $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",2) = $LB("m",,,,"name",tMemberKey,,,tPeriodDim,tPeriodHier,tMemberLevel)
					
					// ancestor
					Set $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",3) = tInfo

					Set tSC = ..Cousin(%cube,tCubeIndex,tLocalKey,.tLocalNodeNo,,4,2,3)
					If $$$ISERR(tSC) Quit

					Set nn = $O($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",1,"all",""))
					Set tCousinNode = $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",nn)

					Set tCousinKey = $LG(tCousinNode,6)
					Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)

					Set tNode = ##class(%DeepSee.Query.memberSpec).%New()
					Set tNode.spec = tBaseSpec _ "." _ "&[" _ tCousinKey _ "]"
					Do tNode.%PreProcess(pIsSlicer)
					Do tSet.children.Insert(tNode)
				}
				If $$$ISERR(tSC) Quit
				Set k = $O(tMemberList(k))
			}
			If $$$ISERR(tSC) Quit
			Set p = $O(tPeriodList(p))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Pre-TimeRange: preprocessing for %TimeRange() function.
Method PreTimeRange(pIsSlicer As %Boolean = 0) As %Status [ Internal ]
{
	// JMD1041
	Set tSC = $$$OK
	Try {
		New %axis,%leafCount

		// Convert range into set of actual members
		New %axis,%leafCount

		Set tCubeIndex = $$$DeepSeeIndex(%cube)

		// check argument types
		Set tStart = ..children.GetAt(1)
		Set tEnd = ..children.GetAt(2)
		Set tFlag = ..children.GetAt(3)
		If ($IsObject(tFlag)) {
			If (tFlag.%IsA("%DeepSee.Query.flag")) {
				Set tFlag = tFlag.%GetValue()
			}
			If ((tFlag'="INCLUSIVE")&&(tFlag'="EXCLUSIVE")) {
				Set tSC = $$$ERROR($$$GeneralError,"Flag for %TimeRange must be INCLUSIVE or EXCLUSIVE.")
				Quit
			}
		}
		Else {
			Set tFlag = "INCLUSIVE"
		}

		Set tStartMissing = 0
		Set tEndMissing = 0
		// JMD1301: test for memberFunction
		If ('$IsObject(tStart)||('tStart.%IsA("%DeepSee.Query.memberSpec")&&'tStart.%IsA("%DeepSee.Query.memberFunction"))) {
			Set tStartMissing = 1
		}
		If ('$IsObject(tEnd)||('tEnd.%IsA("%DeepSee.Query.memberSpec")&&'tEnd.%IsA("%DeepSee.Query.memberFunction"))) {
			Set tEndMissing = 1
		}

		// JMD1301: test for set function
		If ($IsObject(tStart)&&tStart.%IsA("%DeepSee.Query.setFunction")) {
			If (tStart.%GetType()=$$$dstMember) {
				// get the member for this function
				Set %axis = 1
				Set tLocalNodeNo = 1
				Set tLocalKey = -$R(10000000000) // use random key to avoid conflict
				Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)

				Set tSC = tStart.%PreProcess(pIsSlicer)
				If $$$ISERR(tSC) Quit

				Set tSC = tStart.%ProcessAxes(%cube, tLocalKey, .tLocalNodeNo,,1)
				If $$$ISERR(tSC) Quit

				// result should have one member
				Set k = $O($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",1,"all",""))
				If (k'="") {
					Set tMbrInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",k))
					Set tDimNo = $LG(tMbrInfo,9)
					Set tHierNo = $LG(tMbrInfo,10)
					Set tLevelNo = $LG(tMbrInfo,11)
					Set tKey = $LG(tMbrInfo,6)

					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeIndex),"mbr#",tDimNo,tHierNo,tLevelNo))
					Set tSpec = "["_$LG(tInfo,2)_"].["_$LG(tInfo,3)_"].["_$LG(tInfo,4)_"].&["_tKey_"]"

					Set tStart = ##class(%DeepSee.Query.memberSpec).%New()
					Set tStart.spec = tSpec
					Do tStart.%PreProcess(pIsSlicer)
					Set tStartMissing = 0
				}
				Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"Function supplied to %TimeRange does not return a member")
				Quit
			}
		}

		If ($IsObject(tEnd)&&tEnd.%IsA("%DeepSee.Query.setFunction")) {
			If (tEnd.%GetType()=$$$dstMember) {
				// get the member for this function
				Set %axis = 1
				Set tLocalNodeNo = 1
				Set tLocalKey = -$R(10000000000) // use random key to avoid conflict
				Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)

				Set tSC = tEnd.%PreProcess(pIsSlicer)
				If $$$ISERR(tSC) Quit

				Set tSC = tEnd.%ProcessAxes(%cube, tLocalKey, .tLocalNodeNo,,1)
				If $$$ISERR(tSC) Quit

				// result should have one member
				Set k = $O($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",1,"all",""))
				If (k'="") {
					Set tMbrInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",k))
					Set tDimNo = $LG(tMbrInfo,9)
					Set tHierNo = $LG(tMbrInfo,10)
					Set tLevelNo = $LG(tMbrInfo,11)
					Set tKey = $LG(tMbrInfo,6)

					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeIndex),"mbr#",tDimNo,tHierNo,tLevelNo))
					Set tSpec = "["_$LG(tInfo,2)_"].["_$LG(tInfo,3)_"].["_$LG(tInfo,4)_"].&["_tKey_"]"

					Set tEnd = ##class(%DeepSee.Query.memberSpec).%New()
					Set tEnd.spec = tSpec
					Do tEnd.%PreProcess(pIsSlicer)
					Set tEndMissing = 0
				}
				Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"Function supplied to %TimeRange does not return a member")
				Quit
			}
		}
		
		// + WAL048 -- handle related cube case here, then quit
		If (('tStartMissing && $IsObject(tStart.%member) && tStart.%member.%IsA("%DeepSee.Query.memberRelationship")) 
				|| ('tEndMissing && $IsObject(tEnd.%member) && tEnd.%member.%IsA("%DeepSee.Query.memberRelationship"))) {

			If ('tStartMissing && 'tEndMissing) {	
				Set tProvidedSpec = tStart.spec
				Set tProvided = tStart.%ConstructClone(1) 
			}
			ElseIf ('tStartMissing) { 
				Set tProvidedSpec = tStart.spec
				Set tProvided = tStart.%ConstructClone(1) 
			}
			ElseIf ('tEndMissing) { 
				Set tProvidedSpec = tEnd.spec 
				Set tProvided = tEnd.%ConstructClone(1) 
			}
			
			Set tRelationshipDepth = tProvided.%member.%relationshipDepth
			While (tRelationshipDepth > 1) {
				Set tRemoteSpec = tProvided.%member.%remoteSpec		
				Set tActualizedRemoteMember = ##class(%DeepSee.Query.memberSpec).%New()
				Set tActualizedRemoteMember.spec = tRemoteSpec		
				Set tRelatedCubeIndex = $$$UPPER(tProvided.%member.%relatedCube)
				// + WAL073
				Set tRelationshipName = tProvided.%member.%relationship
				Set tDeepRelationshipSpec = $G(DeepRelationshipSpec) _ "[" _ tRelationshipName _ "]."
				// - WAL073
				Set tThisCubeIndex = %cube
				Set %cube = tRelatedCubeIndex
				Do tActualizedRemoteMember.%PreProcess(pIsSlicer)
				Set %cube = tThisCubeIndex
				
				Set tRelationshipDepth = tActualizedRemoteMember.%member.%relationshipDepth
				Set tProvided = tActualizedRemoteMember.%ConstructClone(1)
			}

			Set tRelationshipName = tProvided.%member.%relationship   // + WAL073 -- use relationship name
			Set tRelatedCubeIndex = $$$UPPER(tProvided.%member.%relatedCube)
			Set tRemoteSpec = tProvided.%member.%remoteSpec
			Set tActualizedRemoteMember = ##class(%DeepSee.Query.memberSpec).%New()
			Set tActualizedRemoteMember.spec = tRemoteSpec
			Set tThisCubeIndex = %cube
			Set %cube = tRelatedCubeIndex
			Do tActualizedRemoteMember.%PreProcess(pIsSlicer)
			Set %cube = tThisCubeIndex
			
			Set tDimNo = tActualizedRemoteMember.%member.%dimNumber
			Set tHierNo = tActualizedRemoteMember.%member.%hierNumber
			Set tLevelNo = tActualizedRemoteMember.%member.%levelNumber
			
			Set tExists = ##class(%DeepSee.Query.member).%GetNodeInfo(tRelatedCubeIndex,tDimNo,tHierNo,tLevelNo,.tFact,.tTimeClass)
			If ('tExists) {
				Set tSC = $$$ERROR($$$GeneralError,"Invalid member supplied to %TimeRange")
				Quit
			}
			If ((tTimeClass="")||('$classmethod(tTimeClass,"%IsA","%DeepSee.Time.AbstractLevel"))) {
				Set tSC = $$$ERROR($$$GeneralError,"%TimeRange must be supplied with a time dimension")
				Quit
			}
			
			Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tRelatedCubeIndex),"mbr#",tDimNo,tHierNo,tLevelNo))
			Set tSpec = "["_$LG(tInfo,2)_"].["_$LG(tInfo,3)_"].["_$LG(tInfo,4)_"]"

			If (tStartMissing || tEndMissing) {
				Set tSC = $classmethod(tTimeClass,"%GetAllMembers",.tList,tRelatedCubeIndex,tFact,$S(tStartMissing:"FIRST",tEndMissing:"LAST"),"","")
				If $$$ISERR(tSC) Quit
				
				Set k = $O(tList(""))
				If ((k'="")&&$D(tList(k))) {
					Set tMissingKey = $LG(tList(k),2)
				}
				Else {
					// DP-410151 - If there is no FIRST or LAST date to use, fill in with the key for
					// today so the query can be completed. This case will always produce No Results 
					// so the actual date doesn't matter, it just needs to be able to complete processing.
					Set tMissingKey = +$H
				}

				Set tMissingSpec = $G(tDeepRelationshipSpec) _ "["_ tRelationshipName _ "]." _ tSpec _ ".&[" _ tMissingKey _ "]"  // + WAL073 -- use relationship name
				
				If (tStartMissing) {
					Set tStartSpec = tMissingSpec
					Set tEndSpec = tProvidedSpec	
				}
				ElseIf (tEndMissing) {
					Set tStartSpec = tProvidedSpec
					Set tEndSpec = tMissingSpec	
				}
			}
			Else {
				Set tStartSpec = tStart.spec
				Set tEndSpec = tEnd.spec
			}	
			If (tFlag="EXCLUSIVE") {	
				Set tStartKey = $E($P(tStartSpec,"].&[",$L(tStartSpec,"].&[")),1,*-1)
				Set tEndKey = $E($P(tEndSpec,"].&[",$L(tEndSpec,"].&[")),1,*-1)
				If ('tStartMissing) {
					Set tSC = $classmethod(tTimeClass,"%GetRelatedKey",.tStartRelatedKey,tRelatedCubeIndex,tFact,tStartKey,"lead","1")
					If $$$ISERR(tSC) Quit
					Set tStartKey = tStartRelatedKey
				}
				If ('tEndMissing) {
					Set tSC = $classmethod(tTimeClass,"%GetRelatedKey",.tEndRelatedKey,tRelatedCubeIndex,tFact,tEndKey,"lag","1")
					If $$$ISERR(tSC) Quit	
					Set tEndKey = tEndRelatedKey
				}
				// + WAL073 -- use relationship names
				Set tStartSpec = $G(tDeepRelationshipSpec) _ "["_ tRelationshipName _ "]." _ tSpec _ ".&[" _ tStartKey _ "]"
				Set tEndSpec = $G(tDeepRelationshipSpec) _ "["_ tRelationshipName _ "]." _ tSpec _ ".&[" _ tEndKey _ "]"
				// - WAL073
			}
			
			Set tOrFunc = ##class(setFunction).%New("%OR")
			Set tOrRange = ##class(%DeepSee.Query.memberSpec).%New()
			Set tOrRange.spec = tStartSpec_":"_tEndSpec			
			Do tOrRange.%PreProcess(pIsSlicer)
			Do tOrFunc.children.Insert(tOrRange)
			Do ..children.Clear()
			Set ..function = tOrFunc.function
			Do ..children.Insert(tOrFunc.children.GetAt(1))
			Quit
		}
		// - WAL048

		If (tStartMissing && tEndMissing) {
			Set tSC = $$$ERROR($$$GeneralError,"No arguments supplied to %TimeRange")
			Quit
		}
		ElseIf (tStartMissing) {
			// Use end spec to plug-in start spec
			Set tSpec = ""
			If $IsObject(tEnd.%member) {
				If (tEnd.%member.%IsA("%DeepSee.Query.memberRelationship")) {
					Set tSC = $$$ERROR($$$GeneralError,"%TimeRange does not support relationships")
					Quit
				}
				Set tDimNo = tEnd.%member.%dimNumber
				Set tHierNo = tEnd.%member.%hierNumber
				Set tLevelNo = tEnd.%member.%levelNumber
				Set tExists = ##class(%DeepSee.Query.member).%GetNodeInfo(tCubeIndex,tDimNo,tHierNo,tLevelNo,.tFact,.tTimeClass)
				If ('tExists) {
					Set tSC = $$$ERROR($$$GeneralError,"Invalid member supplied to %TimeRange")
					Quit
				}
				If ((tTimeClass="")||('$classmethod(tTimeClass,"%IsA","%DeepSee.Time.AbstractLevel"))) {
					Set tSC = $$$ERROR($$$GeneralError,"%TimeRange must be supplied with a time dimension")
					Quit
				}

				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeIndex),"mbr#",tDimNo,tHierNo,tLevelNo))
				Set tSpec = "["_$LG(tInfo,2)_"].["_$LG(tInfo,3)_"].["_$LG(tInfo,4)_"]"

				// find first actual member
				Set tSC = $classmethod(tTimeClass,"%GetAllMembers",.tList,tCubeIndex,tFact,"FIRST","","")
				If $$$ISERR(tSC) Quit
				
				Set k = $O(tList(""))
				If ((k'="")&&$D(tList(k))) {
					Set tSpec = tSpec _ ".&["_$LG(tList(k),2)_"]"
				}
				If (tFlag="EXCLUSIVE") {
					// + WAL054
					Set tSC = ..LagOrLeadEndpoint(tEnd,tCubeIndex,"LAG",.tLagEnd)
					Set tEnd = tLagEnd
					Do tEnd.%PreProcess(pIsSlicer)
					// - WAL054
				}

				Set tStart = ##class(%DeepSee.Query.memberSpec).%New()
				Set tStart.spec = tSpec
				Do tStart.%PreProcess(pIsSlicer)
		}
		}
		ElseIf (tEndMissing) {
			Set tSpec = ""
			If $IsObject(tStart.%member) {
				If (tStart.%member.%IsA("%DeepSee.Query.memberRelationship")) {
					Set tSC = $$$ERROR($$$GeneralError,"%TimeRange does not support relationships")
					Quit
				}
				Set tDimNo = tStart.%member.%dimNumber
				Set tHierNo = tStart.%member.%hierNumber
				Set tLevelNo = tStart.%member.%levelNumber
				Set tExists = ##class(%DeepSee.Query.member).%GetNodeInfo(tCubeIndex,tDimNo,tHierNo,tLevelNo,.tFact,.tTimeClass)
				If ('tExists) {
					Set tSC = $$$ERROR($$$GeneralError,"Invalid member supplied to %TimeRange")
					Quit
				}
				If ((tTimeClass="")||('$classmethod(tTimeClass,"%IsA","%DeepSee.Time.AbstractLevel"))) {
					Set tSC = $$$ERROR($$$GeneralError,"%TimeRange must be supplied with a time dimension")
					Quit
				}
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeIndex),"mbr#",tDimNo,tHierNo,tLevelNo))
				Set tSpec = "["_$LG(tInfo,2)_"].["_$LG(tInfo,3)_"].["_$LG(tInfo,4)_"]"

				// find last actual member
				Set tSC = $classmethod(tTimeClass,"%GetAllMembers",.tList,tCubeIndex,tFact,"LAST","","")
				If $$$ISERR(tSC) Quit
				
				Set k = $O(tList(""))
				If ((k'="")&&$D(tList(k))) {
					Set tSpec = tSpec _ ".&["_$LG(tList(k),2)_"]"
				}

				If (tFlag="EXCLUSIVE") {
					// + WAL054
					Set tSC = ..LagOrLeadEndpoint(tStart,tCubeIndex,"LEAD",.tLeadStart)
					Set tStart = tLeadStart
					Do tStart.%PreProcess(pIsSlicer)
					// - WAL054
				}

				Set tEnd = ##class(%DeepSee.Query.memberSpec).%New()
				Set tEnd.spec = tSpec
				Do tEnd.%PreProcess(pIsSlicer)
			}
		}
		Else {
			// JMD1372: both ends specified; check for exclusive flag
			If (tFlag="EXCLUSIVE") {
				// + WAL054
				Set tSC = ..LagOrLeadEndpoint(tStart,tCubeIndex,"LEAD",.tLeadStart)
				Set tStart = tLeadStart
				Do tStart.%PreProcess(pIsSlicer)
				// PreProcess return value
				
				Set tSC = ..LagOrLeadEndpoint(tEnd,tCubeIndex,"LAG",.tLagEnd)
				Set tEnd = tLagEnd
				Do tEnd.%PreProcess(pIsSlicer)
				// - WAL054
			}
		}

		// JMD1365 Apply time folding if possible
		If $IsObject($G(%query)) {
			Set tOrFunc = ##class(setFunction).%New("%OR")
			Set tRange = ##class(%DeepSee.Query.range).%New()
			Do tOrFunc.children.Insert(tRange)
			Set tRange.startMember = tStart
			Set tRange.endMember = tEnd
			Do tRange.%PreProcess()

			Set tNewGroup = ""
			Set tSC = %query.%RewriteForTimeFolding("",tOrFunc,.tNewGroup)
			If $$$ISERR(tSC) Quit

			// turn this node into result of folding
			Do ..children.Clear()
			Set tDone = 0
			If $IsObject(tNewGroup) {
				If (pIsSlicer) {
					// JMD1374 if this is the slicer only use
					// new group if it is AGGREGATE({})
					If ($$$UPPER(tNewGroup.function)="AGGREGATE") {
						If (tNewGroup.children.Count()=1) {
							Set tSet = tNewGroup.children.GetAt(1)
							// JMD1460 change to >= 1
							If (tSet.%IsA("%DeepSee.Query.set")&&(tSet.children.Count()>=1)) {
								Set ..function = "%OR"
								Do ..children.Insert(tSet)
								// + WAL054
								Do ..%PreProcess()
								// - WAL054
								Set tDone = 1
							}
						}
					}
					ElseIf ($$$UPPER(tNewGroup.function)="%OR") {
						// DTB438 - Transfer all %OR children to this setFunction, also
						// a %OR.
						Set ..function = "%OR"
						For c=1:1:tNewGroup.children.Count() {
							Do ..children.Insert(tNewGroup.children.GetAt(c))
						}
						
						Do ..%PreProcess()
						Set tDone = 1
					}
				}
				Else {
					// fold new function (AGGREGATE into this node)
					Set ..function = tNewGroup.function
					For n=1:1:tNewGroup.children.Count() {
						Do ..children.Insert(tNewGroup.children.GetAt(n))
					}
					// + WAL054
					Do ..%PreProcess()
					// - WAL054
					Set tDone = 1
				}
			}

			// use ORiginal group
			If ('tDone) {
				Set ..function = tOrFunc.function
				Do ..children.Insert(tOrFunc.children.GetAt(1))
				
				// + WAL054
				Do ..%PreProcess()
				// - WAL054
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

ClassMethod LagOrLeadEndpoint(pOldGroup As %DeepSee.Query.group, pCubeIndex As %String, pDirection As %String, Output pNewGroup As %DeepSee.Query.group) As %Status
{
	// Method added by WAL054
	Set tSC = $$$OK
	Try {
		If (pOldGroup.%IsA("%DeepSee.Query.memberSpec")) {

				Set tDimNo = pOldGroup.%member.%dimNumber
				Set tHierNo = pOldGroup.%member.%hierNumber
				Set tLevelNo = pOldGroup.%member.%levelNumber
				Set tExists = ##class(%DeepSee.Query.member).%GetNodeInfo(pCubeIndex,tDimNo,tHierNo,tLevelNo,.tFact,.tTimeClass)
				
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeIndex),"mbr#",tDimNo,tHierNo,tLevelNo))
				Set tBaseSpec = "["_$LG(tInfo,2)_"].["_$LG(tInfo,3)_"].["_$LG(tInfo,4)_"]"

				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pOldGroup.spec,.tInfo,,.tMemberKey)
				If $$$ISERR(tSC) Quit
				
				Set tIndex = $O(tInfo(""),-1)
				Set tValue = tInfo(tIndex)
				If ('$G(tMemberKey(tIndex))) {
					Set tKey = $classmethod(tTimeClass,"%ValueToKey",tValue)
				}
				Else {
					Set tKey = tValue	
				}
				If ($$$UPPER(pDirection) = "LAG") {
					Set tSC = $classmethod(tTimeClass,"%GetRelatedKey",.tNewKey,pCubeIndex,tFact,tKey,"lag","1")
				}
				ElseIf ($$$UPPER(pDirection) = "LEAD") {
					Set tSC = $classmethod(tTimeClass,"%GetRelatedKey",.tNewKey,pCubeIndex,tFact,tKey,"lead","1")
				}
				If $$$ISERR(tSC) Quit
				
				Set pNewGroup = ##class(%DeepSee.Query.memberSpec).%New()
				Set pNewGroup.spec = tBaseSpec _ ".&[" _ tNewKey _ "]"
		}
		Else {
			// Old Logic
			Set tFunc = ##class(%DeepSee.Query.memberFunction).%New()
			If ($$$UPPER(pDirection) = "LAG") {
				Set tFunc.function = "LAG"
			}
			ElseIf ($$$UPPER(pDirection) = "LEAD") {
				Set tFunc.function = "LEAD"
			}
			Do tFunc.children.Insert(pOldGroup)
			Set tLit = ##class(%DeepSee.Query.constant).%New()
			Set tLit.value = 1
			Do tFunc.children.Insert(tLit)
			Set pNewGroup = tFunc
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

/// Pre-OR: preprocessing for %OR() function.
Method PreOR(pIsSlicer As %Boolean = 0) As %Status [ Internal ]
{
	// JMD1460
	Set tSC = $$$OK
	Try {
		// look for %OR({%OR}) and flatten
		// DTB697 - A tuple as the argument %OR( (A,B,...) ) remains unchanged
		Set tItemCount = 0
		Set tSet = ..children.GetAt(1)
		// DTB697 - A tuple cannot logically be flattened using this method
		// DP-429168 - A calculatedMember tests true as a "set", but needs to maintain %OR(calc(%OR(...))) structure
		If ($IsObject(tSet)&&tSet.%IsA("%DeepSee.Query.set")&&'tSet.%IsA("%DeepSee.Query.tuple")&&'tSet.%IsA("%DeepSee.Query.calculatedMember")) {
			// %OR({
			Set tCount = tSet.children.Count()
			If (tCount>1) {
				For n = 1:1:tCount {
					Set tChild = tSet.children.GetAt(n)
					If (tChild.%IsA("%DeepSee.Query.setFunction")&&($$$UPPER(tChild.function)="%OR")) {
						// %OR({%OR( -- move children of inner OR to outer OR
						Set tItemCount = tItemCount + 1
						Set tCount2 = tChild.children.Count()
						For n2 = 1:1:tCount2 {
							Set tChild2 = tChild.children.GetAt(n2)
							If (tChild2.%IsA("%DeepSee.Query.set")) {
								Set tCount3 = tChild2.children.Count()
								For n3 = 1:1:tCount3 {
									Set tChild3 = tChild2.children.GetAt(n3)
									Set tList($I(tList)) = tChild3
								}
							}
							Else {
								Set tList($I(tList)) = tChild2
							}
						}
					}
					Else {
						// add to list
						Set tList($I(tList)) = tChild
					}
				}

				If (tItemCount) {
					// rebuild list of children
					Do tSet.children.Clear()
					Set k = $O(tList(""))
					While (k'="") {
						Do tSet.children.Insert(tList(k))
						Set k = $O(tList(k))
					}
				}
			}
			Else {
				// DP-429168 - Remove the set
				Set tChild = tSet.children.GetAt(1)
				Do ..children.Clear()
				Do ..children.Insert(tChild)
			}
		}
		
		// DTB700 - After depth reduction efforts are complete, do a final check to see if the
		// %OR node can be reliably processed.
		// DP-424589 - Turn this off for the slicer but keep it for visible axes
		If 'pIsSlicer {
			Set tSC = ..AnalyzeORNode($this,.tStructure,,,.tMaxDepth)
			If $$$ISERR(tSC) Quit
			
			If (tMaxDepth>2) {
				Set tSC = $$$ERROR($$$GeneralError,"An %OR statement has depth > 2 and cannot be processed")
				Quit
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a CUBE operation on the given items in <var>pArgValues</var>, which takes the form:<br>
/// <var>pArgValues</var>(1) = The reference cube for this axis<br>
/// <var>pArgValues</var>(2) = The target dimension requested on this axis<br>
/// <var>pArgValues</var>(n) = shared dimensions between the cubes<br>
/// This function is generated and inserted into a subquery in the specific case where the target
/// subcube does not itself define the target dimension.
Method CUBE(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, ByRef pNewNodeNo As %Integer, pParent As %Integer, ByRef pArgValues As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	
	Try {
		Set pCube = $$$UPPER(pCube)
		// Get ResultSet for the subquery
		Set tSC = %query.%GetSubQuery(..subqueryKey,.tRS)
		If $$$ISERR(tSC) Quit

		If (tRS.%GetQueryKey()="") {
			// should not happen!
			Set tSC = $$$ERROR($$$GeneralError,"Internal Error in CUBE()")
			Quit
		}

		// copy names into this axis
		Set tRefCube = $$$UPPER(tRS.%GetCubeName())
		Set tRefKey = tRS.%GetQueryKey()

		// Find axes
		Set tTotalAxisCount = ##class(Engine2).%GetAxisInfo(tRefCube,tRefKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)
		Set tRowAxisKey = tAxisKey(2)
		Set tRefCubeIndex = $$$DeepSeeIndex(tRefCube)

		Set tOrigNodeNo = pNodeNo

		// see if there are any shared levels we supposed to connect by
		Set tCorrelateList = ""
		Set tLocalCorrelateList = ""
		Set k = $O(pArgValues(2))
		While (k'="") {
			Set tJoinSpec = $$$UPPER(pArgValues(k))

			// find fact name and number for this level
			Kill tJoinSpecInfo
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tJoinSpec,.tJoinSpecInfo)
			If $$$ISERR(tSC) Quit

			Set tDimName = $$$UPPER($G(tJoinSpecInfo(1)))
			Set tHierName = $$$UPPER($G(tJoinSpecInfo(2)))
			Set tLevelName = $$$UPPER($G(tJoinSpecInfo(3)))

			Set tRefNode = $G($$$DeepSeeMetaGLVN("cubes",tRefCube,"mbrs",tDimName,tHierName,tLevelName))
			If (tRefNode="") {
				Set tSC = $$$ERROR($$$GeneralError,"Invalid connectsBy value in compound cube "_tJoinSpec)
				Quit
			}
			
			Set tRefInfo = $G($$$DeepSeeMetaGLVN("cubes",tRefCube,"mbr#",+$LG(tRefNode,1),+$LG(tRefNode,2),+$LG(tRefNode,3)))
			Set tFactNo = $LG(tRefInfo,5)
			Set tCorrelateList = tCorrelateList _ $LB(tFactNo)

			// get local fact no as well
			Set tLocalNode = $G($$$DeepSeeMetaGLVN("cubes",pCube,"mbrs",tDimName,tHierName,tLevelName))
			Set tLocalInfo = $G($$$DeepSeeMetaGLVN("cubes",pCube,"mbr#",+$LG(tLocalNode,1),+$LG(tLocalNode,2),+$LG(tLocalNode,3)))
			Set tLocalFactNo = $LG(tLocalInfo,5)
			Set tLocalCorrelateList = tLocalCorrelateList _ $LB(tLocalFactNo)
			Set k = $O(pArgValues(k))
		}
		If $$$ISERR(tSC) Quit
			
		// DP-405378 - The row axis of the primary cube as found previously defines the initial
		// computation space across the secondary cubes. Take a direct look at that axis and
		// copy it for this %CUBE function. The must have a value if there are any potential results,
		// while the "leaf" nodes from the primary cube results could legitimately have no value and
		// so could be skipped. 
		If tRowAxisKey="" Quit
			
		Set row = $O($$$DeepSeeAxisGLVN(tRefCubeIndex,tRowAxisKey,"axes",1,"all",""))
		While (row '= "") {
			Set tRowNode = $G($$$DeepSeeAxisGLVN(tRefCubeIndex,tRowAxisKey,"axes",row))
			Set tRowFact = $LG(tRowNode,7)
			Set tRowFactId = $LG(tRowNode,6)

			If (tCorrelateList="") {
				// place *all" node into *this* axis
				// Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("lit",1,1,pParent,$LG(tRowNode,5),0)
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("mbr",1,1,pParent,$LG(tRowNode,5),"","")
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)
				Set pNewNodeNo = pNodeNo
			}
			Else {
				If (tRowFact = "") {
					// all member
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("mbr",1,1,pParent,"")
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
					Set leaf = $I(%leafCount)
				}
				Else {
					// find correlation set
					Set tSC = ##class(%DeepSee.Query.Engine).%GetCorrelatedMembers(tRefCubeIndex,,.tMembers,tRowFact,tRowFactId,tCorrelateList)
					If $$$ISERR(tSC) Quit
				
					// places members into *this* axis under an aggregate node
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("agg",1,1,pParent,$LG(tRowNode,5),"SUM")
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
					Set leaf = $I(%leafCount)
					Set tAggNode = pNodeNo
				
					Set tCCount = $LL(tCorrelateList)
					Set tChildCount = 0
					Set k = $O(tMembers(""))
					While (k'="") {
					
						Set tLocalParent = tAggNode
						If (tCCount > 1) {
							// add tuple node
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("tuple",0,0,tLocalParent,,+$G(%SetOpDepth(pKey)),$$$dsCurrentMethod)		// DP-424589 - Add depth to tuple
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tLocalParent,"ch",pNodeNo) = ""
							Set tLocalParent = pNodeNo
						}

						For n=1:1:tCCount {
							Set tFactNo = $LG(tLocalCorrelateList,n)
							Set tFactId = $LG(tMembers(k),n)
							Set tCompute = $S((n=tCCount):1,1:0)

							// copy empty node into *this* axis (as part of tuple (or single member))
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("mbr",0,tCompute,tLocalParent,"",tFactId,tFactNo)
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tLocalParent,"ch",pNodeNo) = ""
							If (tCompute) {
								Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
							}

							Set tLocalParent = pNodeNo
						}
						Set tChildCount = tChildCount + 1
						Set k = $O(tMembers(k))
					}

					If (tChildCount=0) {
						// copy empty node into *this* axis
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("lit",0,1,tAggNode,"",0)
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tAggNode,"ch",pNodeNo) = ""
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
					}
				}
				Set pNewNodeNo = pNodeNo
			}

			Set row = $O($$$DeepSeeAxisGLVN(tRefCubeIndex,tRowAxisKey,"axes",1,"all",row))
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Construct a single member that is the OR of the elements of a given set.
Method ORSET(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pSet As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pSet="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing arguments for function: ORSET")
			Quit
		}

		Do $I(%SetOpDepth(pKey))		// DP-424589

		// DP-421810 - If the target set has no children, replace pSet with a nullaxis node and quit
		If '$D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch")) {
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet) = $$$DeepSeeNullAxisNode($LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet),4))
			Quit
		}

		// JMD1453 turn on hetero-join behavior
		Set tNewOR = 1

		// loop over children
		Set tCount = 0
		Set tDim = ""
		Set tHier = ""
		Set tLevel = ""

		// JMD887: it is possible to get %OR(tuple) -- %OR(%TERMLIST(list,EXCLUDE))
		Set tSetNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet))
		If ($LG(tSetNode,1)="tuple") {
			// in this case we do not need to process OR, but we will change the tuple to an "agg" node
			Set tSetNode = $lb("agg",1,1,$LG(tSetNode,4),"List","SUM")
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet) = tSetNode

			// insert all node
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pSet) = ""
			Set leaf = $I(%leafCount)

			// make all children invisible
			Set tChildNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
			While (tChildNo'="") {
				Set $$$dsAxisNodeVisible($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNo)) = 0
				Set tChildNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNo,"ch",""))
			}
			Quit
		}

		// JMD1453: organize elements by dimension
		Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
		Set tFirstNodeNo = s1
		Set tGroupCount = 0
		Set tGroupAddrIndex = 0	// DTB974 - A tag for identifying identical addresses functioning as different groups
		Set tOrChildCount = 0
		Set tLastWasCJ = 0		// DTB974 - A flag used in identifying functionally new groups according to usage
		Set tHasTuple = 0		// DTB974 - A flag signaling the existence of tuple behavior within this orset
		While (s1 '="") {
			Set:($G(tFirstNodeNo)="") tFirstNodeNo = s1
			Set tChildNodeRemoved = 0		// DTB807
			Set tNode = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1)
			Set tType = $$$dsAxisNodeTypeGet(tNode)
			Set tNodeIsOR = ($$$dsAxisNodeKeyGet(tNode)["|") || (tType="orset")		// DP-424589
			Set tNodeIsSetOp = $$$dsAxisNodeIsSetOp(tNode)
			Set tOrsetNextChild = ""
			
			If ($$$IsDeepSeeNullAxisNode(tNode)||($$$dsAxisNodeKeyGet(tNode)="NO MEMBER")) {
				// DTB807 - Remove this node since it will have no effect on the ORSET
				// DP-421810 - This delete is a problem if it removes the only node, so keep track of the first NO MEMBER encountered
				// to put back in if it is needed.
				Set:'$D(tNoMember) tNoMember(s1) = tNode
				Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,s1)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
				
				// DP-421810 - This node being removed was the first node. 
				Set:(tFirstNodeNo=s1) tFirstNodeNo = ""
				Set tChildNodeRemoved = 1
				
				Set s1 = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",s1))
				Continue
			}
			ElseIf ((tType'="mbr")&&(tType'="tuple")&&(tType'="orset")) {
				Set tSC = $$$ERROR($$$GeneralError,"All arguments for %OR must be dimension members (" _ tType_")")
				Quit
			}
			Set tDim = $$$dsAxisNodeDimGet(tNode)
			Set tHier = $$$dsAxisNodeHierGet(tNode)
			Set tLevel = $$$dsAxisNodeLevelGet(tNode)

			// JMD1453.3 test for relationship
			Set tRelName = ""
			Set tRelFact = $S('tNodeIsSetOp:$$$dsAxisNodeFactGet(tNode),1:"")
			If (tRelFact'="") {
				Set tRelName = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCubeIndex,"rel#",tRelFact)))
			}
			
			
			// DTB974 - Construct tAddr as a means of tracking the groups of items within this %OR.
			// Homogeneous %OR will simply produce a single member with a '|'-delimited key.
			// Heterogeneous %OR will have multiple groups to work with and maintains an index of
			// the first root node position for each of those groups.
		
			// Define a "true type" of this node according to the actual usage. This is for 
			// the most part same as the canonical type (the default) but can also include "crossjoin" to indicate chained
			// organization with multiple children.
			Set tTrueType = tType		// Set the default
			If (tType="mbr")&&$D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1,"ch")) {
				Set tGrandchildNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1,"ch",""))
				Set tGCType = $$$dsAxisNodeTypeGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tGrandchildNodeNo))
				If ("mbr"=tGCType)||$$$dsAxisNodeTypeIsSetOp(tGCType) {
					// DTB974 - Track that the last child node was a crossjoin
					Set tTrueType = "crossjoin"
				}
			}
			If (tType="orset") {
				// DP-424589 - Test to see if this node is an orset that behaves as a member of an intersection. 
				// If so, mark its trueType as a "crossjoin".
				Set tOrsetNodeLevel = $LG(tNode,6)
				Set tOrsetMbrNo = s1
				For {
					Set tOrsetMbrNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOrsetMbrNo,"ch",""))
					Quit:(tOrsetMbrNo="")
					Set tOrsetMbrType = $$$dsAxisNodeTypeGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOrsetMbrNo))
					Set tOrsetMbrLevel = $$$dsAxisNodeSetOpDepthGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOrsetMbrNo))
					If $$$dsAxisNodeTypeIsSetOp(tOrsetMbrType) && (tOrsetMbrLevel<=tOrsetNodeLevel){
						// The original set s1 is closed out by a set operation with a operator depth less than or equal
						// to the current s1. Any set operation with a depth that is larger than s1 indicates this is still
						// an argument enclosed within the set operation being examined.
						Set tTrueType = "crossjoin"
						Quit
					}
				}
			}

			// DTB974 - Analyze the type according to context and identify whether or not this requires a
			// new heterogenous %OR group
			Set tNewGroup = 0
			If (tTrueType="crossjoin") {
				Set tLastWasCJ = 1
				Set tNewGroup = 1
				Set tHasTuple = 1
			}
			ElseIf (tTrueType="tuple") {
				Set tLastWasCJ = 0
				Set tNewGroup = 1
				Set tHasTuple = 1
			}
			ElseIf (tTrueType="mbr")&&(tLastWasCJ) {
				Set tNewGroup = 1
				Set tLastWasCJ = 0
			}

			// DTB974 - Produce the actual address for this grouping. New groups are always given a
			// unique address.
			If (tRelName'="") {
				Set tAddr = tRelName_":"_$S(tNewGroup:$I(tGroupAddrIndex),1:tGroupAddrIndex)
			}
			Else {
				Set tAddr = tDim_":"_tHier_":"_tLevel_":"_$S(tNewGroup:$I(tGroupAddrIndex),1:tGroupAddrIndex)
			}
			If (($E(tAddr,1,2)="::")&&((tTrueType="tuple")||(tTrueType="crossjoin"))) {
				Set tAddr = "tuple:"_$I(tGroupAddrIndex)
			}
			
			
			If ($E(tAddr,1,2)'="::") {
				If ('$D(tOrgSets(tAddr))) {
					// DTB974 - This now *should* be the vast majority of cases based on the more sophisticated
					// address creation above. The other cases remain for compatibility.
					Set tGroupCount = tGroupCount + 1
					
					// remember original node order; it keeps the axis ordering clean
					Set tOrgIndex(s1) = tAddr
					If tNodeIsOR {		// DTB095
						Set tORMembers(tAddr) = 1
					}
				}
				ElseIf (tTrueType="tuple") {
					// counts as a group
					Set tGroupCount = tGroupCount + 1
				}
				ElseIf (tTrueType="mbr")&&$D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1,"ch")) {
					Set tGrandchildNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1,"ch",""))
					Set tGCType = $LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tGrandchildNodeNo),1)
					If ( "mbr"=tGCType ) {
						// DTB693 - This is a crossjoin and should be treated like a tuple!
						Set tGroupCount = tGroupCount + 1
					}
				}
				ElseIf ( (tTrueType="mbr") && ($D(tORMembers(tAddr))||tNodeIsOR) ) {
					// DTB095 - this is a group of members from the same level with a %OR acting
					// on one or more members of that group. Treat this as multiple groups.
					Set tGroupCount = tGroupCount + 1
				}

				If ((tRelName'="")||(tHier'=0)||('$D(tOrgSets(tAddr)))) {
					Set tOrgSets(tAddr,s1) = tTrueType		// DTB974 - Make this avalailable to later processing
				}
			}

			Set:'tChildNodeRemoved tOrChildCount = tOrChildCount+1		// DTB807
			Set s1 = $S(+$G(tOrsetNextChild):tOrsetNextChild,1:$O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",s1)))
		}
		If $$$ISERR(tSC) Quit

		If '(tOrChildCount>0) {
			// DTB807 - If there was nothing to OR, replace the set node with a literal null and quit
			Set tParentNodeNo = $$$dsAxisNodeParentGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet))
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet) = $LB("lit",1,1,tParentNodeNo,"","")
			
			Quit
		}

		// pre-JMD1453 behavior
		If ('tNewOR && (tGroupCount>1)) {
			Set tSC = $$$ERROR($$$GeneralError,"All members for %OR must come from the same level")
			Quit
		}

		// If we have more than one group, change "set" to special "orset"
		// chain all groups underneath this set:
		// 
		//  %OR({A,B})				==> orset,A,B
		//	%OR({(A,B)})			==> orset,ortuple,A,B					DTB605
		//  %OR({A,(B,C)})			==> orset,A,ortuple,B,C
		// 	%OR({(A,B),C})			==> orset,ortuple,A,B,ortuple,C
		// 	%OR({(A,B),(C,D)})		==> orset,ortuple,A,B,ortuple,C,D
		//	%OR({CJ({A,B},C)})		==> orset,ortuple,A,C,ortuple,B,C
		//	%OR({A,CJ(B,C)})		==> orset,A,ortuple,B,C
		//	%OR({CJ(A,{B,C})})		==> orset,ortuple,A,C,ortuple,A,B
		//	%OR({CJ({A,B},{C,D})})	==> orset,ortuple,A,D,ortuple,A,C,ortuple,B,D,ortuple,B,C
		// 	tuple(%OR({A,B}),C)		==> orset,A,B,tuple,C

		Set tNodeIsOrset = 0
		If (tGroupCount>1)||tHasTuple {
			Set $$$dsAxisNodeType($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet)) = "orset"
			Set $$$dsAxisNodeSetOpDepth($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet)) = +$G(%SetOpDepth(pKey))		// DP-424589 - Add depth to orset
			Set $$$dsAxisNodeSetOpDepthSrc($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet)) = $$$dsCurrentMethod _ " (1)"
			Set tNodeIsOrset = 1		// DTB605
		}

		// loop over groups (in node order)
		Set tLastGroupNodeNo = ""
		Set g1 = $O(tOrgIndex(""))
		While (g1'="") {
			Set tGroup = tOrgIndex(g1)
			Set s1 = $O(tOrgSets(tGroup,""))
			Kill tKeys,tKeyNames
			Set tCount = 0
			Set tFirstNodeNo = s1
			While (s1'="") {
				Set:($G(tFirstNodeNo)="") tFirstNodeNo = s1
				Set tCount = tCount + 1
				Set tNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1))
				Set tType = $$$dsAxisNodeTypeGet(tNode)
				If $$$dsAxisNodeTypeIsSetOp(tType) {
					// special case: %OR({(tuple)})
					// DP-429168 - include %OR(%OR)
				}
				ElseIf (tType="mbr")&&$D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1,"ch")) {
					Set tGrandchildNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1,"ch",""))
					Set tGCType = $$$dsAxisNodeTypeGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tGrandchildNodeNo))
					If ( "mbr"=tGCType )||$$$dsAxisNodeTypeIsSetOp(tGCType) {
						// DTB693 - This is a crossjoin and should be treated like a tuple!
						// Make this a no-op like the "tuple" case above
					}
				}
				Else {
					// build list of keys in sorted order
					// to make cache more efficient
					Set tKey = $$$dsAxisNodeKeyGet(tNode)
					If (tKey="NO MEMBER") {
						// DP-421810 - Immediately remove any NO MEMBER nodes from the set. Keep track of the first one in case
						// everything gets removed.
						Set:'$D(tNoMember) tNoMember(s1) = tNode
						Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,s1)
						If $$$ISERR(tSC) Quit

						// Clear this node from important variables
						Set:(tFirstNodeNo=s1) tFirstNodeNo = ""
						Set tCount = tCount-1
					}
					ElseIf (tKey["|")&&(tGroupCount<2) {	// DTB095
						// JMD1301: don't ORize twice
						Set tCount = tCount - 1
					}
					Else {
						// JMD927: remember old #s & name
						Set:tKey'="" tKeys(tKey)=s1
						Set:tKey'="" tKeyNames(tKey) = $$$dsAxisNodeLabelGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1))

						If (tCount > 1)&&$D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1)) {
							Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,s1)
							If $$$ISERR(tSC) Quit
						}
					}
				}
				Set s1 = $O(tOrgSets(tGroup,s1))
			}
			If $$$ISERR(tSC) Quit

			// DP-421810 - The NO MEMBER might have been the only node in the set. In that case restore a single NO MEMBER identical to the first original
			If '$D(tKeys)&&$D(tNoMember) {
				Set s1 = $O(tNoMember(""),1,tNode)
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",s1) = tNode
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$$$dsAxisNodeParentGet(tNode),"ch",s1) = ""
				Set tKey = $$$dsAxisNodeKeyGet(tNode)
				Set:(tKey'="") tKeys(tKey) = s1
				Set:(tKey'="") tKeyNames(tKey) = $$$dsAxisNodeLabelGet(tNode)
				Set:(tFirstNodeNo="") tFirstNodeNo = s1
			}

			Set tOutputNodeNo = tFirstNodeNo
			If (((tGroupCount>1)||(tCount>1))&&(tFirstNodeNo'="")) {
				// JMD927: split large set into multiple child nodes
				// reuse the node #s that we deleted earlier
				Set tMaxLen = 5000

				// add to parent "orset"
				// later, we convert the tree to a chain
				Set tParentNodeNo = $$$dsAxisNodeParentGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tFirstNodeNo))
				Set tOutputNodeLevel = $$$dsAxisNodeSetOpDepthGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tFirstNodeNo))

				Set tLastName = ""
				Set tKeyList = ""
				Set k = $O(tKeys(""))
				While (k'="") {
					// DP-421810 - Don't add NO MEMBER to an existing list. If there is no list NO MEMBER can be set into the list
					Set tKeyList = tKeyList _ $S(tKeyList="":k,k="NO MEMBER":"",1:"|"_k)
					Set tLastName = $G(tKeyNames(k))
					Set k = $O(tKeys(k))
					If (tKeyList="NO MEMBER") && (k'="") {
						// DP-421810 - If the only key recorded so far is "NO MEMBER" but there is another key, remove that key and 
						// start accumulating keys that are incoming
						Set tKeyList = ""
					}
					If ((k="")||($L(tKeyList)>tMaxLen)) {

						// JMD1453.2 If we have a split list; make sure orset is in place
						If (tNewOR && ($L(tKeyList)>tMaxLen)) {
							Set $$$dsAxisNodeType($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet)) = "orset"
							Set $$$dsAxisNodeSetOpDepth($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet)) = +$G(%SetOpDepth(pKey))		// DP-424589 - Add depth to orset
							Set tNodeIsOrset = 1		// DTB605
						}

						// replace the key with the new list of keys
						Set $$$dsAxisNodeKey($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOutputNodeNo)) = tKeyList
						If (tNewOR) {
							// place this node beneath last node
							Set tOldParentNo = $$$dsAxisNodeParentGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOutputNodeNo))
							If (tOldParentNo'=tParentNodeNo) {
								Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOldParentNo,"ch",tOutputNodeNo)
								Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParentNodeNo,"ch",tOutputNodeNo)=""
								Set $$$dsAxisNodeParent($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOutputNodeNo)) = +tParentNodeNo
							}
						}
						ElseIf (tParentNodeNo'="") {
							// append to top-level set
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParentNodeNo,"ch",tOutputNodeNo)=""
							Set $$$dsAxisNodeParent($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOutputNodeNo)) = +tParentNodeNo
						}

						If (k'="") {
							If (tNewOR) {
								Set tParentNodeNo = tOutputNodeNo
							}

							// add another node for the next set of keys
							Set tKeyList = ""
							Set tOutputNodeNo = tKeys(k)
							Set leaf = $I(%leafCount)

							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOutputNodeNo) = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tFirstNodeNo)
							Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1,"all",tOutputNodeNo) = ""
							Set $$$dsAxisNodeValue($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tOutputNodeNo)) = k
						}
					}
				}

				// change the label for this node
				Set tName = $$$dsAxisNodeLabelGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tFirstNodeNo))
				Set tLabel = ..label		// DTB502 - Add the user-defined label if defined
				If (tLabel'="") {
					Set tName = tLabel
				}
				ElseIf ((tLastName'="")&&(tLastName'=tName)) {
					Set tName = tName_"..."_tLastName
				}
				Else {
					Set tName = tName _ $S((tName'="")&&(tCount>1):"+",1:"")
				}
				Set $$$dsAxisNodeLabel($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tFirstNodeNo)) = tName
			}

			// next group
			Set g1 = $O(tOrgIndex(g1))
			Set tLastGroupNodeNo = tOutputNodeNo
			
			// + WAL036 -- Update pNodeNo when ORizing nodes
			Set pNodeNo=tOutputNodeNo
			// - WAL036
		}

		If (tNewOR) {
			// force compute flag to 0 for all but the last child
			// double loop as we could have nested children

			// if we have %OR(tuple,tuple), then reorganize the axis graph;
			// place everything in a chain and convert "tuple" to "ortuple"
			// for %OR(tuple,mbr), wrap mbr in "ortuple" as well
			Set tBranchNo = 0
			Set tLastChild = ""
			Set tHasOrTuples = 0	// once we have an "ortuple", 
									// all following items need to be wrapped in ortuple

			Set tTopChildNode = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""))
			While (tTopChildNode'="")&&'$D(tReturnedChildren(tTopChildNode)) {
				Set tBranchNo = tBranchNo + 1
				Set tChildNode = tTopChildNode
				Set tType = $LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode),1)
				
				// DTB974 - Test this stored type to replace DTB693 with a better crossjoin approach
				// capable of handling multiple children
				Set tTrueType = $G(tOrgSets($G(tOrgIndex(tChildNode),0),tChildNode))
				If (tTrueType="crossjoin") {
					Set tSC = ..ORizeCrossJoin(pCubeIndex,pKey,tChildNode,.pNodeNo,.pNewNodeNo,pSet,.tChildNode)
					Set tReturnedChildren(tChildNode) = ""		// DP-423012 - Record these to prevent revisiting new child nodes
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					Set tHasOrTuples=1
				}
				ElseIf (tTrueType="tuple") {
					// DP-424589 - Use the trueType to decide if tuple behavior is present
					Set tHasOrTuples=1
				}
				
				If (tType="tuple")&&tNodeIsOrset {
					// change to "ortuple" node
					Set $$$dsAxisNodeType($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode)) = "ortuple"
					Set $$$dsAxisNodeSetOpDepth($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode)) = +$G(%SetOpDepth(pKey))+1		// DP-424589 - Add depth to ortuple
					Set $$$dsAxisNodeSetOpDepthSrc($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode)) = $$$dsCurrentMethod _ " (2)"
					Set tHasOrTuples = 1
				}
			
				If (tBranchNo=1) && (tNodeIsOrset && (tTrueType="tuple") && (tType="orset")) {
					// DP-424589 - For the first branch, if this is an "orset" that has been tagged with the "tuple" behavior
					// and is filed under an overarching "orset", insert an "ortuple" node to file the remaining chain under. 
					// The depth of this is set as 1 greater than the current depth to indicate it is an argument of the current set.
					
					// This set  might have tagged the SetOp as the pNodeNo due to WAL036 concerns. Look for the end of this
					// chain instead of the beginning.
					Set tOutputNodeLevel = $$$dsAxisNodeSetOpDepthGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo))
					Set tLastOutputNodeNo = pNodeNo
					For {
						Set pNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",""))
						If (pNodeNo="") {
							Set pNodeNo = tLastOutputNodeNo
							Quit
						}
						Set tOutputMbrType = $$$dsAxisNodeTypeGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo))
						Set tOutputMbrLevel = $$$dsAxisNodeSetOpDepthGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo))
						If $$$dsAxisNodeTypeIsSetOp(tOutputMbrType) && (tOutputMbrLevel<=tOutputNodeLevel){
							Quit
						}
						Set tLastOutputNodeNo = pNodeNo
					}	
						
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $lb("ortuple",0,0,pSet,,+$G(%SetOpDepth(pKey))+1,$$$dsCurrentMethod _ " (3)")
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",+pNodeNo) = ""
					Set tReturnedChildren(pNodeNo) = ""
					
					// DTB605 - Move the previous node to the end of this chain.
					// This will connect the transplanted child to the new "ortuple" node as its parent.
					Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,pNodeNo,tChildNode)
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tChildNode)
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)

					// Set the tChildNode as the last child of the pSet which is the pointer to the copy just completed. This will trigger an
					// examination of entire length of the chain.
					Set tChildNode = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",""),-1)
					
					Set pNewNodeNo = pNodeNo
					Set tLastChild = pNodeNo
				}

				If ((tBranchNo>1)&&(tLastChild'="")) {
					If (tHasOrTuples && ($LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode),1)'="ortuple")) {
						// DP-424589 - insert "ortuple" node. The depth of this is set as 1 greater than the current depth to indicate it is 
						// an argument of the current set.
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $lb("ortuple",0,0,tLastChild,,+$G(%SetOpDepth(pKey))+1)
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tLastChild,"ch",+pNodeNo) = ""
						
						// DTB605 - Move the previous node to the end of this chain.
						// This will connect the transplanted child to the new "ortuple" node as its parent.
						Set tSC = ..%CopyNode(pCubeIndex,pKey,.pNodeNo,pNodeNo,tChildNode)
						If $$$ISERR(tSC) Quit
						Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tChildNode)
						If $$$ISERR(tSC) Quit
						Set tChildNode = pNodeNo
						
						Set pNewNodeNo = pNodeNo
						If $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1,"all",tLastChild)) {
							Set %leafCount = %leafCount - 1
							Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1,"all",tLastChild)
						}
						// clear compute and visible flags
						Set $$$dsAxisNodeCompute($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tLastChild))=0
						Set $$$dsAxisNodeVisible($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tLastChild))=0
						
						Set tLastChild = pNodeNo
					}
					Else {
						// connect this branch to prior branch
						Set $$$dsAxisNodeParent($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode)) = +tLastChild
						Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tLastChild,"ch",+tChildNode) = ""
						Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",tChildNode)
						If $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1,"all",tLastChild)) {
							Set %leafCount = %leafCount - 1
							Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1,"all",tLastChild)
						}
						// clear compute and visible flags
						Set $$$dsAxisNodeCompute($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tLastChild))=0
						Set $$$dsAxisNodeVisible($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tLastChild))=0
					}
				}

				While (tChildNode'="") {
					// next child
					Set tLastChild = tChildNode
					Set tNextChild = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode,"ch",""))
					If (tNextChild'="") {
						Set tLastChild = tNextChild

						// set compute flag to 0
						Set $$$dsAxisNodeCompute($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode))=0

						// JMD762: force visible to false
						Set $$$dsAxisNodeVisible($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode))=0

						// DP-424589 - Set tuple to ortuple if the depth indicates the tuple was created as an argument to the current function
						If ($$$dsAxisNodeType($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode))="tuple") &&
							($$$dsAxisNodeSetOpDepthGet($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode))>%SetOpDepth(pKey)) {
							Set $$$dsAxisNodeType($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNode))="ortuple"
						}

						// JMD792: remove node from "all" list
						If $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1,"all",tChildNode)) {
							Set %leafCount = %leafCount - 1
							Kill $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",1,"all",tChildNode)
						}
					}
					Set tChildNode = tNextChild
				}
				Set tTopChildNode = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch",tTopChildNode))
			}

			If ($LG($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet),1)="orset") && '$D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet,"ch")) {
				// DP-423012 - Children might have been removed when checking the intersections. Replace the orset with a literal null
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pSet) = $$$DeepSeeNullAxisNode(pParent)
				Quit
			}
		}

		// JMD1453 we need this so that tuple(%OR,%OR) builds the correct graph
		// DTB605 - Do this for tuple chains as well
		// DTB974 - Use the tHasTuple flag instead of the [now generic] counter to identify presence of a proper tuple
		If (tGroupCount>1)||+$G(tHasTuple) {
			Set pNodeNo = tLastChild		// DTB425 - make sure the final node is the one reported
			Set pNewNodeNo = pNodeNo
			// DTB248 - In an orset, flag the final node as visible
			Set tSC = ..%HideNode(pCubeIndex,pKey,%axis,tLastChild,1)
		}

		Do $I(%SetOpDepth(pKey),-1)		// DP-424589
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Implementation of the %TERMLIST/%LOOKUP function.<br/>
/// Create a set from the elements within the given termlist.<br/>
/// If <var>pFlag</var> is "EXCLUDE", create a tuple of %NOT members.
Method TermList(pCube As %String, pCubeIndex As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pTermList As %String, pFlag As %String = "", pTermKey As %String = "", pField As %String = "", pDefaultValue As %String = "") As %Status [ Internal ]
{
	// JMD887
	Set tSC = $$$OK
	Try {
		If (pTermList="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing argument for %TERMLIST")
			Quit
		}

		If (pFlag="EXCLUDE") {
			Set tExclude = 1
			// create a tuple to wrap the termlist
			Set tInfo = $LB("tuple",0,0,pParent,,+$G(%SetOpDepth(pKey)))		// DP-424589 - Add depth to tuple
		}
		Else {
			Set tExclude = 0
			// create a set to wrap the termlist
			Set tInfo = $LB("set",0,0,pParent)
		}

		// get contents of termlist
		If (pTermKey'="") {
			// JMD1062: lookup specific key
			Set tSingleValue = 1
			Set tArray(pTermKey) = ##class(%DeepSee.TermList).%Lookup(pTermList,pTermKey,pField,pDefaultValue)
		}
		Else {
			Set tSingleValue = 0
			Set tSC = ##class(%DeepSee.TermList).%GetValueArray(pTermList,.tArray)
			If $$$ISERR(tSC) Quit
		}

		// if termlist does not exist or is empty, then return a member that does nothing
		If ('$D(tArray)) {
			Set tInfo = $lb("mbr",1,1,pParent,"","")
		}

		// add node to axis
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tInfo
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set tSetNodeNo = pNodeNo
		Set pNewNodeNo = pNodeNo

		// note use of termlist in this axis (even if the termlist does not exist!)
		Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"termlist",$$$UPPER(pTermList)) = $G(^DeepSee.TermList($$$UPPER(pTermList),"modDate"))

		If ('$D(tArray)) {
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
			Set leaf = $I(%leafCount)
			Quit
		}

		// process array
		Set tName = $O(tArray(""))
		While (tName'="") {
			Set tNextName = $O(tArray(tName))
			Set tSpec = $ZSTRIP(tArray(tName),"<>W")	// DTB091

			// process spec, add resulting node to axis
			Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(pCube,tSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec,.tSpecInfo)
			If ($$$ISERR(tSC)||(tSingleValue&&(tSpec=""))) {
				If (tSingleValue) {
					// JMD1062: not a member--treat as literal
					Set tSC = $$$OK
					
					// Create literal node with value
					Set tInfo = $LB("lit",1,1,tSetNodeNo,tName,tSpec)

					// add node to set
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tInfo
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tSetNodeNo,"ch",pNodeNo) = ""
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
					Set leaf = $I(%leafCount)
					Quit
				}
				Else {
					// error
					Quit
				}
			}

			Set tExists = ##class(%DeepSee.Query.member).%GetNodeInfo(pCube,tDimNo, tHierNo, tLevelNo, .tFact)
			If ('tExists) {
				Set tSC = $$$ERROR($$$GeneralError,"Invalid dimension reference in %TERMLIST: "_tSpec)
				Quit
			}

			// JMD904: Do we have a member key or a name?
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tSpec,,,.tKeyInfo)
			If $$$ISERR(tSC) Quit

			If +$G(tKeyInfo(4)) {
				Set tIsKey = 1
				Set tMemberKey = $G(tSpecInfo(4))
			}
			Else {
				Set tIsKey = 0
				Set tMemberKey = ""
			}

			// JMD904: find provider for the member
			Set tSC = ..%ConstructMemberProvider(pCube,tDimNo,tHierNo,tLevelNo,.tMemberProvider,tMemberKey)
			If $$$ISERR(tSC) Quit

			If ('tIsKey) {
				// lookup key for name
				Set tSC = tMemberProvider.%FindMemberByName($G(tSpecInfo(4)),tDimNo,tHierNo,.tIsMember,tLevelNo,.tMemberKey)
				If $$$ISERR(tSC) Quit
				Set tMemberProvider.%name = tName
				Set tMemberProvider.%memberId = tMemberKey
			}
			Else {
				Set tMemberProvider.%name = tName
			}
			Set tSC = tMemberProvider.%ProcessMembers(tSetNodeNo,.tSet)
			If $$$ISERR(tSC) Quit
			
			// tSet(1) = $LB(type,visible,calc,parent,value,key,fact,agg,dim,hier,level)
			Set tInfo = $G(tSet(1))

			If (tExclude) {
				// use NOT operator
				Set tMemberId = $LG(tInfo,6)
				Set:tMemberId'="" $List(tInfo,6) = "!"_tMemberId
				Set tVisible = $S(tNextName="":1,1:0)
				Set $List(tInfo,2) = tVisible

				// add node to tuple
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tInfo
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tSetNodeNo,"ch",pNodeNo) = ""
				Set tSetNodeNo = pNodeNo
				If (tNextName="") {
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
					Set leaf = $I(%leafCount)
				}
			}
			Else {
				// add node to set
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = tInfo
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tSetNodeNo,"ch",pNodeNo) = ""
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)
			}

			// next
			Set tName = tNextName
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Test to see whether this is an oredring function that might require special processing
Method %IsOrderingFunction(pFunctionName = "") As %Boolean
{
	// Method added by DTB260
	Set tIsOrderingFunction = 0
	// DTB314 - Allow argumentless call for testing current object
	Set tFunctionName = $$$UPPER($S(pFunctionName'="":pFunctionName,1:..function))
	Try {
		Set tIsOrderingFunction = $Case(tFunctionName,
					"ORDER":1,
					"TOPCOUNT":1,
					"BOTTOMCOUNT":1,
					"TOPPERCENT":1,
					"BOTTOMPERCENT":1,
					"TOPSUM":1,
					"BOTTOMSUM":1,
					:0)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		Set tIsOrderingFunction = 0
	}
	Quit tIsOrderingFunction
}

/// Search out the AND/OR depth in a particular node
ClassMethod AnalyzeORNode(pQueryNode = {$$$NULLOREF}, ByRef pStructure = 0, pDepth = 0, pParent = 0, pMaxDepth = 0) As %Status
{
	// Method added by DTB700
	Set tSC = $$$OK
	
	Try {
		// Check the incoming parameters to make sure we can properly recurse into the children of this object
		If pQueryNode=$$$NULLOREF {
			Quit
		}
		If '$D(pStructure) {
			Set pStructure = 0
		}

		If 'pParent {
			// Initialize these variables if this is not a recursive call
			Set pDepth = 0
			Set pMaxDepth = 0
			If '(pQueryNode.%IsA("%DeepSee.Query.setFunction")&&(pQueryNode.function="%OR")) {
				// This will only support a %OR node for the intial call
				Quit
			}
		}

		// Test the current object 
		Set tCurrentOperator = ""
		If pQueryNode.%IsA("%DeepSee.Query.tuple") || (pQueryNode.%IsA("%DeepSee.Query.setFunction")&&(pQueryNode.function["CROSSJOIN")){
			// Add an AND node
			Set tCurrentOperator = "AND"
		}
		ElseIf pQueryNode.%IsA("%DeepSee.Query.setFunction")&&(pQueryNode.function="%OR") {
			// Add an OR node
			Set tCurrentOperator = "OR"
		}
		
		If tCurrentOperator'="" {
			Set pStructure($I(pStructure)) = tCurrentOperator
			Set pStructure(pStructure,"depth") = $I(pDepth)
			If pParent {
				Set pStructure(pParent,"ch",pStructure) = ""
			}
		}
		
		If pDepth>pMaxDepth {
			// Preserve the maximum depth encountered
			Set pMaxDepth = pDepth
		}

		// %DeepSee.Query.group defines the "children" property. If this node is a group, search
		// its children
		Set tChildCount = $S(pQueryNode.%IsA("%DeepSee.Query.group"):pQueryNode.children.Count(),1:0)
		Set tCurrNode = pStructure		// Note the parent depth before processing children
		For n = 1:1:tChildCount {
			Set tChildNode = pQueryNode.children.GetAt(n)
			Set tDepthIn = pDepth		// Store current depth before child analysis
			Set tSC = ..AnalyzeORNode(tChildNode,.pStructure,.pDepth,tCurrNode,.pMaxDepth)
			Set pDepth = tDepthIn		// Return depth after analyzing child
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Transform a crossjoin structure to be used within an established orset. The results will be 
/// the appropriate ortuple construct situated in the same position as the <var>pCJRootNo</var> 
/// reference node when this method was called. 
/// The incoming <var>pNodeNo</var> is expected to be the final node in the axis, and will 
/// be returned as the next available node after the transform.
/// The <var>pParent</var> is the node this entire construct should ultimately be filed under.
ClassMethod ORizeCrossJoin(pCubeIndex As %String, pKey As %String, pCJRootNo As %Integer = "", ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pCJRootParent As %Integer, ByRef pNewCJRootNo As %Integer = 0) As %Status [ Internal ]
{
	// Method rewritten by DP-423012
	Set tSC = $$$OK
	
	Try {
		// Change nothing if a direct reference is not supplied
		If pCJRootNo = "" Quit
		
		Set pNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",""),-1)		// Always reset pNodeNo to the final available node

		// This will be constant for every tuple added to the current chain.
		Set tCJRootNode = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pCJRootNo)
		Set tNodes(pCJRootNo) = tCJRootNode
		Set tCJRootFact = $$$dsAxisNodeFactGet(tCJRootNode)
		Set tCJRootKey = $$$dsAxisNodeKeyGet(tCJRootNode) 

		Do $I(%SetOpDepth(pKey))		// DP-424589
	
		// COLLECTION PHASE
		// Loop through children to establish the relevant tuples, diving down to the leaves of nested "mbr" nodes. There are at least the same number of tuples as (<# immediate children> - <# of non intersecting children>)
		// set as the ortuple replacement for the CJ siblings.
		Set tChains = 0		// Array to accumulate the child chains. The top node will be the number of total chains
		Set tChildCount = 0
		Set tLastChainNo = pCJRootNo
		Set tCJChildNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pCJRootNo,"ch",""))
		While (tCJChildNo'="") {
			Set tCJChildNode = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tCJChildNo)
			Set tCJChildFact = $$$dsAxisNodeFactGet(tCJChildNode)
			Set tCJChildKey = $$$dsAxisNodeKeyGet(tCJChildNode)

			// Take the opportunity to test for an intersection. If the current child has no intersection with the primary node,
			// there is no point in adding it to this axis.
			If '$$$dsAxisNodeIsSetOp(tCJRootNode) && '$$$dsAxisNodeIsSetOp(tCJChildNode) && 
					(tCJRootFact'="") && (tCJRootKey'="") &&
					'##class(%DeepSee.Query.Engine).%IntersectExists(pCubeIndex,tCJRootFact,tCJRootKey,tCJChildFact,tCJChildKey) {
				Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tCJChildNo)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)

				Set tCJChildNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pCJRootNo,"ch",tCJChildNo))
				Continue
			}
		
			// Depth search for a full chain to define a tuple
			// Need to account for "mbr", "orset", and "ortuple" nodes
			Set tChildNo = tCJChildNo
			Set tChain = ""
			Set tChStack = []
			Set tDir = 1		// Direction: 1 is descend, -1 is ascend. Add to the current chain only on descent
			Do {

				Set tGChildNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNo,"ch",""))

				If (tGChildNo'="") {
					Set tGChildNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tGChildNo))
					Set tGChildFact = $$$dsAxisNodeFactGet(tGChildNode)
					Set tGChildKey = $$$dsAxisNodeKeyGet(tGChildNode)

					// NB: %Intersect test is removed since it is inappropriate to call %DeleteNode on a chain link that is embedded in an arbitrary chain
					// of AND/OR set operations of arbitrary depth.

					// There is more chain to accumulate. The tDir indicates whether this has popped back up 
					Set:(tDir>0) tChain = tChain _ $LB(tChildNo)
					Do tChStack.%Push(tChain)

					Set tChildNo=tGChildNo,tChildNode=tGChildNode,tDir=1
				}
				Else {	
					// This is the end of a chain if currently descending
					Set:(tDir>0) tChains($I(tChains)) = tChain _ $LB(tChildNo)
					
					// This node has no more children and has been logged, remove it
					If $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNo)) {
						Set tNodes(tChildNo) = $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChildNo)
						Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,tChildNo)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					}

					Set tChain = tChStack.%Pop()
					Set tChildNo = $LG(tChain,*),tDir=-1
				}

			} While (tChildNo'="")

			Set tCJChildNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pCJRootNo,"ch",tCJChildNo))
		}

		// WRITING PHASE
		// There is now a collection of information needed to write these back out:
		// - tNodes contains all the nodes that were involved
		// - tChains contains the tuple organization, all to be added to the top node
		// - pCJRootNo is the node that should have its full branch be replaced by a chain of "ortuple" nodes according to the chain
		If tChains {
			Set tChainParent = pCJRootParent		// Initialize chain parent

			Set (tChainID,tFirst) = $O(tChains(""),1,tChain)
			While tChainID'="" {	
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",$I(pNodeNo)) = $lb("ortuple",0,0,tChainParent,,+$G(%SetOpDepth(pKey)),$$$dsCurrentMethod)
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tChainParent,"ch",pNodeNo) = ""
				Set:(tChainID=tFirst) pNewCJRootNo = pNodeNo

				// Every chain in this set will start with the pCJRootNo
				Set tCurrNode = tCJRootNode
				set $LI(tCurrNode,4) = pNodeNo
				// DP-429168 - Add one to every set op depth in the chain
				Set:$$$dsAxisNodeIsSetOp(tCurrNode) $$$dsAxisNodeSetOpDepth(tCurrNode) = $$$dsAxisNodeSetOpDepthGet(tCurrNode) + 1
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",$I(pNodeNo)) = ""
				Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo) = tCurrNode

				For n=1:1:$LL(tChain) {
					Set tCurrNode = tNodes($LG(tChain,n))
					// DP-429168 - Add one to every set op depth in the chain
					Set:$$$dsAxisNodeIsSetOp(tCurrNode) $$$dsAxisNodeSetOpDepth(tCurrNode) = $$$dsAxisNodeSetOpDepthGet(tCurrNode) + 1
					
					set $$$dsAxisNodeParent(tCurrNode) = pNodeNo
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo,"ch",$I(pNodeNo)) = ""
					Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNodeNo) = tCurrNode
				}

				Set tChainParent = pNodeNo
				Set tChainID = $O(tChains(tChainID),1,tChain)
			}

			If $D($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pCJRootNo)) {
				Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pCJRootNo)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			}

			// Set the new final 
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
			Do $I(%leafCount)
		}
		Else {
			Set tSC = ..%DeleteNode(pCubeIndex,pKey,%axis,pCJRootNo)
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)

			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pCJRootNo) = $$$DeepSeeNullAxisNode(pCJRootParent)
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pCJRootParent,"ch",pCJRootNo) = ""
			//Set pNodeNo = pCJRootNo
			Set $$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",%axis,"all",pCJRootNo) = ""
		}

		Do $I(%SetOpDepth(pKey),-1)		// DP-424589
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

}
