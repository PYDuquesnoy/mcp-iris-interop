/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Likely this will need to be an AET populated with property values that are AE's that wrap
/// Registered counterparts. 
Class %DataModel.Serializer [ Abstract ]
{

/// Immutable universal wrapper for populating an instance of a
/// registered object via a JSON representation of its data.
/// This method calls %FromJSONValue(), which may be overridden, to 
/// perform the actual business of JSON parsing and object population
ClassMethod fromJson(str) As %RegisteredObject
{
	if '$isobject(str) || '(str.%IsA("%Library.DynamicAbstractObject")) {
		set json = ##class(%Library.DynamicAbstractObject).%FromJSON(str)
	} else {
		set json = str
	}
    #; set ..projectRegisteredFromAbstractObject(json)
}

/// This is an internal class that implements utilities used by the $project methods. These 
/// utility methods are implemented here but represent %ToObject and %FromObject 
/// implementations for various system classes, including collection classes, %ZEN.proxyObject, 
/// and so on. 
/// <br>
/// The top level composition methods accept a target instance and that instance will be populated 
/// by the projectrs. These methods are all named <var>project</var>Something. 
/// <br>
/// The lower level methods map an instance of something to an instance of something else. The 
/// method is specific for each category of from object and to object. For example, to map a Cache 
/// Object to an Array, the method is named <method>mapCacheObjectToArray</method>. The various 
/// map methods accept a target and if target is null then it is populated with the <var>To</var> 
/// object type. 
/// <br>
ClassMethod projectArrayFromCollection(target, source, laxMode As %Integer = 1)
{
	if $Isobject(source) {
		if source.%IsA("%Collection.AbstractList") {
		 	return ..mapListCollectionToArray(source,target,laxMode)
		} elseif source.%IsA("%Collection.AbstractArray") {
	 		return ..mapArrayCollectionToArray(source,target,laxMode)
		} else {
				//throw unhandled object type exception here?				
			throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
		}
	}
	return $$$NULLOREF
}

ClassMethod projectArrayFromRegistered(target, source, laxMode As %Integer = 1)
{
	if $Isobject(source) {
		if source.%IsA("%Library.Persistent") {
		 	return ..mapPersistentToArray(source,target,laxMode,0)
		} elseif source.%IsA("%ZEN.proxyObject") {
			return ..mapZPOToArray(source,target,laxMode)
		} elseif source.%IsA("%Stream.Object") {
			return ..mapStreamToArray(source,target,laxMode)
		} elseif source.%IsA("%Library.RegisteredObject") {
		 	return ..mapRegisteredToArray(source,target,laxMode)
		} elseif source.%IsA("%Collection.AbstractList") {
				// This usually means we got here by mistake...
			return ..mapListCollectionToArray(source,target,laxMode)
		} else {
				//throw unhandled object type exception here?				
			throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
		}
	}
	return $$$NULLOREF
}

/// This is the top level of composition - a top level object requested to be projectd from a source 
/// instance. Construct the AET.</Description>
ClassMethod projectObjectFromCollection(target, source, laxMode As %Integer = 1)
{
	if $Isobject(source) {
		if (source.%IsA("%Collection.AbstractList")) {
		 	return ..mapListCollectionToObject(source,target,laxMode)
		} elseif (source.%Extends("%Collection.AbstractArray")) {
	 		return ..mapArrayCollectionToObject(source,target,laxMode)
		} else {
			 //throw unhandled object type exception here?				
		    throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
		}
	}
	return $$$NULLOREF
}

ClassMethod projectCollectionFromCollection(target, source, laxMode As %Integer = 1)
{
	if $Isobject(source) {
			//throw unhandled object type exception here?				
		throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
	}
	return $$$NULLOREF
}

/// This is the top level of composition - a top level object requested to be projectd from a source 
/// instance. Construct the AET.</Description>
ClassMethod projectObjectFromRegistered(target, source, laxMode As %Integer = 1)
{
	if $Isobject(source) {
		if (source.%IsA("%Library.Persistent")) {
		 	return ..mapPersistentToObject(source,target,laxMode,0)
		} elseif source.%IsA("%ZEN.proxyObject") {
			return ..mapZPOToObject(source,target,laxMode)
		} elseif source.%IsA("%Stream.Object") {
			return ..mapStreamToObject(source,target,laxMode)
		} elseif (source.%IsA("%Library.RegisteredObject")) {
		 	return ..mapRegisteredToObject(source,target,laxMode)
		} elseif source.%IsA("%Collection.AbstractArray") {
			return ..mapArrayCollectionToObject(source,target,laxMode)
		} else {
			 //throw unhandled object type exception here?				
		    throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
		}
	}
	return $$$NULLOREF
}

/// target is an instance of the RegisteredObject class, source is a DAO
ClassMethod projectRegisteredFromAbstractObject(target, source, laxMode As %Integer = 1)
{
	if $Isobject(source) {
		if source.%IsA("%Library.DynamicObject") {
		 	return ..mapObjectToRegistered(source,target,laxMode,0)
		} elseif source.%IsA("%Library.DynamicArray") {
			// return ..mapArrayToRegistered(source,target,laxMode,0)
			throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
		} else {
				//throw unhandled object type exception here?				
			throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
		}
	}
	return $$$NULLOREF
}

ClassMethod projectZPOFromAbstractObject(target, source, laxMode As %Integer = 1)
{
	if $Isobject(source) {
		if source.%IsA("%Library.DynamicObject") {
		 	return ..mapObjectToZPO(source,target,laxMode)
		} elseif source.%IsA("%Library.DynamicArray") {
			throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic array is not currently supported")
		} else {
				//throw unhandled object type exception here?				
			throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
		}
	}
	return $$$NULLOREF
}

ClassMethod projectRegisteredFromRegistered(target, source, laxMode As %Integer = 1)
{
	if $Isobject(source) {
		if source.%IsA("%Library.Persistent") {
		 	return ..mapRegisteredToRegistered(source,target,laxMode,0)
		} elseif (source.%IsA("%Collection.AbstractList")) && (target.%IsA("%Library.RegisteredObject")) {
		 	return ..mapListCollectionToRegistered(source,target,laxMode)
		} elseif source.%IsA("%Collection.AbstractArray") {
	 		return ..mapArrayCollectionToRegistered(source,target,laxMode)
		} elseif source.%IsA("%Stream.Object") {
			return ..mapStreamToRegistered(source,target,laxMode)
		} elseif source.%IsA("%ZEN.proxyObject") {
			set ao = ..mapZPOToObject(source,{},laxMode)
			return ..mapObjectToRegistered(ao,target,laxMode,0)
		} elseif source.%IsA("%Library.RegisteredObject") {
		 	return ..mapRegisteredToRegistered(source,target,laxMode)
		} else {
				//throw unhandled object type exception here?				
			throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
		}
	}
	return $$$NULLOREF
}

ClassMethod projectCollectionFromAbstractObject(target, source, laxMode As %Integer = 1)
{
	if $Isobject(source) {
		if target.%IsA("%Collection.AbstractArray") {
			return ..mapAbstractObjectToArrayCollection(source,target,laxMode)
		} else {
			return ..mapAbstractObjectToListCollection(source,target,laxMode)
		}
	} else {
			//throw unhandled object type exception here?				
		throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
	}
	return $$$NULLOREF
}

ClassMethod projectListFromDao(target, source, laxMode As %Integer = 1)
{
	set returnValue = target
	if '$isObject(source) {
		if target = "" {
			set returnValue = source
		} else {
		set returnValue = returnValue _ $listbuild(source)
		}
	} elseif source.%IsA("%Library.DynamicObject") {
		set it = source.%GetIterator()
		while it.%GetNext(.k,.v) {
			set returnValue = returnValue _ $listbuild($listbuild(k, ..projectListFromDao("", v)))
		}
	} elseif source.%IsA("%Library.DynamicArray") {
		set it = source.%GetIterator()
		while it.%GetNext(.k,.v) {
			set returnValue = returnValue _ $listbuild(..projectListFromDao("", v))
		}	
	} elseif source.%IsA("%Library.RegisteredObject") {
		//set returnValue = ..projectListFromDao(.target, ..projectObjectFromRegistered("",source))
		set returnValue = returnValue _ $listbuild(source)
	}
	return returnValue
}

