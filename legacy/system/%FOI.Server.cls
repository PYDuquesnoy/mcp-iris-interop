/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %occErrors, %SYS.DBSRV, %oueXEP)

Class %FOI.Server
{

ClassMethod CompileSchemas(schemaNames)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
		do ##class(%FOI.Schema).compileSchemaList($listfromstring(schemaNames))
	} catch exception {
		do DecomposeStatus^%apiOBJ(exception.AsStatus(),.error)
		return error(1)
	}
	return ""
}

ClassMethod SaveSchema(chunk1, chunk2, chunk3, chunk4, chunk5)
{
	set stream = ##class(%Stream.TmpCharacter).%New()
	do stream.Write(chunk1)
	do:(chunk2'="")&&(chunk2'=$char(0)) stream.Write(chunk2)
	do:(chunk3'="")&&(chunk3'=$char(0)) stream.Write(chunk3)
	do:(chunk4'="")&&(chunk4'=$char(0)) stream.Write(chunk4)
	do:(chunk5'="")&&(chunk5'=$char(0)) stream.Write(chunk5)
	try {
		$$$XEPCHECKPROTOCOLVERSION
		do stream.Rewind()
		set schema = ##class(%FOI.Schema).%FromJSON(stream)
		set response = ""
	} catch exception {
		set status = exception.AsStatus()
		do DecomposeStatus^%apiOBJ(status,.error)
		set response = error(1)
	}
	return response
}

/// return schema definition for schemaName
ClassMethod GetSchema(schemaName)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
		return ##class(%FOI.Schema).getSchema(schemaName)
	} catch exception {
		set status = exception.AsStatus()
		do DecomposeStatus^%apiOBJ(status,.error)
		return error(1)
	}
}

ClassMethod GetRecordMetadata(schemaName)
{
	try {
		return ##class(%FOI.Schema).getRecordDefinition(schemaName)
	} catch exception {
		set status = exception.AsStatus()
		do DecomposeStatus^%apiOBJ(status,.error)
		return error(1)
	}
}

ClassMethod GetTableClass(tableName)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
		if tableName '= "" {
			set className = $$LookUpClassName^%apiDDL2(tableName)
		} else {
			set className = ""
		}
	} catch exception {
		set className = ""
	}
	return className
}

ClassMethod Load(fileName)
{
	Do $System.OBJ.Load(fileName,"-drf/retainstorage=1",.error)
	Quit:'$G(error) ""
	Do DecomposeStatus^%apiOBJ(%objlasterror,.error)
	Quit error(1)
}

ClassMethod Compile(className)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
	Do $System.OBJ.Compile(className,"-drf",.error)
		return:'$G(error) ""
	Do DecomposeStatus^%apiOBJ(%objlasterror,.error)
		return error(1)
	} catch exception {
		Do DecomposeStatus^%apiOBJ(exception.AsStatus(),.error)
		return error(1)
	}
}

ClassMethod GetGlobalName(className)
{
	return $$generateExtentGlobal^%occStorageUtil(className)
}

ClassMethod LoadClass(chunk1, chunk2, chunk3, chunk4, chunk5)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
	Set stream=##class(%GlobalCharacterStream).%New()
	Do stream.Write(chunk1)
	Do:chunk2'="" stream.Write(chunk2)
	Do:chunk3'="" stream.Write(chunk3)
	Do:chunk4'="" stream.Write(chunk4)
	Do:chunk5'="" stream.Write(chunk5)
	Do $System.OBJ.LoadStream(stream,"-drf/retainstorage=1",.error)
		return:'$G(error) ""
	Do DecomposeStatus^%apiOBJ(%objlasterror,.error)
		return error(1)
	} catch exception {
		Do DecomposeStatus^%apiOBJ(exception.AsStatus(),.error)
		return error(1)
	}
}

ClassMethod DeleteClass(className)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
		set response = ""
		if ##class(%FOI.Schema).kFNExists(className) {
			do ##class(%FOI.Schema).deleteSchema(className)
		}
	} catch exception {
		if (exception.Code '= $$$LoadObjectNotFound) && (exception.Code '= $$$ClassDoesNotExist) && (exception.Code '= $$$KeyValueNotFoundOpen) {
			do DecomposeStatus^%apiOBJ(exception.AsStatus(),.error)
			set response = error(1)
		}
	}
	return response
}

