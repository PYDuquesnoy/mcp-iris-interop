/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// The persistent definition of a System Monitor Dashboard Sensor. 
/// This also includes the history of all Sensor Readings.
Class %SYS.Monitor.Sensor Extends %Persistent
{

Index SensorIndex On (Name, Item) [ IdKey, Unique ];

/// Name of the Sensor
Property Name As %String(MAXLEN = 100);

/// Some sensors may define multiple values or 'subitems', such disk space for a specific database.
/// If the sensor is only a single value, then this property contains a "-" to identify as a single
/// or base level sensor.
Property Item As %String(MAXLEN = 500) [ InitialExpression = "-" ];

/// Text description of the Sensor for documentation.
Property Description As %String(MAXLEN = 200);

/// Number of seconds between each reading
/// This value is inherited by %SYS.Monitor.Control in all cases, but could be extended so sensors have induvidual reading delays
Property ReadingInterval As %String;

/// Value used to check for warning status. Note that if WarningValue, CriticalValue, and AlertFlag 
/// are null for a specific Sensor.Item, then that Item will use the values of the base ("-") Sensor.
Property WarningValue As %String;

/// Value used to check for critical/alert status
Property CriticalValue As %String;

/// Boolean flag ("0" or  "1") to indicate if System Monitor generates an alert on CriticalValue
Property Alert As %String;

/// Logical operator used to compare Warning/Critial values. Default is ">", with option of "<".
Property Operator As %String [ InitialExpression = ">" ];

/// Description of units used, for display and documentation only.
Property Units As %String;

/// Class which created this Sensor, so we can delete if class is unregistered.
Property Owner As %String(MAXLEN = 220) [ Internal ];

/// The function or use of this Sensor. Sensors may be grouped by Function so that Subscribers and 
/// Notifications can decide how to handle or whether they are interested certain Sensors.
/// Right now only "%Dashboard" is implemented, but we could use this for System or Health Monitor sensors
/// in the future.
Property Function As %String [ Internal ];

Relationship Readings As %SYS.Monitor.Reading [ Cardinality = children, Inverse = Sensor ];

/// Open an exisiting Sensor for editing Critical and Warning Values or other properties.
/// 'Item' may be "" to open a top level Sensor. Setting Critical/Warning Values for a specific
/// Item will override the Values from the top level.
/// <br><br>
/// Note that internal properties for 'Owner' and 'Function' should not be modified by users.
ClassMethod Open(Sensor As %String, Item As %String = "", ByRef Status As %Status) As Sensor
{
	If Item="" Set Item="-"
	Set sensor=..SensorIndexOpen(Sensor,Item,,.Status)
	Quit $g(sensor)
}

/// Called by CreateSensor() in the Dashboard Sensor class. Only creates a new Sensor, does not update an existing one.
/// Properties for existing Sensors (e.g. CriticalValue and WarningValue) can be update using the standard class APIs.
ClassMethod CreateDashboardSensor(Sensor As %String, Item As %String = "-", CriticalValue As %String, WarningValue As %String, Alert As %String, Units As %String, Operator As %String, Description As %String, ClassName As %String) As %Status [ Internal ]
{
	Try {
		s sc=$$$OK s:Item="" Item="-"
		i '..%ExistsId(Sensor_"||"_Item) {
			s sensor=..%New()
			s sensor.Name=Sensor,sensor.Item=Item
			s:$d(Description) sensor.Description=Description
			s:$d(WarningValue) sensor.WarningValue=WarningValue
			s:$d(CriticalValue) sensor.CriticalValue=CriticalValue
			// If sensor specific reading intervals are defined, this funcionality must be updated
			s sensor.ReadingInterval=##class(%SYS.Monitor).Interval()
			s:$d(Alert) sensor.Alert=Alert
			s:$d(Operator) sensor.Operator=Operator
			i Item="-",Operator="" s sensor.Operator=">"
			s:$d(Units) sensor.Units=Units
			#; if we're creating a specific Item, get the Owner from the top level
			i '$d(ClassName),Item'="-" {
				s top=..SensorIndexOpen(Sensor,"-")
				i top'="" s ClassName=top.Owner
			}
			s sensor.Function="%Dashboard",sensor.Owner=ClassName
			s sc=sensor.%Save()
		}
	} Catch {
		s sc=$$$ERROR($$$ObjectScriptError,$ze)
	}
	q sc
}

/// Fetch Properties (as an array) for an Item which can be "inherited" from the top level Sensor.
/// This includes "CriticalValue", "WarningValue", "Alert", "Operator", "Units" and "Description"
ClassMethod GetInherited(Sensor As %String, Item As %String, ByRef Properties As %String) As %Status [ Internal ]
{
	#; Inherit properties from top level Sensor if not defined for a specific Item
	Set sensor=..SensorIndexOpen(Sensor,Item,,.sc) 
	If sensor="" Set Item="-",sensor=..SensorIndexOpen(Sensor,Item,,.sc) If $$$ISERR(sc) Quit sc
	If Item'="-" {
		Set top=..SensorIndexOpen(Sensor,"-",,.sc)
		If $$$ISERR(sc) Quit sc
		If top'="" {
			If sensor.CriticalValue="" Set sensor.CriticalValue=top.CriticalValue
			If sensor.WarningValue="" Set sensor.WarningValue=top.WarningValue
			If sensor.Alert="" Set sensor.Alert=top.Alert
			If sensor.Operator="" Set sensor.Operator=top.Operator
			If sensor.Operator="" Set sensor.Operator=">"
			If sensor.Units="" Set sensor.Units=top.Units
			If sensor.Description="" Set sensor.Description=top.Description
			If sensor.ReadingInterval="" Set sensor.ReadingInterval= ##class(%SYS.Monitor).Interval()
		}
	}
	For prop="CriticalValue", "WarningValue", "Alert", "Operator", "Units", "Description", "ReadingInterval" {
		Set Properties(prop)=$Property(sensor,prop)
	}
	Quit sc
}