ClassMethod projectListFromRegistered(target, source, laxMode As %Integer = 1)
{
	set dao = ..projectObjectFromRegistered("", source, laxMode)
	return ..projectListFromDao(target, dao, laxMode)
}

/// This mapper accepts any object (oref) and returns an %AbstractObject. This is just a dispatcher that invokes the most reasonable mapper depending on the 
/// type information gathered from the source object. </Description>
ClassMethod mapGenericObjectToAbstractObject(source As %RawString, target As %Library.DynamicAbstractObject = "", laxMode As %Integer = 1, asReference As %Integer = 1, nested As %Integer = 0) As %Library.DynamicAbstractObject
{
	if (source.%IsA("%Library.Persistent")) && ('nested) {
			// If this is a nested call then we will invoke source.%ToAbstractObject
	 	return ..mapPersistentToObject(source,target,laxMode,asReference)
	} elseif source.%IsA("%Collection.AbstractList") {
	 	return ..mapListCollectionToArray(source,target,laxMode)
	} elseif source.%IsA("%Collection.AbstractArray") {
 		return ..mapArrayCollectionToObject(source,target,laxMode)
	} elseif source.%IsA("%ZEN.proxyObject") {
		return ..mapZPOToObject(source,target,laxMode)
	} elseif source.%IsA("%Stream.Object") {
		return ..mapStreamToObject(source,target,laxMode)
	} elseif source.%IsA("%Library.RegisteredObject") {
		if 'nested {
			return source.%ToAbstractObject(target,'laxMode)
		} else {
				// nested prevents recursion in the case of a default %ToObject
		 	return ..mapRegisteredToObject(source,target,laxMode)
		}
	} else {
			//throw unhandled object type exception here?				
		throw ##class(%Exception.General).%New("Mapping of "_$classname(source)_" objects to dynamic entities is not currently supported")
	}
	return $$$NULLOREF
}

