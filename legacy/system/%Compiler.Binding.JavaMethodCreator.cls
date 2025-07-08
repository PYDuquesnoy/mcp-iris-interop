/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Compiler.Binding.JavaMethodCreator Extends %RegisteredObject [ System = 4 ]
{

Property class As %Dictionary.CompiledClass;

Property className As %String;

Property rootSuper As %String;

Property leftSuper As %String;

Property irisSupers As %List;

Property classType As %String;

Property irisPackage As %String;

Property projParams As %ArrayOfDataTypes;

Property newCollections As %Boolean;

Property tConverter As JavaTypeConverter;

Property jdCreator As JavaDocCreator;

Property propsWithGetter As %List [ MultiDimensional ];

Property propsWithSetter As %List [ MultiDimensional ];

Property conflictedMemberName As %List;

Property objectLibraryTypes As %List;

Property streamTypes As %List;

Property utilConvertedTypes As %List;

Property systemMethods As %List;

Property ignoredMethods As %List;

Property typesWithBuildIndices As %List;

Method %OnNew(class As %Dictionary.CompiledClass, className As %String, rootSuper As %String, leftSuper As %String, irisSupers As %List, projParams As %ArrayOfDataTypes, jdCreator As JavaDocCreator) As %Status
{
	s ..class = class
	s ..className = className
	s ..rootSuper = rootSuper
	s ..leftSuper = leftSuper
	s ..irisSupers = irisSupers
 	s ..classType = class.ClassType
 	s ..irisPackage = $p(class.Name, ".", 1)
 	
	s ..projParams = projParams
	s ..newCollections = projParams.GetAt("NEWCOLLECTIONS")
	
	s ..tConverter = ##class(%Compiler.Binding.JavaTypeConverter).%New(projParams)
	s ..jdCreator = jdCreator
	s ..propsWithGetter = ""
	s ..propsWithSetter = ""
	
	s ..conflictedMemberName = $lb("boolean", "char", "double", "float", "int", "Oid", "Id", "Class")
	s ..objectLibraryTypes = $lb("com.intersystems.binding.BinaryStream", "com.intersystems.binding.CharacterStream",
								"com.intersystems.binding.ListOfObjects", "com.intersystems.binding.ListOfDataTypes",
								"com.intersystems.binding.ArrayOfObjects", "com.intersystems.binding.ArrayOfDataTypes",
								"com.intersystems.binding.StatusCode", "com.intersystems.binding.AbstractStream", "Oid")
	s ..streamTypes = $lb("com.intersystems.binding.BinaryStream", "com.intersystems.binding.CharacterStream",
								"com.intersystems.binding.AbstractStream")
	s ..utilConvertedTypes = $lb("Integer", "int", "java.math.BigDecimal",
									"java.sql.Date", "java.sql.Time", "java.sql.Timestamp",
									"Fileman.Date", "Fileman.Timestamp", "Posix.Timestamp")
									
	s ..systemMethods = $lb("%ClassName", "%IsA", "%Delete", "%DeleteId", "%DeleteExtent", "%KillExtent",
							"%Exists", "%ExistsId", "%ComposeOid", "%ObjectIsNull", "%IsNull", "%SaveIndices", "%BuildIndices",
							"LogicalToOdbc", "OdbcToLogical")
	s ..ignoredMethods = $lb("%Delete", "%Exists", "%ComposeOid")
	s ..typesWithBuildIndices = $lb("serial", "stream", "index", "")
	Quit $$$OK
}

/// Create a new method
Method createMethod(file As JavaFile, javaMethodName As %String, params As %List, returnType As %String, irisMethodName As %String, returnsObject = 0, isStatic = 0, description = "", createsJavaDoc = 1, interfaceFile = "")
{
	// prepare type to appear on signature
	s returnType = $case(returnType, "com.intersystems.binding.StatusCode": "Status", : returnType)
	s returnTypePackage = $p(returnType, ".", 1)
	s sigType = ..tConverter.getSigType(returnType, ..newCollections)
	
	// prepare arguments for call to IRIS method
	s args = ..tConverter.paramsToArguments(params, isStatic)
	
	// create method signature
	if isStatic {
		s punc = ""
		if $listlength(params) > 0 {s punc = ", "}
		
		//method with Database argument
		if createsJavaDoc {
			d ..jdCreator.createMethodDoc(file, irisMethodName, params, description, 2, createsJavaDoc)
		}
		s returnKeyword = $case(returnType, "void": "",
											"Status": "",
											: "return ")
		d file.IndentAndWriteLine("public static "_sigType_" "_javaMethodName_"(Database db"_punc_..tConverter.paramsToString(params)_") throws SQLException {", 1)
		if 'returnsObject {
			d file.IndentAndWriteLine(returnKeyword_javaMethodName_"((IRISConnection)db.getConnection()"_..tConverter.paramsToArguments(params, isStatic, 0)_");", 2)
		} else {
			d file.IndentAndWriteLine(sigType_" obj = "_javaMethodName_"((IRISConnection)db.getConnection()"_..tConverter.paramsToArguments(params, isStatic, 0)_");", 2)
			d file.IndentAndWriteLine("obj.setDatabase(db);", 2)
			d file.IndentAndWriteLine("return obj;", 2)
		}
		d file.IndentAndWriteLine("}", 1)
		d file.IndentAndWriteLine()
		
		//method with IRISConnection argument
		d file.IndentAndWriteLine("public static "_sigType_" "_javaMethodName_"(IRISConnection connection"_punc_..tConverter.paramsToString(params)_") throws SQLException {", 1)
		d file.IndentAndWriteLine("IRIS iris = IRIS.createIRIS(connection);", 2)
		
	} else {
		if createsJavaDoc {
			d ..jdCreator.createMethodDoc(file, irisMethodName, params, description, isStatic, createsJavaDoc)
		}
		d file.IndentAndWriteLine("public "_sigType_" "_javaMethodName_"("_..tConverter.paramsToString(params)_") {", 1)
		
		if interfaceFile '= "" {
			d ..jdCreator.createMethodDoc(interfaceFile, irisMethodName, params, description, isStatic, createsJavaDoc)
			d interfaceFile.IndentAndWriteLine("public "_sigType_" "_javaMethodName_"("_..tConverter.paramsToString(params)_");", 1)
			d interfaceFile.IndentAndWriteLine()
		}
	}
	
	// create call to corresponding IRIS method
	d ..createIRISCall(file, args, returnType, returnsObject, irisMethodName, isStatic)
	
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine()
}

