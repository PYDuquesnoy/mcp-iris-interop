/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Instantiate a Tracer object, passing the configured properties for this Service.
/// <p>
/// You may pass an array by reference on %New to set any ResourceAttributes
/// <example>
/// set array("service.name") = "MyService"
/// set array("service.version") = "1.0"
/// set provider = ##class(%Trace.TracerProvider).%New(.array)
/// </example>
/// <p>
/// Note that applications will typically have a central function to create the 
/// TracerProvider and then call GetTracer to return the Tracer object.
Class %Trace.TracerProvider Extends %Trace.AbstractTracerProvider
{

/// Create a Tracer object which will be used to start Spans.
/// 'Name' should uniquely identify the application, library, package, or module.
Method GetTracer(Name As %String = "IRIS OTel Traces", Version As %String = "unknown") As %Trace.AbstractTracer
{
	set tracer = ##class(%Trace.Tracer).%New(Name, Version)
	set tracer.ResourceAttributes = ..ResourceAttributes
	quit tracer
}

Method %OnNew(Attributes As %String) As %Status [ Private ]
{
	if $d(Attributes) {
		set key=""
		for  {
			set key = $o(Attributes(key),1,value) quit:key=""
			do ..ResourceAttributes.SetAt(value,key)
		}
	}
	quit $$$OK
}

}