ClassMethod mapRegisteredToObject(source As %Library.RegisteredObject, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicObject
{
	try {
		if '$Isobject(target) {
			set returnValue = {}
		} else {
			set returnValue = target
		}
			// return non-private properties defined in the source instance
		set sourceClass = $classname(source)
		do ..getObjectProperties(source,.properties)
		set sourceProperty = $Order(properties(""),1,propertyDescriptor)
		while sourceProperty '= "" {	// beginning sourceProperties loop
				// SOS was ignoring properties beginning with % - not sure if that is valid
					// Declared Type Class
					// The property descriptor can tell us basic information and that information can guide us on whether or not 
					// to retrieve additional metadata. First, is this a swizzleable property...if so, we need to know details. If not, 
					// we can assume it is a literal and simply copy it over. It could be not swizzleable and multidimensional so check both. 
					// call a utility that will return basic stuff - category (classType), multidimensional, collection, etc. We'll decide soon enough.
			do ..getPropertyMetadata(sourceClass,propertyDescriptor,.swizzleable,.category,.collectionType,.multiDimensional,.relationship,.cardinality,.type,.runtimeType)
			if 'multiDimensional {
				if 'swizzleable {
					do returnValue.%Set(sourceProperty,$property(source,sourceProperty))
				} else {
					if collectionType = "" {
							// This can be multiDimensional still but the other choices are stream, persistent, serial, registered and so on. Let's carefully get 
							// the value and see if we can do this without swizzling.
						if category = $$$cCLASSCLASSTYPEPERSISTENT {
							do ..getValue(source,propertyDescriptor,.value)
							if value '= "" {
								if $Isobject(value) {
									//do returnValue.%Set(sourceProperty,..mapPersistentToObject(value))
									do returnValue.%Set(sourceProperty, value)
								} else {
									do returnValue.%Set(sourceProperty,..mapOIDToObject(runtimeType,sourceProperty,runtimeType,value))
								}
							}
						} elseif category = $$$cCLASSCLASSTYPESERIAL {
							set value = $property(source,sourceProperty)
							if 'value.%IsNull() {
								//do returnValue.%Set(sourceProperty,..mapSerialToObject(value))
								do returnValue.%Set(sourceProperty,value)
							}
						} elseif category = $$$cCLASSCLASSTYPESTREAM {
							set value = $property(source,sourceProperty)
							//do returnValue.%Set(sourceProperty,..mapStreamToObject(value))
							do returnValue.%Set(sourceProperty,value)
						} elseif (runtimeType = "%Library.DynamicArray") || ( runtimeType = "%Library.DynamicObject") {
							set value = $property(source,sourceProperty)
							if $isObject(value) {
								do returnValue.%Set(sourceProperty,value.%FromJSON(value.%ToJSON()))
							} else {
									// do we generate a default? This simply means the type is out of the CLASSTYPE realm and it didn't automatically 
									// instantiate.
								do returnValue.%Set(sourceProperty,"","null")
							}
						} else {
							set value = $property(source,sourceProperty)
							if $isObject(value) {
								//do returnValue.%Set(sourceProperty,..mapRegisteredToObject(value))
								do returnValue.%Set(sourceProperty,value)
							} else {
									// do we generate a default? This simply means the type is out of the CLASSTYPE realm and it didn't automatically 
									// instantiate.
								do returnValue.%Set(sourceProperty,"","null")
							}
							// do returnValue.%Set(sourceProperty,..mapRegisteredToObject(value))
						}
					} elseif collectionType = $$$cPROPCOLLECTIONLIST {
						//do returnValue.%Set(sourceProperty,..mapListCollectionToArray($property(source,sourceProperty)))
						do returnValue.%Set(sourceProperty,$property(source,sourceProperty))
					} elseif collectionType = $$$cPROPCOLLECTIONARRAY {
						if 'relationship {
							//do returnValue.%Set(sourceProperty,..mapArrayCollectionToObject($property(source,sourceProperty)))
							do returnValue.%Set(sourceProperty,$property(source,sourceProperty))
						} else {
								// this is an N-cardinality relationship and the source oref is most likely a %Library.RelationshipObject
							//do returnValue.%Set(sourceProperty,..mapRelationshipToArray($property(source,sourceProperty)))
							do returnValue.%Set(sourceProperty,$property(source,sourceProperty))
						}
					}
				}
			} else {
					// multidimensonal property - we will process only the base instance variable value, no subscripts, if it is defined. 
				do ..getValue(source,propertyDescriptor,.value)
				if $Data(value)#2 {
					if '$Isobject(value) {
						do returnValue.%Set(sourceProperty,value)
					} else {
						do returnValue.%Set(sourceProperty,..mapGenericObjectToAbstractObject(value,,laxMode,1,1))
					}
				} else {
						// should we, in the interest of full disclosure, include this property as null?
					do returnValue.%Set(sourceProperty,"","null")
				}
			}
			set sourceProperty = $Order(properties(sourceProperty),1,propertyDescriptor)
		}	// end properties loop
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapPersistentToObject(source As %Library.SerialObject, target As %Library.DynamicObject = "", laxMode As %Integer = 1, asReference As %Integer = 1, nested As %Integer = 0) As %Library.DynamicObject
{
	if asReference || nested {
		return ..mapReferenceToValue(source,.target,laxMode)
	} else {
		if $isObject(target) {
			set returnValue = target
			do returnValue.%Set("$CLASSNAME",$classname(source))
			do returnValue.%Set("$REFERENCE",source.%Id())
		} else {
			set returnValue = {"$CLASSNAME":($classname(source)),"$REFERENCE":(source.%Id())}
		}
		return ..mapRegisteredToObject(source,returnValue,laxMode)
	}
}

