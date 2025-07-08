/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syMonitor, %syPidtab, %sySystem)

/// Abstract class for a Subscriber<p>
/// User classes inherit from this class to become a Subscriber for System Monitor.
Class %SYS.Monitor.AbstractSubscriber Extends %RegisteredObject [ Abstract, System = 3 ]
{

/// logfile
Property Logfile As %String [ InitialExpression = {$zu(12)_"SystemMonitor.log"}, Internal ];

/// Sensor readings passed from Sensor classes
/// Sensor(<sensor>, <qualifier>) = value
Property SensorReading [ MultiDimensional ];

/// Sensor subscription lists. If Subscription(type)=1 OR Subscription(name)=1
/// Subscription(<sensor>)= 1
Property SensorName [ MultiDimensional ];

Property Notifications [ MultiDimensional ];

/// Runtime state
Property State As %String [ InitialExpression = " " ];

/// USER MAY IMPLEMENT THIS METHOD
/// This method is called when the subscriber class is created.
Method Start() As %Status
{
	Quit $$$OK
}

/// USER MUST IMPLEMENT THIS METHOD
/// This method is called when the sensor array is filled.
Method Receive() As %Status [ Abstract ]
{
	Quit $$$OK
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// This method is called to clear sensor readings for the SYS.Monitor Controller
Method ClearSensors() As %Integer [ Final ]
{
	k ..SensorReading
	Q $$$OK
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// This method is called to get sensor readings. For a given sensor / qualifier pair, returns the next qualifier and the associated value.<br>
/// Returns 1 if value, 0 if no more values, -1 if invalid Sensor.
Method GetNextSensor(Sensor As %String, ByRef qHandle As %Binary, ByRef Qualifier As %String, ByRef Value As %String) As %Integer [ Final ]
{
	s $zt = "RunErr"
	
	#; 0 The variable is undefined and has no descendents. 
	#; 1 The variable contains data and has no descendants.
	#; 10 The variable is undefined, but has descendants that contain data.  
	#; 11 The variable contains data and has descendents.
	#;Note: 
	#;Status values 1 and 11 indicate only the presence of data, not the type of data.
	#;If $DATA(var) returns either 0 or 10, any direct reference to var will result in an <UNDEFINED> error.

	i qHandle=$C(0) {
		Q 0
	}
	s t = $d(..SensorReading(Sensor))
	i t=0 Q 0
	i t=1 {
		#; The variable contains data and has no descendants
		s Value = ..SensorReading(Sensor)
		s qHandle = $C(0)
		s Qualifier = ""
	} elseif t=10 {
		#; The variable is undefined, but has descendants that contain data
		s qHandle = $o(..SensorReading(Sensor,qHandle))
		i qHandle="" {
			Q 0
		} else {
			s Qualifier = qHandle
			s Value = ..SensorReading(Sensor,qHandle)
		}
	} else {
		#; 11: The variable contains data and has descendents.
		i qHandle="" {
			s Value = ..SensorReading(Sensor)
			s Qualifier = ""
			s qHandle = $C(1)
		} else {
			s qHandle = $o(..SensorReading(Sensor,qHandle))
			i qHandle="" {
				Q 0
			} else {
				s Qualifier = qHandle
				s Value = ..SensorReading(Sensor,qHandle)
			}
		}
	}
	Q 1
RunErr
	s $zt=""
	q $$$ERROR($$$UnexpectedError,$ze)
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// This method is called to get sensor readings. For a given sensor / qualifier pair, returns the value.<br>
/// Returns 1 if value, 0 if no value, -1 if invalid Sensor.
Method GetSensor(Sensor As %String, Qualifier As %String = "", ByRef Value As %String = "") As %Integer [ Final ]
{
	s $zt = "RunErr"
	
	#; 0 The variable is undefined and has no descendents. 
	#; 1 The variable contains data and has no descendants. Note that the null string ("") qualifies as data. 
	#; 10 The variable is undefined, but has descendants that contain data. Status 10 identifies an array element that has descendants (contains a downward pointer to another array element) but does not itself contain data.  
	#; 11 The variable contains data and has descendents. Status 11 identifies a defined array element that has descendants (contains a downward pointer to another array element that also contains data). Variables of this type can be referenced in expressions. 
	#;Note: 
	#;Status values 1 and 11 indicate only the presence of data, not the type of data.
	#;If $DATA(var) returns either 0 or 10, any direct reference to var will result in an <UNDEFINED> error.

	s t = $d(..SensorReading(Sensor))
	i t=0 Q 0
	i t=1 {
		s Value = ..SensorReading(Sensor)
		Q 1
	} elseif t=10 {
		i Qualifier="" Q 0
		i '$d(..SensorReading(Sensor,Qualifier)) Q 0
		s Value = ..SensorReading(Sensor,Qualifier)
		Q 1
	}
	#; t = 11
	i Qualifier="" {
		s Value = ..SensorReading(Sensor)
		Q 1
	} else {
		i Qualifier="" Q 0
		i '$d(..SensorReading(Sensor,Qualifier)) Q 0
		s Value = ..SensorReading(Sensor,Qualifier)
		Q 1
	}
	Q 0
RunErr
	s $zt=""
	q $$$ERROR($$$UnexpectedError,$ze)
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// This method is called to get sensor names. For a given sensor, returns the next sensor.<br>
/// Returns sensor name or "" if no more sensors.
Method GetNextSensorName(ByRef Sensor As %String = "") As %Status [ Final ]
{
	s $zt = "RunErr"
	
	s Sensor = $o(..SensorReading(Sensor))
	Q $$$OK
RunErr
	s $zt=""
	q $$$ERROR($$$UnexpectedError,$ze)
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// This method is called to clear notifications for the SYS.Monitor Controller
Method ClearNotifications() As %Integer [ Final ]
{
	s $zt = "RunErr"
	
	k ..Notifications
	Q $$$OK
RunErr
	s $zt=""
	q $$$ERROR($$$UnexpectedError,$ze)
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// This method is called to post a notification
Method Notify(Sensor As %String, Severity As %Integer, Msg As %String) As %Integer [ Final ]
{
	s $zt = "RunErr"
	
	s ..Notifications(Sensor,$$$NOTIFYSEV) = Severity
	s ..Notifications(Sensor,$$$NOTIFYMSG) = Msg
	Q $$$OK
RunErr
	s $zt=""
	q $$$ERROR($$$UnexpectedError,$ze)
}

Method OpenLog() As %Status [ Final ]
{
	s $zt="OpenLogErr"
	s filesize=$zu(140,1,..Logfile)
	i filesize>2097152 {
		s oldlog=..Logfile_".old"
		#; delete the old log if exists
		o oldlog:"AW":0
		c oldlog:"D"
		#; rename the current log to oldlog
		o ..Logfile:"AW":0
		c ..Logfile:("R":oldlog)
	}
	o ..Logfile:"AW":0
	q $$$OK
OpenLogErr
	;ignore errors.  If can't log, nothing we can do
	s $zt=""
	c ..Logfile
	q 0
}

Method LogMsg(msg As %String = "") As %Status
{
	s $zt="LogMsgErr"
	d ..OpenLog()

	s dt = $H
	s time = $ZDate(dt,1,,2)_"-"_$ZTime($p(dt,",",2))
	U ..Logfile w time," ",msg,!
	c ..Logfile
	q $$$OK
LogMsgErr
	;ignore errors.  If can't log, nothing we can do
	s $zt=""
	c ..Logfile
	q 0
}

Method LogCon(Msg As %String = "", Severity As %Integer = 0) As %Status [ Final ]
{
	s Msg = "[SYSTEM MONITOR] "_Msg
	d $zu(9,"",Msg,0,Severity)
	d ..LogMsg(Msg)
	q $$$OK
}

/// Query method to traverse the SensorReading property. Starting from a null Sensor, returns Sensor, Qualifier, Value, and Sensor Name.<br>
/// Returns 0 when there are no more sensor readings.
Method GetAllSensors(ByRef qHandle As %Binary, ByRef Sensor As %String, ByRef Qualifier As %String, ByRef Value As %String) As %Integer [ Final ]
{
	s $zt = "RunErr"
	
	i qHandle="" {
		s sensbase = $p(Sensor,"*",1)
		s slen = $length(sensbase)
		s qHandle("B") = sensbase
		s qHandle("B",1) = slen
		s Sensor = sensbase
		f {
			s Sensor = ..GetNextSensorName(Sensor) i Sensor="" goto done
			i (slen) && ($extract(Sensor,1,slen)'=sensbase) goto done
			Q
		}
		s Qualifier = ""
		s qH = ""
		s qHandle = Sensor
	} else {
		s Sensor = qHandle
		s Qualifier = qHandle("Q")
		s sensbase = qHandle("B")
		s slen = qHandle("B",1)
		s qH = qHandle("Q")
	}
getvalue	
    s rc = ..GetNextSensor(Sensor,.qH,.Qualifier,.Value)
    i rc {
	    s qHandle("Q") = qH
		Q 1
    }
getsens
	s Sensor = ..GetNextSensorName(Sensor) i Sensor="" goto done
	i (slen) && ($extract(Sensor,1,slen)'=sensbase) goto done
	s Qualifier = ""
	s qH = ""
	s qHandle = Sensor
    goto getvalue
done
	Q 0
RunErr
	s $zt=""
	q $$$ERROR($$$UnexpectedError,$ze)
}

}
