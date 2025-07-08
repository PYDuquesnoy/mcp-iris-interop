/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// This class contains methods that can be used to
/// construct common tree structures for use with the 
/// <class>%ZEN.Component.dynaTree</class> component.
Class %ZEN.TreeUtils Extends %RegisteredObject [ Deprecated, System = 2 ]
{

Parameter DOMAIN = "%ZEN";

/// Create a tree based on the packages and classes visible in the
/// current namespace.<br/>
/// Each node has a value with a ".pkg" or ".cls" suffix.<br/>
/// <var>pRoot</var> is "" when called for the top-level. Otherwise
/// it contains the package name of the parent node.<br/>
/// <var>pParms</var> can contain the following:<br/>
/// pParms("system") = 0 | 1  control whether % items are displayed.<br/>
ClassMethod ClassTree(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSystem = +$G(pParms("system"))
	Set tMask = $ZCVT($G(pParms("mask")),"U")
	Set tProperties = +$G(pParms("properties"))  // show properties

	If (pRoot = "") {
		Set n = 1
		Set tCurrPkg = ""

		#; return top-level packages
		Set tKey = $O(^rINDEXCLASS(""))
		While (tKey '= "") {
			If (tSystem||($E(tKey,1,1)'="%")) {
				If ((tMask="")||($E(tKey,1,$L(tMask))=tMask)){
					Set tClass = $LG(^rINDEXCLASS(tKey),2)
					Set tPkg = $P(tClass,".",1)
					If (tPkg '= tCurrPkg) {
						Set tCurrPkg = tPkg
						Set pTree(n) = $LB(tPkg,tPkg_".pkg",1)
						Set pTree(0,"ch",n) = ""
						Set n = n + 1
					}
				}
			}
			Set tKey = $O(^rINDEXCLASS(tKey))
		}
	}
	Else {
		#; pRoot is parent package; check extension
		Set tExt = $P(pRoot,".",$L(pRoot,"."))
		Set pRoot = $P(pRoot,".",1,$L(pRoot,".")-1)

		If (tExt = "pkg") {
			Set n = 1
			Set tCurrPkg = ""
			Set tLevel = $L(pRoot,".")
	
			#; find packages and classes within pRoot (at this level)
			Set tKey = $O(^rINDEXCLASS($ZCVT(pRoot,"U")))
			While (tKey '= "") {
				If ((tMask="")||($E(tKey,1,$L(tMask))=tMask)){
					Set tClass = $LG(^rINDEXCLASS(tKey),2)
					If (pRoot '= $P(tClass,".",1,tLevel)) {
						#; we've moved on to the next top-level package
						Quit
					}
					Set tName = $P(tClass,".",tLevel+1)
					Set tPkg = $P(tClass,".",1,tLevel+1)
					If (tPkg = tClass) {
						#; this is a class name
						Set pTree(n) = $LB(tName,tClass_".cls",tProperties)
						Set pTree(0,"ch",n) = ""
						Set n = n + 1
					}
					ElseIf (tPkg '= tCurrPkg) {
						Set tCurrPkg = tPkg
						Set pTree(n) = $LB(tName,tPkg_".pkg",1)
						Set pTree(0,"ch",n) = ""
						Set n = n + 1
					}
				}
				Set tKey = $O(^rINDEXCLASS(tKey))
			}
		}
		ElseIf (tExt = "cls") {
			Quit ..PropertyTree(pRoot,.pTree,.pParms)
		}
	}
	Quit $$$OK
}

/// Return the set of properties within a given class.
ClassMethod PropertyTree(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Set tClass = pRoot
	If (tClass '= "") {
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.MemberSummary")
		Set tSC = tRS.%Execute(tClass,"a")
		Set n = 1
		While (tRS.Next()) {
			Set tName = tRS.Data("Name")
			Set pTree(n) = $LB(tName,tClass_":"_tName,0)
			Set pTree(0,"ch",n) = ""
			Set n = n + 1
		}
	}

	Quit tSC
}

/// Create a tree containing time periods.<br/>
/// The contents of the tree are specified by values within the <var>pParms</var>
/// array:<br/>
/// pParms("spec") - A comma-delimited list that controls the hierarchy of time
/// periods. This can contain Y(ear), Q(uarter), M(onth), W(eek), D(ay). For example:
/// "Y,Q,M" will show years, quarters, and months. 
/// <br/>
/// The time period of the tree can be controlled using:<br/>
/// pParms("startYear") - starting year for year periods (default is current year)<br/>
/// pParms("endYear") - end year for year periods (default is startYear)<br/>
/// pParms("startMonth") - starting month (1-12) for month periods (default is 1)<br/>
/// pParms("endMonth") - ending month (1-12) for month periods (default is 12)<br/>
/// pParms("startQuarter") - starting quarter (1-4) for quarter periods (default is 1)<br/>
/// pParms("endQuarter") - ending quarter (1-4) for quarter periods (default is 4)<br/>
/// pParms("startWeek") - starting week (1-52) for week periods (default is 1)<br/>
/// pParms("endWeek") - ending week (1-52) for week periods (default is 52)<br/>
/// pParms("startDay") - starting day for day periods (default is 1)<br/>
/// pParms("endDay") - ending day for day periods. Interpretation of this value depends on how days are displayed (yearly, weekly, etc.) <br/>
/// <br/>
/// When years are not displayed, the startYear is used to provide the
/// year portion of date values.<br/>
/// The logical value of nodes an indicator followed ODBC format date:<br/>
/// "Y 2007", "M 2007-03", etc.<br/>
/// For weeks and quarters the starting month or day of the period is used.
/// <br/>
/// Weeks are not supported at this time.
ClassMethod TimePeriodTree(pRoot As %String, Output pTree, ByRef pParms, pTopNode As %Integer = 0) As %Status
{

#; right justify to 2 places
#define RJ2(%val) $TR($J(%val,2)," ","0")

	Set tSpec = $G(pParms("spec"))
	Set:tSpec="" tSpec = "Y"
	Set tStartYear = +$G(pParms("startYear"))
	Set tEndYear = +$G(pParms("endYear"))
	Set tStartQuarter = +$G(pParms("startQuarter"),1)
	Set tEndQuarter = +$G(pParms("endQuarter"),4)
	Set tStartMonth = +$G(pParms("startMonth"),1)
	Set tEndMonth = +$G(pParms("endMonth"),12)
	Set tStartWeek = +$G(pParms("startWeek"),1)
	Set tEndWeek = +$G(pParms("endWeek"),52)
	Set tStartDay = +$G(pParms("startDay"),1)
	Set tEndDay = $G(pParms("endDay")) 	// special case=""

	Set:tStartYear=0 tStartYear = +$ZDT($H,3)
	Set:tStartYear<1900 tStartYear = 1900
	Set:tStartQuarter<=0 tStartQuarter = 1
	Set:tStartMonth<=0 tStartMonth = 1
	Set:tStartWeek<=0 tStartWeek = 1
	Set:tStartDay<=0 tStartDay = 1

	Set:(tEndYear < tStartYear) tEndYear = tStartYear
	Set:(tEndQuarter < tStartQuarter) tEndQuarter = tStartQuarter
	Set:(tEndMonth < tStartMonth) tEndMonth = tStartMonth
	Set:(tEndWeek < tStartWeek) tEndWeek = tStartWeek

	#; date context
	Set tYearVal = tStartYear
	Set tMonthVal = 1

	Set tParent = pTopNode
	Set tNode = pTopNode
	Set tDepth = $L(tSpec,",")
	For tLevel = 1:1:tDepth {
		Set tType(tLevel) = $E($P(tSpec,",",tLevel),1,1)
		Set tFormat = $E($P(tSpec,",",tLevel),2,*)
		If (tLevel = 1) {
			If (tType(tLevel) = "Q") {
				Do Quarters(tStartQuarter,tEndQuarter)
			}
			ElseIf (tType(tLevel) = "M") {
				Do Months(tStartMonth,tEndMonth)
			}
			ElseIf (tType(tLevel) = "W") {
				Do Weeks(tStartWeek,tEndWeek)
			}
			ElseIf (tType(tLevel) = "D") {
				Do YearDays(tStartDay,tEndDay)
			}
			ElseIf (tType(tLevel) = "Y") {
				Do Years(tStartYear,tEndYear)
			}
		}
		ElseIf (tLevel = 2) {
			Set n = 0
			Set tParent = $O(pTree(pTopNode,"ch",""))
			While (tParent '= "") {
				Set tParentVal = $LG(pTree(tParent),2)
				If ($E(tParentVal) = "Y") {
					Set tYearVal = $P(tParentVal," ",2)
					Set tMonthVal = 1
				}
				ElseIf ($E(tParentVal) = "M") {
					Set tYearVal = +$P(tParentVal," ",2)
					Set tMonthVal = +$P(tParentVal,"-",2)
				}
				ElseIf ($E(tParentVal) = "Q") {
					Set tYearVal = +$P(tParentVal," ",2)
					Set tMonthVal = +$P(tParentVal,"-",2)
				}

				Set n = n + 1
				If (tType(tLevel) = "Q") {
					Do Quarters(tStartQuarter,tEndQuarter)
				}
				ElseIf (tType(tLevel) = "W") {
					If (tType(1) = "Q") {
						Do Weeks(((n-1)*13)+1,((n-1)*13)+13)
					}
					Else {
						Do Weeks(tStartWeek,tEndWeek)
					}
				}
				ElseIf (tType(tLevel) = "D") {
					If (tType(1) = "W") {
						Do WeekDays()
					}
					ElseIf (tType(1) = "M") {
						Do MonthDays(tStartDay,tEndDay)
					}
					ElseIf (tType(1) = "Y") {
						Do YearDays(tStartDay,tEndDay)
					}
				}
				ElseIf (tType(tLevel) = "M") {
					If (tType(1) = "Q") {
						Do Months(((n-1)*3)+1,((n-1)*3)+3)
					}
					ElseIf (tType(1) = "Y") {
						Do Months(tStartMonth,tEndMonth)
					}
				}
				Set tParent = $O(pTree(pTopNode,"ch",tParent))
			}
		}
		ElseIf (tLevel = 3) {
			Set t1 = $O(pTree(pTopNode,"ch",""))
			While (t1 '= "") {
				Set n = 0
				Set tParent = $O(pTree(t1,"ch",""))
				While (tParent '= "") {
					Set tParentVal = $LG(pTree(tParent),2)
					If ($E(tParentVal) = "Y") {
						Set tYearVal = $P(tParentVal," ",2)
						Set tMonthVal = 1
					}
					ElseIf ($E(tParentVal) = "M") {
						Set tYearVal = +$P(tParentVal," ",2)
						Set tMonthVal = +$P(tParentVal,"-",2)
					}
					ElseIf ($E(tParentVal) = "Q") {
						Set tYearVal = +$P(tParentVal," ",2)
						Set tMonthVal = +$P(tParentVal,"-",2)
					}

					Set n = n + 1
					If (tType(tLevel) = "Q") {
						#; error
					}
					ElseIf (tType(tLevel) = "W") {
						If (tType(2) = "Q") {
							Do Weeks(((n-1)*13)+1,((n-1)*13)+13)
						}
						ElseIf (tType(2) = "M") {
							Do Weeks(1,4) // !!!
						}
					}
					ElseIf (tType(tLevel) = "D") {
						If (tType(2) = "W") {
							Do WeekDays()
						}
						ElseIf (tType(2) = "M") {
							Do MonthDays(tStartDay,tEndDay)
						}
					}
					ElseIf (tType(tLevel) = "M") {
						If (tType(2) = "Q") {
							Do Months(((n-1)*3)+1,((n-1)*3)+3)
						}
					}
					Set tParent = $O(pTree(t1,"ch",tParent))
				}
				Set t1 = $O(pTree(pTopNode,"ch",t1))
			}
		}
	}
	Quit $$$OK

Years(start,end)
	For tYear = start:1:end {
		Set tNode = $I(pTree)
		Set pTree(tNode) = $LB(tYear,"Y "_tYear,tDepth>tLevel,"",0,,tYear)
		Set pTree(tParent,"ch",tNode) = ""
	}
	Quit

Quarters(start,end)
	For q = start:1:end {
		Set tNode = $I(pTree)
		Set tVal = tYearVal _ "-"_$$$RJ2(((q-1)*3)+1)
		Set pTree(tNode) = $LB("Q"_q,"Q "_tVal,tDepth>tLevel,"",0,,tVal)
		Set pTree(tParent,"ch",tNode) = ""
	}
	Quit

Weeks(start,end)
	For w = start:1:end {
		Set tNode = $I(pTree)
		Set pTree(tNode) = $LB("W"_$$$RJ2(w),"W "_w,tDepth>tLevel,"",0,,"")
		Set pTree(tParent,"ch",tNode) = ""
	}
	Quit

DaysInMonth(y,m)
	Quit $Case(m,1:31,2:$S($$IsLeapYear(y):29,1:28),3:31,4:30,5:31,6:30,7:31,8:31,9:30,10:31,11:30,12:31,:0)
DaysInYear(y)
	Quit $Case($$IsLeapYear(y),1:366,:365)

IsLeapYear(y)
	If ((y#4) = 0) {
		If '(((y#100) = 0) && ((y#400) '= 0)) {
			Quit 1
		}
	} 
	Quit 0


YearDays(start,end)
	Set tYearH = $ZDTH(tYearVal_ "-01-01",3)
	Set dy = $$DaysInYear(tYearVal)
	Set:(end="")||(end>dy) end=dy
	For d = start:1:end {
		Set tNode = $I(pTree)
		Set tVal = $ZDT(tYearH+d-1,3)
		Set pTree(tNode) = $LB(d,"D "_tVal,tDepth>tLevel,"",0,,tVal)
		Set pTree(tParent,"ch",tNode) = ""
	}
	Quit

WeekDays()
	For d = 1:1:7 {
		#; !!!
		Set tNode = $I(pTree)
		Set pTree(tNode) = $LB($$WeekDayName(d),d,tDepth>tLevel,"",0,,"")
		Set pTree(tParent,"ch",tNode) = ""
	}
	Quit

MonthDays(start,end)
	Set dm = $$DaysInMonth(tYearVal,tMonthVal)
	Set:(end="")||(end>dm) end=dm
	For d = start:1:end {
		Set tNode = $I(pTree)
		Set tVal = tYearVal_"-"_$$$RJ2(tMonthVal)_"-"_$$$RJ2(d)
		Set pTree(tNode) = $LB(d,"D " _ tVal,tDepth>tLevel,"",0,,tVal)
		Set pTree(tParent,"ch",tNode) = ""
	}
	Quit

Months(start, end)
	For m = start:1:end {
		Set tNode = $I(pTree)
		Set tText = $Case(tFormat,"#":m,"mmm":$$MonthName3(m),"mm":$$MonthName2(m),"m":$$MonthName1(m),:$$MonthName(m))
		Set tVal = tYearVal_"-"_$$$RJ2(m)
		Set pTree(tNode) = $LB(tText,"M " _ tVal,tDepth>tLevel,"",0,,tVal)
		Set pTree(tParent,"ch",tNode) = ""
	}
	Quit
MonthName(m)
	Quit $P($ZDT($ZDTH("2008-"_$$$RJ2(m)_"-01",3),9)," ",1)
MonthName1(m)
	Quit $E($ZDT($ZDTH("2008-"_$$$RJ2(m)_"-01",3),5),1,1)
MonthName2(m)
	Quit $E($ZDT($ZDTH("2008-"_$$$RJ2(m)_"-01",3),5),1,2)
MonthName3(m)
	Quit $E($ZDT($ZDTH("2008-"_$$$RJ2(m)_"-01",3),5),1,3)
WeekDayName(d)
	Quit $P($ZDT($ZDTH("2008-01-"_$$$RJ2(5+d),3),11)," ")
}

/// This is an internal method used for testing.<br/>
/// Take a $List containing a nested set of node names
/// and create a tree from it that
/// can be used as an AXIS definition:<br/>
/// The list is of the form: $LB(parent,children,parent,children)
/// where *children* is a list of child nodes, if any.
/// For example:<br/>
/// $LB("Node1","Node2",)<br/>
/// $LB("Fruit",$LB("Apple","Banana"))
ClassMethod %BuildTreeFromList(pList As %List, ByRef pTree, pTopNode As %Integer = 0) [ Internal ]
{
	For n = 1:1:$LL(pList) {
		Set tItem = $LG(pList,n)
		Set tChildren = $LG(pList,n+1)
		Set tHasChildren = (tChildren'="")&&$ListValid(tChildren)
		If (tHasChildren) {
			Set n = n + 1 // skip children next time around
		}

		#; allocate node #, insert into tree and parent list
		Set tNode = $I(pTree)

		#; each node supplies: $LB(caption, value, hasChildren, link, expanded, icon)
		Set pTree(tNode) = $LB(tItem,tItem,tHasChildren)
		Set pTree(pTopNode,"ch",tNode) = ""

		#; insert children
		If (tHasChildren) {
			Do ..%BuildTreeFromList(tChildren, .pTree, tNode)
		}
	}
}

}
