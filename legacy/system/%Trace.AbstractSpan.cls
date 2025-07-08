/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Tracks and manages a Trace Span object.
Class %Trace.AbstractSpan Extends %RegisteredObject [ Abstract ]
{

/// The span name, e.g. web service endpoint or function name
Property Name As %String;

/// Set by IRIS, uniquely identifies the Span
Property Context As %Trace.SpanContext;

/// Parent span, null for root span
Property Parent As %Trace.SpanContext;

/// Values: Internal (default), Server, Client, Producer, Consumer
/// Describes the relationship between the Span, its parents, and its children in a Trace
Property SpanKind As %String(VALUELIST = "Internal, Server, Client, Producer, Consumer") [ InitialExpression = "Internal" ];

/// Additional attributes (key-value pairs) to help describe the Span. 
Property Attributes As array Of %String;

/// Start time of Span (in $ZTS format).
Property StartTime As %String;

/// End time of Span (in $ZTS format).
Property EndTime As %String;

/// Status of Span. Values: Unset (default), Ok, Error.
Property Status As %String(VALUELIST = "Unset, Ok, Error") [ InitialExpression = "Unset" ];

/// Links to other Spans
Property Links As list Of %Trace.SpanLink;

/// Events related to this Span
Property Events As list Of %Trace.SpanEvent;

/// Value which indicates if the Span is "recording", i.e. any data related to the Span wil be recorded.
/// This is set to 1 when the Span is created (StartSpan) and 0 when span.End() is called.
Property IsRecording As %Boolean [ InitialExpression = 0 ];

/// End Span.
Method End(EndTime As %String) [ Abstract ]
{
}

/// Update the Status of the Span. Only 'Unset', 'Ok', 'Error' allowed.
Method SetStatus(status As %String) [ Abstract ]
{
}

/// Add a Link for another Span. Pass 'attributes' by reference as an array(key, value)
Method AddLink(context As %Trace.SpanContext, attributes As %String) [ Abstract ]
{
}

/// Add an Event related to this Span. Pass 'attributes' by reference as an array(key, value).
/// 'timestamp' is in $ZTS format, and will be set to current $ZTS if left null.
Method AddEvent(name As %String, timestamp As %String, attributes As %String) [ Abstract ]
{
}

}
