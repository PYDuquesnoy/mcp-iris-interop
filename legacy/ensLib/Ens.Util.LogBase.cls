/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Common base class for event log and enterprise event log tables
Class Ens.Util.LogBase Extends Ens.Util.BitmapPurge [ Abstract, System = 4 ]
{

/// Name of the class from which the event was logged.
Property SourceClass As %String(MAXLEN = 255, TRUNCATE = 1);

/// Name of the method from which the event was logged.
Property SourceMethod As %String(MAXLEN = 40, TRUNCATE = 1);

/// User-supplied description of the event.
Property Text As %String(MAXLEN = 32000, TRUNCATE = 1);

/// What type of event.
Property Type As Ens.DataType.LogType;

/// Time when the event was logged.
Property TimeLogged As Ens.DataType.UTC;

/// Current Message Session (if any) when the event was logged.
Property SessionId As %Integer;

/// Configured name of the InterSystems IRIS host from which the event was logged.
Property ConfigName As %String(MAXLEN = 128, TRUNCATE = 1);

/// Specifies what the trace category for this event.
Property TraceCat As %String(MAXLEN = 10, TRUNCATE = 1);

/// Identifies the job from which this event was logged.
Property Job As %String(TRUNCATE = 1);

/// For errors, contents of the stack at the time the error was logged.
Property Stack As list Of %String(MAXLEN = 400, TRUNCATE = 1);

/// Value of the system Message ID counter when the event was logged.
Property MessageId As %Integer;

/// Optional Status Value recorded when calling $$$LOGSTATUS.
/// Defaults to OK.
/// Used in the SMP Event Log display to retrieve extra stack trace information.
/// 
Property StatusValue As %Status [ InitialExpression = 1 ];

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

}
