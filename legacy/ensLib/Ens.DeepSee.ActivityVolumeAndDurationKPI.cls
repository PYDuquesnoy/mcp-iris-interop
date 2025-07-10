/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// For dashboard Ens.DeepSee.ActivityVolumeAndDuration.
Class Ens.DeepSee.ActivityVolumeAndDurationKPI Extends %DeepSee.KPI [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter RESOURCE = "%Ens_Dashboard";

XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
<kpi xmlns="http://www.intersystems.com/deepsee/kpi"
 name="Ens/DeepSee/ActivityVolumeAndDurationKPI"
 sourceType="manual"
 caption="Activity Volume And Duration"
>
<property name="Name"/>
<property name="Site Dimension"/>
<property name="Total Count"/>
<property name="Count Trend"/>
<property name="Est. Min. Duration"/>
<property name="Est. Max. Duration"/>
<property name="Avg. Duration"/>
<property name="Duration Sum Squared"/>
<property name="Std. Deviation"/>
<property name="Std. Deviation 2"/>
<property name="Duration Trend"/>
<property name="Avg. Queue Time"/>
<property name="Queue Trend"/>
<filter name="Period" displayName="Period of Time" valueList="Minute,Hour,Day,Week,Month,Year" displayList="Minute,Hour,Day,Week,Month,Year" multiSelect="false"/>
<filter name="Instance" displayName="Instance" sql="SELECT DISTINCT Instance FROM Ens_Activity_Data.Days" multiSelect="false"/>
<filter name="Namespace" displayName="Namespace" sql="SELECT DISTINCT Namespace FROM Ens_Activity_Data.Days" multiSelect="false"/>
<filter name="SiteDimension" displayName="Site Dimension" sql="SELECT DISTINCT SiteDimension FROM Ens_Activity_Data.Days" multiSelect="false"/>
<filter name="SortBy" displayName="Sort by" valueList="Name,Total Count,Avg. Duration,Avg. Queue Time" displayList="Name,Total Count,Avg. Duration,Avg. Queue Time" defaultValue="Name" multiSelect="false" />
</kpi>
}

