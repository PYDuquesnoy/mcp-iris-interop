/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Context object allows for management of implicit Span propagation.
/// The ActiveSpan will be automaticaly used as the Parent of any new Spans.
Class %Trace.Context Extends %RegisteredObject
{

/// Span object to be used as Parent of new Span. This can be set implicitly by calling
/// Tracer.SetActiveSpan(). Or, user may pass a Context object with a valid ActiveSpan
/// as Parent to Tracer.StartSpan.
Property ActiveSpan As %Trace.Span;

/// Returns a Context object with the current ActiveSpan.
ClassMethod GetCurrentContext() As %Trace.Context
{
	set ctx=..%New()
	set ctx.ActiveSpan=..GetActiveSpan()
	quit ctx
}

/// Returns a Span object for the current ActiveSpan.
ClassMethod GetActiveSpan() As %Trace.Span
{
	set ctx = $System.Context.OTel()
	set index = $O(ctx.Spans(""),1,span)
	if $G(span)="" {
		set span=##class(%Trace.NoopSpan).%New()
		#; this adds an invalid SpanContext
		set span.Context = ##class(%Trace.SpanContext).%New()
	}
	quit span
}

/// Sets the ActiveSpan to the specified Span object.
/// This Method is for internal use only and should only be called
/// from Tracer.MakeSpanActive so it is associated with a Scope object.
ClassMethod SetActiveSpan(Span As %Trace.Span) As %Integer [ Internal ]
{
	set ctx = $System.Context.OTel()
	#; use negative index here so latest sorts to top
	set index = $o(ctx.Spans("")) - 1
	set ctx.Spans(index)=Span
	quit index
}

/// Called when a Scope object is destroyed to remove a Span from the active list. 
ClassMethod RemoveSpan(Index As %Integer) [ Internal ]
{
	set ctx = $System.Context.OTel()
	kill ctx.Spans(Index)
	quit
}

}
