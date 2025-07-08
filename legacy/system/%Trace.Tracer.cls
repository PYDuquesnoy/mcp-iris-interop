/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%callout, %syMonitor, %sySystem)

/// A Tracer object allows you to start a Span.
/// A Tracer object MUST be created by calling TracerProvider.GetTracer().
Class %Trace.Tracer Extends %Trace.AbstractTracer
{

/// Array of Resource Attributes inherited from the TracerProvider (e.g. service.name and service.version)
Property ResourceAttributes As array Of %String [ Internal ];

/// Initialize a Span object. Span objects should only be created by calling StartSpan.
/// 'Attributes' should be passed by reference as an array, e.g. Attribute("key")="value".
/// 'StartTime is in $ZTS format, and defaults to the current time.
/// 'Name' is required.
Method StartSpan(Name As %String, Parent As %Trace.Context = "", Spankind As %String = "Internal", Attributes As %String, StartTime As %String = {$zts}) As %Trace.AbstractSpan
{
	if ($g(Name))="" set Name="empty"
	if $$$OTELTRACEISOFF {
		set span = ##class(%Trace.NoopSpan).%New()
		set span.Name = Name
		set span.Context = ##class(%Trace.SpanContext).%New()
		set span.IsRecording = 0
		quit span
	}
	set span = ##class(%Trace.Span).%New()
	set span.Name = Name
	if Parent]"" {
		try {
			if Parent.ActiveSpan.Context.IsValid() set span.Parent = Parent.ActiveSpan.Context
		} catch {
			$$$InfoMsg("Invalid Context object passed as Parent to %Trace.Tracer.StartSpan") 
		}
	} else {
		set activespan = ##class(%Trace.Context).GetActiveSpan()
		if activespan.Context.IsValid() set span.Parent = activespan.Context
	}
	set span.SpanKind = Spankind
	set span.StartTime = StartTime
	set pstr=$s(span.Parent]"":span.Parent.ToString(),1:"")
	#; ignore error if this system doesn't have libirisotel
	try {
		set ctxstr = $ZF(-6,$$$IrisOTelLibrary,3,pstr)
	} catch exc {
		if exc.Name'="<DYNAMIC LIBRARY LOAD>" THROW exc
		$$$WarnMsg("Unable to access OTel Traces library, disabling Traces.")
		$$$OTELTRACEOFF
		set ctxstr = "00-"_$$$InvalidTraceId_"-"_$$$InvalidSpanId_"-00"
		set span.IsRecording = 0
	}
	set context = ##class(%Trace.SpanContext).%New()
	set context.TraceId = $p(ctxstr,"-",2)
	set context.SpanId = $p(ctxstr,"-",3)
	set context.TraceFlags = +$p(ctxstr,"-",4)
	set span.Context = context
	if $d(Attributes) {
		set key=""
		for {
			set key=$o(Attributes(key),1,value) quit:key=""
			do span.Attributes.SetAt(value,key)
		}
	}
	set span.Tracer = $this
	quit span
}

/// Set a Span as the ActiveSpan. Subsequent calls to StartSpan will use the ActiveSpan
/// as the Parent if no Parent is specified.
/// <br><br>
/// This returns a Scope object to manage the lifetime of the ActiveSpan. The Span remains active
/// as long as the Scope object remains in memory (or until it is replaced by a new ActiveSpan).
/// When the Scope object is destroyed, the previous ActiveSpan becomes the current ActiveSpan.
Method SetActiveSpan(Span As %Trace.Span) As %Trace.Scope
{
	set scope = ##class(%Trace.Scope).%New()
	set scope.SpanIndex = ##class(%Trace.Context).SetActiveSpan(Span)
	quit scope
}

ClassMethod Test() [ Internal ]
{
	set resattr("service.name") = "test_service"
	set resattr("service.version") = "2.0"
	set resattr("host.name") = ##class(%SYS.System).GetNodeName()
	set provider = ##class(%Trace.TracerProvider).%New(.resattr)
	set sc = ##class(%Trace.Provider).SetTracerProvider(provider)
	kill provider
	set tracer = ##class(%Trace.Provider).GetTracerProvider().GetTracer("iris.otel.testing","2.0")
	set link = tracer.StartSpan("test_linkspan","","Internal")
	hang .001
	do link.End()
	set att1("span.key1") = "SpanValue1",att1("span.key2") = "SpanValue2"
	set root = tracer.StartSpan("test_rootspan","","Internal",.att1)
	set scope = tracer.SetActiveSpan(root)
	set ea("event.key1") = "EventValue1",ea("event.key2") = "EventValue2"
	set la("link.key1") = "LinkValue1",la("link.key2") = "LinkValue2"
	hang .001
	do root.AddEvent("event1",$zts,.ea)
	do root.AddLink(link.Context,.la)
	hang .002
	set att2("span.key3") = "SpanValue3",att2("span.key4") = "SpanValue4"
	set child = tracer.StartSpan("test_childspan","","Internal",.att2)
	hang .002
	do child.SetStatus("Ok")
	set ctx = ##class(%Trace.Context).%New()
	set ctx.ActiveSpan = child
	set child2 = tracer.StartSpan("test_childspan2",ctx,"Internal",.att2)
	hang .002
	do child2.End()
	do child.End()
	do root.SetStatus("Ok")
	do root.End()
	quit
}

Method %OnNew(tracername As %String, tracerversion As %String) As %Status [ Private ]
{
	#; A Tracer may only be created by TracerProvider.GetTracer
	i $$$CallingRoutine'="%Trace.TracerProvider.1" q 0
	set ..Name = tracername
	set ..Version = tracerversion
	q 1
}

}