Method %OnLoadKPI() As %Status
{
	Set scale = ""
	Set instance = ""
	Set sort = "Name"
	Set nspace = ""
	Set dimension = ""
	Try {
		Set filter = ..%filterValues
		If filter.Period'="" {
			Set scale = filter.Period
		}
		If filter.Instance'="" {
			Set instance = filter.Instance
		}
		If filter.SortBy'="" {
			Set sort = filter.SortBy
		}
		If filter.Namespace'="" {
			Set nspace = filter.Namespace
		}
		If filter.SiteDimension'="" {
			Set dimension = $ZSTRIP(filter.SiteDimension,"<>W")
		}
		If dimension = $C($ZH("FFFD")) Set dimension = ""
		// Calculate high value UTC timestamp of the current time slot
		// (not to be included in the calculations as it is incomplete)
		// and base timestamp for delimiting period of time
		Do ..GetPeriod(scale, .low, .high, .base)
		
		// Initialize based on chosen time scale
		Kill ^||ISC.Ens.ActivityCounters
		Kill ^||ISC.Ens.ActivityBuckets
		Kill ^||ISC.Ens.Activitydata
		Kill ^||ISC.Ens.Activitysorted
		Kill ^||ISC.Ens.Activitytemp
		
		If scale="Minute" {
			Set low = $system.SQL.DATEADD("s",-50,base)
			Set secs = 0
			For i=1:1:6 {
				Set ^||ISC.Ens.ActivityBuckets($system.SQL.DATEADD("s",secs,base)_"z") = ""
				Set secs = secs-10 // Buckets of 10 seconds each
			}
		}
		ElseIf scale="Hour" {
			Set low = $system.SQL.DATEADD("hh",-1,base)
			Set mins = 0
			For i=1:1:30 {
				Set ^||ISC.Ens.ActivityBuckets($system.SQL.DATEADD("mi",mins,base)_"z") = ""
				Set mins = mins-2 // Buckets of 2 minutes each
			}
		}
		ElseIf scale="Day" {
			Set low = $system.SQL.DATEADD("d",-1,base)
			Set hrs = 0
			For i=1:1:24 {
				Set ^||ISC.Ens.ActivityBuckets($system.SQL.DATEADD("hh",hrs,base)_"z") = ""
				Set hrs = hrs-1 // Buckets of 1 hours each
			}
		}
		ElseIf scale="Week" {
			Set low = $system.SQL.DATEADD("d",-7,base)
			Set days = 0
			For i=1:1:7 {
				Set ^||ISC.Ens.ActivityBuckets($system.SQL.DATEADD("d",days,base)_"z") = ""
				Set days = days-1 // Buckets of 1 day each
			}
		}
		ElseIf scale="Month" {
			Set low = $system.SQL.DATEADD("mm",-1,base)
			Set low = $system.SQL.DATEADD("d",3,low)
			Set days = 0
			For i=1:1:10 {
				Set ^||ISC.Ens.ActivityBuckets($system.SQL.DATEADD("d",days,base)_"z") = ""
				Set days = days-3 // Buckets of 3 days each
			}
		}
		ElseIf scale="Year" {
			Set low = $system.SQL.DATEADD("yy",-1,base)
			Set days = 0
			For i=1:1:52 {
				Set ^||ISC.Ens.ActivityBuckets($system.SQL.DATEADD("d",days,base)_"z") = ""
				Set days = days-7 // Buckets of 1 week each
			}
		}
		Else {
			// "All" or ""
			&sql(SELECT MIN(TimeSlotUTC) into :low from Ens_Activity_Data.Days)
			If SQLCODE {
				Set low = "2001-01-01 00:00:00"
			}
			Set days = 0
			Set tDiffDays = $SYSTEM.SQL.DATEDIFF("d",low,$ZDATETIME($ZTS,3))
			Set nDays = tDiffDays\30 ;30 Buckets			
			For i=1:1:30 {
				Set ^||ISC.Ens.ActivityBuckets($system.SQL.DATEADD("d",days,base)_"z") = ""
				Set days = days-nDays // Buckets depend on oldest.
			}
		}
		Set tClass = $Case(scale,"Minute":"Seconds","Hour":"Seconds","Day":"Hours","Week":"Days","Month":"Days","Year":"Days","All":"Days",:"Days")
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSQL = "SELECT TimeSlot, TimeSlotUTC, HostName, Instance, Namespace, SiteDimension, TotalCount, TotalDuration, TotalDurationSquare, TotalQueueDuration FROM Ens_Activity_Data."_tClass_
										" WHERE TimeSlotUTC >= ? AND TimeSlotUTC <= ?"
		Set tSC = tStatement.%Prepare(tSQL)
		Set tResult = tStatement.%Execute(low,base)
		Set ts = "", name = "", inst = "", count = 0, dur = ""
		
		While tResult.%Next() {
		
		// Loop over all data in the chosen time period, accumulating metrics
			Set tRowKey = $S(instance="":tResult.Instance,1:"")
			Set tRowKey = tRowKey_$S(nspace="":($S(tRowKey'="":":",1:"")_tResult.Namespace),1:"")
			If (tRowKey'="") Set tRowKey = " ("_tRowKey_")"
			Set tRowKey = tResult.HostName_tRowKey
			If (tResult.HostName="Ens.MonitorService")||(tResult.HostName="Ens.ScheduleService")||(tResult.HostName="Ens.ScheduleHandler") Continue
			If (tResult.TimeSlotUTC'="") && ((instance="") || (tResult.Instance=instance)) && ((nspace="") || (tResult.Namespace=nspace)) && ((dimension="") || (dimension=$ZCVT(tResult.SiteDimension,"U")) ) {
				If dimension'="" {Set tRowKey = tRowKey_"["_tResult.SiteDimension_"]"} Else {Set tRowKey = tRowKey_"[All]"}
				Set ^||ISC.Ens.ActivityCounters(tRowKey,"count") = $G(^||ISC.Ens.ActivityCounters(tRowKey,"count")) + tResult.TotalCount
				Set ^||ISC.Ens.ActivityCounters(tRowKey,"duration") = $G(^||ISC.Ens.ActivityCounters(tRowKey,"duration")) +tResult.TotalDuration
				Set ^||ISC.Ens.ActivityCounters(tRowKey,"duration2") = $G(^||ISC.Ens.ActivityCounters(tRowKey,"duration2")) + tResult.TotalDurationSquare
				Set ^||ISC.Ens.ActivityCounters(tRowKey,"queue") = $G(^||ISC.Ens.ActivityCounters(tRowKey,"queue")) + tResult.TotalQueueDuration
				If (tResult.TotalCount>0) && (tResult.TotalDuration'="") {
					Set slotdur = tResult.TotalDuration/tResult.TotalCount
					If slotdur<$G(^||ISC.Ens.ActivityCounters(tRowKey,"minduration"),9999999) {
						Set ^||ISC.Ens.ActivityCounters(tRowKey,"minduration") = slotdur
					}
					If slotdur>=$G(^||ISC.Ens.ActivityCounters(tRowKey,"maxduration")) {
						Set ^||ISC.Ens.ActivityCounters(tRowKey,"maxduration") = slotdur
					}
				}
				
				Set bck = $S($D(^||ISC.Ens.ActivityBuckets(tResult.TimeSlotUTC))#2:tResult.TimeSlotUTC,1:$O(^||ISC.Ens.ActivityBuckets(tResult.TimeSlotUTC)))
				;Set bck = $O(^||ISC.Ens.ActivityBuckets(tsUTC))
				If bck'="" {
					Set ^||ISC.Ens.ActivityBuckets(bck,tRowKey,"count") = $G(^||ISC.Ens.ActivityBuckets(bck,tRowKey,"count")) + tResult.TotalCount
					Set ^||ISC.Ens.ActivityBuckets(bck,tRowKey,"duration") = $G(^||ISC.Ens.ActivityBuckets(bck,tRowKey,"duration")) + tResult.TotalDuration
					Set ^||ISC.Ens.ActivityBuckets(bck,tRowKey,"queue") = $G(^||ISC.Ens.ActivityBuckets(bck,tRowKey,"queue")) + tResult.TotalQueueDuration
				}
			}
		}
	
		// Set dashboard data
		If scale="All"||(scale="") {
			Set bck = $O(^||ISC.Ens.ActivityBuckets(""))
			Kill:bck'="" ^||ISC.Ens.ActivityBuckets(bck) // Remove first time bucket which contains counters that will not go into the chart
		}
		Set row = 0
		Set name = $O(^||ISC.Ens.ActivityCounters(""))
		While (name'="") {
			Set row = row+1
			Set ^||ISC.Ens.Activitydata(row,"Name") = $P(name,"[")
			Set ^||ISC.Ens.Activitydata(row,"Site Dimension") = $P($P(name,"[",2),"]")
			Set count = $G(^||ISC.Ens.ActivityCounters(name,"count"))
			Set ^||ISC.Ens.Activitydata(row,"Total Count") = $S(count'="":count,1:"")
			Set ^||ISC.Ens.Activitydata(row,"Est. Min. Duration") = $S($G(^||ISC.Ens.ActivityCounters(name,"minduration"))'="":$J(^||ISC.Ens.ActivityCounters(name,"minduration"),0,3),1:"")
			Set ^||ISC.Ens.Activitydata(row,"Est. Max. Duration") = $S($G(^||ISC.Ens.ActivityCounters(name,"maxduration"))'="":$J(^||ISC.Ens.ActivityCounters(name,"maxduration"),0,3),1:"")
			Set mean = $S($G(^||ISC.Ens.ActivityCounters(name,"count")):$J($G(^||ISC.Ens.ActivityCounters(name,"duration"))/^||ISC.Ens.ActivityCounters(name,"count"),0,3),1:"")
			Set ^||ISC.Ens.Activitydata(row,"Avg. Duration") = mean
			Set ^||ISC.Ens.Activitydata(row,"Duration Sum Squared") = $S($G(^||ISC.Ens.ActivityCounters(name,"duration2"))'="":$J(^||ISC.Ens.ActivityCounters(name,"duration2"),0,6),1:"")
			If (count>0) && (mean'="") {
				Set tmp = +$G(^||ISC.Ens.ActivityCounters(name,"duration2")) - ( mean*mean*count )
				Set:tmp>=0 ^||ISC.Ens.Activitydata(row,"Std. Deviation") = $J($ZSQR(tmp/count),0,3)
				Set tmp = +$G(^||ISC.Ens.ActivityCounters(name,"duration2")) - ( mean*$G(^||ISC.Ens.ActivityCounters(name,"duration")) )
				Set:tmp>=0 ^||ISC.Ens.Activitydata(row,"Std. Deviation 2") = $J($ZSQR(tmp/count),0,3)
			}
			Set ^||ISC.Ens.Activitydata(row,"Avg. Queue Time") = $S(count:$J($G(^||ISC.Ens.ActivityCounters(name,"queue"))/count,0,3),1:"")
			Set ctHistory = ""
			Set avgHistory = ""
			Set qHistory = ""
			Set bck = ""
			For i = 1:1 {
				Set bck = $O(^||ISC.Ens.ActivityBuckets(bck))
				Quit:bck=""
				Set $P(ctHistory,",",i) = +$G(^||ISC.Ens.ActivityBuckets(bck,name,"count")) // Use unary + to force 0 instead of null
				Set avg = 0 // Use null to omit a duration history segment, or 0 otherwise
				If +$G(^||ISC.Ens.ActivityBuckets(bck,name,"count")) {
					Set:+$G(^||ISC.Ens.ActivityBuckets(bck,name,"duration")) avg = $J($G(^||ISC.Ens.ActivityBuckets(bck,name,"duration"))/$G(^||ISC.Ens.ActivityBuckets(bck,name,"count")),0,3)
					Set $P(avgHistory,",",i) = avg
					Set avg = 0 // Use null to omit a queue history segment, or 0 otherwise
					Set:+$G(^||ISC.Ens.ActivityBuckets(bck,name,"queue")) avg = $J($G(^||ISC.Ens.ActivityBuckets(bck,name,"queue"))/$G(^||ISC.Ens.ActivityBuckets(bck,name,"count")),0,3)
					Set $P(qHistory,",",i) = avg
				} Else {
					Set $P(avgHistory,",",i) = 0
					Set $P(qHistory,",",i) = 0
				}
			}
			Set ^||ISC.Ens.Activitydata(row,"Count Trend") = ctHistory
			Set ^||ISC.Ens.Activitydata(row,"Duration Trend") = avgHistory
			Set ^||ISC.Ens.Activitydata(row,"Queue Trend") = qHistory
			Set name = $O(^||ISC.Ens.ActivityCounters(name)) // Next name
		}
			
		If sort="Name" {
			Merge ..%data = ^||ISC.Ens.Activitydata
		}
		Else {
			// Create local array sorted(rank) = row, sorted by the selected column in descending order
			For i = 1:1:row {
				Set ^||ISC.Ens.Activitytemp(+$G(^||ISC.Ens.Activitydata(i,sort)),i) = ""
			}
			Kill ^||ISC.Ens.Activitysorted
			Set rank = 0
			Set i = ""
			For {
				Set i = $O(^||ISC.Ens.Activitytemp(i),-1)
				Quit:i=""
				Set j = ""
				For {
					Set j = $O(^||ISC.Ens.Activitytemp(i,j))
					Quit:j=""
					Set rank = rank+1
					Set ^||ISC.Ens.Activitysorted(rank) = j
				}
			}
			For i = 1:1:rank {
				Merge ..%data(i) = ^||ISC.Ens.Activitydata(^||ISC.Ens.Activitysorted(i))
			}
		}

		For i = 1:1:row {
			Set ..%seriesNames(i) = ..%data(i,"Name")
		}

		// Row with total
		Set total = 0
		Set name = ""
		For {
			Set name = $O(^||ISC.Ens.ActivityCounters(name))
			Quit:name=""
			Set total = total+$G(^||ISC.Ens.ActivityCounters(name,"count"))
		}
		Set row = row+1
		Set txt = $$$Text("Total","Ensemble")
		Set ..%seriesNames(row) = txt
		Set ..%data(row,"Name") = txt
		Set ..%data(row,"Total Count") = total

		Set ..%seriesCount = row
	}
	Catch e {
	}

	Kill ^||ISC.Ens.ActivityCounters
	Kill ^||ISC.Ens.ActivityBuckets
	Kill ^||ISC.Ens.Activitydata
	Kill ^||ISC.Ens.Activitysorted
	Kill ^||ISC.Ens.Activitytemp
	
    Quit $$$OK
}

/// Gets Period based on scale in UTC
ClassMethod GetPeriod(scale As %String = "", Output low As %String, Output high As %String, Output base As %String) [ Internal ]
{
	Set high = $ZTS
	Set time = ($P(high,",",2)\$$$EnsCounterInterval)*$$$EnsCounterInterval
	Set high = $zdt((+high)_","_time,3)
	Set base = $system.SQL.DATEADD("s",-$$$EnsCounterInterval,high)
	If scale="Minute" {
		Set low = $system.SQL.DATEADD("mi",-1,base)
	}
	ElseIf scale="Hour" {
		Set low = $system.SQL.DATEADD("hh",-1,base)
	}
	ElseIf scale="Day" {
		Set low = $system.SQL.DATEADD("d",-1,base)
	}
	ElseIf scale="Week" {
		Set low = $system.SQL.DATEADD("d",-7,base)
	}
	ElseIf scale="Month" {
		Set low = $system.SQL.DATEADD("mm",-1,base)
	}
	ElseIf scale="Year" {
		Set low = $system.SQL.DATEADD("yy",-1,base)
	}
	Else {
		// "All"
		Set low = "2001-01-01 00:00:00"
	}
}

/// This callback is invoked from a dashboard when an action defined by this dashboard is invoked.
ClassMethod %OnDashboardAction(pAction As %String, pContext As %ZEN.proxyObject) As %Status
{
	// pAction is the name of the action (as defined in the XML list).
	// pContext contains information from the client
	// and can be used to return information.
	Quit $$$OK
}

}
