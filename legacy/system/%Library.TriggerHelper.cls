/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.TriggerHelper Extends %RegisteredObject [ Language = objectscript ]
{

/// Holds the property names/values that can be referenced by the Python trigger code
Property properties As %String(MAXLEN = 250) [ MultiDimensional ];

/// Holds the type of trigger, (Foreach).  row, row/object, statement
Property type As %RawString;

/// Holds the operation being performed. 
/// Returns INSERT, UPDATE, or DELETE depending on the current SQL /Objects operation
Property operation As %RawString;

/// Holds the time when the trigger is pulled, 'before' or 'after'
Property time As %RawString;

/// 1/0 flag.  Set to 0 if the trigger failed and should cause the filing operation to report an error with a message in msg
Property ok As %RawString [ InitialExpression = 1 ];

/// Holds an error message when ok=0
Property msg As %RawString;

Method getfield(fieldname As %RawString, newold As %Boolean = 1) As %RawString [ Language = objectscript ]
{
	RETURN $get(..properties($zcvt(fieldname,"L"),$s(newold=1:"n",1:"o")))
}

Method getoperation() As %RawString [ Language = objectscript ]
{
	RETURN ..operation
}

Method gettype() As %RawString [ Language = objectscript ]
{
	RETURN ..type
}

}
