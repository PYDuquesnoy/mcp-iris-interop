/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements SASchema for the ZEN mobile classes
Class %ZEN.Mobile.SASchema Extends %Studio.SASchemaClass [ Deprecated, System = 3 ]
{

/// This is the namespace value used to identify this SA schema.
/// This corresponds to the XMLNamespace keyword of a Studio XData block.
Parameter XMLNAMESPACE As STRING = "http://www.intersystems.com/zen/mobile";

/// This is comma-separated list of the classes whose xml elements
/// can be used as the root level element of a document.
Parameter ROOTCLASSES As STRING = "%ZEN.Component.page:page,%ZEN.Component.pane:pane";

Parameter SACATEGORY = "mobile";

}
