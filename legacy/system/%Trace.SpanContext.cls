/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMonitor

/// Uniquely identifies a Span. Used as the 'parent' to create related Spans.
Class %Trace.SpanContext Extends %RegisteredObject
{

/// Trace identifier for a Span (16 character, i.e. byte, hex string). TraceId is generated at StartSpan.
Property TraceId As %String [ InitialExpression = {$$$InvalidTraceId} ];

/// Span identifier for a Span (8 character, i.e. byte, hex string). SpanId is generated at StartSpan.
Property SpanId As %String [ InitialExpression = {$$$InvalidSpanId} ];

/// Bit map of Trace flags. First bit (and only bit so far) is for 'sampled'.
/// See bit definitions in %syMonitor.
Property TraceFlags As %Integer [ InitialExpression = 0 ];

/// List of key-value pairs that can carry vendor-specific trace information.
/// These should follow the W3C tracestate header rules.
/// Keys should contain only lowercase alphanumeric characters, underscores, dashes, asterisks, 
/// and forward slashes. Keys and Values should not contain the ',' or '=' characters.
Property TraceState As array Of %String;

/// Flag which indicates if the SpanContext is from another system.
/// False if SpanContext was locally generated, otherwise true.
Property IsRemote As %Boolean [ InitialExpression = 0 ];

/// Format the SpanContext as a string in W3C format
Method ToString() As %String [ CodeMode = expression ]
{
"00-"_..TraceId_"-"_..SpanId_"-0"_..TraceFlags
}

/// Returns true if both TraceID and SpanID are valid strings.
Method IsValid() As %Boolean
{
	quit ((..TraceId'=$$$InvalidTraceId) && (..SpanId'=$$$InvalidSpanId))
}

/// Format the TraceState as a string in W3C format
Method StateToString() As %String
{
	set key = "",state = ""
	for  {
		set value = ..TraceState.GetNext(.key) quit:key=""
		set state = state_$s(state]"":",",1:"")_key_"="_value
	}
	quit state
}

}
