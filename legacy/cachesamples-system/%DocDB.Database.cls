/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DocDB.Document

/// <class>%DocDB.Database</class> implements the DocDB ObjectScript User Database API.  <br> <br>
/// <!doctype html public "-//w3c//dtd html 4.0 transitional//en">
/// <html>
/// <head>
///    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
///    <meta name="GENERATOR" content="Mozilla/4.77 [en] (Windows NT 5.0; U) [Netscape]">
/// 	<style type="text/css">
/// 		table.todo {
/// 				background-color:yellow;
/// 				border:1px solid red;
/// 			}
/// 		table.todo tr td {
/// 				vertical-align:top;
/// 				border:1px solid red;
/// 			}
/// 	</style>
///    <title>DocDB</title>
/// </head>
/// <body>
/// <h1>DocDB ObjectScript User Database API</h1>
/// <p>
/// This class implements the public DocDB ObjectScript User Database API. 
/// </p>
/// <p>
/// A Database is a set of Documents, implemented by a objects persistent class that extends <class>%DocDB.Document</class>. 
/// </p>
/// <p>
/// Databases are explicitly created by calling <method>%CreateDatabase</method>. A previously created Database can 
/// be retrieved by calling the <method>%GetDatabase</method>. 
/// </p>
/// <p>
/// A Document is inserted into a Database by executing <method>%SaveDocument</method>, passing in the document value as a string containing a 
/// valid serialized document, or an instance of the type class. The default type class is <class>%Library.DynamicAbstractObject</class> and 
/// the default serialization is JSON. An existing Document can be replaced by passing in the documentID. If a documentID is provided and that document does 
/// not exist then an exception is thrown. 
/// </p>
/// <p>
/// %SaveDocument() returns an oref referencing the newly created document. If an error is encountered by %SaveDocument() an exception is thrown. 
/// </p>
/// <p>
/// Other methods to access documents are <method>%GetDocument</method> and <method>%DeleteDocument</method>. There are also ByKey versions of %GetDocument, %DeleteDocument and %SaveDocument. 
/// </p>
/// 
/// Database Functions to be implemented:
/// FindDocuments
/// Return a set of all Documents from the Database that match the provided selection criteria. The form of the selection criteria is a list of simple predicates applied to defined properties joined with AND (we may need OR but IN is probably sufficient). The set of predicates supported initially includes Equal, GT, LT, GTE, LTE, and IN.
/// Accepts Database Name, a definition of the structure of the returned documents, and the selection criteria. 
/// QueryDatabase(sql-like query spec)
/// Add a new function to allow for SQL-like SELECT query.
Class %DocDB.Database Extends %Library.Persistent [ Final, StorageStrategy = DocSD, System = 3 ]
{

Parameter USEEXTENTSET = 1;

Index xN On Name [ Unique ];

/// The name of the database. This value must be a valid class name but it does not need to be package-qualified. 
/// If no package qualifier is present then a system default package, 'ISC.DM', will be used. 
Property Name As %String(MAXLEN = "");

/// The name of the class that implements the Database. 
Property ClassName As %String(MAXLEN = 220);

/// DocumentType is the type class of the %Doc property or one of (JSON, XML). 
/// JSON is the default DocumentType. 
Property DocumentType As %String(MAXLEN = "");

/// The Resource required to access this Database. 
Property Resource As %String(MAXLEN = "");

/// This is the SQL Schema.Table name as constructed during class compile. If the class is edited directly and later recompiled 
/// then this value could be stale. Perhaps add a projection to the %DocDB.Document class to verify this. 
Property SqlNameQualified As %String(MAXLEN = 220);

/// Create a new database. If a database with the name <var>databaseName</var> already exists then an exception is thrown. The return 
/// value is an OREF referencing the newly created Database instance in memory. 
ClassMethod %CreateDatabase(databaseName As %String(MAXLEN=220) = "", documentType As %String = "%Library.DynamicAbstractObject", resource As %String = "") As %DocDB.Database [ PublicList = SQLCODE ]
{
	try {
		new SQLCODE, %ROWCOUNT
		tstart
		set inTransaction = 1
		set database = $$createDatabase^%DocDB.Document(databaseName,documentType,resource)
		tcommit
		set inTransaction = 0
	} catch exception {
		if $get(inTransaction) {
			trollback
		}
		set database = $$$NULLOREF
		throw exception
	}
	return database
}

/// Retrieve the Database whose name is <var>databaseName</var>. If a Database identified by that name does not exist then an 
/// exception is thrown. The return value is an oref referencing the Database object in memory. 
ClassMethod %GetDatabase(databaseName) As %DocDB.Database
{
	set response = ..xNOpen(databaseName,,.status)
	if $$$ISERR(status) {
		set exception = ##class(%Exception.StatusException).CreateFromStatus(status)
		if exception.Code = $$$ERRORCODE($$$KeyValueNotFoundOpen) {
			$$$ThrowStatus($$$ERROR($$$DocumentDatabaseDoesNotExist,databaseName))
		} else {
			$$$ThrowStatus(status)
		}
	}
	return response
}

/// Return an array (<class>%Library.DynamicArray</class>) containing the names of all of the Databases defined in the current namespace. 
ClassMethod %GetAllDatabases() As %Library.DynamicArray
{
	set response = []
	&sql(declare cGA CURSOR FOR SELECT %ID, Name into :id, :name from %DocDB.Database ORDER BY %ID)
	&sql(open cGA)
	for {
		&sql(FETCH cGA)
		quit:SQLCODE
		do response.%Push(name)
	}
	set sqlcode = SQLCODE
	set message = $Get(%msg)
	&sql(close cGA)
	if sqlcode < 0 {
		throw ##class(%Exception.SQL).CreateFromSQLCODE(sqlcode,message)
	}
	return response
}

Method %GetDatabaseDefinition() As %Library.DynamicAbstractObject
{
	try {
		set response = {"Name":(..Name),"Class":(..ClassName)}
			// return non-private properties defined in the source instance
		set response.properties = ..getAllPropertyDefinitions()
	} catch exception {
		set response = ""
		throw exception
	}
	return response
}

/// <p>
/// WARNING!! This is a destructive call. 
/// </p>
/// <p>Drop the Database and remove its extent. User data is deleted. 
/// </p>
ClassMethod %DropDatabase(databaseName As %Library.String(MAXLEN=220)) As %Library.Boolean [ PublicList = SQLCODE ]
{
	try {
		new SQLCODE, %ROWCOUNT
		if ..xNExists(databaseName,.databaseID) {
			tstart
			set inTransaction = 1
			do dropDatabase^%DocDB.Document(databaseName)
			tcommit
			set inTransaction = 0
			set response = 1
		} else {
			set response = 0
		}
	} catch exception {
		set response = 0
		if $get(inTransaction) {
			trollback
		}
		throw exception
	}
	return response
}

/// <p>
/// WARNING!! This is a destructive call. 
/// </p>
/// <p>Drop all Databases defined in the current namespace. User data is deleted. 
/// </p>
ClassMethod %DropAllDatabases() As %Library.DynamicArray
{
	try {
		tstart
		set inTransaction = 1
		set response = $$dropAllDatabases^%DocDB.Document()
		tcommit
		set inTransaction = 0
	} catch exception {
		set response = ""
		if $get(inTransaction) {
			trollback
		}
		throw exception
	}
	return response
}

/// GetDocument
/// Return the Document from the Database with the specified ID. 
/// If no document with that ID is found then an exception is thrown. 
Method %GetDocument(documentID As %Integer = "") As %Library.DynamicAbstractObject
{
	try {
		set container = $classmethod(..ClassName,"%Open",$$$oidForm(documentID),,.status)
		if ('$Isobject(container)) && ($$$ISERR(status)) {
			$$$ThrowStatus(status)
		}
		set response = container.%Doc
	} catch exception {
		set response = ""
		throw exception
	}
	return response
}

/// GetDocumentByKey
/// Return the Document from the Database that matches the key value provided. Key Property Name, Key Property Value. Returns Document. 
Method %GetDocumentByKey(keyName As %String(MAXLEN=220), keyValue As %String(MAXLEN="")) As %Library.DynamicAbstractObject
{
	try {
			// First task is to determine the keyName's index name
		set indexName = ..findKey(keyName)
		if indexName '= "" {
			set container = $classmethod(..ClassName,indexName_"Open",keyValue,,.status)
			if $isObject(container) {
				set response = container.%Doc
			} elseif $$$ISERR(status) {
				$$$ThrowStatus(status)
			} else {
				$$$ThrowStatus($$$ERROR($$$DocumentKeyNotFound,..Name,keyName,keyValue))
			}
		} else {
				// Didn't find the key name - we could use dynamic SQL to find this but that would mean we don't care if the keyName
				// is valid or not.
			$$$ThrowStatus($$$ERROR($$$DocumentDatabaseKeyNotExist,..Name,keyName))
		}
	} catch exception {
		set response = ""
		throw exception
	}
	return response
}