ClassMethod GetMetaData(className)
{
	Try {
		$$$XEPCHECKPROTOCOLVERSION
		Set importTimestamp=$zobjclassmethod(className,"%GetParameter","IMPORTTIMESTAMP")
		Set importFlags=$zobjclassmethod(className,"%GetParameter","IMPORTFLAGS")
		If (importTimestamp="")||(importFlags="") {
			return "-1"_",The class might exist but has not been created by way of XEP import " 
		}
		set metadata = $$GetMetaDataUnconditionally(className)
		Set metadata=importTimestamp_","_importFlags_","_metadata
	} Catch exception {
		do DecomposeStatus^%apiOBJ(exception.AsStatus(),.errorText)
		set metadata="-1"_","_errorText(1)	
	}
	return metadata
}

ClassMethod GetMetaDataUnconditionally(className)
{
	Try {
		$$$XEPCHECKPROTOCOLVERSION
		Set className=$$$NormalizeClassname(className)
		Set globalName=$$getClassGlobalName^%SYS.LCBINDSRV(className)
		Set error=$$XEPNodeMetadata^%ocsCacheUtil(className,.metadata)
		Set idKeys=$$XEPGetIdMetadata^%ocsCacheUtil(className)
		// Set idMetaData=$$GetIdMetadata^%ocsCacheUtil(className)
		If error'=1 {
			Do DecomposeStatus^%apiOBJ(error,.errorText)
			Set metadata="-1"_","_errorText(1)
		} Else {
			If (idKeys="%%ID")||($G(idKeys)="") {
				Set metadata="%%,"_metadata
			} Else {
				Set metadata=idKeys_","_metadata
			}
			Set metadata=globalName_","_$$$comClassKeyGet(className,$$$cCLASSfinal)_","_$$GetIndexCount^%ocsCacheUtil(className)_","_metadata
		}
	} Catch exception {
		do DecomposeStatus^%apiOBJ(exception.AsStatus(),.errorText)
		set metadata="-1"_","_errorText(1)
	}
	return metadata
}

ClassMethod CompareTimestamp(className, timestamp)
{
	Set exists="false"
	Try {
		$$$XEPCHECKPROTOCOLVERSION
		If ##class(%Dictionary.CompiledClass).%ExistsId(className) {
			If timestamp=$zobjclassmethod(className,"%GetParameter","IMPORTTIMESTAMP") {
				Set exists="true"
			} Else {
				Set exists="recompiled"
			}
		}
		return exists
	} catch exception {
		return "false"
	}
}

ClassMethod Handshake(protocolVersion, userName, machineName, exeName, osInfo, hostInfo)
{
	Try {
		Set x=$ZU(67,11,userName,$j)
		Set x=$ZU(67,12,machineName,$j)
		Set x=$ZU(67,13,exeName,$j)
		//Set x=$ZU(67,14,osInfo,$j)
		Set x=$ZU(67,15,hostInfo,$j)
		Set protocolVersion=$S(protocolVersion>$$$PROTOCOLVERSION:$$$PROTOCOLVERSION,1:protocolVersion)
		Set x=protocolVersion_":"_$zbitget($zversion(0),1)_":"_$$GetCharset^%SYS.NLS()
	} Catch {
		Quit
	}
	Quit x
}

ClassMethod ResetSequence(globalName)
{
	set $sequence(@globalName)=""
}

ClassMethod DeleteObject(className, id)
{
	Set className=$$$NormalizeClassname(className)
	Set error=$classmethod(className,"%DeleteId",id)
	Quit:error=1 ""
	Do DecomposeStatus^%apiOBJ(error,.errorText)
	Quit errorText(1)
}

ClassMethod UpdateObject(id, value, className, keyDegree, nodeCount)
{
	if '$classmethod(className,"%ExistsId",id) {
		return "Object to update does not exist: '" _ className _ "', id = '" _ id _ "'"
	}
	try {
		set nodes = 0
		if ('keyDegree) {
			set idList = $lb(id)
			if nodeCount = 1 {
				set nodes = value
			}
		} else {
			set idList = $list(value,1,keyDegree)
			for ptr = (keyDegree + 1):2:$listLength(value)-1 {
				set sub = $listget(value,ptr)
				if (sub = "") || (sub = "null") {
					set nodes = $lg(value,ptr + 1)
				} else {
					set nodes(sub) = $lg(value,ptr + 1)
				}
			}
		}
		$$$THROWONERROR(status,$classmethod(className, "%SaveDirect",id,idList,.nodes))
		return ""
	} catch exception {
		do DecomposeStatus^%apiOBJ(exception.AsStatus(), .errorText)
		return errorText(1)
	}
}

