/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMonitor

/// Provide Trace Context Propagation handling methods.
Class %Trace.Propagation Extends %RegisteredObject
{

/// Extract the W3C Trace Context from HTTP headers. Headers are passed by reference as an array.
/// Returns a new %Trace.Context with the extracted SpanContext. If no valid Trace Context
/// is found, we return the same 'Context' as passed in.
ClassMethod HttpExtract(ByRef Headers As %String, Context As %Trace.Context) As %Trace.Context
{
	set header=""
	try {
		set context=Context.%ConstructClone(1)
		set context.ActiveSpan.Context.TraceId = $$$InvalidTraceId
		set context.ActiveSpan.Context.SpanId = $$$InvalidSpanId
		set context.ActiveSpan.Context.TraceFlags = 0
		do context.ActiveSpan.Context.TraceState.Clear()
		set parent=$g(Headers("traceparent"))
		if parent]"" {
			set context.ActiveSpan.Context.TraceId=$p(parent,"-",2)
			set context.ActiveSpan.Context.SpanId=$p(parent,"-",3)
			set context.ActiveSpan.Context.TraceFlags=+$p(parent,"-",4)
		}
		set state=$g(Headers("tracestate"))
		if state]"" {
			for pc=1:1:$l(state,",") {
				set entry=$p(state,",",pc)
				do Context.ActiveSpan.Context.TraceState.SetAt($p(entry,"=",2),$p(entry,"=",1))
			}
		}
		if 'context.ActiveSpan.Context.IsValid() set context=Context
	} catch {
		set context=Context
	}
	quit context
}

/// Inject the W3C Trace Context from the passed 'Context' into the HTTP headers
/// array in 'Headers'. This will add Headers("traceparent") and Headers("tracestate").
ClassMethod HttpInject(ByRef Headers As %String, Context As %Trace.Context)
{
	set Headers("traceparent")=Context.ActiveSpan.Context.ToString()
	set Headers("tracestate")=Context.ActiveSpan.Context.StateToString()
	quit
}

/// Inject the W3C Trace Context from the passed 'Context' into the Headers of an HttpRequest object.
ClassMethod HttpRequestInject(Request As %Net.HttpRequest, Context As %Trace.Context)
{
	do Request.SetHeader("traceparent", Context.ActiveSpan.Context.ToString())
	do Request.SetHeader("tracestate", Context.ActiveSpan.Context.StateToString())
	quit
}

/// Extract the W3C Trace Context from the HTTP Headers in a %CSP.Request object (i.e. %request).
/// Returns a new %Trace.Context with the extracted SpanContext.
/// If no valid Trace Context is found, we return the same 'Context' as passed in.
ClassMethod CSPRequestExtract(Request As %CSP.Request, Context As %Trace.Context) As %Trace.Context
{
	Set headers("traceparent")=$G(Request.CgiEnvs("HTTP_TRACEPARENT"))
	Set headers("tracestate")=$G(Request.CgiEnvs("HTTP_TRACESTATE"))
	quit ..HttpExtract(.headers,Context)
}

}