/// <p>
/// SaveDocument() accepts a document value and an optional <var>documentID</var>. The document value is either an instance of the DocumentType class 
/// or a serialized value in the format expected by the DocumentType class. The default serial format is JSON. 
/// If <var>documentID</var> is specified then the document identified by that value is replaced by the provided document value. If a document with 
/// that ID does not exist then an exception is thrown. If no <var>documentID</var> then the provided document value is inserted into the Database. 
/// This method returns the instance of the Database class that was inserted or replaced.  
/// </p>
/// <p>
/// <pre>
/// USER>set car = cars.%SaveDocument({"make":"Ford","model":"Flatbed","year":"1938","location":{"city":"Winslow","state":"Arizona"})
/// </pre>
/// </p>
/// <p>
/// This method throws an exception if an error is encountered. 
/// </p>
Method %SaveDocument(request As %RawString, documentID As %Integer = "") As %DocDB.Document
{
	try {
		if $Get(documentID) '= "" {
			set document = $classmethod(..ClassName,"%OpenId",documentID,,.status)
			if $$$ISERR(status) {
				$$$ThrowStatus(status)
			}
		} else {
			set document = $classmethod(..ClassName,"%New")
		}
		if $isObject(request) {
			set document.%Doc = request
		} else {
			do document.%DocSetObjectId(request)
		}
		$$$THROWONERROR(status,document.%Save())
	} catch exception {
					// Placeholder for exception logging.
		set document = ""
		throw exception
	}
	return document
}

/// <p>
/// SaveDocumentByKey()  
/// </p>
Method %SaveDocumentByKey(request As %RawString, keyName As %String(MAXLEN=220), keyValue As %String(MAXLEN="")) As %DocDB.Document
{
	try {
			// First task is to determine the keyName's index name
		set indexName = ..findKey(keyName)
		if indexName '= "" {
			set container = $classmethod(..ClassName,indexName_"Open",keyValue,,.status)
			if $isObject(container) {
				if $isObject(request) {
						set container.%Doc = request
				} else {
					do container.%DocSetObjectId(request)
				}
				$$$THROWONERROR(status,container.%Save())
				set response = container
			} elseif $$$ISERR(status) {
				$$$ThrowStatus(status)
			} else {
				$$$ThrowStatus($$$ERROR($$$DocumentKeyNotFound,..Name,keyName,keyValue))
			}
		} else {
				// Didn't find the key name - we could use dynamic SQL to find this but that would mean we don't care if the keyName
				// is valid or not.
			$$$ThrowStatus($$$ERROR($$$DocumentDatabaseKeyNotExist,..Name,keyName))
		}
	} catch exception {
					// Placeholder for exception logging.
		set response = ""
		throw exception
	}
	return response
}

