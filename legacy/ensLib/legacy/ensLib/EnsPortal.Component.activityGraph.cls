/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Example chart for TimeLine.
Class EnsPortal.Component.activityGraph Extends %ZEN.Component.composite [ System = 3 ]
{

/// Namespace for this
Parameter NAMESPACE = "http://www.intersystems.com/EnsPortal";

Parameter USECOMMONDIRECTORY = 1;

Property autoUpdate As %Boolean [ InitialExpression = 1 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

body {
	background: white;
	font-family: arial;
	color: #404040;
}

.zenLabel {
	color: #606060;
	font-size: 10px;
}


</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite>
<!--<pane xmlns="http://www.intersystems.com/zen" title="Hey!">-->

<!-- get history as JSON data -->
<jsonProvider id="jsonHistory" OnGetArray="GetHistoryData" seriesNameProperty="date">
<parameter id="timeFrame" paramName="timeFrame" value="lastDay" />
<parameter id="configName" paramName="configName" value="" />
</jsonProvider>

<radioSet id="rbTimeFrame" value="lastDay" valueList="lastWeek,lastDay,lastHour,last5Minutes" 
displayList="Last Week,Last Day,Last Hour,Last 5 Minutes" onchange="zenThis.composite.changeTimeFrame();"/>

<timer id="graphTimer" timeout="0" ontimeout="zenThis.composite.changeTimeFrame();"/>

<svgFrame id="svgFrame" width="375" height="200" layout="vertical">

<lineChart id="chartRecent" title="History" titleAlign="left" 
titleStyle="font-size:20px;fill:#606060;font-variant:small-caps;"
markersVisible="false" markerScale="0.5"
width="375" height="200" controllerId="jsonHistory" 
legendVisible="false" labelStyle="fill:#808080;" seriesColorsOverride="rgb(200,100,100)" 
plotAreaStyle="fill:none;" lineStyle="stroke-width:2.5px;" backgroundStyle="fill:white;"
timeBased="true"
>
</lineChart>

</svgFrame>
<!--</pane>-->
</composite>
}

/// This callback method determines lets a page specify level of CSS support is used by this page.
/// The default is to return "", which indicates that the built-in ZEN CSS level
/// detection is used. A page can override this and return 2 or 3.
Method %OnDetermineCSSLevel() As %Integer [ CodeMode = expression ]
{
3
}

/// Change time frame, reload data from server.
ClientMethod changeTimeFrame() [ Language = javascript ]
{
	// get value from radioSet
	var timeFrame = this.getChildById('rbTimeFrame').getValue();

	// set parameter value
	this.getChildById('timeFrame').value = timeFrame;

	// reload JSON data
	var json = this.getChildById('jsonHistory');
	json.reloadContents();
		
	// For pages in the management portal, zenPage.enableAutoRefresh will be a boolean.
	// However, we also need to check for other pages where zenPage.enableAutoRefresh is not a property
	if (this.autoUpdate && zenPage && (zenPage.enableAutoRefresh || (typeof zenPage.enableAutoRefresh != 'boolean'))) {
		// restart timer
		this.getChildById('graphTimer').startTimer();
	}
}

/// Set the selected configuration name
ClientMethod setConfigName(confName) [ Language = javascript ]
{
	// Set the name, ...
	var json = this.getChildById('jsonHistory');
	this.getChildById('configName').value = confName;
	if (confName == '') {
		this.getChildById('chartRecent').title = $$$Text('History');
	} else {
		this.getChildById('chartRecent').title = confName;	
	}
	// Reload the data, ...
	json.reloadContents();
	/// And restart the timer
	// For pages in the management portal, zenPage.enableAutoRefresh will be a boolean.
	// However, we also need to check for other pages where zenPage.enableAutoRefresh is not a property
	if (zenPage && (zenPage.enableAutoRefresh || (typeof zenPage.enableAutoRefresh != 'boolean'))) {
		this.getChildById('graphTimer').startTimer();
	}
}

/// Get totals of InterSystems IRIS host counters for each time slice
///    startDate, startTime start of period for graph, specified in UTC
///    timeSlice - size of time "buckets" in seconds
Method TraverseHostCounters(startDate As %Integer, startTime As %Integer, timeSlice As %Integer, configName As %String = "", timeFrame As %String, configSubscript As %String = "_")
{
	If '##class(Ens.Director).IsProductionRunning() Quit
	Set tUpdateStamp = (startDate*86400) + startTime
	#;lastupdatestamp^lastCalcDuration^lastTotalsStartUTC^lastTotalsEndUTC^lastBucket
	Set tLastUpdateDetails = $G($$$EnsHostCounterTotals(timeFrame,configSubscript),0)
	Set tLastUpdateStamp = +tLastUpdateDetails
	#; Quit if updated within last timeSlice
	If ((tUpdateStamp-tLastUpdateStamp)<=timeSlice) Quit
	Set $$$EnsHostCounterTotals(timeFrame,configSubscript)=tUpdateStamp
	Set tCalcDuration = $ZH
	Set lastTotalsStartUTC = $P(tLastUpdateDetails,"^",3),tThislastTotalsStartUTC = ""
	Set lastTotalsEndUTC = $P(tLastUpdateDetails,"^",4),tThislastTotalsEndUTC = ""
	Set lastDayHourBucket = $P(tLastUpdateDetails,"^",5),tThislastBucket = ""
	
	Set tNowUTCH=$ZTS
	Set today = $P(tNowUTCH,",",1)
	Set rightNow = $P(tNowUTCH,",",2)\1

	Set bucketDate = startDate
	Set bucketTime = (startTime\timeSlice) * timeSlice
	
	Set startTimebucket = (startTime\$$$EnsCounterInterval)-0.5

	Set tRecordFirstUTC = 1
	While (bucketDate <= today) {
		If (bucketDate < today) {
			Set lastBucket = (24*60*60) - timeSlice
		} Else {
			Set lastBucket = rightNow
		}
		While (bucketTime <= lastBucket) {
			Set tTotalsUTC = $ZDT($ZDTH((bucketDate_","_bucketTime),-3),3,1)
			If tRecordFirstUTC {
				Set tThislastTotalsStartUTC = tTotalsUTC, tRecordFirstUTC = 0
				#;Clean out up to the most recent we will be recording
				Set tRemoveTotalsUTC = $O($$$EnsHostCounterTotals(timeFrame,configSubscript,tTotalsUTC),-1)
				While (tRemoveTotalsUTC'="") {
					Kill $$$EnsHostCounterTotals(timeFrame,configSubscript,tRemoveTotalsUTC)
					Set tRemoveTotalsUTC = $O($$$EnsHostCounterTotals(timeFrame,configSubscript,tRemoveTotalsUTC),-1)
				}
			}
			#;Zero if same or more recent than last.
			If ((lastTotalsEndUTC="")||(tTotalsUTC]lastTotalsEndUTC)||(tTotalsUTC=lastTotalsEndUTC)) {
				Set $$$EnsHostCounterTotals(timeFrame,configSubscript,tTotalsUTC) = 0
			}
			Set bucketTime = bucketTime + timeSlice
		}
		Set tThislastBucket = bucketTime - timeSlice
		Set bucketDate = $I(bucketDate)
		Set bucketTime = "0"
	}
	Set tThislastTotalsEndUTC = tTotalsUTC
	Set tThislastBucket = tThislastBucket\$$$EnsCounterInterval
	If (lastTotalsEndUTC="")||('$D($$$EnsHostCounterTotals(timeFrame,configSubscript,lastTotalsEndUTC))#2) Set lastDayHourBucket = ""
	
	// If not a BusinessService or BusinessOperation, leave empty
	If (configName = "n/a") Quit
	
	// Now populate from ^IRIS.Temp.EnsHostCounter
	Set config = $S(configName'="":configName,1:$$$OrderHostCounter(""))
	If (lastDayHourBucket'="") {
		Set tStartOrderDate = $P(lastDayHourBucket,",",1)-1
		Set startTimebucket = $P(lastDayHourBucket,",",2)-0.5
	} Else {
		Set tStartOrderDate = startDate-1
	}
	While (config '= "") {
		// Filter out the "noise" of the monitor service itself
		If ((configName = config) || ((configName = "") && (config '= "Ens.MonitorService"))) {
			Set h1UTC = $$$OrderHostCounter(config,tStartOrderDate)
			While (h1UTC '= "") {
				Set data = ""
				Set tOrderStartTimeBucket =$S((h1UTC=(tStartOrderDate+1)):(startTimebucket),1:"")
				Set h2UTCbucket = $$$OrderHostCounter(config,h1UTC,tOrderStartTimeBucket)
				While (h2UTCbucket '= "") {
					Set data =$$$GetHostCounter(config,h1UTC,h2UTCbucket)
					Set h2UTC = h2UTCbucket * $$$EnsCounterInterval
					Set h2UTCtimeslice = (h2UTC\timeSlice) * timeSlice
					If $I($$$EnsHostCounterTotals(timeFrame,configSubscript,$ZDT($ZDTH((h1UTC_","_h2UTCtimeslice),-3),3,1)),data) {}
					Set h2UTCbucket = $$$OrderHostCounter(config,h1UTC,h2UTCbucket)
				}
				Set h1UTC = $$$OrderHostCounter(config,h1UTC)
			}
		}
		Set config = $S(config=configName:"",1:$$$OrderHostCounter(config))
	}
	Set tCalcDuration = $ZH-tCalcDuration
	Set $$$EnsHostCounterTotals(timeFrame,configSubscript)=tUpdateStamp_"^"_tCalcDuration_"^"_tThislastTotalsStartUTC_"^"_tThislastTotalsEndUTC_"^"_today_","_tThislastBucket
	Quit
}

/// Get History data for the JSON provider.
Method GetHistoryData(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK, tNowUTCH=$ZTS
	Set tStartDate=$P(tNowUTCH,",",1), tStartTime=$P(tNowUTCH,",",2)\1
	Try {
		// create array of data to display within the chart
		// these will be shipped to the client in JSON format
		Set pMetaData = $LB("date","value")

		Set tTimeFrame = $G(pParameters("timeFrame"))
		
		Set tConfigName = $G(pParameters("configName"))
		
		If (tTimeFrame="lastWeek") {
			// every hour over past week
			Set tStartDate = tStartDate - 7
			Set tTimeSlice = 3600
		}
		ElseIf (tTimeFrame="lastDay") {
			// every 15 minutes over past day
			Set tStartDate = tStartDate - 1
			Set tTimeSlice = 900
		}
		ElseIf (tTimeFrame="lastHour") {
			// every 1 minute over past hour
			if (tStartTime < (3600)) {
				Set tStartDate = tStartDate - 1
				Set tStartTime = (86400)-((3600)-tStartTime)
			} Else {
				Set tStartTime = tStartTime - (60*60)
			}
			Set tTimeSlice = 60
		}
		ElseIf (tTimeFrame="last5Minutes") {
			// every 15 sec over past 5 minutes
			if (tStartTime < 300) {
				Set tStartDate = tStartDate - 1
				Set tStartTime = 86400-(300-tStartTime)
			} Else {
				Set tStartTime = tStartTime - 300
			}
			Set tTimeSlice = 15
		}
		#; Check if need to recompute. Use "_" for all configs since subscript cannot be ""
		Set tConfigSubscript = $S(tConfigName="":"_",1:tConfigName)
		Do ..TraverseHostCounters(tStartDate, tStartTime, tTimeSlice, tConfigName, tTimeFrame,tConfigSubscript)
		Set msgCount = 0
		Set sample = $O($$$EnsHostCounterTotals(tTimeFrame,tConfigSubscript,""),1,msgCount)
		while (sample '= "") {
			Set pData($I(pData)) = $LB(sample,msgCount)
			Set sample = $O($$$EnsHostCounterTotals(tTimeFrame,tConfigSubscript,sample),1,msgCount)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (self.zenPage && self.zenPage.enableAutoRefresh) {
		var graphTimer = this.getChildById('graphTimer');
		if (graphTimer) {
			graphTimer.setProperty('timeout',15000);
			graphTimer.startTimer();
		}
	}
}

}