ClassMethod mapOIDToObject(className As %RawString = "", propertyName As %RawString = "", typeClass As %RawString = "", oid As %RawString = "", target As %Library.DynamicObject = "") As %Library.DynamicObject
{
	try {
		if (className '= "") && (propertyName '= "") {
			set classinoid = +$$$comMemberArrayGet(className,$$$cCLASSproperty,propertyName,$$$cPROPparameter,"CLASSNAME")
			if 'classinoid {
				set id = oid
				do $classmethod(typeClass,"%OnDetermineClass",$$$oidForm(oid),.mstc)
			} else {
				set id = $$$oidPrimary(oid)
				set mstc = $$$oidClassName(oid)
				if mstc = "" {
					do $classmethod(className,"%OnDetermineClass",oid,.mstc)
				}
			}
		} else {
			try {
				set mstc = $$$oidClassName(oid)
				set id = $$$oidPrimary(oid)
			} catch {
					// default to the declared type class
				set mstc = typeClass
				set id = oid
			}
		}
		if mstc = "" {
			set mstc = typeClass
		}
		if '$Isobject(target) {
			set returnValue = {"$CLASSNAME":(mstc),"$REFERENCE":(id)}
		} else {
			set returnValue = target
			do returnValue.%Set("$CLASSNAME",mstc)
			do returnValue.%Set("$REFERENCE",id)
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapSerialToObject(source As %Library.SerialObject, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicObject
{
	return ..mapRegisteredToObject(source,target)
	/*
	try {
		if '$Isobject(target) {
			set returnValue = {}
		} else {
			set returnValue = target
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
	*/
}

/// This is a generic collection dispatcher - Cache Objects collection type is either list or array</Description>
ClassMethod mapCollectionToObject(source As %Collection.AbstractIterator, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicObject
{
	try {
			// This is just a dispatcher
		if source.%IsA("%Collection.AbstractList") {
			return ..mapListCollectionToObject(source,.target)
		} elseif source.%IsA("%Collection.AbstractArray") {
			return ..mapArrayCollectionToObject(source,.target)
		} else {
				// huh? - we need to formalize General exceptions
			throw ##class(%Exception.General).%New("Invalid instance type in context of a collection instance")
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapListCollectionToObject(source As %Collection.AbstractList, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicObject
{
		// CURRENTLY DAO CAN'T HANDLE THIS CASE
    throw ##class(%Exception.General).%New("Mapping Cache Objects list collections to %Array is not currently supported")
}

ClassMethod mapArrayCollectionToObject(source As %Collection.AbstractArray, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicObject
{
	try {
		if '$Isobject(target) {
			set returnValue = {}
		} else {
			set returnValue = target
		}
		If source.%IsA("%Collection.AbstractArrayOfObj") { // object elements
			set key = ""
			set element = source.GetNext(.key)
			while key '= "" {
				if $IsObject(element) {
					//do returnValue.%Set(key,..mapGenericObjectToAbstractObject(element,,laxMode,1,1))
					do returnValue.%Set(key, element)
				} else {
					do returnValue.%Set(key,element)
				}
				set element = source.GetNext(.key)
			}
		} else {
				// scalar array elements
			try {
				set elementType = source.ElementType
				if elementType [ ":" {
					set elementType = $$$comMemberKeyGet($Piece(elementType,":",1),$$$cCLASSproperty,$Piece(elementType,":",2, output ),$$$cPROPtype)
				}
			} catch {
				set elementType = source.#ELEMENTTYPE
			}
			set jsonType = ..getJSONType(elementType)
			set key = ""
			set element = source.GetNext(.key)
			while key '= "" {
				do returnValue.%Set(key,element,jsonType)
				set element = source.GetNext(.key)
			}
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapStreamToObject(source As %Library.SerialObject, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicObject
{
	try {
		if '$Isobject(target) {
			set returnValue = {}
		} else {
			set returnValue = target
		}
		do returnValue.%Set("$CLASSNAME",$classname(source))
		if source.Size > 0 {
			$$$comClassKeyGetLvar(clientDataType,$classname(source),$$$cCLASSclientdatatype)
			if clientDataType = $$$cCLASSCLIENTDATATYPECHARACTERSTREAM {
				do source.Rewind()
				set line = source.ReadLine(.len)
				if len '< 0 {
					set totalLen = len
					set content = []
					while (len '< 0) && (totalLen '> 32000) {
						do content.%Push(line)
						kill len
						set line = source.ReadLine(.len)
						set totalLen = totalLen + len
					}
					do returnValue.%Set("content",content)
				}
				do source.Rewind()
			} else {
				do returnValue.%Set("$ERROR","Mapping streams to %AbstractObject not currently supported")
			}
		} else {
			do returnValue.%Set("content","")
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapZPOToObject(source As %ZEN.proxyObject, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicObject [ Internal ]
{
	try {
		if '$Isobject(target) {
			set returnValue = {}
		} else {
			set returnValue = target
		}
			// %ZEN.proxyObject (ZPO) is a legacy implementation of %Library.DynamicObject, all dynamic content. 
			// ZPO's don't natively handle arrays, rather, they rely on %Library.ListOfDataTypes. There is an 
			// implied restriction that a ZPO cannot be an array, it must start with an Object as the root node of 
			// the AET. We start here with the dynamic content, realizing that this might be a recursive call.
		set property = $order(source.%data(""),1,value)
	 	while property '= "" {
	 		if ($isobject(value)) {
		 		do returnValue.%Set(property,..mapGenericObjectToAbstractObject(value,,laxMode))
			} else {
	  			set aetValue = value
				if ($isvalidnum(aetValue)) {
					do returnValue.%Set(property,$fnumber(aetValue,"LON"),"number")
				} else {
					do returnValue.%Set(property,aetValue)
				}
			}
			set property = $order(source.%data(property),1,value)
	 	}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

/// This is a generic collection dispatcher - Cache Objects collection type is either list or array
ClassMethod mapCollectionToArray(source As %Collection.AbstractIterator, target As %Library.DynamicArray = "", laxMode As %Integer = 1) As %Library.DynamicArray
{
	try {
			// This is just a dispatcher
		if source.%IsA("%Collection.AbstractList") {
			return ..mapListCollectionToArray(source,.target)
		} elseif source.%IsA("%Collection.AbstractArray") {
			return ..mapArrayCollectionToArray(source,.target)
		} else {
				// huh? - we need to formalize General exceptions
			throw ##class(%Exception.General).%New("Invalid instance type in context of a collection instance")
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapListCollectionToArray(source As %Collection.AbstractList, target As %Library.DynamicArray = "", laxMode As %Integer = 1) As %Library.DynamicArray
{
	try {
		if '$Isobject(target) {
			set returnValue = []
		} else {
			set returnValue = target
		}
		If source.%IsA("%Collection.AbstractListOfObj") { // object elements
			set key = ""
			set element = source.GetNext(.key)
			while key '= "" {
				if $IsObject(element) {
					do returnValue.%Push(..mapGenericObjectToAbstractObject(element,,laxMode,1,1))
				} else {
					do returnValue.%Push(element)
				}
				set element = source.GetNext(.key)
			}
		} else {
				// scalar array elements
			try {
				set elementType = source.ElementType
				if elementType [ ":" {
					set elementType = $$$comMemberKeyGet($Piece(elementType,":",1),$$$cCLASSproperty,$Piece(elementType,":",2, output ),$$$cPROPtype)
				}
			} catch {
				set elementType = source.#ELEMENTTYPE
			}
			set jsonType = ..getJSONType(elementType)
			set key = ""
			set element = source.GetNext(.key)
			while key '= "" {
				if '$isObject(element) {
					do returnValue.%Push(element,jsonType)
				} else {
						// Sometimes the list collection type class lies. %ZEN.proxyObject doesn't really 
						// care so most likely this is a %ZEN.proxyObject instance. We could check. Or just do it.
						// The primary difference between %ListOfDataTypes and %ListOfObjects is swizzling. We don't 
						// support swizzling with %ListOfDataTypes but if the swizzling is already done then who are 
						// we to judge?
					do returnValue.%Push(..mapGenericObjectToAbstractObject(element,,laxMode,1,1))
				}
				set element = source.GetNext(.key)
			}
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapListCollectionToRegistered(source As %Collection.AbstractList, target As %Library.DynamicArray = "", laxMode As %Integer = 1) As %Library.RegisteredObject
{
}

ClassMethod mapArrayCollectionToArray(source As %Collection.AbstractArray, target As %Library.DynamicArray = "", laxMode As %Integer = 1) As %Library.DynamicArray
{
		// not supported
    throw ##class(%Exception.General).%New("Mapping Cache Objects Array Collection to %Array is not currently supported")
}

ClassMethod mapArrayCollectionToRegistered(source As %Collection.AbstractList, target As %Library.DynamicArray = "", laxMode As %Integer = 1) As %Library.RegisteredObject
{
}

ClassMethod mapPersistentToArray(source As %Library.RegisteredObject, target As %Library.RegisteredObject = "", laxMode As %Integer = 1, asReference As %Integer = 1) As %Library.RegisteredObject
{
}

ClassMethod mapRegisteredToArray(source As %Library.RegisteredObject, target As %Library.RegisteredObject = "", laxMode As %Integer = 1, asReference As %Integer = 1) As %Library.RegisteredObject
{
}

/// An N-Cardinality relationship has an interface consistent with a Cache Array Collection but there are differences. This mapper function
ClassMethod mapRelationshipToArray(source As %Collection.AbstractList, target As %Library.DynamicArray = "", laxMode As %Integer = 1) As %Library.DynamicArray
{
	try {
		if '$Isobject(target) {
			set returnValue = []
		} else {
			set returnValue = target
		}
		set persistent = source.#INVERSEPERSISTENT
		set key = ""
		set element = source.GetNext(.key)
		while key '= "" {
			if $IsObject(element) {
				if persistent {
					do returnValue.%Push(..mapPersistentToObject(element))
				} else {
					do returnValue.%Push(..mapGenericObjectToAbstractObject(element,,laxMode,1,1))
				}
			} else {
				do returnValue.%Push(element)
			}
			set element = source.GetNext(.key)
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapStreamToArray(source As %Library.SerialObject, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicArray
{
}

ClassMethod mapZPOToArray(source As %ZEN.proxyObject, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicArray [ Internal ]
{
}

ClassMethod mapObjectToRegistered(source As %Library.DynamicObject, target As %Library.RegisteredObject = "", laxMode As %Integer = 1, asReference As %Integer = 1) As %Library.RegisteredObject
{
	try {
		if '$Isobject(target) {
				// Registered targets must be supplied, otherwise it is just a copy because we must have the target schema.
			return source.%ConstructClone()
		} else {
			set returnValue = target
		}
			// return non-private properties defined in the source instance
		set targetClass = $classname(returnValue)
		do ..getObjectProperties(returnValue,.targetProperties)
		set sourceIterator = source.%GetIterator()
			// This is a copy from operation, loop over the target properties to see if the source property is defined and the type is compatible
		while sourceIterator.getNext(.sourceProperty,.sourceValue) {
					// Declared Type Class
					// The property descriptor can tell us basic information and that information can guide us on whether or not 
					// to retrieve additional metadata. First, is this a swizzleable property...if so, we need to know details. If not, 
					// we can assume it is a literal and simply copy it over. It could be not swizzleable and multidimensional so check both. 
					// call a utility that will return basic stuff - category (classType), multidimensional, collection, etc. We'll decide soon enough.
				// If there is a compatible sourceProperty defined, copy the value to the returnVal
			if ($Data(targetProperties(sourceProperty),targetDescriptor)) && ('$Piece(targetDescriptor,"^",4)) {
				do ..getPropertyMetadata(targetClass,targetDescriptor,.targetSwizzleable,.targetCategory,.targetCollectionType,.targetMultiDimensional,.targetRelationship,.targetCardinality,.targetType,.targetRuntimeType)
				if '$Isobject(sourceValue) {
						// literal value from AET
					if targetCollectionType = "" {
						do ..setValue(returnValue,targetDescriptor,.sourceValue)
					} elseif targetCollectionType = $$$cPROPCOLLECTIONLIST {
						do $method($property(returnValue,sourceProperty),"Insert",sourceValue)
					} elseif (targetCollectionType = $$$cPROPCOLLECTIONARRAY) && ('targetRelationship) {
					} else {
					}
				} elseif sourceValue.%IsA("%Library.DynamicObject") {
					if targetCollectionType = "" {
						if targetSwizzleable {
								// mapObjectToRegistered, just grab the type class and construct it. Perhaps should go through %FromObject
							do ..setValue(returnValue,targetDescriptor,$classmethod(targetRuntimeType,"%FromObject",sourceValue))
						} else {
								// default stringify source value ?
						}
					} elseif targetCollectionType = $$$cPROPCOLLECTIONARRAY {
						set collection = $property(returnValue,sourceProperty)
						do ..mapAbstractObjectToArrayCollection(sourceValue, collection, .laxMode)
					} elseif targetCollectionType = $$$cPROPCOLLECTIONLIST {
						set collection = $property(returnValue,sourceProperty)
						do ..mapAbstractObjectToListCollection(sourceValue, collection, .laxMode)
					} else {
							// unknown collection type
					}
				} elseif sourceValue.%IsA("%Library.DynamicArray") {
						// literal value from AET
					if targetCollectionType = "" {
						do ..setValue(returnValue,targetDescriptor,.sourceValue)
					} elseif targetCollectionType = $$$cPROPCOLLECTIONLIST {
						set collection = $property(returnValue,sourceProperty)
						do ..mapAbstractObjectToListCollection(sourceValue, collection, .laxMode)
					} elseif (targetCollectionType = $$$cPROPCOLLECTIONARRAY) && ('targetRelationship) {
					} else {
							// unknown collection type
					}
				} elseif sourceValue.%IsA("%Library.RegisteredObject") {
				} else {
						// huh?
				}
			} elseif 'laxMode {
					// unmappable data in the source object
					// this will trigger an exception.
				set dummy = $property(returnValue,sourceProperty)
			}
		}
	}
	catch exception {
			set returnValue = ""
			throw exception
		}
	return returnValue
}

ClassMethod mapObjectToZPO(source As %Library.DynamicObject, target As %ZEN.proxyObject = "", laxMode As %Integer = 1) As %ZEN.proxyObject [ Internal ]
{
	try {
		if '$Isobject(target) {
				// Registered targets must be supplied, otherwise it is just a copy because we must have the target schema.
			set returnValue = ##class(%ZEN.proxyObject).%New()
		} else {
			set returnValue = target
		}
		set sourceIterator = source.%GetIterator()
			// This is a copy from operation, loop over the target properties to see if the source property is defined and the type is compatible
		while sourceIterator.%GetNext(.sourceProperty,.sourceValue) {
			if '$isObject(sourceValue) {
				set $property(returnValue,sourceProperty) = sourceValue
			} elseif sourceValue.%IsA("%Library.DynamicArray") {
				set $property(returnValue,sourceProperty) = ..mapArrayToZPO(sourceValue,, .laxMode)
			} elseif sourceValue.%IsA("%Library.DynamicObject") {
				set $property(returnValue,sourceProperty) = ..mapObjectToZPO(sourceValue,, .laxMode)
			} else {
					// Some other kind of object
			}
		}
	}
	catch exception {
			set returnValue = $$$NULLOREF
			throw exception
		}
	return returnValue
}

ClassMethod mapArrayToZPO(source As %Library.DynamicArray, target As %Library.ListOfDataTypes = "", laxMode As %Integer = 1) As %Library.ListOfDataTypes [ Internal ]
{
	try {
		if '$Isobject(target) {
				// Registered targets must be supplied, otherwise it is just a copy because we must have the target schema.
			set returnValue = ##class(%Library.ListOfDataTypes).%New()
		} else {
			set returnValue = target
		}
		set sourceIterator = source.%GetIterator()
			// This is a copy from operation, loop over the target properties to see if the source property is defined and the type is compatible
		while sourceIterator.%GetNext(.sourceKey,.sourceValue) {
			if '$isObject(sourceValue) {
				do returnValue.Insert(sourceValue)
			} elseif sourceValue.%IsA("%Library.DynamicArray") {
				do returnValue.Insert(..mapArrayToZPO(sourceValue,, .laxMode))
			} elseif sourceValue.%IsA("%Library.DynamicObject") {
				do returnValue.Insert(..mapObjectToZPO(sourceValue,, .laxMode))
			} else {
					// Some other kind of object
				do returnValue.Insert(sourceValue)
			}
		}
	} catch exception {
		set returnValue = $$$NULLOREF
		throw exception
	}
	return returnValue
}

ClassMethod mapAbstractObjectToArrayCollection(source As %Library.DynamicArray, target As %Collection.AbstractArray = "", laxMode As %Integer = 1, asReference As %Integer = 1) As %Collection.AbstractArray
{
	try {
		if '$Isobject(target) {
				// Registered targets must be supplied, otherwise it is just a copy because we must have the target schema.
			return source.%ConstructClone()
		} else {
			set returnValue = target
		}
		if target.%IsA("%Collection.AbstractArrayOfObj") {
			set targetElementType = target.ElementType
		} else {
			set targetElementType = ""
		}
		set sourceIterator = source.%GetIterator()
			// This is a copy from operation, loop over the target properties to see if the source property is defined and the type is compatible
		while sourceIterator.%GetNext(.sourceKey,.sourceValue) {
				// If there is a compatible sourceProperty defined, copy the value to the returnVal
			if '$Isobject(sourceValue) {
					// literal value from AET
				do returnValue.SetAt(sourceValue,sourceKey)
			} else {
				if targetElementType '= "" {
					do returnValue.SetAt(sourceValue.project(targetElementType),sourceKey)
				} elseif 'laxMode {
						// unmappable data in the source object
						// this will trigger an exception.
					set dummy = $property(returnValue,sourceProperty)
				}
			}
		}
	}
	catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapAbstractObjectToListCollection(source As %Library.DynamicArray, target As %Collection.AbstractArray = "", laxMode As %Integer = 1, asReference As %Integer = 1) As %Collection.AbstractArray
{
	try {
		if '$Isobject(target) {
				// Registered targets must be supplied, otherwise it is just a copy because we must have the target schema.
			return source.%ConstructClone()
		} else {
			set returnValue = target
		}
		if target.%IsA("%Collection.AbstractListOfObj") {
			set targetElementType = target.ElementType
		} else {
			set targetElementType = ""
		}
		set sourceIterator = source.%GetIterator()
			// This is a copy from operation, loop over the target properties to see if the source property is defined and the type is compatible
		while sourceIterator.%GetNext(.sourceKey,.sourceValue) {
				// If there is a compatible sourceProperty defined, copy the value to the returnVal
			if '$Isobject(sourceValue) {
					// literal value from AET
				do returnValue.Insert(sourceValue)
			} else {
				if targetElementType '= "" {
					do returnValue.Insert(sourceValue.project(targetElementType))
				} elseif 'laxMode {
						// unmappable data in the source object
						// this will trigger an exception.
					set dummy = $property(returnValue,sourceProperty)
				}
			}
		}
	}
	catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod mapRegisteredToRegistered(source As %Library.RegisteredObject, target As %Library.RegisteredObject = "", laxMode As %Integer = 1, asReference As %Integer = 1) As %Library.RegisteredObject
{
	try {
		if '$Isobject(target) {
				// Registered targets must be supplied, otherwise it is just a copy because we must have the target schema.
			return source.%ConstructClone()
		} else {
			set returnValue = target
		}
		set ao = source.%ToAbstractObject(,laxMode)
		set returnValue = ao.project({"returnValue":(returnValue),"mode":($Select(laxMode:"lax",1:"strict"))})
	}
	catch exception {
			set returnValue = ""
			throw exception
	}
	return returnValue
}

ClassMethod mapStreamToRegistered(source As %Library.SerialObject, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.RegisteredObject
{
}

/// Return an object containing the class name and ID of a Persistent instance</Description>
ClassMethod mapReferenceToValue(source As %Library.Persistent, target As %Library.DynamicObject = "", laxMode As %Integer = 1) As %Library.DynamicObject
{
	try {
		if '$Isobject(target) {
			set returnValue = {"$CLASSNAME":($classname(source)),"$REFERENCE":(source.%Id())}
		} else {
			set returnValue = target
			do returnValue.%Set("$CLASSNAME",$classname(source))
			do returnValue.%Set("$REFERENCE",source.%Id())
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

ClassMethod getObjectProperties(oref As %Library.ObjectHandle = "", ByRef properties As %RawString) As %Integer [ Internal ]
{
		// DumpObjectToArray^%occRun(oref,retvar,refdec=2) - this call is the inspiration for the following:
	try {
		if ($Isobject(oref)) {
			set cd = $system.CLS.DumpContext(oref)
			set numsub = $piece(cd,"^",10),valid=$piece(cd,"^",11) if valid="" set valid=1
			for supcls=0:1:numsub-1 {
				set propertyCount = $piece($system.CLS.DumpContext(oref,supcls),"^",7)
				set ivarCount = $piece($system.CLS.DumpContext(oref,supcls),"^",8)
				set properties = ivarCount
				for ptr = 1:1:propertyCount {
					try {
						set pd = $system.CLS.Property(ptr,oref,supcls)
					} catch {
							// Aliases have no slots so it will throw a FUNCTION error for these so just ignore
							// these slots, we could use 'inst' to only iterate through items with slots assigned
							// but this would miss calculated properties which we want to detect
						continue
					}
					set ivar = $piece(pd,"^")
						// Skip some of these...
					if ivar = "%Concurrency" continue
					if $data(properties(ivar)) continue
					set mode = +$Piece(pd,"^",3)
						// We won't include private properties - for now.
					if '($zboolean(mode,8,1)=8) {
						set properties(ivar) = pd _  (ptr>ivarCount)
					}
				}
			}
		} else {
			// NaO
		}
	} catch exception {
		throw exception
	}
	return 1
}

ClassMethod getPropertyMetadata(class As %String(MAXLEN=""), propertyDescriptor As %String(MAXLEN=""), Output swizzleable As %Integer = 0, Output category As %String(MAXLEN="") = "", Output collectionType As %String(MAXLEN="") = "", Output multiDimensional As %Integer = 0, ByRef relationship As %Integer = 0, ByRef cardinality As %String(MAXLEN=6) = "", ByRef type As %String(MAXLEN="") = "", Output runtimeType As %String(MAXLEN="") = "", Output extGet As %Integer = 0, Output extSet As %Integer = 0) [ Internal ]
{
	try {
			// The descriptor is defined as (From GK694):
			//		1- <The property name>^
			//		2- <instance id could be passed to $zobjval to get the property value>^
			//		3- <property type, see the following bits or the sample routine for its use>
			//			MULTI_RTSET  0x01	- a multi dim property only invoke
			//								extrinsic on root set
			//			MULTI_LEAFST 0x02	- a multi dim property only invoke
			//								extrinsic on leaf set
			//			INST	     0x04	- an instance property (single dimensional)
			//			PRIVATE      0x08	- a private property
			//			SWIZZLE      0x10	- The swizzle property
			//			GETMTHD      0x20	- has extrinsic get method
			//			SETMTHD      0x40	- has extrinsic set method
			//			READONLY     0x80	- The property is read only

		set property = $Piece(propertyDescriptor,"^")
		set mode = +$piece(propertyDescriptor,"^",3)
		set multiDimensional = ($zb(mode,3,1)'=0)
		set swizzleable = ($zboolean(mode,16,1)=16)
		set extGet = ($zboolean(mode,32,1)=32)
		set extSet = ($zboolean(mode,64,1)=64)
		if swizzleable {
			$$$comMemberKeyGetLvar(relationship,class,$$$cCLASSproperty,property,$$$cPROPrelationship)
			if relationship {
				$$$comMemberKeyGetLvar(cardinality,class,$$$cCLASSproperty,property,$$$cPROPcardinality)
			}
			$$$comMemberKeyGetLvar(collectionType,class,$$$cCLASSproperty,property,$$$cPROPcollection)
			$$$comMemberKeyGetLvar(type,class,$$$cCLASSproperty,property,$$$cPROPtype)
			$$$comMemberKeyGetLvar(runtimeType,class,$$$cCLASSproperty,property,$$$cPROPruntimetype)
			set category = $$$getClassType(type)
		} else {
				// avoid global access:
			set category = $$$cCLASSCLASSTYPEDATATYPE
			set relationship = 0
			set cardinality = ""
			set collectionType = ""
			set type = ""
			set runtimeType = ""
		}
	} catch exception {
		throw exception
	}
	return 1
}

/// Returns the value of the property from the property descriptor
/// because the current value may be multidimensional and we need to pass back an array with structure</Description>
ClassMethod getValue(oref, pd, Output value) As %Integer
{
	try {
		kill value
		set mode = +$piece(pd,"^",3)
			// for now, private properties aren't in the ..properties array
		set refprop = ($zboolean(mode,16,1)=16)
		set extGet = ($zboolean(mode,32,1)=32)
		if 'extGet {
			set slot = $piece(pd,"^",2)
			if $zboolean(mode,3,1)'=0||($data($zobjval(oref,slot,0,3,slot))\10) {
				merge value = $zobjval(oref,slot,0,3,slot)
			} elseif $data($zobjval(oref,slot,0,3,slot)) {
				set value = $zobjval(oref,slot,0,3,slot)
			}
			if refprop {
				set slot = slot + 1
				if $zboolean(mode,3,1)'=0||($data($zobjval(oref,slot,0,3,slot))\10) {
					merge refvalue = $zobjval(oref,slot,0,3,slot)
					if ($Get(refvalue) '= "") || ($Data(refvalue)>2) {
						merge value = refvalue
					}
				} elseif $data($zobjval(oref,slot,0,3,slot)) {
					set refvalue = $zobjval(oref,slot,0,3,slot)
					if refvalue '= "" {
						set value = refvalue
					}
				}
			}
		} else {
			set property = $Piece(pd,"^")
			set value = $Property(oref,property)
		}
	} catch exception {
		kill value
		return 0
	}
	return 1
}

ClassMethod setValue(oref, pd, ByRef value) As %Integer
{
	try {
		set mode = +$piece(pd,"^",3)
			// for now, private properties aren't in the ..properties array
		set refprop = ($zboolean(mode,16,1)=16)
		set extSet = ($zboolean(mode,64,1)=64)
		if 'extSet {
			set slot = $piece(pd,"^",2)
			if ('$Isobject(value)) || ('refprop) {
				if $zboolean(mode,3,1)'=0||($data(value)\10) {
					merge $zobjval(oref,slot,0,3,slot) = value
				} elseif $data($zobjval(oref,slot,0,3,slot)) {
					if '$Isobject(value) {
						set $zobjval(oref,slot,0,3,slot) = value
					} elseif refprop {
						set slot = slot + 1
						set $zobjval(oref,slot,0,3,slot) = value
					}
				}
			} elseif refprop {
				set $zobjval(oref,slot,0,3,slot) = ""
				set slot = slot + 1
				if $zboolean(mode,3,1)'=0||($data(value)\10) {
					merge $zobjval(oref,slot,0,3,slot) = value
				} else {
					set $zobjval(oref,slot,0,3,slot) = value
				}
			} else {
			}
		} else {
			set property = $Piece(pd,"^")
			if ('refprop) || ($Isobject($get(value))) {
				do $method(oref,$$$QN(property_"Set"),.value)
			} else {
				do $method(oref,$$$QN(property_"SetObjectId"),.value)
			}
		}
	} catch exception {
		return 0
	}
	return 1
}