/// DeleteDocument
/// Remove a document from the currently visible extent of the Database class. Accepts Database Name, Document ID. Returns the deleted Document. 
Method %DeleteDocument(documentID As %Integer)
{
	try {
		tstart
		set inTransaction = 1
		set response = ..%GetDocument(documentID)
		$$$THROWONERROR(status,$classmethod(..ClassName,"%DeleteId",documentID))
		tcommit
		set inTransaction = 0
	} catch exception {
		set response = ""
		if $get(inTransaction) {
			trollback
		}
		throw exception
	}
	return response
}

/// DeleteDocumentByKey
/// Remove a document identified by KeyPropertyName = KeyValue from the currently visible extent of the Database class. Accepts Database Name, KeyPropertyName and KeyValue. Returns the deleted Document. 
Method %DeleteDocumentByKey(keyName As %String(MAXLEN=220), keyValue As %String(MAXLEN=""))
{
	try {
		tstart
		set inTransaction = 1
			// First task is to determine the keyName's index name
		set indexName = ..findKey(keyName)
		if indexName '= "" {
			set container = $classmethod(..ClassName,indexName_"Open",keyValue,,.status)
			if $isObject(container) {
				$$$THROWONERROR(status,$classmethod(..ClassName,indexName_"Delete",keyValue))
				set response = container.%Doc
			} elseif $$$ISERR(status) {
				$$$ThrowStatus(status)
			} else {
				$$$ThrowStatus($$$ERROR($$$DocumentKeyNotFound,..Name,keyName,keyValue))
			}
		} else {
				// Didn't find the key name - we could use dynamic SQL to find this but that would mean we don't care if the keyName
				// is valid or not.
			$$$ThrowStatus($$$ERROR($$$DocumentDatabaseKeyNotExist,..Name,keyName))
		}
		tcommit
		set inTransaction = 0
	} catch exception {
		set response = ""
		if $get(inTransaction) {
			trollback
		}
		throw exception
	}
	return response
}

/// CreateProperty
/// Add a new property to the Database class. Accepts Database Name, Property Name, Property Type, an optional Expression used to derive 
/// the property value and an optional UNIQUE indicator. If UNIQUE is specified, then an index to support uniqueness is automatically 
/// created if one does not already exist. All properties created through this function will be implicitly indexed. 
Method %CreateProperty(propertyName As %String(MAXLEN=220), propertyType As %String(MAXLEN=220), propertyExpression As %String(MAXLEN="") = "", unique = 0)
{
	try {
		tstart
		set inTransaction = 1
		set classLocked = 0
			// Let's lock the class
		set response = $this
		set className = ..ClassName
		set status = $$LockOneClass^%occLock(className,-1,1,$$$LockTimeout)
		if $$$ISERR(status) {
			$$$ThrowStatus(status)
		}
		set classLocked = 1
		set propertyDefinition = ##class(%Dictionary.PropertyDefinition).%New()
		do propertyDefinition.parentSetObjectId(className)
		set propertyDefinition.Name = propertyName
		if propertyType '[ "(" {
			set propertyDefinition.Type = propertyType
			set status = $$DefaultCollation^%occStorageCompiler(propertyType,.collation)
		} else {
			do parseFormal^%occName("","","dummy:"_propertyType,.args)
			if $data(args(1,2))#2 {
				set propertyDefinition.Type = args(1,2)
				set status = $$DefaultCollation^%occStorageCompiler(args(1,2),.collation)
				set param = ""
				for {
					set param = $order(args(1,2,param),1,paramVal)
					quit:param=""
					set params(param) = paramVal
					do propertyDefinition.Parameters.SetAt(paramVal,param)
				}
				if $data(params("COLLATION")) {
					set collation = params("COLLATION")
				}
			}
		}

		if propertyExpression '= "" {
			set propertyDefinition.SqlComputed = 1
			if $extract(propertyExpression) = "$" {
				set lex = $extract(propertyExpression,2)
				if $find("[.",lex) {
					set context = "%Doc"
				} else {
						// named context
					do parseDelimitedString^%ocuParser(propertyExpression,.exprElements,".")
				}
			} else {
				set context = "%Doc"
			}
			set propertyDefinition.SqlComputeCode = " set {*}=$$%EvaluatePathOne^%DocDB.Document({"_context_"},"_$$$quote(propertyExpression)_")" _ $$$NL
			set propertyDefinition.SqlComputeOnChange = "%Doc"
		}
		$$$THROWONERROR(status,propertyDefinition.%Save())
		set indexName = ..findKey(propertyName)
		if indexName = "" {
			set collationExpression = ""
			if ($get(collation) '= "") && (collation '[ "(") && (##class(%Library.CollationGenerator).IsValid(collation_"(120)")) {
				set type = propertyDefinition.Type
				$$$NormalizeClassnameByCom(type,className)
				if $$$ISERR(sc) {
					$$$ThrowStatus(sc)
				}
				do GetODBCColInfo^%ourODBC(type,.params,.odbcname,.odbctype,.maxlen,.precision,.scale)
				if maxlen > 120 {
					set collationExpression = collation _ "(120)"
				}
			}
			do ..createIndex(propertyName,propertyName,unique,collationExpression)
		}
			// Recompile the class and refresh the oref
		do ..compile()
		do UnlockOneClass^%occLock(className,-1,1)
		set classLocked = 0
		tcommit
		set inTransaction = 0
	} catch exception {
			// Placeholder for exception logging.
		if $get(classLocked) {
			do UnlockOneClass^%occLock(..ClassName,-1,1)
		}
		if $get(inTransaction) {
			trollback
			set inTransaction = 0
		}
		set response = ""
		throw exception
	}
	return response
}

Method %GetPropertyDefinition(propertyName As %String(MAXLEN=220)) As %Library.DynamicObject [ CodeMode = expression ]
{
..getPropertyDefinition(propertyName)
}

