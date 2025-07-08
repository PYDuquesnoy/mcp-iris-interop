/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a link displayed by the <class>%ZEN.Component.locatorBar</class> component.<br>
Class %ZEN.Auxiliary.locatorLink Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// Caption displayed for a locator link.
/// This is a localizable value.
Property caption As %ZEN.Datatype.caption;

/// URI used for a locator link.
Property href As %ZEN.Datatype.uri;

/// Optional.
/// Tooltip help for a locator link.
/// This is a localizable value.
Property title As %ZEN.Datatype.caption;

/// Allows for programmatically setting the target for which target window will open the document. It defaults to '_top'. 
/// Valid options are _blank, _parent, _self, _top, or framename
Property target As %ZEN.Datatype.string [ InitialExpression = "_top" ];

}
