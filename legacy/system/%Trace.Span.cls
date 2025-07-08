/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%callout, %syMonitor, %sySecurity, %sySystem)

/// Tracks and manages a Trace Span object. Spans MUST be created by calling Tracer:StartSpan()
Class %Trace.Span Extends %Trace.AbstractSpan
{

/// Value which indicates if the Span is "recording", i.e. any data related to the Span wil be recorded.
/// This is set to 1 when the Span is created (StartSpan) and 0 when span.End() is called.
Property IsRecording As %Boolean [ InitialExpression = 1 ];

/// Provider properties passed from Tracer
Property Tracer As %Trace.Tracer [ Internal ];

/// End and record Span. EndTime is optional, in $ZTS format (defaults to current time).
Method End(EndTime As %String = {$zts})
{
	if '..IsRecording quit
	if '..Context.IsValid() || ($$$OTELTRACEISOFF) set ..IsRecording = 0 quit
	try {
		set ..EndTime = EndTime
		set parent = ""
		#; create 'parent' SpanContext parameter as concatentated string with multiple fixed length components + tracestate string
		if ..Parent]"" {
			set parent = ..Parent.ToString()_+..Parent.IsRemote_..Parent.StateToString()
		}
		set name = $zcvt(..Name,"O","UTF8")
		#; pass 'attributes' parameter as a list of C strings (null terminated)
		set attributes="",key=""
		for  {
			set val=..Attributes.GetNext(.key) quit:key=""
			set attributes=attributes_$zcvt(key,"O","UTF8")_$c(0)_$zcvt(val,"O","UTF8")_$c(0)
		}
		#; pass 'resattributes' parameter as list of C strings
		set resattributes="",key=""
		for  {
			set val=..Tracer.ResourceAttributes.GetNext(.key) quit:key=""
			set resattributes=resattributes_$zcvt(key,"O","UTF8")_$c(0)_$zcvt(val,"O","UTF8")_$c(0)
		}
		#; pass 'events' parameter as list of C strings
		set events="",key=""
		for {
			set evt=..Events.GetNext(.key) quit:key=""
			set events = events_$zcvt(evt.Name,"O","UTF8")_$c(0)_$$$OTELtimestamp(evt.Timestamp)_$c(0)
			set ekey = ""
			for {
				set eval = evt.Attributes.GetNext(.ekey) quit:ekey=""
				set events=events_$zcvt(ekey,"O","UTF8")_$c(0)_$zcvt(eval,"O","UTF8")_$c(0)
			}
			#; add a null attribute to signal the end of the list
			set events = events_$c(0)
		}
		#; pass 'links' parameter as list of C strings
		set links="",key=""
		for {
			set link = ..Links.GetNext(.key) quit:key=""
			#; Context is a fixed-length (56 characters) string
			set links = links_link.Context.ToString()_+link.Context.IsRemote
			set lkey = ""
			for {
				set lval = link.Attributes.GetNext(.lkey) quit:lkey=""
				set links = links_$zcvt(lkey,"O","UTF8")_$c(0)_$zcvt(lval,"O","UTF8")_$c(0)
			}
			#; add a null attribute to signal the end of the list
			set links = links_$c(0)
		}
		#; pass 'tracer' Name and Version as a list of 2 C strings
		set tracer=..Tracer.Name_$c(0)_..Tracer.Version_$c(0)
		try {
			#; zfSendTrace(name, spancontext, parentcontext, spankind, status, start, end, attributes, resourceattributes, links, events, tracer_info)
			#; Note that many of these parameters (parent, attributes, resourceattributes, links, events) are lists or other
			#; structures, which are passed as null terminated C strings, or counted strings with embedded C strings.
			#; See the $ZF definition and C++ code for zfSendTrace.
			set zh = $zh
			do $ZF(-6,$$$IrisOTelLibrary,4,name,..Context.ToString(),parent,..SpanKind,..Status,$$$OTELtimestamp(..StartTime),$$$OTELtimestamp(..EndTime),attributes,resattributes,links,events,tracer)
			if ($zh - zh) > $$$OTELTIMEOUT {
				$$$SevereMsg("OTel Send Trace exceeded timeout, disabling Traces.")
				$$$OTELTRACEOFF
			}
		} catch exc {
			#; trap error if this system doesn't have libirisotel
			if exc.Name'="<DYNAMIC LIBRARY LOAD>",exc.Name'="<VALUE OUT OF RANGE>" THROW exc
			$$$WarnMsg("Unable to access OTel Traces library, disabling Traces.")
			$$$OTELTRACEOFF
		}
	} catch {
		$$$SevereMsg("Unexpected error in OTel Trace, disabling Traces. $ze = "_$ze)
		$$$OTELTRACEOFF		
	}
	set ..IsRecording = 0
	quit
}

/// Update the Status of the Span. Only 'Unset', 'Ok', 'Error' allowed.
Method SetStatus(status As %String)
{
	if '..IsRecording quit
	if '$lf($lb("Unset","Ok","Error"),status) quit
	#; enforce total order of Ok > Error > Unset
	if ..Status'="",status = "Unset" quit
	if ..Status="Ok",status="Error" quit 
	set ..Status = status
}

/// Add a Link for another Span. Pass 'attributes' by reference as an array(key, value)
Method AddLink(context As %Trace.SpanContext, attributes As %String)
{
	if '..IsRecording quit
	set link = ##class(%Trace.SpanLink).%New()
	set link.Context = context
	set key = ""
	for  {
		set key = $o(attributes(key),1,value) quit:key=""
		do link.Attributes.SetAt(value,key)
	}
	do ..Links.Insert(link)
}

/// Add an Event related to this Span. Pass 'attributes' by reference as an array(key, value).
/// 'timestamp' is in $ZTS format, and will be set to current $ZTS if left null.
Method AddEvent(name As %String, timestamp As %String, attributes As %String)
{
	if '..IsRecording quit
	set event = ##class(%Trace.SpanEvent).%New()
	set event.Name = name
	if $g(timestamp) = "" set timestamp = $zts
	set event.Timestamp = timestamp
	set key = ""
	for  {
		set key=$o(attributes(key),1,value) quit:key=""
		do event.Attributes.SetAt(value,key)
	}
	do ..Events.Insert(event)
}

Method %OnNew() As %Status [ Private ]
{
	#; A Span may only be created by Tracer.StartSpan
	i $$$CallingRoutine'="%Trace.Tracer.1" q 0
	q 1
}

}