/// DropProperty
/// Remove a property from the Database class. Accepts a Property Name. The current Database oref is returned to allow chaining. 
Method %DropProperty(propertyName As %String(MAXLEN=220)) As %DocDB.Database
{
	try {
		tstart
		set inTransaction = 1
		set classLocked = 0
			// Let's lock the class
		set response = $this
		set className = ..ClassName
		set status = $$LockOneClass^%occLock(className,-1,1,$$$LockTimeout)
		if $$$ISERR(status) {
			$$$ThrowStatus(status)
		}
		set classLocked = 1
			// Should probably check the origin of the class to make certain we don't drop properties inherited
			// from a superclass. 
		$$$THROWONERROR(status,##class(%Dictionary.PropertyDefinition).%DeleteId(..ClassName_"||"_propertyName))
			// do we also delete any indices that reference this property? Do we check for more than one?
		set indexName = ..findIndex(propertyName)
		if indexName '= "" {
			do ..dropIndex(indexName)
		}
		do ..compile()
		do UnlockOneClass^%occLock(className,-1,1)
		set classLocked = 0
		tcommit
		set inTransaction = 0
	} catch exception {
		set response = ""
		if $get(classLocked) {
			do UnlockOneClass^%occLock(..ClassName,-1,1)
		}
		if $get(inTransaction) {
			trollback
		}
		throw exception
	}
	return response
}

/// %Clear() - Remove all documents from the current Database. The current Database oref is returned to allow chaining. 
Method %Clear(databaseName) As %DocDB.Database
{
	try {
		set response = $this
		set status = $classmethod(..ClassName,"%DeleteExtent")
		if $$$ISERR(status) {
			throw ##class(%Exception.StatusException).CreateFromStatus(status)
		}
	} catch exception {
		set response = ""
		throw exception
	}
	return response
}

/// <p>
/// %FromJSON() - accepts a stream, a string containing JSON, a stream oref or a string containing a file URI. The contents of <var>jsonValue</var> 
/// are then inserted into the current database. This method return an oref referencing the database to support stringing method calls. 
/// </p>
/// <p>
/// If a file URI is passed then a file stream is instantiated and the translation table set to UTF-8. If the file is not encoded as UTF-8 then 
/// the user must instantiate a stream object before calling $fromJSON() and set the translation table to the appropriate value. 
/// </p>
Method %FromJSON(jsonValue As %RawString) As %DocDB.Database
{
	try {
		if $zs < $$$MaxPartitionSize {
			set oldSize=$zs, $zs=$$$MaxPartitionSize
		} else {
			set oldSize = ""
		}
		if '$isobject(jsonValue), $find("{[",$extract($zstrip(jsonValue,"<W"),1))<1 {
			set aet = ##class(%Library.DynamicAbstractObject).%FromJSONFile(.jsonValue)
		} else {
			set aet = ##class(%Library.DynamicAbstractObject).%FromJSON(.jsonValue)
		}
		if aet.%IsA("%Library.DynamicArray") {
			set iterator = aet.%GetIterator()
			while iterator.%GetNext(.key,.value) {
				if $isobject(value) {
					set document = ..%SaveDocument(value)
				}
			}
		} else {
			set document = ..%SaveDocument(aet)
		}
		if oldSize '= "" {
			set $zs = oldSize
			set oldSize = ""
		}
	} catch exception {
		if $Get(oldSize) '= "" {
			set $zs = oldSize
		}
		throw exception
	}
	return $this
}

/// Serialize the database and its content as JSON. If <var>destination</var> is not passed then the output is either sent to the 
/// current device or returned as a string. 
/// <p> 
/// <b><var>destination</var></b> is optional. There are a number of possibilities: 
/// <br>(1) Parameter <b><var>destination</var></b> is not defined and the method is called via 'DO'. In this case the JSON string is written to the current output device. 
/// <br>(2) Parameter <b><var>destination</var></b> is not defined and the method is called as an expression. In this case the JSON string becomes the value of the expression. 
/// <br>(3) Parameter <b><var>destination</var></b> is defined. If it is %Stream object then the JSON string will be written to the stream. If <var><var>destination</var></var> is not an object 
/// and is not null then it is presumed to be a fully qualified file specification. In that case, a <class>%Stream.FileCharacter</class> stream is created, linked to that file 
/// and the JSON string is written to that stream. On completion, this stream is saved. The full path to the file must be defined. If <var><var>destination</var></var> is an object but is not 
/// an instance of %Stream.Object then an exception will be thrown. 
/// <p>
Method %ToJSON(destination As %Stream.Object) As %RawString
{
	try {
		if $zu(141) {
			if '$Data(destination) {
				throw ##class(%Exception.General).%New("$toJSON - argument passed is undefined")
			}
				// If an object is passed then we presume it is a stream, otherwise check for literal json vs. file name
			if ('($Isobject(destination))) && ('$Find("{[",$Extract($zstrip(destination,"<W")))) {
					// Write to a file stream.
				set stream = ##class(%Stream.FileCharacter).%New()
				set stream.TranslateTable = "UTF8"
				set sc = stream.LinkToFile(destination)
				throw:'sc ##class(%Exception.General).%New("%FromJSON - unable to link file "_destination)
				do stream.Rewind()
				set saveStream = 1
			} else {
 				if 'destination.%IsA("%Stream.Object") {
					throw ##class(%Exception.General).%New("%ToJSON - argument passed is not an instance of %Stream.Object")
				}
				set stream = destination
				set saveStream = 0
			}
				// stream
			set outputMode = 2
			do stream.WriteLine("[")
		} elseif $quit {
				// return value
			set outputMode = 1
			set returnValue = "[" _ $$$NL
		} else {
				// current device
			set outputMode = 0
			write "[",!
		}
		set statement = ##class(%SQL.Statement).%New()
		set statement.%ObjectSelectMode = 1
		do statement.prepare("SELECT %ID as container FROM "_$$$comClassKeyGet(..ClassName,$$$cCLASSsqlqualifiednameQ)_" ORDER BY %ID")
		set iterator = statement.execute()
		if iterator.%SQLCODE '< 0 {
			if (iterator.%Next()) && ('iterator.%SQLCODE) {
				set container = iterator.container
				if $isobject(container) {
					set output = { "documentID":(container.%Id()),"lastModified":(container.%LastModified), "content":(container.%Doc) }
					if 'outputMode {
						do output.%ToJSON()
					} elseif outputMode = 1 {
						set returnValue = returnValue _ output.%ToJSON()
					} else {
						if outputMode = 2 {
							do output.%ToJSON(stream)
						} else {
							do output.%ToJSON()
						}
					}
				}
				while (iterator.%Next()) && ('iterator.%SQLCODE) {
					set container = iterator.container
					if $isobject(container) {
						set output = { "documentID":(container.%Id()),"lastModified":(container.%LastModified), "content":(container.%Doc) }
						if 'outputMode {
							write ",",!
							do output.%ToJSON()
						} elseif outputMode = 1 {
							set returnValue = returnValue _ "," _ output.%ToJSON()
						} else {
							if outputMode = 2 {
								do stream.WriteLine(",")
								do output.%ToJSON(stream)
							} else {
								write ",",!
								do output.%ToJSON()
							}
						}
					}
				}
			}
		}
		if 'outputMode {
			write !,"]"
		} elseif outputMode = 1 {
			set returnValue = returnValue _ $$$NL _ "]"
			return returnValue
		} else {
			do stream.WriteLine("]")
			if saveStream {
				$$$THROWONERROR(status,stream.%Save())
			}
		}
	} catch exception {
		throw exception
	}
}