ClassMethod getObjectUM(args...)
{
	set globalName = args(1)
	set gref = globalName _ "("
	for ptr = 2:1:args {
		set gref = gref _ $select(args(ptr)'=+args(ptr):$zu(144,1,args(ptr)),1:args(ptr)) _ ","
	}
	set $extract(gref,*) = ")"
	if $data(@gref) {
		set result = $lb("",@gref)
	} else {
		set id = $get(args(2))
		for ptr = 3:1:args {
			set id = id _ "||" _ args(ptr)
		}
		if $order(^rINDEXEXT("G",globalName,""),1,className) '= "" {
			set className = $list(className,2)
		} else {
			set className = globalName
		}
		throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LoadObjectNotFound, className, id))
	}
	set subscript = $order(@gref@(""),1,nodeVal)
	while subscript '= "" {
		set result = result _ $lb(subscript, nodeVal)
		set subscript = $order(@gref@(subscript),1,nodeVal)
	}
	return result
}

ClassMethod assignShardedId(className, globalName)
{
	set seqval = $sequence(@globalName), contextRange = $g($system.Context.SQL().ShardIDRange($namespace_":" _ className),$lb(0,0,0))
	set id = seqval + $lg(contextRange,3)
	if id > $lg(contextRange,2) {
		set id = $$GetNextIdRange^%apiSQL(className,seqval,id,.sqlcode)
		if sqlcode<0 {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(sqlcode, $get(%msg))
		}
	} elseif id < $lg(contextRange,1) {
		set endrange = $o(^IRIS.SM.Shard("nr",className_".cls",id),1,data)
		if endrange = "" {
			set id = $$GetNextIdRange^%apiSQL(className,seqval,id,.sqlcode)
			if sqlcode < 0 {
				throw ##class(%Exception.SQL).CreateFromSQLCODE(sqlcode, $get(%msg))
			} else {
				set $system.Context.SQL().ShardIDRange($namespace_":"_className) = $lb(+$lg(data,1),+endrange,+$lg(data,2))
				set id = seqval + $lg(data,2)
			}
		}
	}
	return id
}