/// create call to IRIS method
Method createIRISCall(file As JavaFile, args As %String, returnType As %String, returnsObject As %Boolean, irisMethodName As %String, isStatic = 0)
{
	// prepare Java method name
	s call = "irisObject.invoke"
	s irisClassName = ""
	if isStatic {
		s call = "iris.classMethod"
		s irisClassName = "IRIS_CLASS_NAME, "
	}
	
	// Retrieve the type that would be returned by the IRIS call
	s typeForIRISCall = ..tConverter.getTypeForIRISCall(returnType, returnsObject, 1)
	
	// If returnType is a simple %Library type, get and return it
	if 'returnsObject && '$lf(..objectLibraryTypes, returnType) && '$lf(..utilConvertedTypes, returnType) {
		s returnKeyword = $case(returnType, "void": "",
											"Status": "",
											: "return ")
		d file.IndentAndWriteLine(returnKeyword_call_typeForIRISCall_"("_irisClassName_""""_irisMethodName_""""_args_");", 2)
		
	// Else handle object type or more complicated %Library type	
	} else {
		d ..getCastForIRISCall(typeForIRISCall, .rType, .cast)
		d file.IndentAndWriteLine(rType_" _x = "_cast_call_typeForIRISCall_"("_irisClassName_""""_irisMethodName_""""_args_");", 2)
		
		d ..processResultOfIRISCall(file, returnType, typeForIRISCall, , isStatic)
	}
}

Method getCastForIRISCall(typeForIRISCall As %String, ByRef rType As %String, ByRef cast As %String)
{
	s rType = $case(typeForIRISCall, "Bytes": "byte[]",
									"Object": "IRISObject",
											: typeForIRISCall)
	s cast = $case(rType, "IRISObject": "(IRISObject)",
										: "")
}

Method processResultOfIRISCall(file As JavaFile, returnType As %String, typeForIRISCall As %String, elementType = "", isStatic = 0)
{
	s dbArg = $case(isStatic, 1: "",
								: ", db")
	
	// For ObjectHandle class, we need to find its correct concrete class
	if returnType = "com.intersystems.binding.ObjectHandle" {
		d file.IndentAndWriteLine("com.intersystems.binding.ClassnameMap cMap = ClassnameMap.getInstance();", 2)	
		d file.IndentAndWriteLine("return (com.intersystems.binding.ObjectHandle)cMap.constructJavaInstance((IRISObject)_x"_dbArg_");", 2)
	
	// Most classes can be converted using com.intersystems.binding.Util
	} elseif $lf(..utilConvertedTypes, returnType) {
		s returnTypePackage = $p(returnType, ".", 1)
		s returnType = $p(returnType, ".", *)
		s returnType = $case(returnType, "int": "Integer",
												: returnType)
		s fileman = $select(returnTypePackage = "Fileman": "Fileman",
														1: "")
		s iris = $select((returnTypePackage = "Fileman") && isStatic: "iris, ",
							(returnTypePackage = "Fileman") && 'isStatic: "irisObject.iris, ",
																		1: "")
		d file.IndentAndWriteLine("return Util."_fileman_returnType_"JavaFormat("_iris_"_x);", 2)
	
	} elseif returnType = "Oid"{
		d file.IndentAndWriteLine("return Oid.fromString((String) _x);", 2)
		
	} elseif (returnType = "com.intersystems.binding.StatusCode") {
		d file.IndentAndWriteLine("return _x == null ? null : new "_returnType_"(_x, irisObject.getConnection());", 2)

	} else {
		//TODO: simplifying resolving elementType
		s punc = $case(elementType, "": "",
									: ", """)
		s punc2 = $case(elementType, "": "",
									: """")						
		s elementType = $case(elementType, "Integer": "java.lang.Integer",
											"Double": "java.lang.Double",
											"String": "java.lang.String",
											"Name": "java.lang.String",
												: elementType)
		d file.IndentAndWriteLine("return _x == null ? null : new "_returnType_"(_x"_dbArg_punc_elementType_punc2_");", 2)
	}
}

/// Create constructors
Method createConstructors(file As JavaFile, onNew As %CompiledMethod, ByRef qstruct As %String) As %Status
{
	s Status = $$$OK
	if (..rootSuper = "") {
		return Status
	}
	
	//static initialization block to register this class to ClassnameMap
	d file.IndentAndWriteLine("static {", 1)
 	d file.IndentAndWriteLine("ClassnameMap cMap = ClassnameMap.getInstance();", 2)
 	d file.IndentAndWriteLine("cMap.putJavaClass(IRIS_CLASS_NAME, "_..className_".class);", 2)
 	d file.IndentAndWriteLine("}", 1)
 	d file.IndentAndWriteLine()

	//Default constructor with object parameter
	d ..jdCreator.createSystemConstructorDoc(file)
	d file.IndentAndWriteLine("public "_..className_"(IRISObject irisObjectNew) {", 1)
 	d file.IndentAndWriteLine("super(irisObjectNew);", 2)
 	d file.IndentAndWriteLine("}", 1)
	
	//Constructor with object and database
	d ..jdCreator.createSystemConstructorDoc(file)
	d file.IndentAndWriteLine("public "_..className_"(IRISObject irisObjectNew, Database db) {", 1)
 	d file.IndentAndWriteLine("super(irisObjectNew, db);", 2)
 	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine()
	
	s params = ##class(%ListOfDataTypes).%New()
	s Status = ..convertParams(.params, onNew.FormalSpec, .qstruct)
	if $$$ISERR(Status) {
		return Status	
	}
	for i=1:1:params.Count() {
		s param = params.GetAt(i)
		s punc = ""
		if $listlength(param) > 0 {s punc = ", "}
		s paramAsString = ..tConverter.paramsToString(param)
		s args = ..tConverter.paramsToArguments(param)
		
		//Public constructor with Database argument
		d ..jdCreator.createConstructorDoc(file, param, 2)
		d file.IndentAndWriteLine("public "_..className_"(Database db"_punc_paramAsString_") throws SQLException {", 1)
		d file.IndentAndWriteLine("this((IRISConnection)db.getConnection()"_args_");", 2)
		d file.IndentAndWriteLine("setDatabase(db);", 2)
		d file.IndentAndWriteLine("}", 1)
		d file.IndentAndWriteLine()
		
		//Public constructor with IRISConnection argument
		d file.IndentAndWriteLine("public "_..className_"(IRISConnection connection"_punc_paramAsString_") throws SQLException {", 1)
		d file.IndentAndWriteLine("super((IRISObject) IRIS.createIRIS(connection).classMethodObject(IRIS_CLASS_NAME, ""%New"""_args_"));", 2)
		d file.IndentAndWriteLine("}", 1)
		d file.IndentAndWriteLine()
	}
	q Status
}