/// Accepts an SQL statement and a variable number of parameter values. Returns a %SQL.StatementResult. 
ClassMethod %ExecuteQuery(ByRef sql As %RawString = "", ByRef parameter... As %RawString) As %SQL.StatementResult
{
	#dim statementResult as %SQL.StatementResult

	try {
		set statement = ##class(%SQL.Statement).%New()
		do statement.prepare(sql)
		set details = statement.%GetImplementationDetails(.className,.statementText,.arguments,.statementType)
		if statementType '= 1 {
			$$$ThrowStatus($$$ERROR($$$InvalidStatementType,$$GetTypen^%SYS.SQLSRV(statementType)))
		}
		set statementResult = statement.execute(parameter...)
	} catch exception {
		set statementResult = ""
		throw exception
	}
	return statementResult
}

/// <p>
/// Retrieve documents that match the <var>restrictionRequest</var> restriction. The set of properties included in the result is 
/// defined by <var>projectionRequest</var>. Find options can be specified in the <var>optionsRequest</var> argument. 
///  The format of these arguments is either a <class>%DynamicAbstractObject</class> oref or a string containing JSON. 
/// </p>
/// <p>
/// <var>restrictionRequest</var> - This can be either a predicate or an array of predicates. A predicate is an array with three elements, the first 
/// is the property to be restricted, the second is the value the property is compared to and an optional third element is the comparison operator. The 
/// comparison operator defaults to &quot;=&quot;. The list of supported comparison operators includes =, !=, <, >, <=, >=, <>, %STARTSWITH, IN, NULL, and NOT NULL. 
/// When multiple predicates are specified they are combined using AND. 
/// Properties included in the restriction must be defined in the Database. 
/// </p>
/// <p>
/// <var>projectionRequest</var> - an array of properties to select from the Database. If not specified then the projection will include 
/// %DocumentId, %LastModified and %Doc. The properties included in the projectionRequest must be explicitly defined in the Database. 
/// </p>
/// <p>
/// <var>optionsRequest</var> - is an object containing the requested options. At this time, the only option supported is limit. If options.limit is specified 
/// then it is the maximum number of matching documents retrieved from the database.
/// </p>
/// <p>
/// The return value is a <class>%Library.DynamicArray</class> whose elements correspond to objects as defined by <var>projectionRequest</var>.
/// </p>
/// <p>
/// <pre>
/// 	SAMPLES>set result = db.%FindDocuments(["Name","N","%STARTSWITH"],["Name"],{"limit":5})             
/// 
/// 	SAMPLES>w result.%ToJSON()                                                                          
/// 	{"sqlcode":100,"message":null,"content":[{"Name":"Nebraska"},{"Name":"Nevada"},{"Name":"New Hampshire"},{"Name":"New Jersey"},{"Name":"New Mexico"}]}
/// </pre>
/// </p>  
Method %FindDocuments(restrictionRequest As %DynamicAbstractObject = "", projectionRequest As %DynamicAbstractObject = "", optionsRequest As %DynamicObject = "") As %Library.DynamicAbstractObject
{
	try {
			// query spec in three arguments that can be JSON or object refs...
		if $Isobject(restrictionRequest) {
			set restriction = restrictionRequest
		} elseif restrictionRequest '= "" {
			set restriction = ##class(%DynamicAbstractObject).%FromJSON(restrictionRequest)
		} else {
			set restriction = ""
		}
		if $Isobject(projectionRequest) {
			set projection = projectionRequest
		} elseif projectionRequest '= "" {
			set projection = ##class(%DynamicAbstractObject).%FromJSON(projectionRequest)
		} else {
			set projection = ""
		}
		if $Isobject(optionsRequest) {
			set options = optionsRequest
		} elseif optionsRequest '= "" {
			set options = ##class(%DynamicAbstractObject).%FromJSON(optionsRequest)
		} else {
			set options = ""
		}
			// Generate the SQL statement that implements this query request
		set sql = ..generateFindSQL(restriction,projection,options)
		if sql '= "" {
			set statement = ##class(%SQL.Statement).%New()
			do statement.prepare(.sql)
			set result = statement.execute()
			if result.%SQLCODE < 0 {
				$$$ThrowStatus($$$ERROR($$$SQLError,result.%SQLCODE,result.%Message))
			}
		}
		set response = ..resultToObject(result)
	} catch exception {
		set response = ""
		throw exception
	}
	return response
}