/// SSSND - Sharded System assigned, ID, Single node, No Return, Deferred Indexing (SSND)
ClassMethod writeObjectSSSND(value, className, globalName, indexOpt)
{
	set id = assignShardedId(className, globalName)
	set @globalName@(id) = value
	if (indexOpt) set $bit(@(globalName_".0")@(id\64000+1),id#64000+1) = 1
}

/// SSSRD - Write array of objects to database, system assigned ID, single node, return ID's, indexOpt = 0 (deferred), 1 = no indexing, 2 = immediate indexing
ClassMethod writeArraySSSRD(arrayList, className, globalName, indexOpt)
{
	if 'indexOpt set didiGlobal = globalName _ ".0"
	set ids = ""
	set listPtr = 0
	set contextRange = $g($system.Context.SQL().ShardIDRange($namespace_":" _ className),$lb(0,0,0))
	while $listNext(arrayList,listPtr,value){
		set seqval = $sequence(@globalName)
		set id = seqval + $lg(contextRange,2)
		if (id < $lg(contextRange,1)) || (id > $lg(contextRange,2)) {
			set id = assignShardedId(className, globalName)
			set contextRange = $g($system.Context.SQL().ShardIDRange($namespace_":" _ className),$lb(0,0,0))
		}
		set @globalName@(id) = value
		if indexOpt set $bit(@(didiGlobal)@(id\64000+1),id#64000+1) = 1
		set ids = ids _ $lb(id)
	}
	return ids
}

/// SMND - Write object to database, system assigned ID, multiple nodes, return ID, Deferred or no indexing
ClassMethod writeObjectSMND(value, globalName, nodeCount, indexOpt)
{
	if indexOpt set didiGlobal = globalName _ ".0"
	set id = $sequence(@globalName)
			set listPtr = 0
	for ptr = 1:1:nodeCount {
		if ($listNext(value,listPtr,subscript)) && ($listNext(value,listPtr,nodeValue)) {
			if (subscript = "") || (subscript = "null") {
				set @globalName@(id) = nodeValue
			} else {
				set @globalName@(id,subscript) = nodeValue
			}
		} else {
			quit
		}
	}
	if indexOpt set $bit(@(didiGlobal)@(id\64000+1),id#64000+1) = 1
}

/// SSRD - Write object to database, system assigned ID, Single node, Return ID, Deferred or no indexing (SSR)
ClassMethod writeObjectSSRD(value, globalName, indexOpt)
{
	set id = $sequence(@globalName)
	set @globalName@(id) = value
	if (indexOpt) set $bit(@(globalName_".0")@(id\64000+1),id#64000+1) = 1
	return id
}

ClassMethod writeObjectSSNI(value, className, indexOpt)
{
	do $classmethod(className, "%SaveDirect",,"",value)
}

/// SMNI - Write array of objects to database, system assigned ID, multiple nodes, return ID's, Immediate indexing
ClassMethod writeObjectSMNI(value, className, nodeCount, indexOpt)
{
	for count = 1:1:nodeCount {
		if ($listNext(arrayList,listPtr,subscript)) && ($listNext(arrayList,listPtr,value)) {
			if (subscript = "") {
				set nodes = value
			} else {
				set nodes(subscript) = value
			}
		}
	}
	do $classmethod(className,"%SaveDirect",,,.nodes)
}

/// SMRI - Write array of objects to database, system assigned ID, multiple nodes, return ID's, Immediate indexing
ClassMethod writeObjectSMRI(value, className, nodeCount, indexOpt)
{
	for count = 1:1:nodeCount {
		if ($listNext(arrayList,listPtr,subscript)) && ($listNext(arrayList,listPtr,value)) {
			if (subscript = "") {
				set nodes = value
			} else {
				set nodes(subscript) = value
			}
		}
	}
	set id = ""
	do $classmethod(className,"%SaveDirect",.id,,.nodes)
	return id
}

/// SMRD - Write object to database, system assigned ID, multiple nodes, return ID, Deferred or no indexing
ClassMethod writeObjectSMRD(value, globalName, indexOpt)
{
	set id = $sequence(@globalName)
	for ptr = 0:1:nodeCount-1 {
		set sub = $lg(value,ptr+1)
		if (sub = "") || (sub = "null") {
			set @globalName@(id) = $lg(value,ptr+2)
		} else {
			set @globalName@(id,sub) = $lg(value,ptr+2)
		}
	}
	if indexOpt set $bit(@(globalName_".0")@(id\64000+1),id#64000+1) = 1
	return id
}

ClassMethod writeObjectUSND(value, globalName, keyDegree, indexOpt)
{
	set gref = globalName _ "("
	for ptr = 1:1:keyDegree {
		set keySeg = $list(value,ptr)
		set gref = gref _ $select(keySeg'=+keySeg:$zu(144,1,keySeg),1:keySeg) _ ","
	}
	set $extract(gref,*) = ")"
	set sub = $listget(value,keyDegree + 1)
	set @gref = $lg(value,keyDegree + 2)
}

ClassMethod writeObjectUSNI(value, className, keyDegree, indexOpt)
{
	do $classmethod(className, "%SaveDirect",,$list(value,1,keyDegree),$lg(value,keyDegree+2))
}

ClassMethod writeObjectUMNI(value, className, keyDegree, nodeCount, indexOpt)
{
	set idList = $list(value,1,keyDegree)
	for ptr = (keyDegree + 1):2:$listLength(value)-1 {
		set sub = $listget(value,ptr)
		if (sub = "") || (sub = "null") {
			set nodes = $lg(value,ptr + 1)
		} else {
			set nodes(sub) = $lg(value,ptr + 1)
		}
	}
	do $classmethod(className, "%SaveDirect",,idList,.nodes)
}

ClassMethod writeObjectUMND(value, globalName, keyDegree, nodeCount, indexOpt)
{
	set gref = globalName _ "("
	for ptr = 1:1:keyDegree {
		set keySeg = $list(value,ptr)
		set gref = gref _ $select(keySeg'=+keySeg:$zu(144,1,keySeg),1:keySeg) _ ","
	}
	set $extract(gref,*) = ")"
	for ptr = (keyDegree + 1):2:$listLength(value)-1 {
		set sub = $listget(value,ptr)
		if (sub = "") || (sub = "null") {
			set @gref = $lg(value,ptr + 1)
		} else {
			set @gref@(sub) = $lg(value,ptr + 1)
		}
	}
}

ClassMethod writeArraySSNI(arrayList, className, indexOpt)
{
	set listPtr = 0
	while ($listNext(arrayList,listPtr,value)) {
		do $classmethod(className, "%SaveDirect",,"",value)
	}
}

/// SMNI - Write array of objects to database, system assigned ID, multiple nodes, return ID's, Immediate indexing
ClassMethod writeArraySMNI(arrayList, className, nodeCount, indexOpt)
{
	set listPtr = 0
	set atEnd = 0
	while 'atEnd {
			// for each node
		kill nodes
		for count = 1:1:nodeCount {
			if ($listNext(arrayList,listPtr,subscript)) && ($listNext(arrayList,listPtr,value)) {
				if (subscript = "") {
					set nodes = value
				} else {
					set nodes(subscript) = value
				}
			} else {
					// in a properly constructed buffer this should only happen at the beginning (count = 1) of a new object
					// and we didn't find one. (at the end of the arraylist
				set atEnd = 1
				continue
			}
		}
		do $classmethod(className,"%SaveDirect",,,.nodes)
	}
}

/// sSSRD - Write array of objects to database, system assigned ID, single node, return ID's, indexOpt = 0 (deferred), 1 = no indexing, 2 = immediate indexing
ClassMethod writeArraySSRD(arrayList, globalName, indexOpt)
{
	if 'indexOpt set didiGlobal = globalName _ ".0"
	set ids = ""
	set listPtr = 0
	while $listNext(arrayList,listPtr,value){
		set id = $sequence(@globalName)
		set @globalName@(id) = value
		if indexOpt set $bit(@(didiGlobal)@(id\64000+1),id#64000+1) = 1
		set ids = ids _ $lb(id)
	}
	return ids
}

/// Array of SMND - System assigned ID, Multiple nodes, No Return (SMNR)
ClassMethod writeArraySMND(arrayList, globalName, nodeCount, indexOpt)
{
	if 'indexOpt set didiGlobal = globalName _ ".0"
	set listPtr = 0
	if $listNext(arrayList,listPtr,subscript) {
		set atEnd = 0
		while 'atEnd {
			set id = $sequence(@globalName)
				// for each node
			for count = 1:1:nodeCount {
				if $listNext(arrayList,listPtr,value) {
					if (subscript = "") {
						set @globalName@(id) = value
					} else {
						set @globalName@(id,subscript) = value
					}
				}
				if '$listNext(arrayList,listPtr,subscript) {
					set atEnd = 1
					quit
				}
			}
			if indexOpt set $bit(@(didiGlobal)@(id\64000+1),id#64000+1) = 1
		}
	}
}

/// SMRD - Write array of objects to database, system assigned ID, multiple nodes, return ID's, Deferred or no indexing
ClassMethod writeArraySMRD(arrayList, globalName, nodeCount, indexOpt)
{
	if 'indexOpt set didiGlobal = globalName _ ".0"
	set ids = ""
	set listPtr = 0
	if $listNext(arrayList,listPtr,subscript) {
		set atEnd = 0
		while 'atEnd {
			set id = $sequence(@globalName)
				// for each node
			for count = 1:1:nodeCount {
				if $listNext(arrayList,listPtr,value) {
					if (subscript = "") {
						set @globalName@(id) = value
					} else {
						set @globalName@(id,subscript) = value
					}
				}
				if '$listNext(arrayList,listPtr,subscript) {
					set atEnd = 1
					quit
				}
			}
			if indexOpt set $bit(@(didiGlobal)@(id\64000+1),id#64000+1) = 1
			set ids = ids _ $lb(id)
		}
	}
	return ids
}

/// sSMRI - Write array of objects to database, system assigned ID, multiple nodes, return ID's, Immediate indexing
ClassMethod writeArraySMRI(arrayList, className, nodeCount, indexOpt)
{
	set ids = ""
	set listPtr = 0
	set atEnd = 0
	while 'atEnd {
			// for each node
		kill nodes
		for count = 1:1:nodeCount {
			if ($listNext(arrayList,listPtr,subscript)) && ($listNext(arrayList,listPtr,value)) {
				if (subscript = "") {
					set nodes = value
				} else {
					set nodes(subscript) = value
				}
			} else {
					// in a properly constructed buffer this should only happen at the beginning (count = 1) of a new object
					// and we didn't find one. (at the end of the arraylist
				set atEnd = 1
				continue
			}
		}
		set id = ""
		do $classmethod(className,"%SaveDirect",.id,,.nodes)
		set ids = ids _ $lb(id)
	}
	return ids
}

ClassMethod writeArrayUSND(arrayList, globalName, keyDegree, indexOpt)
{
	set listPtr = 0
	while $listnext(arrayList,listPtr,keySeg) {
		set gref = globalName _ "(" _ $select(keySeg'=+keySeg:$zu(144,1,keySeg),1:keySeg)
		for ptr = 2:1:keyDegree {
			if $listnext(arrayList,listPtr,keySeg) set gref = gref _ "," _ keySeg
		}
		set gref = gref _ ")"
			// at this time, the buffer is configured with a subscript present for the single node case. That can be optimized
			// but, for now, it remains and the subscript will be ignored.
		if $listnext(arrayList,listPtr,subscript) && $listnext(arrayList,listPtr,value) set @gref = value
	}
}

ClassMethod writeArrayUSNI(arrayList, className, keyDegree, indexOpt)
{
	set listPtr = 0
	while $listnext(arrayList, listPtr, keyElement) {
		set idList = $listbuild(keyElement)
		for ptr = 2:1:keyDegree {
			if $listnext(arrayList, listPtr, keyElement) set idList = idList _ $listbuild(keyElement)
		}
		if $listnext(arrayList, listPtr, subscript) 
		if $listnext(arrayList, listPtr, nodes)
		do $classmethod(className, "%SaveDirect",,idList,.nodes)
	}
}

/// writeArrayUMND - user-defined IDKEY indexing doesn't allow (currently) for deferred
/// filing of indexes but we do need this for schemas with no indexes defined. In the future we 
/// may relax this restriction for deferred index filing. For now, indexOpt is expected to be zero (no indexing).
ClassMethod writeArrayUMND(arrayList, globalName, keyDegree, nodeCount, indexOpt)
{
	set listPtr = 0
	while $listnext(arrayList,listPtr,keySeg) {
		set gref = globalName _ "(" _ keySeg _ ","
		for ptr = 2:1:keyDegree {
			if $listnext(arrayList,listPtr,keySeg) {
				set gref = gref _ $select(keySeg'=+keySeg:$zu(144,1,keySeg),1:keySeg) _ ","
			} // else this is a corrupt buffer
		}
		set $extract(gref,*) = ")"
		for ptr = 1:1:nodeCount {
			if ($listnext(arrayList,listPtr,sub)) && ($listnext(arrayList,listPtr,value)) {
				if sub = "" {
					set @gref = value
				} else {
					set @gref@(sub) = value
				}
			}
		}
	}
}

ClassMethod writeArrayUMNI(arrayList, className, keyDegree, nodeCount, indexOpt)
{
	set listPtr = 0
	while $listnext(arrayList,listPtr,value) {
		set idList = $list(value,1,keyDegree)
		for ptr = (keyDegree + 1):2:$listLength(value)-1 {
			set sub = $listget(value,ptr)
			if (sub = "") || (sub = "null") {
				set nodes = $lg(value,ptr + 1)
			} else {
				set nodes(sub) = $lg(value,ptr + 1)
			}
		}
		do $classmethod(className, "%SaveDirect",,idList,.nodes)
	}
}

ClassMethod InsertObjectNoId(className, data)
{
	Set className = $$$NormalizeClassname(className)
	set dataAddress = $$$EXTdataaddress($$$pEXT,className)
	set globalName = $$$EXTADDRbasereference($$$pEXT,className,dataAddress)
	set id=$seq(@globalName)
	Set error=$classmethod(className,"%SaveDirect",.id,$lb(id),data,-1)
	Quit:error=1 id
	Do DecomposeStatus^%apiOBJ(error,.errorText)
	Quit errorText(1)
}

ClassMethod InsertObject(className, id, data)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
		$$$THROWONERROR(error, $classmethod($$$NormalizeClassname(className),"%SaveDirect","",id,data,-1))
		return ""
	} catch exception {
		do DecomposeStatus^%apiOBJ(exception.AsStatus(),.errorText)
		return errorText(1)
	}
}

ClassMethod IsExtentEmpty(className)
{
	Set globalName=$$getClassGlobalName^%SYS.LCBINDSRV(className)
	Quit:$G(globalName)="" "1"
	If '$D(@globalName) && '$G(@globalName) Quit "1"
	Quit "0"
}

ClassMethod CleanUpExtent(className)
{
	return ""
}

ClassMethod DeleteExtent(className)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
		set class = ##class(%Dictionary.CompiledClass).%OpenId(className)
		if ($isobject(class)) && (class.ClassType = $$$cCLASSCLASSTYPEPERSISTENT) && ('class.NoExtent) {
			$$$THROWONERROR(status, $classmethod(className,"%DeleteExtent",,,,1,.errorlog))
		}
		return ""
	} catch exception {
		do DecomposeStatus^%apiOBJ(exception.AsStatus(),.errorText)
		return errorText(1)
	}
}

ClassMethod StartIndexing(className)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
		return "Timed out attempting to start indexing."
	} catch exception {
		do DecomposeStatus^%apiOBJ(exception.AsStatus(),.errorText)
		return errorText(1)
	}
}

