/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Instantiate a Noop Tracer object
/// <p>
/// This allows an application to 'disable' tracing without the need for extra
/// logic in its instrumentation code. By using the NoopTracerProvider, all
/// code using the %Trace API will still work, but no Spans will be recorded.
/// 
Class %Trace.NoopTracerProvider Extends %Trace.AbstractTracerProvider
{

Method GetTracer(Name As %String, Version As %String) As %Trace.AbstractTracer
{
	set tracer = ##class(%Trace.NoopTracer).%New()
	quit tracer
}

}