/// As an optimization we might actually cache this by computing a hash on these three things. For now, generate the SQL SELECT. 
/// Instead of accepting a projection (a definition of AET transformation using JPL), we accept a simple SELECT column list. 
Method generateFindSQL(restriction As %Library.DynamicAbstractObject, projection As %Library.DynamicAbstractObject, options As %Library.DynamicAbstractObject) As %String(MAXLEN="") [ Internal, ServerOnly = 1 ]
{
	try {
		set sql = "SELECT "
		if $isObject(options) {
			if options.limit '= "" {
				set sql = sql _ "TOP " _ options.limit _ " "
			}
		}
		if $isObject(projection) {
			set select = ""
			set iterator = projection.%GetIterator()
			while iterator.%GetNext(.key,.value) {
				$$$comMemberKeyGetLvar(column,..ClassName,$$$cCLASSproperty,value,$$$cPROPsqlfieldname)
				if column '= "" {
					set select = select _ " ," _ $$quoter2^%apiDDL(column)
				} else {
					$$$ThrowStatus($$$ERROR($$$DocumentDatabasePropertyNotValid,..Name,value))
				}
			}
			set sql = sql _ $extract(select,3,*)
		} else {
			set sql = sql _ "%DocumentId, %LastModified, %Doc"
		}
		set sql = sql _ " FROM "_ ..SqlNameQualified
		if ($isObject(restriction)) && (restriction.%IsA("%Library.DynamicArray")) {
			set predicate = restriction.%Get(0)
			if $isObject(predicate) {
				set iterator = restriction.%GetIterator()
				set where = ..generatePredicate(predicate)
					// advance the iterator - we already processed this one.
				do iterator.%GetNext()
				while iterator.%GetNext(.key,.predicate) {
					if $isObject(predicate) {
						set where = where _ " AND " _ ..generatePredicate(predicate)
					} else {
							// We expect an array that defines the operands and operator (defaults to '=')
					}
				}
			} else {
					// Simple restriction, single predicate
				set where = ..generatePredicate(restriction)
			}
			set sql = sql _ " WHERE " _ where
		}
	} catch exception {
		set sql = ""
		throw exception
	}
	return sql
}

Method generatePredicate(predicate As %Library.DynamicArray) As %String(MAXLEN="") [ Internal, ServerOnly = 1 ]
{
#define quoteSQLLiteral(%lvar)			$$quoteLiteral^%DocDB.Document(%lvar)
	set expression = ""
	$$$comMemberKeyGetLvar(column,..ClassName,$$$cCLASSproperty,predicate.%Get(0),$$$cPROPsqlfieldname)
	if column '= "" {
		set compareValue = predicate.%Get(1)
		set operator = $$$ucase(predicate.%Get(2))
		if (operator '= "") && ('$find(",=,!=,<,>,<=,>=,<>,%STARTSWITH,NULL,NOT NULL,IN,",","_operator_",")) {
			$$$ThrowStatus($$$ERROR($$$DocumentDatabaseFindOperatorNotValid,operator))
		}
		if operator = "" {
			set operator = "="
		}
		if ('$find("NULL,NOT NULL,IN",operator)) {
			set expression = $$quoter2^%apiDDL(column) _ " " _ operator _ " " _  $$$quoteSQLLiteral(compareValue)
		} elseif operator = "IN" {
			do parseDelimitedString^%ocuParser(compareValue,.element)
			if element {
				set inList = $select(element(1)'=+element(1):"'"_element(1)_"'",1:element(1))
				for ptr = 2:1:element {
					set inList = inList _ ", " _ $$$quoteSQLLiteral(element(ptr))
				}
			} else {
				set inList = ""
			}
			set expression = $$quoter2^%apiDDL(column) _ " " _ operator _ " (" _ inList _ ")"
		} else {
			set expression = $$quoter2^%apiDDL(column) _ " IS " _ operator
		}
	} else {
		$$$ThrowStatus($$$ERROR($$$DocumentDatabasePropertyNotValid,..Name,predicate.%Get(0)))
	}
	return expression
}

Method createIndex(indexName As %RawString = "", propertyName As %RawString = "", unique As %Integer = 0, collationExpression As %String = "") As %DocDB.Database [ Internal, ServerOnly = 1 ]
{
	try {
		set response = $this
		set indexDefinition = ##class(%Dictionary.IndexDefinition).%New()
		do indexDefinition.parentSetObjectId(..ClassName)
		set indexDefinition.Name = propertyName
		set indexDefinition.Properties = $$$QN(propertyName) _ $select(((collationExpression="")||(unique)):"",1:":"_collationExpression)
		set indexDefinition.Unique = unique
		set status = indexDefinition.%Save()
			// We probably need to check for name uniqueness here.
	} catch exception {
		set response = ""
		throw exception
	}
	return response
}

