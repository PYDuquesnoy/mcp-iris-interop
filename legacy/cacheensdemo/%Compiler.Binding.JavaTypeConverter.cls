/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Compiler.Binding.JavaTypeConverter Extends %RegisteredObject [ System = 4 ]
{

Property objectLibraryTypes;

Property timeTypes;

Property projParams As %ArrayOfDataTypes;

Property primitiveDataTypes As %Boolean;

Method %OnNew(projParams As %ArrayOfDataTypes) As %Status [ Private, ServerOnly = 1 ]
{
	s ..objectLibraryTypes = $lb("ListOfDataTypes", "ArrayOfDataTypes", "ListOfObjects", "ArrayOfObjects",
									"BinaryStream", "CharacterStream", "AbstractStream", "ObjectHandle",
									"Id", "Oid", "BigDecimal", "StatusCode")
	s ..timeTypes = $lb("java.sql.Date", "java.sql.Time", "java.sql.Timestamp", "Fileman.Date", "Fileman.Timestamp", "Posix.Timestamp")
	s ..projParams = projParams
	s ..primitiveDataTypes = projParams.GetAt("PRIMITIVEDATATYPES")
	Quit $$$OK
}

Method getSigType(returnType As %String, newCollections As %Boolean) As %String
{
	s returnTypePackage = $p(returnType, ".", 1)
	s sigType = $select(returnType = "Status": "void",
						returnTypePackage = "Fileman": "java.sql."_$p(returnType, ".", *),
						returnTypePackage = "Posix": "java.sql."_$p(returnType, ".", *),
						1: returnType)				
	if newCollections {
		s sigType = $case(sigType, "com.intersystems.binding.ListOfObjects": "java.util.List",
									"com.intersystems.binding.ListOfDataTypes": "java.util.List",
									"com.intersystems.binding.ArrayOfObjects": "java.util.Map",
									"com.intersystems.binding.ArrayOfDataTypes": "java.util.Map",
									: sigType)
	}
	if ..primitiveDataTypes {
		s sigType = $case(sigType, "Integer": "int",
								"Double": "double",
								"Boolean": "boolean",
								"Long": "long",
								: sigType)	
	}
	return sigType
}

Method convertType(fullType As %String, ByRef package As %String, ByRef type As %String, ByRef elementType = "", collectionType = "", isRelationship = 0, ByRef qstruct As %String) As %Status
{
	s Status = $$$OK
	s package = $p(fullType, ".", 1)
	s type = $p(fullType, ".", 2)
	s elementType = type
	
	// Type can be:
	// (1) Stream,
	// (2) data type,
	// (3) object type, or
	// (4) user-defined data type.
	// If the latter 3, convert it.
	// First, project and save the type to class mapping.
	if '$data(^irisToJavaClassName(fullType)) {
		s Status = ##class(%Compiler.Binding.Java).CreateProjection(fullType, ..projParams, 0,,.qstruct)
		if $$$ISERR(Status) {q Status}
	}
	s type = $get(^irisToJavaClassName(fullType))

	// Process %Library type of form '%Typename'
	if $extract(type, 1, 1) = "%" {
		s package = "%Library"
		s type = $extract(type, 2, *)
	}
	
	s elementType = type
	
	// If type is collection, convert to the right Java equivalent
	if collectionType '= "" {
		if isRelationship {
			s type = "com.intersystems.binding.RelationshipObject"
		} elseif package = "%Library" {
			s type = $case(collectionType, "list": "com.intersystems.binding.ListOfDataTypes",
											"array": "com.intersystems.binding.ArrayOfDataTypes")
		} else {
			s type = $case(collectionType, "list": "com.intersystems.binding.ListOfObjects",
												"array": "com.intersystems.binding.ArrayOfObjects")
		}
	}
	
	q Status
}

