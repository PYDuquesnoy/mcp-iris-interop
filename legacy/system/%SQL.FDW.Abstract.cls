/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract class providing interface for Foreign Data Wrappers.
/// Foreign Data Wrappers provide the API for interacting with data stored in foreign sources 
/// such as CSV files, external databases, distributed file servers etc.
Class %SQL.FDW.Abstract Extends (%RegisteredObject, %SQL.StatementResult) [ Abstract, System = 4 ]
{

/// Specifies whether this foreign data wrapper supports pushing logical predicates to its source.
/// 0 by default, overridden to be 1 by the XDBC FDW
Parameter PREDICATEPUSHDOWN = 0;

Parameter PASSTHROUGH = 0;

/// Whether there are more buffers (batches of rows) that the source can return
Property RemainingBuffers As %Boolean;

/// The current buffer (batch of rows - a $lb of $lb's)
Property Buffer As %List;

/// Maintains the pointer output by $listnext
Property BufferPointer As %Integer;

/// The size of the buffer (number of characters)
Property BufferLength As %Integer;

/// Whether we are at the end of the entire result set
Property %AtEnd As %Boolean;

/// Multidimensional property that stores the current row being fetched, where each
/// node of the property is indexed by column number and the node data is the field value.
/// This is where the field data is accessed by cached queries and "overrides" the %GetData() method
/// of the %SQL.StatementResult parent class
Property %GetData As %String [ MultiDimensional ];

/// If this FDW/result is "open", set in %OnNew once the FDW has been instantiated
Property %IsOpened As %Integer [ InitialExpression = 0, Private ];

Property %ResultSetColumnCount As %Integer;

/// Disconnect Gateway, optionally stop External Language Server (costly to start it again).
Method CleanUp(StopLanguageServer As %Boolean) As %Status
{
}

/// Create the request string sent to Java
Method GetRequestObject(Server As %String, FTClassName As %String) As %Library.DynamicObject
{
}

/// Prepare the Query to be executed against the Server
Method Prepare(Server As %String, FTClassName As %String, Query As %String, Parameters As %List) As %Status
{
}

/// Execute the query, binding the given parameters first if necessary.
Method Execute(Parameters As %List) As %Status
{
}

/// Reset the result set back to the first row. Note this may entail a full re-execution depending on the specific
/// implmentation of the foreign data wrapper.
Method Reset() As %Status
{
}

/// Advance the result set cursor to the next row. Returns 0 if the cursor is at the end of the 
/// result set.. An optional argument contains a <class>%Library.Status</class> value on return. This %Status value
/// indicates success or failure of the %Next call. <property>%SQLCODE</property> is also set by %Next.
Method %Next(ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer
{
}

Method Close() As %Status
{
    RETURN $$$OK
}

/// Every foreign data wrapper should build it's own version of this method to return metadata about the columns
/// that will be provided by the foreign data wrapper. Each one should return metadata as specified below. This metadata
/// should be made available as requested after the Prepare() stage of the foreign data wrapper. If desired, a foreign data wrapper can 
/// wait until this method is called to retrieve and then build the corresponding metadata structure.
/// 
/// see also %SQL.StatementMetadata:%GenerateMetadata()
///  metadata = $lb()
/// 		1 - # of SELECT columns
/// 		2 - i:  <For each SELECT column>
/// 			1) Name
/// 			2) ODBC Type
/// 			3) Precision
/// 			4) Scale
/// 			5) NULLABLE (integer)
/// 			6) Column Label (same as Name)
/// 			7) Column Table Name
/// 			8) Column Schema Name
/// 			9) Column Qualifier Name - NULL
/// 			10) $Char(1)/$Char(0) string / $Extract position:
/// 				1)  isAutoIncrement
/// 				2)  isCaseSensitive
/// 				3)  isCurrency
/// 				4)  IsReadOnly
/// 				5)  IsRowVersion
/// 				6)  IsUnique
/// 				7)  IsAliased
/// 				8)  IsExpression
/// 				9)  IsHidden
/// 				10) IsIdentity
/// 				11) IsKeyColumn
/// 				12) IsRowid
/// 				13) IsList
Method GetSQLMetaData(Output metadata) As %Status
{
}

/// Quote identifiers appropriately for the data source type that this foreign data wrapper wraps based 
/// on whether delimited identifiers should be supported.
/// 
/// Default implementation returns the identifier as is. It is up to the subclass to implement the behavior
/// appropriate for the data source type.
ClassMethod QuoteIdentifier(identifier As %String, supportsDelimitedIdentifiers As %Boolean) As %String
{
    RETURN identifier
}

Method SetSQLCODEFromStatus(sc As %Status, optionalMessage As %String = "")
{
    set i%%SQLCODE = $SYSTEM.Status.StatusToSQLCODE(sc)
    set i%%Message = $s(optionalMessage="": $SYSTEM.Status.GetErrorText(sc), 1: optionalMessage)
}

}
