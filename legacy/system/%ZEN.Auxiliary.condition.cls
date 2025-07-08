/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a style-condition for a <class>%ZEN.Component.tablePane</class>.<br>
/// A <class>%ZEN.Component.tablePane</class> may define one or more conditions. Each
/// condition is evaluated when the table is displayed and provides a way to change the style
/// of rows or cells within the table based on the data values within a given row.<br>
/// Each condition consists of:
/// <ul>
/// <li><property>colName</property> - The name of the column in the table that provides the value to test.</li>
/// <li><property>value</property> - The value to test against (a literal or a reference to another column value)</li>
/// <li><property>predicate</property> - The comparison operator to use for the test.</li>
/// <li><property>cellStyle</property> - The CSS style to apply to the target cell if the condition is true.</li>
/// <li><property>rowStyle</property> - The CSS style to apply to the current row if the condition is true.</li>
/// </ul>
Class %ZEN.Auxiliary.condition Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// Name of a column within the table that this condition applies to.
Property colName As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Literal value that is compared against column value<br>
/// Note: if the value of <property>value</property> is enclosed in {}, then it refers to a column of that
/// name within the table. For example, "{PatientName}", will resolve to the value of the 
/// <i>PatientName</i> column within the table.
Property value As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// The comparison operator used to compare the value of the <property>colName</property>
/// column with <property>value</property>.<br>
/// This is one of the following:
/// <ul>
/// <li>GT - Greater than</li>
/// <li>EQ - Equal to</li>
/// <li>LT - Less than</li>
/// <li>NEQ - Not equal to</li>
/// <li>GTEQ - Greater than or equal to</li>
/// <li>LTEQ - Less than or equal to</li>
/// <li>EXTEQ - File extension (text after last ".") equal to</li>
/// <li>CONTAINS - Contains</li>
/// <li>STARTSWITH - Starts with</li>
/// </ul>
Property predicate As %ZEN.Datatype.string(VALUELIST = ",GT,EQ,LT,NEQ,GTEQ,LTEQ,EXTEQ,STARTSWITH,CONTAINS") [ InitialExpression = "EQ" ];

/// Optional.
/// The name of the column to apply CellStyle to.
/// If this is not provided, then the column specified by <var>colName</var> is used as the target.
Property targetCol As %ZEN.Datatype.string;

/// Style to apply to cell if condition is true.<br>
/// This is a CSS style string: e.g., "color: red;"
Property cellStyle As %ZEN.Datatype.style;

/// Style to apply to row if condition is true.<br>
/// This is a CSS style string: e.g., "color: red;"
Property rowStyle As %ZEN.Datatype.style;

/// Internal Method.<br>
/// Evaluate this condition using the values in the
/// provided row arrays.
Method Eval(ByRef pValues As %String) As %Boolean [ Internal ]
{
	Set tColName = $$$ZENVAL(..colName)
	Set tPredicate = $$$ZENVAL(..predicate)
	
	If ((tColName = "") || (tPredicate = "")) {
		Quit 0
	}

	#; get value	
	Set tValue = $$$ZENVAL(..value)

	If (($E(tValue,1) = "{") && ($E(tValue,$L(tValue)) = "}")) {
		#; de-reference column name
		Set tName = $E(tValue,2,$L(tValue)-1)
		If (tName '= "") {
			Set tValue = $G(pValues(tName))
		}
		Else {
			Set tValue = ""
		}
	}

	#; case-insensitive
	Set tValue = $ZCVT(tValue,"U")

	#; get data
	Set tData = $ZCVT($G(pValues(tColName)),"U")

	#; dispatch to predicate logic
	Goto $CASE(tPredicate,"EQ":EQ,"NEQ":NEQ,"GT":GT,"GTEQ":GTEQ,"LT":LT,"LTEQ":LTEQ,"EXTEQ":EXTEQ,"STARTSWITH":STARTSWITH,"CONTAINS":CONTAINS,:NOP)
EQ
	If tValue = "NULL" Quit tData = ""
	Quit tData = tValue
NEQ
	If tValue = "NULL" Quit tData '= ""
	Quit tData '= tValue
GT
	Quit tData > tValue
GTEQ
	Quit tData >= tValue
LT
	Quit tData < tValue
LTEQ
	Quit tData <= tValue
EXTEQ
	#; e.g. File extension equal to .obj
	Quit $E(tData,$L(tData)-3,$L(tData)) = tValue
STARTSWITH
	Quit (tValue="")||($E(tData,1,$L(tValue)) = tValue)
CONTAINS
	Quit tData [ tValue
NOP
	Quit 0
}

}