ClassMethod StopIndexing(className)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
		return "Timed out attempting to stop indexing."
	} catch exception {
		do DecomposeStatus^%apiOBJ(exception.AsStatus(),.errorText)
		return errorText(1)
	}
}

ClassMethod WaitForIndexing(className)
{
	try {
		$$$XEPCHECKPROTOCOLVERSION
		$$$THROWONERROR(status, $classmethod(className,"%BuildDeferredIndices"))
			return ""
	} catch exception {
		Do DecomposeStatus^%apiOBJ(exception.AsStatus(),.error)
		return error(1)
	}
}

ClassMethod RemoteCalls(function)
{
	$$$WriteHeader
	Try {
		Set count=$$$ReadNext
		For i=1:1:count { Set parameter(i)=$$$ReadNext }
		If function=1 {
			Set x = ..Handshake(parameter(1),parameter(2),parameter(3),parameter(4),parameter(5),parameter(6))
		} ElseIf function=2 {
			Set x = ..GetMetaData(parameter(1))
		} ElseIf function=3 {
			Set x = ..CompareTimestamp(parameter(1),parameter(2))
		} ElseIf function=4 {
			Set x=..LoadClass(parameter(1),$G(parameter(2),""),$G(parameter(3),""),$G(parameter(4),""),$G(parameter(5),""))
		} ElseIf function=5 {
			Set x=..Compile(parameter(1))
		} ElseIf function=6 {
			Set x=..DeleteClass(parameter(1))
		} ElseIf function=7 {
			Set x=..DeleteObject(parameter(1),parameter(2))
		} ElseIf function=8 {
			s idList=""
			for ii=1:1:256 {
				s idKey=$p(parameter(2),"||",ii)
				q:idKey=""
				s idList=idList_$lb(idKey)
			}
			Set x=$classmethod($$$NormalizeClassname(parameter(1)),"%SaveDirect",parameter(2),idList,parameter(3),-1)
			If x'=1 {
				Do DecomposeStatus^%apiOBJ(x,.errorText) 
				Set x=errorText(1)
			} Else {
				Set x=""
			}
		} ElseIf function=9 {
			Set x=..DeleteExtent(parameter(1))    
		} ElseIf function=10 {
			Set x=..IsExtentEmpty(parameter(1))
		} ElseIf function=11 {
			Set x=..CleanUpExtent(parameter(1))    
		} ElseIf function=12 {
			Set x=..StartIndexing(parameter(1))
	    } Elseif function=13 {
			Set x=..StopIndexing(parameter(1))
		} ElseIf function=14 {
			Set x=..WaitForIndexing(parameter(1),parameter(2))
		} ElseIf function=15 {
			Set x=..InsertObjectNoId(parameter(1),parameter(2))
		} ElseIf function=16 {
			Set x=..InsertObject(parameter(1),parameter(2),parameter(3))
		} ElseIf function=17 {
			Set x=..GetGlobalName(parameter(1))
		}
		Kill parameter,function,count
		$$$WriteData(x) 
		$$$Flush0
	} Catch exception {
		Do ProcessException(exception)
	}
}

