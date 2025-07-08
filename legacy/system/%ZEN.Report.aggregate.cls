/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an aggregate element within a ZEN Report.
Class %ZEN.Report.aggregate Extends valueNode [ Deprecated, System = 3 ]
{

/// Type of aggregate to calculate.
Property type As %ZEN.Datatype.string(MAXLEN = 50, VALUELIST = ",COUNT,SUM,AVG,MIN,MAX,CUSTOM,PLACEHOLDER,EXPRESSION");

Property class As %ZEN.Datatype.className;

Property format As %ZEN.Datatype.string;

/// escape can be nonspace in which case any text with line-feed or space characters is not XML spaced
/// or none in which case no characters are XML spaced but all are enclosed in CDATA
/// or xml in which case the text is XML escaped
/// this controls elements and attributes in groups
Property escape As %ZEN.Datatype.string(VALUELIST = ",xml,none,noneifspace") [ InitialExpression = "xml" ];

/// In Excel mode, have ZEN Reports use this formula to calculate aggregate =formula(cellbeginnings:cellend)
Property excelFormula As %ZEN.Datatype.string;

/// Unique id for aggregate.  Doesn't matter what it is as long as it is unique
/// Doesn't need to be set unless one is using EXPRESSION aggregate that refers to other unique aggregates
/// Other unique aggregates have values in %agg(..uniqueId)
Property uniqueId As %ZEN.Datatype.string;

Property excelName As %ZEN.Datatype.string;

/// if non-null is display number format of aggregate value, only effective when mode="xlsx"
Property excelNumberFormat As %ZEN.Datatype.string;

/// When filter is 0, element is skipped
Property filter As %ZEN.Datatype.integer [ InitialExpression = 1 ];

Property preprocessValue As %ZEN.Datatype.boolean;

Property postprocessResult As %ZEN.Datatype.boolean;

/// Don't process NLS concerns in the aggregate (if null we pick up default from report parameter AGGREGATESIGNORENLS)
Property ignoreNLS As %ZEN.Datatype.boolean;

/// internal property used to communicate with custom aggregates
Property runtimeMode As %Integer(XMLPROJECTION = "none");

ClassMethod %PreProcessValue(value As %String, preprocessValue As %Boolean, runtimeMode As %Integer, ignoreNLS As %Boolean)
{
	
	If (+preprocessValue=0||(ignoreNLS=1)||(value="")) {
		quit value
	} else {
		if runtimeMode=2 {
			quit $INUMBER(value,",")
		} else {
			quit value
		}

	}
}

ClassMethod %PostProcessValue(result As %String, postprocessResult As %Boolean, runtimeMode As %Integer, ignoreNLS As %Boolean)
{
	If (+postprocessResult=0||(ignoreNLS=1)) {
		quit result
	} else {
		if runtimeMode=2 {
			quit $FNUMBER(result,"N")
		} else {
			quit result
		}

	}
}

}
