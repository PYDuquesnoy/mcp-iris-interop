/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A Tracer object allows you to start a Span.
/// A Tracer object MUST be created by calling TracerProvider.GetTracer().
Class %Trace.AbstractTracer Extends %RegisteredObject [ Abstract ]
{

/// The Tracer Name should uniquely identify the application, library, package, or module.
Property Name As %String;

/// Version of this library (optional)
Property Version As %String;

/// Initialize a Span object. Span objects should only be created by calling StartSpan.
Method StartSpan(Name As %String, Parent As %Trace.Context = "", Spankind As %String = "Internal", Attributes As %String, StartTime As %String) As %Trace.AbstractSpan [ Abstract ]
{
}

}
