/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class contains SQL queries to replace old queries in %Library.ClassDefinition et al. classes.
Class %Dictionary.LegacyQuery [ Abstract, System = 4 ]
{

/// This query is to supersede query %Library.CompiledProperty:PropertyInfo
Query CompiledPropertyInfo(pClassName As %String) As %SQLQuery [ SqlName = CompiledPropertyInfo, SqlProc ]
{
SELECT CompiledProperty.Name AS PropertyName,
	CASE WHEN TypeClass.ClassType = 'datatype' THEN 1 ELSE 0 END AS Datatype,
	CompiledProperty.Type,
	CompiledProperty.Collection,
	coalesce(%Dictionary.GetParameterValue(CompiledProperty.Parameters,'CAPTION'),CompiledProperty.Name) AS Caption,
	CASE WHEN TypeClass.ClassType = 'serial' THEN 1 ELSE 0 END AS Serial,
	CASE WHEN CompiledProperty.Calculated = 0 THEN 1 WHEN ( SetMethod.Runnable <> 0 OR SetMethod.Stub IS NOT NULL ) THEN 1 ELSE 0 END AS Editable,
	%Dictionary.GetParameterValue(CompiledProperty.Parameters,'MAXLEN') AS MaxLen,
	CompiledProperty.Required,
	CASE WHEN TypeClass.ClassType = 'stream' THEN TypeClass.ClientDataType ELSE NULL END AS Stream
FROM %Dictionary.CompiledProperty AS CompiledProperty
	LEFT OUTER JOIN %Dictionary.CompiledMethod AS SetMethod ON CompiledProperty.Parent = SetMethod.Parent AND SetMethod.Name = ( CompiledProperty.Name || 'Set' )
	LEFT OUTER JOIN %Dictionary.CompiledClass AS TypeClass ON CompiledProperty.Type = TypeClass.Name
WHERE CompiledProperty.parent = :pClassName
	AND CompiledProperty.Private = 0
}

/// This query is to supersede query %Library.CompiledQuery:QueryInfo
Query CompiledQueryInfo(pClassName As %String) As %SQLQuery(ROWSPEC = "Name:%String:QueryName,ContainId:%String") [ SqlName = CompiledQueryInfo, SqlProc ]
{
SELECT Name AS Name,
	%Dictionary.GetParameterValue(Parameters,'CONTAINID') AS ContainId
FROM %Dictionary.CompiledQuery WHERE parent = :pClassName
}

/// This query is to supersede query %Library.CompiledClass:IndexInfo
Query CompiledIndexInfo(pClassName As %String) As %SQLQuery(ROWSPEC = "Name:%String,Attributes:%String,Type:%String,PrimaryKey:%Integer,Unique:%Integer") [ SqlName = CompiledIndexInfo, SqlProc ]
{
SELECT Name,
	Properties AS Attributes,
	CASE WHEN IdKey = 1 THEN 'idkey' WHEN Extent = 1 THEN 'extent' ELSE Type END AS Type,
	PrimaryKey,
	_Unique
FROM %Dictionary.CompiledIndex WHERE parent = :pClassName
}

}
