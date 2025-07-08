/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// A single value for a Dashboard Sensor gathered at a specific time.
/// The collected history of a Sensor is kept as children of %SYS.Monitor.Sensor.
Class %SYS.Monitor.Reading Extends %Persistent
{

Index TimeIndex On ReadTime [ IdKey, Unique ];

/// UTC Timestamp for reading.
Property ReadTime As %TimeStamp [ InitialExpression = {$zdatetime($ztimestamp,3)}, Internal ];

/// Return Local Time based on UTC ReadTime.
Property LocalReadTime As %TimeStamp [ Calculated, Internal ];

Method LocalReadTimeGet() As %String [ CodeMode = expression, Internal ]
{
##class(%UTC).Normalize(##class(%UTC).ConvertUTCtoLocal(i%ReadTime))
}

Property Value As %String;

Relationship Sensor As %SYS.Monitor.Sensor [ Cardinality = parent, Inverse = Readings ];

ClassMethod LocalTime(time) As %TimeStamp [ Internal, SqlProc ]
{
	#; short hand for this would be $zdt($zdth($zdth(time,3),-3),3)
	q ##class(%UTC).Normalize(##class(%UTC).ConvertUTCtoLocal(time))
}

/// Add sensor history entry for Dashboard
ClassMethod AddDashboardEntry(Sensor As %String, Value As %String, Item As %String = "", ReadTime As %TimeStamp = "", ByRef Alert As %Integer) As %Integer [ Internal ]
{
	Try {
		s return=$$$OK,Alert=0
		i Item="" s Item="-"
		#; make sure the base level sensor has already been created
		i '##class(%SYS.Monitor.Sensor).%ExistsId(Sensor_"||-") s return=0 q
		#; see if the Sensor.Item exists
		i Item'="-",'##class(%SYS.Monitor.Sensor).%ExistsId(Sensor_"||"_Item) {
			s sc=##class(%SYS.Monitor.Sensor).CreateDashboardSensor(Sensor,Item,"","","","","","")
			i $$$ISERR(sc) s return=0 q
		}
		s sensor=##class(%SYS.Monitor.Sensor).SensorIndexOpen(Sensor,Item)
		i sensor="" s return=0 q
		s reading=##class(%SYS.Monitor.Reading).%New()
		s reading.Value=Value,reading.Sensor=sensor
		i ReadTime'="" s reading.ReadTime=ReadTime
		s sc=reading.%Save()
		if $$$ISERR(sc) s return=0
		#; signal a Notify on "critical" value
		Set sc=##class(%SYS.Monitor.Sensor).GetInherited(Sensor,Item,.prop)
		if prop("Alert"),..GetState(Sensor,Item,Value,Value)=2 s Alert=1
	} Catch {
		s return=0
	}
	Q return
}

/// Get max, min, mean, stdDev for a Sensor.Item.
/// 'BeginTime' is a UTC TimeStamp. Returns true if data, or false if not.
ClassMethod GetCalculatedValues(Sensor As %String, Item As %String, BeginTime As %TimeStamp, ByRef Values As %String) As %Boolean [ Internal ]
{
	s count=0,total=0,max="",min="",ts=""
	s rs=##class(%ResultSet).%New("%SYS.Monitor.Reading:ListSensorUTC")
	s sc=rs.Execute(Sensor,Item,BeginTime,$zdt($zts,3)) i $$$ISERR(sc) quit 0
	while rs.Next() {
		s count=count+1,value=rs.Get("Value")
		s value(count)=value,total=total+value
		i (max="")||(value>max) s max=value
		i (min="")||(value<min) s min=value
		s ts = rs.Get("ReadTime")
	}
	i 'count quit 0
	s Values("max")=max,Values("min")=min,Values("mean")=$Normalize(total/count,2)
	s variance=0,mean=Values("mean")
	f i=1:1:count s variance=variance+((value(i)-mean)**2)
	s Values("stdDev")=$Normalize($ZSQR(variance/count),2)
	
	s Values("state") = ##class(%SYS.Monitor.Reading).GetState(Sensor, Item, max, min)
	
	s Values("timestamp") = ts
	q 1
}