/// Create %OpenId and %Open
Method createOpens(file As JavaFile, tableName As %String)
{
	if (..rootSuper = "") || (..rootSuper = "RegisteredObject") {
		return	
	}
	
	d ..createOpen(file, "open", "_open", $listbuild("Id id"), ..className, "%OpenId", 1)
	d ..createOpen(file, "open", "_open", $listbuild("Id id", "int concurrency"), ..className, "%OpenId", 1)
	d ..createOpen(file, "open", "_open", $listbuild("Oid oid"), ..className, "%Open", 1)
	d ..createOpen(file, "open", "_open", $listbuild("Oid oid", "int concurrency"), ..className, "%Open", 1)
	
	if (..rootSuper = "Persistent") && '..class.NoExtent {
		d ..createOpenByQueryPair(file, tableName)
	}
}

/// Template to create 1 pair of open methods
Method createOpen(file As JavaFile, javaMethodName1 As %String, javaMethodName2 As %String, params As %List, returnType As %String, irisMethodName As %String, returnsObject = 0)
{
	s args1 = ""
	s args2 = ""
	s hasConcurrency = 0
	s id = ""
	s paramNum = $listlength(params)
	if paramNum > 0 {
		for i=1:1:paramNum {
			s param = $list(params, i)
			s paramType = $piece(param, " ", 1)
			s paramName = $piece(param, " ", 2)
			if paramName = "concurrency" {s hasConcurrency = 1}
			s args2 = args2_", "_paramName
			if (paramType = "Id") || (paramType = "Oid") {
				s paramName = $case(paramType, "Id": paramName_".toString()",
											"Oid": paramName_".getData()",
												: paramName)
				s id = paramName
			}
			
			s args1 = args1_", "_paramName
		}
	}
	s conc = ""
	if paramNum = 1 {
		s conc = ", -1"	
	}
	s paramsAsString = ..tConverter.paramsToString(params)
	
	//Open method with Database argument
	d ..jdCreator.createOpenDoc(file, irisMethodName, params, 2, hasConcurrency)
	d file.IndentAndWriteLine("public static RegisteredObject "_javaMethodName1_"(Database db, "_paramsAsString_") throws SQLException {", 1)
 	d file.IndentAndWriteLine("RegisteredObject ro = "_javaMethodName1_"((IRISConnection)db.getConnection()"_args2_");", 2)
 	d file.IndentAndWriteLine("ro.setDatabase(db);", 2)
 	d file.IndentAndWriteLine("return ro;", 2)
 	d file.IndentAndWriteLine("}", 1)
 	d file.IndentAndWriteLine()
 	
	//Open method with IRISConnection argument
	d file.IndentAndWriteLine("public static RegisteredObject "_javaMethodName1_"(IRISConnection connection, "_paramsAsString_") throws SQLException {", 1)
 	d file.IndentAndWriteLine("IRIS iris = IRIS.createIRIS(connection);", 2)
 	d file.IndentAndWriteLine("IRISReference ref = new IRISReference(null);", 2)
 	d file.IndentAndWriteLine("IRISObject irisObjectNew = (IRISObject)iris.classMethodObject(IRIS_CLASS_NAME, """_irisMethodName_""""_args1_conc_", ref);", 2)
 	d file.IndentAndWriteLine("if (irisObjectNew == null)", 2)
 	d file.IndentAndWriteLine("RegisteredObject.ParseStatusForOpenMethods(iris, IRIS_CLASS_NAME, "_id_", ref.getValue());", 3)
 	d file.IndentAndWriteLine("return new "_returnType_"(irisObjectNew);", 2)
 	d file.IndentAndWriteLine("}", 1)
 	d file.IndentAndWriteLine()
	
	//Open method with Database argument
	d ..jdCreator.createOpenDoc(file, irisMethodName, params, 2, hasConcurrency)
	d file.IndentAndWriteLine("public static RegisteredObject "_javaMethodName2_"(Database db, "_paramsAsString_") throws SQLException {", 1)
 	d file.IndentAndWriteLine("RegisteredObject ro = "_javaMethodName2_"((IRISConnection)db.getConnection()"_args2_");", 2)
 	d file.IndentAndWriteLine("ro.setDatabase(db);", 2)
 	d file.IndentAndWriteLine("return ro;", 2)
 	d file.IndentAndWriteLine("}", 1)
 	d file.IndentAndWriteLine()
	
	//Open method with IRISConnection argument
	d file.IndentAndWriteLine("public static RegisteredObject "_javaMethodName2_"(IRISConnection connection, "_paramsAsString_") throws SQLException {", 1)
 	d file.IndentAndWriteLine("return "_javaMethodName1_"(connection"_args2_");", 2)
 	d file.IndentAndWriteLine("}", 1)
 	d file.IndentAndWriteLine()
}

/// Create %Delete and %DeleteId
Method createDeletes(file As JavaFile)
{
	if (..rootSuper = "") || (..rootSuper = "RegisteredObject") {
		return	
	}
	
	d ..createMethodPair(file, "delete", "_deleteId", $listbuild("Id id"), "Status", "%DeleteId")
	d ..createMethodPair(file, "delete", "_deleteId", $listbuild("Id id", "int concurrency"), "Status", "%DeleteId")
}

/// Generate %Exists and %ExistsId
Method createExists(file As JavaFile)
{
	if ..rootSuper '= "Persistent" {
		return
	}
	
	d ..createMethodPair(file, "exists", "_existsId", $listbuild("Id id"), "Boolean", "%ExistsId")
	d ..jdCreator.createPersistentMethodDoc(file, "%Exists", $listbuild("Oid oid"))
	d ..createMethod(file, "exists", $listbuild("Oid oid"), "boolean", "%Exists",,1,,0)
}

/// Generate ClassName methods
Method createClassName(file As JavaFile, hasFields As %Boolean)
{
	d ..jdCreator.createIRISClassNameDoc(file)
	d file.IndentAndWriteLine("public static String getIRISClassName() {", 1)
 	d file.IndentAndWriteLine("return IRIS_CLASS_NAME;", 2)
 	d file.IndentAndWriteLine("}", 1)
 	d file.IndentAndWriteLine()
 	
 	/*
 	if hasFields {
	 	d file.IndentAndWriteLine("public static String[] getFieldList() {", 1)
	 	d file.IndentAndWriteLine("return fieldList;", 2)
	 	d file.IndentAndWriteLine("}", 1)
	 	d file.IndentAndWriteLine()
 	}
 	*/
 	
 	if (..rootSuper = "") {
		return 	
 	}
}

/// Track all properties of the class
Method trackProperties(prop As %CompiledProperty, properties As %ArrayOfDataTypes, leftSuperProps As %ArrayOfDataTypes, ByRef qstruct As %String) As %Status
{
	s Status = $$$OK
	s propName = prop.Name
	
	// Stop processing property if it (1) is a library property, or (2) belongs to superclass
	if ($e(propName, 1, 1) = "%") || (prop.Origin = ..leftSuper) {
			return Status
	}
	
	s Status = ..tConverter.convertType(prop.Type, .propPackage, .propType, , prop.Collection, prop.Relationship,.qstruct)
	if $$$ISERR(Status) {return Status}
	
	s typeInLeftSuper = leftSuperProps.GetAt(propName)
	if (typeInLeftSuper '= "") && (typeInLeftSuper '= propType) {
		return $System.Status.Error(6629, ..className, propName)	
	}
	
	// Store the name of this property
	d properties.SetAt(propType, propName)
	q Status
}

/// Create property methods
Method createProperty(file As JavaFile, prop As %Dictionary.CompiledProperty, interfaceFile = "") As %Status
{
	s Status = $$$OK
	s propName = prop.Name
	
	// Stop processing property if it (1) is a library property, or (2) belongs to superclass
	if ($e(propName, 1) = "%") || (prop.Origin = ..leftSuper) {
			return Status
	}
	
	// Process property's type
	s collectionType = prop.Collection
	s isRelationship = prop.Relationship
	s Status = ..tConverter.convertType(prop.Type, .propPackage, .propType, .elementType, collectionType, isRelationship)
	if $$$ISERR(Status) {q Status}
	
	if prop.MultiDimensional || prop.Private {
		return Status
	}
 		
	s clientName = propName
	if prop.ClientName '= "" {s clientName = prop.ClientName}
 	
 	// Create setter and getter
 	// If Calculated and Get() / Set() are supplied, turn them into getter/setter
 	if prop.Calculated {
	 	if $lf(..propsWithGetter, propName) || prop.SqlComputed {
		 	d ..createGetter(file, propPackage, propName, clientName, propType, elementType, collectionType, prop.Description)	
	 	}
	 	if $lf(..propsWithSetter, propName) {
		 	d ..createSetter(file, propPackage, propName, clientName, propType, collectionType, isRelationship, prop.ReadOnly, prop.Description)
	 	}
	 	
	 	// Generate IsValid() and Logical/Display methods
		d ..createPropertySystemMethod(file, prop.Type, propType, elementType, collectionType, propName, propPackage)
		return Status
		
	// Else simply project Get() / Set() if they exist, or if SqlComputed
	} elseif (propPackage = "%Library") && (collectionType = "") {
		if $lf(..propsWithGetter, propName) || prop.SqlComputed {
		 	d ..createMethod(file, propName_"Get", "", propType, propName_"Get")
	 	}
	 	if $lf(..propsWithSetter, propName) || prop.SqlComputed {
		 	d ..createMethod(file, propName_"Set", $listbuild(propType_" _val"), "Status", propName_"Set")
	 	}
	}
	
	d ..createGetter(file, propPackage, propName, clientName, propType, elementType, collectionType, prop.Description, interfaceFile)
	if '(..newCollections && (collectionType '= "")) {d ..createSetter(file, propPackage, propName, clientName, propType, collectionType, isRelationship, prop.ReadOnly, prop.Description, interfaceFile)}
	// Generate IsValid() and Logical/Display methods
	d ..createPropertySystemMethod(file, prop.Type, propType, elementType, collectionType, propName, propPackage)
	q Status
}

/// Generate IsValid() and Logical/Display methods
Method createPropertySystemMethod(file As JavaFile, irisType As %String, javaType As %String, elementType As %String, collectionType As %String, propName As %String, propPackage As %String)
{
	if (collectionType = "") && ((irisType = "%Library.Date") || (irisType = "%Library.Time")) {
		d ..createDateTimeValidator(file, propName, $p(javaType, ".", *))
	} else {
		d ..createMethod(file, propName_"IsValid", $listbuild("String _val"), "Status", propName_"IsValid",,1)
	}

	if (javaType = "com.intersystems.binding.ListOfDataTypes") || (javaType = "com.intersystems.binding.ArrayOfDataTypes")
	|| ((propPackage = "%Library") && '$lf(..objectLibraryTypes, javaType) && (javaType '= "byte[]") && (javaType '= "com.intersystems.jdbc.IRISList")) {
		d ..createMethod(file, propName_"DisplayToLogical", $listbuild("String _val"), elementType, propName_"DisplayToLogical",,1)
		d ..createMethod(file, propName_"LogicalToDisplay", $listbuild(elementType_" _val"), "String", propName_"LogicalToDisplay",,1)
	}
	
	if $lf(..objectLibraryTypes, javaType) || (propPackage '= "%Library") || (collectionType '= "") {
		if '$lf(..streamTypes, javaType) {
			d ..createMethod(file, propName_"GetObject", "", "Oid", propName_"GetObject", 1)
			d ..createMethod(file, propName_"GetObject", $listbuild("Integer force"), "Oid", propName_"GetObject", 1)
		}
		d ..createMethod(file, propName_"GetObjectId", "", "String", propName_"GetObjectId")
		d ..createMethod(file, propName_"GetObjectId", $listbuild("Integer force"), "String", propName_"GetObjectId")
		d ..createMethod(file, propName_"SetObject", $listbuild("Oid newvalue"), "void", propName_"SetObject")
	    d ..createMethod(file, propName_"SetObjectId", $listbuild("String newid"), "void", propName_"SetObjectId")
	}
}

/// Create property getter 
Method createGetter(file As JavaFile, propPackage As %String, propName As %String, clientName As %String, propType As %String, elementType As %String, collectionType As %String, description As %String, interfaceFile = "")
{
	// Prepare type to appear on method signature
	s isStream = ((propType = "com.intersystems.binding.BinaryStream") || (propType = "com.intersystems.binding.CharacterStream"))
					&& ((propPackage = "%Stream") || (propPackage = "%Library"))
	if isStream {
		s propType = $case(propType, "com.intersystems.binding.CharacterStream": "com.intersystems.binding.Reader",
									"com.intersystems.binding.BinaryStream": "com.intersystems.binding.InputStream")
	}
	s sigType = ..tConverter.getSigType(propType, ..newCollections)
	
	// Create JavaDoc
	d ..jdCreator.createGetterDoc(file, clientName, sigType, description)
	if interfaceFile '= "" {d ..jdCreator.createGetterDoc(interfaceFile, clientName, sigType, description)}
	
	// Getter signature
	s in = $select(isStream: "In", 1: "")
	d file.IndentAndWriteLine("public "_sigType_" get"_..resolveConflictedMemberName(clientName)_in_"() {", 1)
	if interfaceFile '= "" {
		d interfaceFile.IndentAndWriteLine("public "_sigType_" get"_..resolveConflictedMemberName(clientName)_in_"();", 1)
		d interfaceFile.IndentAndWriteLine()
	}
	
	if isStream {
		d file.IndentAndWriteLine("return new "_propType_"((IRISObject)irisObject.get("""_propName_"""), db);", 2)
		
	} else {
		// Get type the IRIS call would return
		s returnsObject = (propPackage '= "%Library") && (propPackage '= "%MV")
		s typeForIRISCall = ..tConverter.getTypeForIRISCall(propType, returnsObject)
		
		// If a %Library type, get property as a library type
		if 'returnsObject && (collectionType = "") && '$lf(..objectLibraryTypes, propType) && '$lf(..utilConvertedTypes, propType) {
			d file.IndentAndWriteLine("return irisObject.get"_typeForIRISCall_"("""_propName_""");", 2)
			
		// Else handle object type or more complicated %Library type
		} else {
			d ..getCastForIRISCall(typeForIRISCall, .rType, .cast)
			d file.IndentAndWriteLine(rType_" _x = "_cast_"irisObject.get"_typeForIRISCall_"("""_propName_""");", 2)
			
			//if property isn't a collection, no need for elementType
			if (collectionType = "") {s elementType = ""}
			d ..processResultOfIRISCall(file, propType, typeForIRISCall, elementType)
		}
	}
	
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine()
}

/// Create property setter
Method createSetter(file As JavaFile, propPackage As %String, propName As %String, clientName As %String, propType As %String, collectionType As %String, isRelationship As %Boolean, isReadOnly As %Boolean, description As %String, interfaceFile = "")
{
	// Prepare return type for method signature
	s isStream = ((propType = "com.intersystems.binding.BinaryStream") || (propType = "com.intersystems.binding.CharacterStream"))
					&& ((propPackage = "%Stream") || (propPackage = "%Library"))
	if isStream {
		s propType = $case(propType, "com.intersystems.binding.CharacterStream": "com.intersystems.binding.Writer",
									"com.intersystems.binding.BinaryStream": "com.intersystems.binding.OutputStream")
	}
	s sigType = ..tConverter.getSigType(propType, ..newCollections)
	
	// Create JavaDoc
	if 'isRelationship {
		d ..jdCreator.createSetterDoc(file, clientName, sigType, description)
		if interfaceFile '= "" {d ..jdCreator.createSetterDoc(interfaceFile, clientName, sigType, description)}
	}
	
	// Don't project setter if:
	// (1) property is ReadOnly, or
	// (2) property is the non-collection half in a Relationship
	if '(isRelationship && (collectionType '= "")) && 'isReadOnly {
		// Create setter signature
		s rType = $select(isStream: sigType_" ", 1: "void ")
		s op = $select(isStream: "get", 1: "set")
		s out = $select(isStream: "Out", 1: "")
		s param = $select(isStream: "", 1: sigType_" _val")
		d file.IndentAndWriteLine("public "_rType_op_..resolveConflictedMemberName(clientName)_out_"("_param_") {", 1)
		if interfaceFile '= "" {
			d interfaceFile.IndentAndWriteLine("public "_rType_op_..resolveConflictedMemberName(clientName)_out_"("_param_");", 1)
			d interfaceFile.IndentAndWriteLine()
		}
		
		if isStream {
			d file.IndentAndWriteLine("return new "_propType_"((IRISObject)irisObject.get("""_propName_"""), db);", 2)
			
		} else {
			s arg = ..tConverter.paramsToArguments($lb(propType_" _val"))
			d file.IndentAndWriteLine("irisObject.set("""_propName_""""_arg_");", 2)
		}
		
		d file.IndentAndWriteLine("}", 1)
		d file.IndentAndWriteLine()
	}
}

/// Create index methods
Method createIndexMethods(file As JavaFile, index As %Dictionary.CompiledIndex, ByRef qstruct As %String) As %Status
{
	s Status = $$$OK
	s indexName = index.Name
	// Check if index is system index
	if indexName = "" {
		return Status
	}
	
	s methods = index.Methods
	for i=1:1:methods.Count() {
		s method = methods.GetAt(i)
		s methodName = method.Name 
		// Only project Delete, Exists, and Open methods
		if method.ServerOnly {
			continue	
		}
		
		// Process return type
		s returnType = method.ReturnType
		s Status = ..convertReturnType(.returnType, .package, .returnsObject, .qstruct)
		if $$$ISERR(Status) {
			return Status	
		}
		
		// Process method parameters
		s props = index.Properties
		s propTypes = method.UserActualType
		for j=1:1:$length(props, ",") {
			s prop = $p(props, ",", j)
			s prop = $p($p(prop, ":", 1), ".", *)
			if prop = "" {
				s prop = "K"_j	
			}
			s $p(props, ",", j) = prop_":"_$p(propTypes, ",", j)
		}
		s params = ##class(%ListOfDataTypes).%New()
		s Status = ..convertParams(.params, props_","_method.FormalSpec, .qstruct)
		if $$$ISERR(Status) {
			return Status	
		}
		
		// Create index methods
		for j=1:1:params.Count() {
			d ..createMethod(file, indexName_methodName, params.GetAt(j), returnType, indexName_methodName, returnsObject, 1)
		}
	}
	q Status
}

/// Create user-defined methods
Method createQueryMethod(file As JavaFile, query As %CompiledQuery)
{
	// If not a SqlProc query, don't project
	if 'query.SqlProc || ((query.Name = "Extent") && ..class.NoExtent) {
		return
	}	
	
	s queryName = query.Name
	s sqlName = query.SqlName
	s params = query.FormalSpec
	s numParams = 0
	if params '= "" {
		s numParams = $length(params, ",")	
	}
	
	//create query with Database argument
	d ..jdCreator.createQueryDoc(file, queryName, query.Description, 2)
	d file.IndentAndWriteLine("public static com.intersystems.binding.IRISQuery query_"_queryName_"(Database db) throws SQLException {", 1)
	d file.IndentAndWriteLine("return query_"_queryName_"((IRISConnection)db.getConnection());", 2)
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine()
	
	//create query with IRISConnection argument
	d file.IndentAndWriteLine("public static com.intersystems.binding.IRISQuery query_"_queryName_"(IRISConnection connection) throws SQLException {", 1)
	d file.IndentAndWriteLine("return new com.intersystems.binding.IRISQuery(connection, """_..irisPackage_"."_sqlName_""", "_numParams_");", 2)
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine()
}

/// Create user-defined methods
Method createUserDefinedMethod(file As JavaFile, method As %CompiledMethod, properties As %ArrayOfDataTypes, interfaceFile = "", ByRef qstruct As %String) As %Status
{
	if '..isProjectableMethod(method) {return $$$OK}
	
	s Status = $$$OK
	s methodName = method.Name
	s returnType = method.ReturnType
	s methodParams = method.FormalSpec
	if $lf(..systemMethods, methodName) {s interfaceFile = ""}
	
	// Process return type
	s Status = ..convertReturnType(.returnType, .package, .returnsObject, .qstruct)
	if $$$ISERR(Status) {return Status}
	
	// Process parameters
	s convertedParams = ##class(%ListOfDataTypes).%New()
	s Status = ..convertParams(.convertedParams, methodParams, .qstruct)
	if $$$ISERR(Status) {return Status}
	
	// Check if this method is a property getter/setter
	s op = $e(methodName, *-2, *)
	s propName = $e(methodName, 1, *-3)
	if propName '= "" {
		s propType = properties.GetAt(propName)
		// Special case if this is a property getter
		if (methodParams = "") && (returnType = propType) && (op = "Get") {
			s $list(..propsWithGetter, *+1)	= propName
			return Status
		}
		
		// Special case if this is a property setter
		if convertedParams.Count() = 1 {
			s convertedParam = convertedParams.GetAt(1)
			if ($listlength(convertedParam) = 1) && ($p($list(convertedParam, 1), " ", 1) = propType)
			&& (returnType = "com.intersystems.binding.StatusCode") && (op = "Set") {
				s $list(..propsWithSetter, *+1)	= propName
				return Status
			}
		}
	}

	// If ClientName is specified, use it as Java method name
	if method.ClientName '= "" {
		s methodName = method.ClientName	
	}
	
	// Get name of the Java method to create
	s javaMethodName = ..resolveConflictedMemberName(methodName)
	s op = $e(javaMethodName, 1, 3)
	if (op = "set") || (op = "get") {
		s propName = $extract(javaMethodName, 4, *)
		if (propName '= "") && (properties.GetAt(propName) '= "") {
			s javaMethodName = "_"_javaMethodName	
		}
	}

	for i=1:1:convertedParams.Count() {
		s params = convertedParams.GetAt(i)
		// Ignore  buggy instances of sys_Delete(IRISConnection) and sys_Exists(IRISConnection)
		if $lf(..ignoredMethods, method.Name) && ($listlength(params) = 0) {
			continue	
		}
		d ..createMethod(file, javaMethodName, params, returnType, method.Name, returnsObject, method.ClassMethod, method.Description, , interfaceFile)
	}
	
	if method.SqlProc {
		s argCount = 0
		i methodParams '= "" {s argCount = $length(methodParams, ",")}
		d ..createStoredProcedure(file, method.Name, argCount, method.ReturnType, method.SqlName, method.Description)	
	}
	
	q Status
}

Method isProjectableMethod(method As %CompiledMethod) As %Boolean
{
	s origin = method.Origin
	s name = method.Name

	// Some system methods are projected, if other inheritance conditions are matched
	if $lf(..systemMethods, name) {
		return $select((..rootSuper = ""): 0,
						'(((..rootSuper = "SerialObject") || (..classType = "serial")) && (..classType '= "index") && (..classType '= "")) && (name = "LogicalToOdbc"): 0,
						'(((..rootSuper = "SerialObject") || (..classType = "serial")) && (..classType '= "index") && (..classType '= "")) && (name = "OdbcToLogical"): 0,
						'((..rootSuper = "Persistent") && $lf(..typesWithBuildIndices, ..classType)) && (name = "%BuildIndices"): 0,
														1: 1)
	}
	
	// Skip creation for a number of method types, including:
	// system methods,
	// methods belonging to leftmost superclass that aren't classmethods,
	// methods in other superclasses marked NotInheritable,
	// methods that are Private or ServerOnly
	if ($e(name, 1) = "%")
	|| ((origin '= ..class.Name) && '$lf(..irisSupers, origin))
	|| ((origin = ..leftSuper) && 'method.ClassMethod)
	|| ($lf(..irisSupers, origin, 1) && method.NotInheritable)
	|| method.Private || method.ServerOnly {
		return 0
	}
	
	return 1
}

/// Create stored procedure for a SqlProc class method
Method createStoredProcedure(file As JavaFile, methodName As %String, argCount As %Integer, returnType As %String, sqlName As %String, description As %String)
{
	
	s fullClassName = ..class.Name
	s packageName = fullClassName
	s $p(packageName, ".", *) = ""
	s procName = $p(fullClassName, ".", *)_"_"_methodName
	if sqlName '= "" s procName = sqlName
	
	// Create JavaDoc
	d ..jdCreator.createStoredProcedureDoc(file, procName, methodName, description)
	
	s params = ""
	for i=1:1:argCount {
		s $list(params, *+1) = "?"	
	}
	
	//Method with Database argument
	d file.IndentAndWriteLine("public static java.sql.CallableStatement prepare_"_procName_"(Database db) {", 1)
	d file.IndentAndWriteLine("return prepare_"_procName_"((IRISConnection)db.getConnection());", 2)
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine()
	
	//Method with IRISConnection argument
	d file.IndentAndWriteLine("public static java.sql.CallableStatement prepare_"_procName_"(IRISConnection connection) {", 1)
	d file.IndentAndWriteLine("try {", 2)
			
	// If there's no return value, no need to registerOutParameter
	if returnType = "" {
		d file.IndentAndWriteLine("return connection.prepareCall(""{call "_packageName_procName_"("_..tConverter.paramsToString(params)_")}"");", 3)
		
	} else {
		d file.IndentAndWriteLine("java.sql.CallableStatement stmt = connection.prepareCall(""{? = call "_packageName_procName_"("_..tConverter.paramsToString(params)_")}"");", 3)
		d file.IndentAndWriteLine("stmt.registerOutParameter(1, java.sql.Types."_$get(^irisToODBCType(returnType))_");", 3)
		d file.IndentAndWriteLine("return stmt;", 3)
	}
			
	d file.IndentAndWriteLine("} catch (java.sql.SQLException x) {", 2)
	d file.IndentAndWriteLine("throw new RuntimeException(""Failed to prepare stored procedure "_procName_": "" + x.getMessage());", 3)
	d file.IndentAndWriteLine("}", 2)
	
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine()
}

/// Format a method return type into the right form to append to a Java template
Method convertReturnType(ByRef returnType As %String, ByRef package = "", ByRef returnsObject As %Boolean, ByRef qstruct As %String) As %Status
{
	s Status = $$$OK
	s returnsObject = 0
	
	// If there's no return type supplied, set type to void
	if returnType = "" {
		s returnType = "void"
		
	// Else, fetch the right matching Java type
	} else {
		s Status = ..tConverter.convertType(returnType, .package, .type,,,,.qstruct)
		if $$$ISERR(Status) {q Status}
		s returnsObject = (package '= "%Library") && (package '= "%MV")
		s returnType = type
	}
	q Status
}

/// Format a string of method parameters into a $list of parameters
Method convertParams(ByRef convertedParams As %ListOfDataTypes, methodParams As %String, ByRef qstruct As %String) As %Status
{
	s Status = $$$OK
	d convertedParams.Insert("")
	if methodParams '= "" {
		// Keep duplicating parameter sets as long as we haven't found a parameter WITHOUT a default value
		s duplicateParamSets = 1
		s paramLength = $length(methodParams, ",")
		
		for j=paramLength:-1:1 {
			s methodParam = $p(methodParams, ",", j)
			s defaultVal = $p(methodParam, "=", 2)
			
			s methodParam = $p(methodParam, "=", 1)
			s paramName = ..resolveConflictedMemberName($p(methodParam, ":", 1))
			s paramType = $p(methodParam, ":", 2)
			s paramType = $p(paramType, "(", 1)
			
			// When param type not found, default to String
			if paramType = "" {
				s paramType = "%String"	
			}
			
			// When parameters are denoted ByRef or Output, wrap them in IRISReference
			if $lf($lb("&", "*"), $e(paramName, 1, 1)) {
				s paramName = $e(paramName, 2, *)
				s paramType = "com.intersystems.binding.IRISReference"
				
			} else {
				// Retrieve the full package name of param type
				if $length(paramType, ".") = 1 {
					if $e(paramType, 1) = "%" {
						s paramType = $replace(paramType, "%", "%Library.")
					} else {
						s paramType = ..irisPackage_"."_paramType
					}
				}
				// Convert to the right Java type
				s Status = ..tConverter.convertType(paramType, .package, .type,,,, .qstruct)
				if $$$ISERR(Status) {return Status}
				s paramType = type
			}
			
			if duplicateParamSets && (defaultVal = "") {
					s duplicateParamSets = 0
			}
			
			s param = paramType_" "_paramName
			for i=1:1:convertedParams.Count() {
				s params = convertedParams.GetAt(i)
				d convertedParams.SetAt($lb(param)_params, i)
			}
			// If we haven't found a parameter without a default value, continue duplicating the parameter sets
			if duplicateParamSets {
				d convertedParams.Insert("")	
			}
		}
	}
	q Status
}

/// Template to create 1 pair of system methods
Method createMethodPair(file As JavaFile, javaMethodName1 As %String, javaMethodName2 As %String, params As %List, returnType As %String, irisMethodName As %String, returnsObject = 0)
{
	//Create the main method that handles calling the server-side method
	d ..jdCreator.createPersistentMethodDoc(file, irisMethodName, params)
	d ..createMethod(file, javaMethodName1, params, returnType, irisMethodName, returnsObject, 1, , 0)
	
	//process return type for stub method
	s returnType = $piece(returnType, ":", 1)
	if returnType = "Status" {
		s returnType = "void"	
	}
	s returnKeyword = $case(returnType, "void": "", : "return ")
	
	//process arguments for stub method
	s args = ..tConverter.paramsToArguments(params, 1, 0)
	
	//Create stub method that calls main method
	d ..jdCreator.createPersistentMethodDoc(file, irisMethodName, params)
	d file.IndentAndWriteLine("public static "_returnType_" "_javaMethodName2_"(Database db, "_..tConverter.paramsToString(params)_") throws SQLException {", 1)
 	d file.IndentAndWriteLine(returnKeyword_javaMethodName1_"((IRISConnection)db.getConnection()"_args_");", 2)
 	d file.IndentAndWriteLine("}", 1)
 	d file.IndentAndWriteLine()
	d file.IndentAndWriteLine("public static "_returnType_" "_javaMethodName2_"(IRISConnection connection, "_..tConverter.paramsToString(params)_") throws SQLException {", 1)
 	d file.IndentAndWriteLine(returnKeyword_javaMethodName1_"(connection"_args_");", 2)
 	d file.IndentAndWriteLine("}", 1)
 	d file.IndentAndWriteLine()
}

/// Create %OpenByQuery
Method createOpenByQueryPair(file As JavaFile, tableName As %String)
{
	d ..createOpenByQuery(file, tableName, 1)
	d ..createOpenByQuery(file, tableName)
}

Method createOpenByQuery(file As JavaFile, tableName As %String, hasArgs = 0)
{
	//Create javadoc
	d ..jdCreator.createOpenByQueryDoc(file, hasArgs)
	
	s argsInSignature = $case(hasArgs, 0: "",
										1: ", Object[] args")
										
	//method with Database argument
	d file.IndentAndWriteLine("public static java.util.Iterator openByQuery(Database db, String condition"_argsInSignature_") throws SQLException {", 1)
	s argsInBody = $case(hasArgs, 0: "",
									1: ", args")
	d file.IndentAndWriteLine("return openByQuery((IRISConnection)db.getConnection(), condition"_argsInBody_");", 2)
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine()
	
	//method with IRISConnection argument
	d file.IndentAndWriteLine("public static java.util.Iterator openByQuery(IRISConnection connection, String condition"_argsInSignature_") throws SQLException {", 1)
	d file.IndentAndWriteLine("String sql= ""SELECT %ID FROM "_tableName_" WHERE "" + condition;",2)
	d file.IndentAndWriteLine("java.sql.PreparedStatement statement = connection.prepareStatement(sql);",2)
	if hasArgs {
		d file.IndentAndWriteLine("for (int i = 0;i < args.length;i++)",2)
		d file.IndentAndWriteLine("statement.setObject(i + 1, args[i]);",3)
	}
	d file.IndentAndWriteLine("java.sql.ResultSet rs = statement.executeQuery();",2)
	d file.IndentAndWriteLine()
	d file.IndentAndWriteLine("java.util.List<"_..className_"> list = new java.util.ArrayList<"_..className_">();",2)
	d file.IndentAndWriteLine("while (rs.next())",2)
	d file.IndentAndWriteLine("list.add(("_..className_")"_..className_"._open(connection, new Id(rs.getInt(1))));",3)
	d file.IndentAndWriteLine()
	d file.IndentAndWriteLine("return list.iterator();",2)
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine()
}

Method resolveConflictedMemberName(name As %String) As %String
{
	// Resolve system method name
	if $e(name, 1) = "%" {s name = "sys_"_$e(name, 2, *)}
	
	// Resolve name conflicted with Java type names
	if $lf(..conflictedMemberName, name) {q "_"_name}
	q name
}

Method createDateTimeValidator(file As JavaFile, propName = "", propType = "")
{
	d ..jdCreator.createMethodDoc(file, propName_"IsValid", $lb("IRISConnection connection", "String _val"), "", 2)
	
	//Method with Database argument
	d file.IndentAndWriteLine("public static void "_propName_"IsValid(Database db, String _val) throws SQLException {" ,1)
	d file.IndentAndWriteLine(propName_"IsValid((IRISConnection)db.getConnection(), _val);", 2)
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine("", 1)
	
	//Method with IRISConnection argument
	d file.IndentAndWriteLine("public static void "_propName_"IsValid(IRISConnection connection, String _val) throws SQLException {" ,1)
	d file.IndentAndWriteLine("IRIS iris = IRIS.createIRIS(connection);", 2)
	d file.IndentAndWriteLine("iris.classMethodStatusCode(IRIS_CLASS_NAME, """_propName_"IsValid"", Util."_propType_"IRISFormat(_val));", 2)
	d file.IndentAndWriteLine("}", 1)
	d file.IndentAndWriteLine("", 1)
}

Method default()
{
}

}