ClassMethod getJSONType(class) As %String
{
	set jsonType = "string"
	try {
		set normalizedClass = $$NormalizeClassname^%occName(class)
		if (normalizedClass '= "") && ($$$comClassDefined(normalizedClass)) {
			set clientType = $$$comClassKeyGet(normalizedClass,$$$cCLASSclientdatatypeenum)
			if clientType '= "" {
				set jsonType = $case(clientType,
												2	: "string", // "datetime", - dates are just strings for now,
																// we may encode them differently in the future.
																// datatime DAO type is an epoch date. See %Library.DynamicAbstractObject.getTypeOf()
												3	: "number",
												4	: "oref",
												5	: "number",
												8	: "string",
												9	: "string",
												14	: "number",
												15	: "number",
												16	: "boolean",
												18	: "number",
												19	: "string",
												20	: "string",
												21	: "number",
												22	: "string",
													: "string"
											)
			}
		}
	} catch exception {
		set jsonType = "string"
	}
	return jsonType
}

ClassMethod fromObject(source As %RegisteredObject = "", returnValue = "", laxMode As %Integer = 1) [ Internal ]
{
	try {
		if $Isobject(source) {
			return ..%FromObject(source,returnValue,laxMode)
		} else {
		}
	} catch exception {
		throw exception
	}
	return $$$NULLOREF
}