/// Delete all Sensor and Readings associated with a ClassName (i.e. "Owner")
ClassMethod DeleteByClass(ClassName As %String) As %Status
{
	&sql(DELETE FROM Sensor WHERE Sensor.Owner = :ClassName)
	Q $$$OK
}

/// A list of all top level Sensor IDs
Query SensorIDs() As %SQLQuery(CONTAINID = 1)
{
SELECT ID FROM Sensor
WHERE Sensor.Item = '-'
}

/// A list of all top level Sensor Names
Query SensorNames() As %SQLQuery(CONTAINID = 1)
{
SELECT Name FROM Sensor
WHERE Sensor.Item = '-'
}

/// A list of all Sensor.Items for a given Sensor
Query SensorItems(Name As %String) As %SQLQuery(CONTAINID = 1)
{
SELECT Item FROM Sensor
WHERE Sensor.Name = :Name AND Sensor.Item != '-'
}

/// Loop through all registered Namespaces and return all registered Dashboard Sensors.
/// If a Sensor has specific Items, do not include the top-level Sensor definition.
Query AllDashboardSensors() As %Query(ROWSPEC = "Name:%String,Item:%String,CriticalValue:%String,WarningValue:%String,Alert:%String,Operator:%String,Units:%String,Description:%String,ReadingInterval:%String,Namespace:%String")
{
}

ClassMethod AllDashboardSensorsExecute(ByRef qHandle As %Binary) As %Status
{
	Set beginNS=$Namespace,sc=$$$OK
	Set Index=$i($$$ISCQUERYTEMP)
	Try {
		zn "%SYS"
		Set sc=##class(%SYS.Monitor).ListStartNS(.nslist)
		If $$$ISERR(sc) Quit
		Set nslist=$lb("%SYS")_nslist
		For n=1:1:$ll(nslist) {
			Set namespace=$lg(nslist,n) zn namespace
	   		Set rs1 = ##class(%ResultSet).%New("%SYS.Monitor.Sensor:SensorNames")
			Set tSC = rs1.Execute()
			If $$$ISOK(tSC) {
				Set count = 0
				While rs1.Next(.tSC) {
					Set sname = rs1.Data("Name"),hasItems=0
					Set rs2 = ##class(%ResultSet).%New("%SYS.Monitor.Sensor:SensorItems")
					Set tSC = rs2.Execute(sname)
					If $$$ISOK(tSC) {
						While rs2.Next(.tSC) {
							Set hasItems=1 Kill prop
							Set item=rs2.Data("Item")
							Set sc = ..GetInherited(sname,item,.prop)
							If $$$ISOK(sc) {
								Set row=$lb(sname,item,prop("CriticalValue"),prop("WarningValue"),prop("Alert"),prop("Operator"),prop("Units"),prop("Description"),prop("ReadingInterval"),namespace)
								Set $$$ISCQUERYTEMP(Index,$I(Index1))=row
							}
						}
					}
					If 'hasItems {
						Kill prop
						Set sc = ..GetInherited(sname,"-",.prop)
						If $$$ISOK(sc) {
							Set row=$lb(sname,"-",prop("CriticalValue"),prop("WarningValue"),prop("Alert"),prop("Operator"),prop("Units"),prop("Description"),prop("ReadingInterval"),namespace)
							Set $$$ISCQUERYTEMP(Index,$I(Index1))=row
						}
					}
				}
			}	
    	} 
   	} Catch (e) {
	   	Set sc=e.AsStatus()
   	}
   	zn beginNS
	Set qHandle=Index_"^"
	Quit sc
}

ClassMethod AllDashboardSensorsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	
	$$$DEFAULTFETCHPPG
	Quit $$$OK
}

ClassMethod AllDashboardSensorsClose(ByRef qHandle As %Binary) As %Status
{
	Set Index=$p(qHandle,"^",1)
	Kill $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

Storage Default
{
<Data name="SensorDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>WarningValue</Value>
</Value>
<Value name="4">
<Value>CriticalValue</Value>
</Value>
<Value name="5">
<Value>Alert</Value>
</Value>
<Value name="6">
<Value>Operator</Value>
</Value>
<Value name="7">
<Value>Units</Value>
</Value>
<Value name="8">
<Value>Owner</Value>
</Value>
<Value name="9">
<Value>Function</Value>
</Value>
<Value name="10">
<Value>ReadingInterval</Value>
</Value>
</Data>
<DataLocation>^ISC.Monitor.SensorD</DataLocation>
<DefaultData>SensorDefaultData</DefaultData>
<IdLocation>^ISC.Monitor.SensorD</IdLocation>
<IndexLocation>^ISC.Monitor.SensorI</IndexLocation>
<StreamLocation>^ISC.Monitor.SensorS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
