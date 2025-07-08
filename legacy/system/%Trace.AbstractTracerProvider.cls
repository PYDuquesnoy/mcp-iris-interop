/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Instantiate a Tracer object, passing the configured properties for this Service.
/// Note that applications will typically have a central function to create the 
/// TracerProvider and then call GetTracer to return the Tracer object.
Class %Trace.AbstractTracerProvider Extends %RegisteredObject [ Abstract ]
{

/// Array of Resource Attributes, primarily service.name and service.version
Property ResourceAttributes As array Of %String;

/// Create a Tracer object which will be used to start Spans.
/// 'Name' should uniquely identify the application, library, package, or module.
Method GetTracer(Name As %String, Version As %String) As %Trace.AbstractTracer [ Abstract ]
{
}

}
