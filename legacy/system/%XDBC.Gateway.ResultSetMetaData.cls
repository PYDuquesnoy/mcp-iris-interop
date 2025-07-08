/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// FOR INTERNAL USE - do not invoke directly
Class %XDBC.Gateway.ResultSetMetaData Extends %RegisteredObject [ System = 4 ]
{

/// Internal metadata format specific to xDBC result sets
/// For regular serialized metadata for IRIS result sets, see <method>ToSQLMetadata</method>
Property %xdbcMetadata As %List [ Internal, MultiDimensional, Private ];

Property %columnindex As %Integer [ Internal, MultiDimensional, Private ];

Parameter SERVERRESULTSETMETADATAVERSION As INTEGER = 1;

Method %OnNew(metadata As %List) As %Status
{
    /*
	Version 0 (before version 1):
        mdl.add(metadata.getCatalogName(colIndex));
        mdl.add(metadata.getSchemaName(colIndex));
        mdl.add(metadata.getTableName(colIndex));
        mdl.add(metadata.getColumnName(colIndex));
        mdl.add(metadata.getColumnLabel(colIndex));
        mdl.add(metadata.getColumnType(colIndex));
        mdl.add(metadata.getPrecision(colIndex));
        mdl.add(metadata.getScale(colIndex));
        mdl.add(metadata.getColumnTypeName(colIndex));
	Version 1 appends:
		mdl.add(metadata.getColumnDisplaySize(colIndex));
    */
    set ..%xdbcMetadata = $listget(metadata)
    set cstart = 2
    for c = 1:1:..%xdbcMetadata {
        set ..%xdbcMetadata(c) = $list(metadata,cstart, cstart + 9)
        set cstart = cstart + 10
		set columnName = $listget(..%xdbcMetadata(c),4)
		if columnName = "" {
			set unlabeledCols(c) = ""
		} else {
			set ..%columnindex($$$lcase(columnName)) = c
		}
    }
	// Some DBs don't return column names for e.g. aggregates, can cause problems later on; now that we have all the named columns we can assign unique placeholder names to unnamed columns
	if $d(unlabeledCols) {
		set colIndex = ""
		for {
			set colIndex = $o(unlabeledCols(colIndex))
			QUIT:colIndex=""
			set name = "Unlabeled_Column_"_$i(labelCount)
			while $d(..%columnindex($$$lcase(name))) {
				set name = "Unlabeled_Column_"_$i(labelCount)
			}
			set $li(..%xdbcMetadata(colIndex), 4) = name
			set ..%columnindex($$$lcase(name)) = colIndex
		}
	}
    return $$$OK
}

Method find(columnname As %String(MAXLEN=220)) As %Integer
{
    try {
        return ..%columnindex($$$lcase(columnname))
    } catch e {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(-102, "Column does not exist")
    }
}

Method GetColumnCount() As %Integer
{
    return ..%xdbcMetadata
}

Method GetColumnLabel(colIdx As %Integer) As %String(MAXLEN=220)
{
    return $listget(..%xdbcMetadata(colIdx), 5)
}

Method GetColumnName(colIdx As %Integer) As %String(MAXLEN=220)
{
    return $listget(..%xdbcMetadata(colIdx), 4)
}

Method GetTableName(colIdx As %Integer) As %String(MAXLEN=220)
{
    return $listget(..%xdbcMetadata(colIdx), 3)
}

Method GetSchemaName(colIdx As %Integer) As %String(MAXLEN=220)
{
    return $listget(..%xdbcMetadata(colIdx), 2)
}

Method GetPrecision(colIdx As %Integer) As %Integer
{
    return $listget(..%xdbcMetadata(colIdx), 7)
}

Method GetScale(colIdx As %Integer) As %Integer
{
    return $listget(..%xdbcMetadata(colIdx), 8)
}

Method GetCatalogName(colIdx As %Integer) As %String(MAXLEN=220)
{
    return $listget(..%xdbcMetadata(colIdx), 1)
}

Method GetColumnType(colIdx As %Integer) As %Integer
{
    return $listget(..%xdbcMetadata(colIdx), 6)
}

Method GetColumnTypeName(colIdx As %Integer) As %String(MAXLEN=220)
{
    return $listget(..%xdbcMetadata(colIdx), 9)
}

Method GetColumnDisplaySize(colIdx As %Integer) As %Integer
{
    return $listget(..%xdbcMetadata(colIdx), 10)
}

/// Internal method to lazily build an IRIS-internal $list representation of the result set metadata
/// from <property>%xdbcMetadata</property>
Method ToSQLMetadata(Output metadata) As %Status [ Internal ]
{
	// see also %SQL.StatementMetadata:%GenerateMetadata()
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
	kill metadata
	set sc = $$$OK
	set ptr = 0, 
		metadata(ptr) = $lb(..GetColumnCount())
	try {
		for i = 1:1:..GetColumnCount() {
			set metadata(ptr) = metadata(ptr) _ $lb(  ..GetColumnName(i), 		// Name
													..GetColumnType(i), 		// ODBC Type
													..GetPrecision(i), 		// Precision
													..GetScale(i), 			// Scale
													1, 								// Nullable - no upstream info
													..GetColumnLabel(i), 		// Column Label
													..GetTableName(i), 		// Column Table Name
													..GetSchemaName(i), 		// Column Schema Name
													..GetCatalogName(i), 		// Column Qualifier Name (catalog)
													$c(0,0,0,0,0,0,0,0,0,0,0,0,0))  	// additional MD - no upstream info
			set:$l(metadata(ptr))>32000 ptr = ptr+1, metadata(ptr)=""
		}
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	quit sc
}

}