/// Returns 0:"OK",1:"Warning",2:"Critical".
ClassMethod GetState(sid As %String, iid As %String, max As %Integer, min As %Integer) As %Integer [ Internal ]
{
	s state = 0 k prop
	s sc = ##class(%SYS.Monitor.Sensor).GetInherited(sid, iid, .prop)
	i $$$ISERR(sc) q state
	
	if (prop("Operator") = ">") {
		if ((prop("CriticalValue") '= "") && (prop("CriticalValue") <= max)) { s state = 2 }
		elseif ((prop("WarningValue") '= "") && (prop("WarningValue") <= max)){ s state = 1 }
	} else {
		if ((prop("CriticalValue") '= "") && (prop("CriticalValue") >= min)) { s state = 2 }
		elseif ((prop("WarningValue") '= "") && (prop("WarningValue") >= min)){ s state = 1 }
	}
	
	q state
}

/// Purge old readings, up to 'Time' argument (in %TimeStamp format).
ClassMethod Purge(Time As %TimeStamp) As %Status
{
	&sql(DELETE FROM %SYS_Monitor.Reading WHERE %SYS_Monitor.Reading_LocalTime(ReadTime) < :Time)
	Q $$$OK
}

/// Return the sensor data for a given time range
Query ListAll(BeginTime As %TimeStamp, EndTime As %TimeStamp = {$zdt($h,3)}) As %SQLQuery(CONTAINID = 1)
{
	SELECT Sensor->Name As Sensor, Sensor->Item As Item, %SYS_Monitor.Reading_LocalTime(ReadTime), Value
	FROM %SYS_Monitor.Reading
	WHERE %SYS_Monitor.Reading_LocalTime(ReadTime) BETWEEN :BeginTime AND :EndTime
}

/// Return the sensor data for a given time range. Uses UTC time for arguments and data.
Query ListAllUTC(BeginTime As %TimeStamp, EndTime As %TimeStamp = {$zdt($zts,3)}) As %SQLQuery(CONTAINID = 1)
{
	SELECT Sensor->Name As Sensor, Sensor->Item As Item, ReadTime, Value
	FROM %SYS_Monitor.Reading
	WHERE ReadTime BETWEEN :BeginTime AND :EndTime
}

/// Return the sensor data for a given Sensor.Item. 'Item' must be '-' for a top level Sensor.
Query ListSensor(Sensor As %String, Item As %String, BeginTime As %TimeStamp, EndTime As %TimeStamp = {$zdt($h,3)}) As %SQLQuery(CONTAINID = 1)
{
	SELECT %SYS_Monitor.Reading_LocalTime(ReadTime),Value
	FROM %SYS_Monitor.Reading
	WHERE %SYS_Monitor.Reading_LocalTime(ReadTime) BETWEEN :BeginTime AND :EndTime
		AND Sensor->Name = :Sensor AND Sensor->Item = :Item
}

/// Return the sensor data for a given Sensor.Item. 'Item' must be '-' for a top level Sensor.
/// Uses UTC time for arguments and data.
Query ListSensorUTC(Sensor As %String, Item As %String, BeginTime As %TimeStamp, EndTime As %TimeStamp = {$zdt($zts,3)}) As %SQLQuery(CONTAINID = 1)
{
	SELECT ReadTime,Value
	FROM %SYS_Monitor.Reading
	WHERE ReadTime > :BeginTime AND ReadTime <= :EndTime
		AND Sensor->Name = :Sensor AND Sensor->Item = :Item
}

/// INPUTS
/// sid: A string defining the sensor's name, or null if all sensor's readings should be returned
/// iid: A string defining the sensor's item, or null if all sensor's readings should be returned
/// sPer: An integer defining the sample period of which to return readings
/// sTime: A string in timestamp format that defines the starting point to get data from
/// readings: A list of objects passed in by reference that will be populated with sensor data
/// RETURNS
/// code: the http code (204 if no data was found, 200 if data was found)
ClassMethod GetReadings(sid As %String = "", iid As %String = "", sPer As %Integer, sTime As %String, ByRef readings As %ListOfObjects) As %Integer
{
	// Default to the http code 204 (success no data)
	Set code = 204
	
	// Query for all sensor's readings if no sensor or item is provided
	If ((sid = "") || (iid = "")) {
		s rS = ##class(%ResultSet).%New("%SYS.Monitor.Reading:ListAllUTC")
		s sC = rS.Execute(sTime) //TODO add end time
	// Otherwise query only for the requested sensors data
	} Else {
		s rS = ##class(%ResultSet).%New("%SYS.Monitor.Reading:ListSensorUTC")
		s sC = rS.Execute(sid, iid, sTime) //TODO add end time
	}
	
	Set sensorList = ##class(%ListOfObjects).%New() // Contains the sensors
	If $$$ISOK(sC) {
		
		// Loop through all the data returned by the query
		While (rS.Next(.sC)) {
			// If the loop runs at least once, the query got data and the http code should be 200 (success got data)
			Set code = 200
			
			// Extract the data from the result set
			Set readSensor = $G(rS.Data("Sensor"), sid) // if no sensor is returned by the query (getting readings for a specific sensor) use the sensor arg value
			Set readItem = $G(rS.Data("Item"), iid) // if no item is returned by the query (getting readings for a specific sensor) use the item arg value
			Set readTime = rS.Data("ReadTime")
			Set readVal = rS.Data("Value")
			
			//  If the current sensor or item differs from the readings sensor or item (or is undefined)
			If (($G(curSensor, -1) '= readSensor) || ($G(curItem, -1) '= readItem)) {
				// If a sensor object exists (it will only not exist on the first itteration of the loop)
				If ($Data(sensorObj)) { Do sensorList.Insert(sensorObj) } // put the sensor object on the sensor list 
				
				// Create a new sensor object to store the sensor's identifiers and readings
				Set sensorObj = ##class(%ZEN.proxyObject).%New()
				
				Set sensorObj.sensor = readSensor
				Set sensorObj.item = readItem
				// The sensors readings will be an list of objects
				Set sensorObj.readings = ##class(%ListOfObjects).%New()
				
				// Update the current sensor and item
				Set curSensor = readSensor
				Set curItem = readItem
				
				// Set the start time of the interval so readings can be averaged to create the chart data points
				Set intervalSTime = readTime
				// Reset the averages
				Set avgVal = 0
				// Reset the count of the number of readings in the interval
				Set numReadingsInInterval = 0
			}
			
			// If the reading was taken outside the current interval's time range
			If (($G(prevReadTime, -1) '= -1) && ..NewInterval(intervalSTime, readTime, sPer)) {
				// Create the reading object
				Set readObj = ##class(%ZEN.proxyObject).%New()
				set readObj.timestamp = prevReadTime // timestamp is the last timestamp in the interval
				Set readObj.value = avgVal // value is the average value of the interval
				
				// Insert the reading object into the sensor object's reading list
				Do sensorObj.readings.Insert(readObj)
				
				// Set the start time of the interval so readings can be averaged to create the chart data points
				Set intervalSTime = readTime
				// Reset the averages
				Set avgVal = 0
				// Reset the count of the number of readings in the interval
				Set numReadingsInInterval = 0
			}
			
			// Increment the total count of the readings in the interval
			Set numReadingsInInterval = numReadingsInInterval + 1
			// Calculate the new average 
			Set avgVal = avgVal + ( (readVal - avgVal ) / numReadingsInInterval )
			// Store the current read time (used as timestamp of interval if the next reading is outside the interval's time range)
			Set prevReadTime = readTime
		}
		
		// if there was a previous reading (aka data was 
		If ($G(prevReadTime, -1) '= -1) {
			// Insert the final reading object onto the sensor object if it exists (This will return a partially complete sample interval of data)
			Set readObj = ##class(%ZEN.proxyObject).%New()
			set readObj.timestamp = prevReadTime // timestamp is the last timestamp in the interval
			Set readObj.value = avgVal // value is the average value of the interval
			
			// Insert the reading object into the sensor object's reading list
			Do sensorObj.readings.Insert(readObj)
		}
		
		// Insert the final sensor object onto the sensor list if it exists (if no data is found it wont)
		If ($G(sensorObj, 0)) Do sensorList.Insert(sensorObj)
	}
	
	// Return the whole sensor list if all sensor were requested
	If ((sid = "") || (iid = "")) { Set readings = sensorList } 
	// Otherwise only return the readings of the specified sensor
	ElseIf ($Data(sensorObj)) { Set readings = sensorObj.readings }
	
	// return the HTTP code
	Quit code
}

ClassMethod NewInterval(start As %TimeStamp, read As %TimeStamp, sPer As %Integer) As %Integer
{
	Set SECPERDAY = 86400
	Set newInterval = 0
	
	// If sample interval is set to a positive value, averaging needs to take place, so figure out if the current reading is in the current interval
	If (sPer > 0) {
		// Convert the interval's start time into the internal format
		Set start = $ZDTH(start, 3)
		// Split day and time integers
		Set sDay = $P(start, ",", 1)
		Set sTime = $P(start, ",", 2)
		
		// Convert the readings's timestamp into the internal format
		Set read = $ZDTH(read, 3)
		// Split day and time integers
		Set rDay = $P(read, ",", 1)
		Set rTime = $P(read, ",", 2)
		
		// If the sample interval is longer than a day
		If (sPer >=  SECPERDAY) {
			// If the start day of the interval is before the reading's day minus the sample interval
			If (sDay < (rDay - (sPer / SECPERDAY))){
				Set newInterval = 1
			}
			// If the start day of the interval is the same as the reading's time munus the sample interval
			If (sDay < (rDay - (sPer / SECPERDAY))){
				// If the start time is greater than the reading's time
				If (sTime > rTime){
					Set newInterval = 1
				}
			}
		// Otherwise the sample interval is less than a day
		} Else {
			// Calculate the reading time minus the sample interval
			Set lTime = rTime - sPer
			// If it is below zero
			If (lTime < 0){
				Set lDay = rDay - 1 // Decrement a day
				Set lTime = $ZTIMEH("23:59:59") + lTime // Carry over the left over seconds to the time
			// Otherwise the day is the same as the readings
			} Else {
				Set lDay = rDay
			}
			// If the start day is less than the last day (meaning the reading's day is further away from the start day, it must be greater than a sample interval of less than a day)
			If (sDay < lDay){
				Set newInterval = 1
			}
			// If the start day is the same as the last day
			If (sDay = lDay){
				// If the start time is less the last time (meaning the reading's time is further away than one sample interval from the start time)
				If (sTime <= lTime){
					Set newInterval = 1
				}
			}
		}
	// Otherwise sample period is set to System Interval and each interval should consist of one point (no averaging)
	} Else {
		Set newInterval = 1
	}
	
	Quit newInterval
}

Storage Default
{
<Data name="ReadingDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Value</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Readings")</DataLocation>
<DefaultData>ReadingDefaultData</DefaultData>
<IdLocation>^ISC.Monitor.SensorC("Readings")</IdLocation>
<IndexLocation>^ISC.Monitor.ReadingI</IndexLocation>
<StreamLocation>^ISC.Monitor.ReadingS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
