/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements SASchema for the DeepSee model classes.
Class Ens.Rule.Model.SASchema Extends %Studio.SASchemaClass [ System = 3 ]
{

/// This is the namespace value used to identify this SA schema.
/// This corresponds to the XMLNamespace keyword of a Studio XData block.
Parameter XMLNAMESPACE = "http://www.intersystems.com/rule";

/// This is comma-separated list of the classes whose xml elements
/// can be used as the root level element of a document.
Parameter ROOTCLASSES As STRING = "Ens.Rule.Model.ruleDefinition:ruleDefinition";

}
