/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %REST.Application describes a REST application.
Class %REST.Application Extends (%RegisteredObject, %JSON.Adaptor) [ System = 4 ]
{

/// The name of the REST application either in the form of
/// a web application name or package for REST specification class name.
Property name As %String(MAXLEN = "");

/// a comma separated list of the web application that the REST application is deployed to.
Property webApplications As %String(MAXLEN = "");

/// The name of the dispatch class for this REST application.
Property dispatchClass As %String(MAXLEN = "");

/// The namespace in which this application is defined.
Property namespace As %String(MAXLEN = "");

/// Resource which is required for this application of the form resource:mode.
Property resource As %String(MAXLEN = "");

/// A URL to produce a swagger specification for this application.
Property swaggerSpec As %xsd.anyURI;

/// This application is enabled if the enabled property is true.
Property enabled As %Boolean;

}