/// dropIndex() - delete an index definition and its structure. This method returns an oref referencing the index definition 
/// document that was removed from the index definition database. 
/// <br>
/// <pre>
/// SAMPLES>set people = $system.DocDB.GetDatabase("People")
/// SAMPLES>set index = people.%DropIndex("HC")
/// SAMPLES>write index.%ToJSON() 
/// {"database":"People","name":"HC","type":"bitmap","class":"%DocDB.Server.Index.Bitmap","key":[["HomeCity","string"]]}
/// </pre>
Method dropIndex(indexName As %RawString = "") As %Library.DynamicAbstractObject [ Internal, ServerOnly = 1 ]
{
	try {
		set response = $this
		$$$THROWONERROR(status,$classmethod(..ClassName,"%PurgeIndices",$listBuild(indexName)))
		$$$THROWONERROR(status,##class(%Dictionary.IndexDefinition).%Delete($$$oidForm(..ClassName_"||"_indexName)))
			// check status?
	} catch exception {
		set response = ""
		throw exception
	}
	return response
}

/// Return the size of the database where size is the number of documents. 
Method %Size() As %Integer [ CodeMode = expression ]
{
$classmethod(..ClassName,"%Size")
}

/// This should be private - once basic testing is complete
Method compile() [ Internal, ServerOnly = 1 ]
{
	try {
		$$$THROWONERROR(status,$system.OBJ.Compile(..ClassName,"-d"))
		set compiledClass = ##class(%Dictionary.CompiledClass).%OpenId(..ClassName)
		set ..SqlNameQualified = compiledClass.SqlQualifiedNameQ
	} catch exception {
			// Placeholder to log exception
		throw exception
	}
}

/// This should be private - once basic testing is complete
/// Find a unique index on propertyName. This find operation might be enhanced to match 
/// collation, and perhaps other refinements. Return NULL if no matching key is found. 
Method findKey(propertyName As %String(MAXLEN="")) As %String(MAXLEN="") [ Internal, ServerOnly = 1 ]
{
	set response = ""
	if $$$comMemberDefined(..ClassName,$$$cCLASSproperty,propertyName) {
		set propertyNameQ = $$$QN(propertyName)
		set indexName = ""
		for {
			set indexName = $$$comMemberNext(..ClassName,$$$cCLASSindex,indexName)
			quit:indexName=""
			if (($$$comMemberKeyGet(..ClassName,$$$cCLASSindex,indexName,$$$cINDEXunique)) || ($$$comMemberKeyGet(..ClassName,$$$cCLASSindex,indexName,$$$cINDEXprimarykey)) || ($$$comMemberKeyGet(..ClassName,$$$cCLASSindex,indexName,$$$cINDEXidkey))) && ($$$comMemberKeyGet(..ClassName,$$$cCLASSindex,indexName,$$$cINDEXproperty) = 1) && ($$$comSubMemberKeyGet(..ClassName,$$$cCLASSindex,indexName,$$$cINDEXproperty,1,$$$cINDEXPROPproperty) = propertyNameQ) {
				set response = indexName
				quit
			}
		}
	}
	return response
}

/// This should be private - once basic testing is complete
/// Find a unique index on propertyName. This find operation might be enhanced to match 
/// collation, and perhaps other refinements. Return NULL if no matching key is found. 
Method findIndex(propertyName As %String(MAXLEN="")) As %String(MAXLEN="") [ Internal, ServerOnly = 1 ]
{
	set response = ""
	if $$$comMemberDefined(..ClassName,$$$cCLASSproperty,propertyName) {
		set propertyNameQ = $$$QN(propertyName)
		set indexName = ""
		for {
			set indexName = $$$comMemberNext(..ClassName,$$$cCLASSindex,indexName)
			quit:indexName=""
			if ($$$comMemberKeyGet(..ClassName,$$$cCLASSindex,indexName,$$$cINDEXproperty) = 1) && ($$$comSubMemberKeyGet(..ClassName,$$$cCLASSindex,indexName,$$$cINDEXproperty,1,$$$cINDEXPROPproperty) = propertyNameQ) {
				set response = indexName
				quit
			}
		}
	}
	return response
}

Method getAllPropertyDefinitions() As %Library.DynamicArray [ Internal, ServerOnly = 1 ]
{
	set propertyArray = []
	set propertyName = $$$comMemberNext(..ClassName,$$$cCLASSproperty,"")
	while propertyName '= "" {
		do propertyArray.%Push(..getPropertyDefinition(propertyName))
		set propertyName = $$$comMemberNext(..ClassName,$$$cCLASSproperty,propertyName)
	}
	return propertyArray
}

Method getPropertyDefinition(propertyName As %String(MAXLEN=220)) As %Library.DynamicObject [ Internal, ServerOnly = 1 ]
{
	if ##class(%Dictionary.CompiledProperty).%ExistsId(..ClassName_"||"_propertyName) {
		set property = ##class(%Dictionary.CompiledProperty).%Open($$$oidForm(..ClassName_"||"_propertyName),,.status)
		if $isObject(property) {
			set propertyDefinition = {"Name":(propertyName),"Type":(property.Type)}
			if property.Collection '= "" {
				set propertyDefinition.collectionType = property.Collection
			}
		} else {
			if $$$ISERR(status) {
				$$$ThrowStatus(status)
			} else {
				$$$ThrowStatus($$$ERROR($$$PropertyDoesNotExist,..ClassName_"."_propertyName))
			}
		}
	} else {
		$$$ThrowStatus($$$ERROR($$$DocumentDatabasePropertyNotValid,..ClassName,propertyName))
	}
	return propertyDefinition
}

ClassMethod resultToObject(statementResult As %SQL.StatementResult) As %Library.DynamicAbstractObject [ Internal, ServerOnly = 1 ]
{
	set response = {"sqlcode":null,"message":null}
	if statementResult.%SQLCODE '< 0 {
		if statementResult.%IsA("%SQL.IResultSet") {
			set response.content = ..resultSetToArray(statementResult)
			set response.sqlcode = statementResult.%SQLCODE
			if statementResult.%Message'="" {
				set response.message = statementResult.%Message
			}
		} elseif statementResult.%IsA("%Library.IProcedureContext") {
			new %sqlcontext
			set %sqlcontext = statementResult
			if statementResult.%SQLCODE < 0 {
				set response.sqlcode = {"code":(statementResult.%SQLCODE),"description":($$sqlcode^%apiSQL(statementResult.%SQLCODE))}
			} else {
				if $Data(statementResult.%OutputValues) {
					set outputValues = []
					set valuePtr = $Order(statementResult.%OutputValues(""))
					while valuePtr '= "" {
						do outputValues.%Set(valuePtr,statementResult.%OutputValues(valuePtr))
						set valuePtr = $Order(statementResult.%OutputValues(valuePtr))
					}
				}
				set resultSet = statementResult.%NextResult()
				if $isObject(resultSet) {
					set resultSets = [(..resultSetToArray(resultSet))]
					for resultPtr = 2:1 {
						set resultSet = statementResult.%NextResult()
						if $isobject(resultSet) {
							do resultSets.%Push(..resultSetToArray(resultSet))
						} else {
							quit
						}
					}
					set response.resultSets = resultSets
				}
			}
		} else {
				// not a CALL result and not a simple result set
		}
	} else {
			// SQLCODE indicates failure
		set response.sqlcode = {"code":(statementResult.%SQLCODE),"description":($$sqlcode^%apiSQL(statementResult.%SQLCODE))}
	}
	return response
}

