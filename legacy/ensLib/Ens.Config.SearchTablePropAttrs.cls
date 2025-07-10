/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// SearchTable Property attributes, shared between Item and Prop definitions
Class Ens.Config.SearchTablePropAttrs [ Abstract, ClassType = "", ProcedureBlock, System = 2 ]
{

/// Normalize case for this property type when storing and querying
Property PropType As %String(VALUELIST = ",String:CaseSensitive,String:CaseInsensitive,Integer,Numeric,Boolean,DateTime:ODBC,DateTime:HL7", XMLPROJECTION = "ATTRIBUTE");

Property Unselective As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

/// Store empty values in the SearchTable for this property type
Property StoreNulls As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

/// Build an index of this type for values stored with this property type
Property IndexType As %String(VALUELIST = ",None,Standard,Bitmap", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "None" ];

}
