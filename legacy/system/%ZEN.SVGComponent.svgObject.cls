/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an abstract base class used to define auxilary components that
/// are used by SVG components but do not have a visual representation.
Class %ZEN.SVGComponent.svgObject Extends %ZEN.Component.object [ Abstract, Deprecated, System = 3 ]
{

/// Internal parameter.
/// Make sure we generate SVG include files
Parameter POSTCOMPILEACTIONS = "schema,SVG";

}