ClassMethod MethodCalls(type)
{
	$$$WriteHeader
	Set methodOrTag=$$$ReadNext
	Set classOrRoutine=$$$ReadNext
	Set count=$$$ReadNext
	Set pText=""
	Try {
		If count>0 {
			For i=1:1:count-1 { Set %p(i)=$$$ReadNext,pText=pText_"%p("_i_")," }
			Set %p(count)=$$$ReadNext
			If (type<2)||(type=4) {
				Set pText="("_pText_"%p("_count_"))"
			} Else {
				Set pText=","_pText_"%p("_count_"))"
			}
		}
		If type=0 { 		// function, no return
			Set code="Do "_methodOrTag_"^"_classOrRoutine_pText
			Xecute code
			$$$Flush0
		} ElseIf type=1 { 	// function, return 
			Set code="Set %return=$$"_methodOrTag_"^"_classOrRoutine_pText
			Xecute code
			Set %return=$LB(%return)
			If %return'="" {
				Set x=$zobjexport($L(%return),57),x=$zobjexport(%return,59)
			} Else {
				$$$Flush0
			}
		} ElseIf type=2 { 	// class method, no return
			Set:pText="" pText=")"
			Set code="Do $classmethod("""_methodOrTag_""","""_classOrRoutine_""""_pText
			Xecute code
			$$$Flush0
		} ElseIf type=3 { 	// class method, return
			Set:pText="" pText=")"
			Set code="Set %return=$classmethod("""_methodOrTag_""","""_classOrRoutine_""""_pText
			Xecute code
			Set %return=$LB(%return)
			If %return'="" {
				Set x=$zobjexport($L(%return),57),x=$zobjexport(%return,59)
			} Else {
				$$$Flush0
			}
		} ElseIf type=4 {  // function, returns byte[]/$LIST
			Set code="Set %return=$$"_methodOrTag_"^"_classOrRoutine_pText
			Xecute code
			If %return'="" {
				Set x=$zobjexport($L(%return),57),x=$zobjexport(%return,59)
			} Else {
				$$$Flush0
			}
		} ElseIf type=5 {  // class method, returns byte[]/$LIST
			Set:pText="" pText=")"
			Set code="Set %return=$classmethod("""_methodOrTag_""","""_classOrRoutine_""""_pText
			Xecute code
			If %return'="" {
				Set x=$zobjexport($L(%return),57),x=$zobjexport(%return,59)
			} Else {
				$$$Flush0
			}
		}
	} Catch exception {
		Do ProcessException(exception)
	}
	Kill %p,%return,classOrRoutine,methodOrTag,count,code
}

ClassMethod SetStream(type, globalNameLength, length)
{
	Try {
		$$$WriteHeader
		If (type=0) {	// binary
			Set stream=##class(%Stream.GlobalBinary).%New()
		} Else {		// character
			Set stream=##class(%Stream.GlobalCharacter).%New()
		}
		Set stream.%Location=$zobjexport(globalNameLength,13),chunkSize=32656 //$$$MaxLocalLength
		For  {
			Set toRead=$select(length>chunkSize:chunkSize,1:length)
			Set status=stream.Write($zobjexport(toRead,13))
			Set length=length-toRead
			Quit:length=0||($$$ISERR(status))
		}
		Set:status status=stream.%Save()
		If (status'=1) {
			Do DecomposeStatus^%apiOBJ(status,.errorText)
			$$$WriteData(errorText(1))
			$$$Flush(400)
			Quit
		}                             
		$$$WriteData(stream.%Id())
		$$$Flush0
	} Catch exception {
		Do ProcessException(exception)
	}
}

ClassMethod GetStream(type, oidLength)
{
	Try {
		$$$WriteHeader
		Set oid=$zobjexport(oidLength,13),chunkSize=32656
		If (type=0) {	// binary
			Set stream=##class(%Stream.GlobalBinary).%Open(oid)
			Set length=stream.Size,x=$zobjexport(length,57)
			For {
				Quit:length=0
				Set length=$zobjexport(stream.Read(chunkSize,.status),59)
			}
		} Else {		// character
			Set stream=##class(%Stream.GlobalCharacter).%Open(oid)
			Set length=stream.Size,x=$zobjexport(length,57)
			For {
				Quit:length=0
				Set length=$zobjexport(stream.Read(chunkSize,.status),58)
			}
		}
		/*
		For {
			Quit:stream.AtEnd
			Set x=$zobjexport(stream.Read(maxLocalLength,.status),5)
			Quit:$$$ISERR(status)
		}
		*/
		If $$$ISERR(status) {
			Do DecomposeStatus^%apiOBJ(status,.errorText)
			$$$WriteData(errorText(1))
			$$$Flush(400)
			Quit
		}			
		//$$$Flush0
	} Catch exception {
		Do ProcessException(exception)
	}
}

ClassMethod ProcessException(exception) [ Private ]
{
	$$$WriteData(exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
	$$$Flush(400)
}

}