ClassMethod resultSetToArray(resultSet As %SQL.IResultSet) As %Library.DynamicArray [ Internal, ServerOnly = 1 ]
{
	try {
		set response = []
		set metadata = resultSet.%GetMetadata()
		merge columns = metadata.columnIndex
		while resultSet.%Next() {
			set row = {}
			set COLUMN = $Order(columns(""),1,columnDef)
			while COLUMN '= "" {
				set value = resultSet.%GetData($list(columnDef,1))
				do row.%Set($list(columnDef,2),value)
				set COLUMN = $Order(columns(COLUMN),1,columnDef)
			}
			do response.%Push(row)
		}
	} catch exception {
		set response = $$$NULLOREF
		throw exception
	}
	return response
}

ClassMethod resultMetadataToObject(metadata As %SQL.StatementMetadata) As %Library.DynamicObject [ Internal, ServerOnly = 1 ]
{
	set response = {"statementType":(metadata.statementType)}
	do response.%Set("interface",+(metadata.interface),"number")
	if metadata.columns.Count() > 0 {
		do response.%Set("columns",..resultColumnsToArray(metadata.columns))
	}
	if metadata.parameters.Count() > 0 {
		do response.%Set("parameters",..resultParametersToArray(metadata.parameters))
	}
	if metadata.objects.Count() > 0 {
		do response.%Set("objects",..resultObjectsToArray(metadata.objects))
	}
	return response
}

ClassMethod resultColumnsToArray(columns As %Collection.ListOfObj) As %Library.DynamicArray [ Internal, ServerOnly = 1 ]
{
	set response = []
	set key = ""
	set element = columns.GetNext(.key)
	while key '= "" {
		if $IsObject(element) {
			do response.%Push(..resultColumnToObject(element))
		} else {
			do response.%Push(element)
		}
		set element = columns.GetNext(.key)
	}
	return response
}

ClassMethod resultColumnToObject(column As %SQL.StatementColumn) As %Library.DynamicObject [ Internal, ServerOnly = 1 ]
{
	set response = {}
	do response.%Set("columnType","SQLRESULTCOL","string")
	do response.%Set("colName",column.colName,"string")
	do response.%Set("ODBCType",column.ODBCType)
	do response.%Set("precision",column.precision,"number")
	do response.%Set("scale",column.scale,"number")
	do response.%Set("isNullable",column.isNullable,"boolean")
	do response.%Set("label",column.label)
	do response.%Set("tableName",column.tableName)
	do response.%Set("schemaName",column.schemaName)
	do response.%Set("qualifier",column.qualifier)
	do response.%Set("isAutoIncrement",column.isAutoIncrement,"boolean")
	do response.%Set("isCaseSensitive",column.isCaseSensitive,"boolean")
	do response.%Set("isCurrency",column.isCurrency,"boolean")
	do response.%Set("isReadOnly",column.isReadOnly,"boolean")
	do response.%Set("isRowVersion",column.isRowVersion,"boolean")
	do response.%Set("isUnique",column.isUnique,"boolean")
	do response.%Set("isAliased",column.isAliased,"boolean")
	do response.%Set("isExpression",column.isExpression,"boolean")
	do response.%Set("isHidden",column.isHidden,"boolean")
	do response.%Set("isIdentity",column.isIdentity,"boolean")
	do response.%Set("isKeyColumn",column.isKeyColumn,"boolean")
	do response.%Set("isRowId",column.isRowId,"boolean")
	return response
}

ClassMethod resultParametersToArray(parameters As %Collection.ListOfObj) As %Library.DynamicArray [ Internal, ServerOnly = 1 ]
{
	set response = []
	set key = ""
	set element = parameters.GetNext(.key)
	while key '= "" {
		if $IsObject(element) {
			do response.%Push(..resultParameterToObject(element))
		} else {
			do response.%Push(element)
		}
		set element = parameters.GetNext(.key)
	}
	return response
}

ClassMethod resultParameterToObject(parameter As %SQL.StatementParameter) As %Library.DynamicObject [ Internal, ServerOnly = 1 ]
{
	set response = {}
	do response.%Set("columnType",parameter.columnType,"string")
	do response.%Set("colName",parameter.colName,"string")
	do response.%Set("ODBCType",parameter.ODBCType)
	do response.%Set("precision",parameter.precision,"number")
	do response.%Set("scale",parameter.scale,"number")
	do response.%Set("isNullable",parameter.isNullable,"boolean")
	return response
}

ClassMethod resultObjectsToArray(objects As %Collection.ListOfObj) As %Library.DynamicArray [ Internal, ServerOnly = 1 ]
{
	set response = []
	set key = ""
	set element = objects.GetNext(.key)
	while key '= "" {
		if $IsObject(element) {
			do response.%Push(..resultObjectToObject(element))
		} else {
			do response.%Push(element)
		}
		set element = objects.GetNext(.key)
	}
	return response
}

ClassMethod resultObjectToObject(object As %SQL.StatementObject) As %Library.DynamicObject [ Internal, ServerOnly = 1 ]
{
	set response = {}
	do response.%Set("colName",object.columnName,"string")
	do response.%Set("extentName",object.extentName)
	do response.%Set("exportCall",object.exportCall,"string")
	return response
}

Storage DocSD
{
<Data name="DatabaseDefaultData">
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>ClassName</Value>
</Value>
<Value name="3">
<Value>DocumentType</Value>
</Value>
<Value name="4">
<Value>Resource</Value>
</Value>
<Value name="5">
<Value>SqlNameQualified</Value>
</Value>
</Data>
<DataLocation>^ISC.DocDB.1</DataLocation>
<DefaultData>DatabaseDefaultData1</DefaultData>
<ExtentLocation>^C1lN.sfGT</ExtentLocation>
<IdLocation>^ISC.DocDB.1</IdLocation>
<Index name="IDKEY">
<Location>^ISC.DocDB.1</Location>
</Index>
<Index name="xN">
<Location>^ISC.DocDB.2</Location>
</Index>
<IndexLocation>^ISC.DocDB.I</IndexLocation>
<StreamLocation>^ISC.DocDB.S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