Method convertCDType(type As %String, className = "") As %String
{
	if className = "PosixTime" {
		q "Posix.Timestamp"	
	} elseif (className = "ObjectIdentity") && (type = "BINARY") {
		q "Oid"	
	}
	
	if $lf(..objectLibraryTypes, className) {
		q "com.intersystems.binding."_className
	}
	
	if ..primitiveDataTypes {
		s type = $case(type, "INTEGER": "%int",
								"DOUBLE": "%double",
								"BOOLEAN": "%boolean",
								"BIGINT": "%long",
								:type)
	}
	
	q $case(type, "BIGINT": "%Long",
					"BINARY": "%byte[]",
					"BOOLEAN": "%Boolean",
					"DOUBLE": "%Double",
					"VARCHAR": "%String",
					"LONGVARCHAR": "%String",
					"CURRENCY": "%java.math.BigDecimal",
					"DATE": "%java.sql.Date",
					"FDATE": "%Fileman.Date",
					"TIMESTAMP": "%java.sql.Timestamp",
					"FTIMESTAMP": "%Fileman.Timestamp",
					"DECIMAL": "%Double",
					"LIST": "%com.intersystems.jdbc.IRISList",
					"NUMERIC": "%java.math.BigDecimal",
					"INTEGER": "%Integer",
					"TIME": "%java.sql.Time",
					"BINARYSTREAM": "com.intersystems.binding.BinaryStream",
					"CHARACTERSTREAM": "com.intersystems.binding.CharacterStream",
					"HANDLE": "com.intersystems.binding.ObjectHandle",
					"STATUS": "%com.intersystems.binding.StatusCode",
							: type)
}

Method convertObjectTypes(type As %String) As %String
{
	q $case(type, "RegisteredObject": "com.intersystems.binding.RegisteredObject",
					"SerialObject": "com.intersystems.binding.SerialObject",
					"Persistent": "com.intersystems.binding.Persistent",
								: type)
}

Method paramsToArguments(params As %List, isStatic = 0, convertsType = 1) As %String
{
	s args = ""
	s paramNum = $listlength(params)

	if paramNum > 0 {
		for i=1:1:paramNum {
			s param = $list(params, i)
			s paramType = $p(param, " ", 1)
			s paramName = $p(param, " ", 2)
			
			if convertsType {
			if $data(^projectedJavaClasses(paramType)) || $lf(..objectLibraryTypes, $p(paramType, ".", *)) {
				s op = $case(paramType, "Id": ".toString()",
										"Oid": ".getData()",
										"com.intersystems.binding.StatusCode": ".getBytes()",
										"java.math.BigDecimal": ".doubleValue()",
										: ".getProxy()")	
				s paramName = paramName_" == null ? null : "_paramName_op
				
			} elseif $lf(..timeTypes, paramType) {
				s package = $p(paramType, ".", 1)
				s timeOp = $case(package, "Fileman": "Fileman",
											"Posix": "Posix",
													: "")
				s iris = $select((package = "Fileman") && isStatic: "iris, ",
									package = "Fileman": "irisObject.iris, ",
													1: "")
				s paramName = "Util."_timeOp_$p(paramType, ".", *)_"IRISFormat("_iris_paramName_")"
			}
			}

			s args = args_", "_paramName
		}
	}
	return args
}

Method paramsToString(params As %List) As %String
{
	for i = 1:1:$listlength(params) {
		s param = $list(params, i)
		s paramType = $p(param, " ", 1)
		s paramName = $p(param, " ", 2)
		if ($p(paramType, ".", 1) = "Fileman") || ($p(paramType, ".", 1) = "Posix")  {
			s $list(params, i) = "java.sql."_$p(paramType, ".", *)_" "_paramName
			continue	
		}
		if ..primitiveDataTypes {
			s paramType = $case(paramType, "Integer": "int",
											"Double": "double",
											"Boolean": "boolean",
											"Long": "long",
													:paramType)
			s $list(params, i) = paramType_" "_paramName
		}
	}
	return $listtostring(params, ", ")
}

Method getTypeForIRISCall(type As %String, returnsObject As %Boolean, notPropertyCall = 0) As %String
{
	if type = "Oid" {return "String"}
	elseif type = "com.intersystems.binding.StatusCode" {return "Bytes"}
	if returnsObject || ($p(type, ".", 1, 3) = "com.intersystems.binding") {return "Object"}
	if notPropertyCall && (type = "Posix.Timestamp") {return "String"}
	
	return $case(type, "Integer": "Long",
						"int": "Long",
						"long": "Long",
						"double": "Double",
						"boolean": "Boolean",
						"byte[]": "Bytes",
						"void": "Void",
						"Status": "StatusCode",
						"java.sql.Date": "Long",
						"java.sql.Timestamp": "String",
						"java.sql.Time": "Long",
						"Fileman.Date": "Long",
						"Fileman.Timestamp": "String",
						"Posix.Timestamp": "Long",
						"java.math.BigDecimal": "Double",
						"com.intersystems.jdbc.IRISList": "IRISList",
						: type)
}

}
