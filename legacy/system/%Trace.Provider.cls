/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Store and retrieve a TracerProvider singleton for this Namespace. 
/// An application can define a TracerProvider at startup, and then save it using this class.
/// Then all instrumentation code can access the single TracerProvider to create a Tracer.
/// <br><br>
/// Note that this uses temporary storage in the Namespace in which it's created, so it must
/// be initialized at each startup.
Class %Trace.Provider Extends %RegisteredObject
{

/// Save the default TracerProvider for this Namespace.
ClassMethod SetTracerProvider(Provider As %Trace.TracerProvider) As %Status
{
	set sc = $$$OK
	try {	
		set key = ""
		for {
			set att = Provider.ResourceAttributes.GetNext(.key) quit:key=""
			set resattr(key) = att
		}
		kill ^IRIS.Temp.TracerProvider($namespace)
		merge ^IRIS.Temp.TracerProvider($namespace,"ResourceAttributes") = resattr
	} catch exc {
		set sc = exc.AsStatus()	
	}
	quit sc
}

/// Retrieve the default TracerProvider for this Namespace.
/// If no default has been set, then a NoopTracerProvider is returned.
ClassMethod GetTracerProvider() As %Trace.TracerProvider
{
	if '$d(^IRIS.Temp.TracerProvider($namespace)) {		
		quit ##class(%Trace.NoopTracerProvider).%New()
	}
	set provider = ##class(%Trace.TracerProvider).%New()
	set key = ""
	for {
		set key=$o(^IRIS.Temp.TracerProvider($namespace,"ResourceAttributes",key),1,value) quit:key=""
		do provider.ResourceAttributes.SetAt(value,key)
	}
	quit provider
}

}
