/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract class to provide Sensor metrics for the SAM (System Alerting and Monitoring) application
/// and Prometheus API. All classes which define SAM metrics should inherit from this class.
/// Users may inherit from this class to create application metrics. The application classes
/// may then be registered using SYS.Monitor.SAM.Config.AddApplicationClass(), and they will be added to the system metrics.
/// <br><br>
/// Note that this will be called directly by the SAM REST service, and not by the System Monitor.
/// The main SAM polling API will call GetSensors(), which should create the array of:
/// <br><br>SAMValues(key)=value or SAMValues(key,item)=value.
/// <br><br>Users may call SetSensor(Sensor, Value, Item) or directly set ..SAMValues for each metric.
/// <br>All 'values' MUST BE NUMERIC values to be used for SAM and/or Prometheus.
/// <br><br> Since this will be called directly by the SAM REST service, users should be
/// careful to not introduce any hangs, pauses, or any coding excesses here, as this may be called
/// at intervals of only a few seconds.
Class %SYS.Monitor.SAM.Abstract Extends %SYS.Monitor.AbstractSensor
{

/// Fill in the Product name here, which will be appended to all metric names.
/// This should be a short, lower-case prefix to indicate the company or application.
/// InterSystems IRIS will use "iris" for system metrics. 
Parameter PRODUCT = "unknown";

/// Local array to hold all Sensor values, in the format SAMValues(key,item)=value.
/// <br>For use by SAM and Prometheus, the 'value' must be numeric.
Property SAMValues As %String [ Internal, MultiDimensional ];

/// Local array to hold all Sensor info values, in the format SAMinfo(metric,token)=value.
/// Tokens ("HELP", "TYPE" and "UNIT") are used to create Prometheus comment lines, with 
/// information about the individual Sensors.
Property SAMInfo As %String [ Internal, MultiDimensional ];

/// Override Dashboard sensors which are persistent, and System sensors which get passed to Subscribers.
/// Just store all Sensors in the local SAMValues array.
Method SetSensor(Sensor As %String, Value As %String, Item As %String = "") As %Integer [ Final ]
{
	s return = 1
	Try {
		i Item="" {
			s ..SAMValues(Sensor) = Value
		} else {
			s ..SAMValues(Sensor,Item) = Value
		}
	} Catch {
		s return=0
	}
	Q return
}

/// Extension of SetSensor which allows for multiple Prometheus 'labels' for a metric.
/// <br>Labels are passed as an array of label/value pairs, e.g. for a database metric we might use
/// <br><br> Labels("id")="USER"
/// 	<br> Labels("dir")="c:\\intersystems\\iris\\mgr\\user"
/// <br><br>By convention, metrics with a single label value use the "id" key. So, for consistency,
/// multiple labels should always include an "id" label which identifies that metric instance. Other
/// labels can be used to add further information about the metric.
Method SetSensorLabels(Sensor As %String, Value As %String, ByRef Labels As %String = "") As %Integer [ Final ]
{
	Set return = 1
	Try {
		Set key="",labels=""
		For {
			Set key=$o(Labels(key)) Quit:key=""
			Set labels=labels_$lb($lb(key,Labels(key)))
		}
		Set ..SAMValues(Sensor,labels)=Value
	} Catch {
		Set return = 0
	}
	Quit return
}

/// Add informational data (Help, Type and Unit) describing a Sensor (i.e. Metric)
/// Valid values for 'Type' are (counter, gauge, histogram, summary, or untyped)
/// <br><br>
/// Note that the OTel Metrics Exporter will also use these values. The Exporter recognizes
/// Units of "milliseconds", "seconds", "megabytes" and "kilobytes", which are converted to
/// UCUM abbreviations for OTel.
Method SetSensorInfo(Sensor As %String, Help As %String = "", Type As %String = "", Unit As %String = "") As %Integer [ Final ]
{
	Set return=1
	Try {
		If Type]"",'$lf($lb("counter", "gauge", "histogram", "summary", "untyped"),Type) {
			Set Type = "untyped"
		}
		If Help]"" Set ..SAMInfo(Sensor,"HELP") = Help
		If Type]"" Set ..SAMInfo(Sensor,"TYPE") = Type
		If Unit]"" Set ..SAMInfo(Sensor,"UNIT") = Unit
	} Catch {
		Set return = 0
	}
	Quit return
}

}