/// Default mechanism for populating an instance of this object from 
/// a JSON representation of its data.</Description>
ClassMethod %FromJSONValue(str) As %RegisteredObject [ ServerOnly = 1 ]
{
	Set tAET = ##Class(%Library.DynamicAbstractObject).%FromJSON(str)
	return ..%FromObject(tAET)
}

/// Default mechanism for populating an instance of this object from
/// an instance of some other object. This method is responsible for identifying the type of the 
/// source object and processing the mapping from that source to the target object. If the 
/// <var>target</var> instance is not populated then this method is responsible for instantiating 
/// the current class and returning that instance to the caller. ]]></Description>
ClassMethod %FromObject(source = "", target = "", laxMode As %Integer = 1) As %RegisteredObject [ ServerOnly = 1 ]
{
	try {
		if source.%IsA("%Library.AbstractObject") {
				// source is an AET
			set returnValue = ..projectRegisteredFromAbstractObject($Select($isObject(target):target,1:..%New()),source,laxMode)
		} elseif source.%IsA("%Library.RegisteredObject") {
			set returnValue = ..projectRegisteredFromRegistered($Select($isObject(target):target,1:..%New()),source,laxMode)
		} else {
				// huh?
			set returnValue = $$$NULLOREF
		}
	}
	catch exception {
		set returnValue = $$$NULLOREF
		if ('laxMode) && (exception.Name = "<PROPERTY DOES NOT EXIST>") {
			throw ##class(%Exception.General).%New("Compose","Compose","%FromObject","Strict mode and source contains unmapped property, "_$classname(source)_" instance to "_$classname($this),exception)
		} else {
				// exception might have something interesting but we'll just throw a generic exception here.
			throw ##class(%Exception.General).%New("Compose","Compose","%FromObject","Unable to map from "_$classname(source)_" instance to "_$classname($this),exception)
		}
	}
	return returnValue
}

}
