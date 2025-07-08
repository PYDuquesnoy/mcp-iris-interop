/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p>This is the default implementation for the <class>%iKnow.Queries.MetadataI</class> interface
/// and the central place to manage and query metadata fields and values.</p>
Class %iKnow.Queries.MetadataAPI Extends (%iKnow.Queries.MetadataI, %iKnow.Queries.AbstractAPI) [ Deprecated, System = 4 ]
{

Parameter GetFieldsRT = "mdFieldId:%String,fieldName:%String,supportedOperators:%List,dataType:%String,storage:%Integer,caseSensitive:%Boolean,lovId:%Integer,validateLov:%Boolean,hidden:%Boolean";

/// <p>Returns all field definitions (including their properties) for the given domain.</p>
/// <p>Setting <var>includeHidden</var> to true will also return any metadata fields marked as 'hidden'.</p>
ClassMethod GetFields(ByRef result As %Integer, domainId As %Integer, includeHidden As %Boolean = 0) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
    $$$CHECKDOMAINEXISTSX(domainId,tSC)
    
    set counter = 0
    
    set mdfId = ""
    for {
        set mdfId = $order(^IRIS.IK.Mdt.FieldId(domainId, mdfId), 1, data)
        quit:mdfId=""
        
        continue:'includeHidden&&+$lg(data,8)
        
        set counter = counter + 1
        $$$IKQADDRESULT(result,counter,$lb(mdfId) _ $li(data,1,7) _ $lb(+$lg(data,8)))
    }
    
    $$$IKQENDCATCH(result,"",tSC)
}

/// Returns the metadata field ID corresponding to the supplied name, or "" if none exists in this domain.
ClassMethod GetFieldId(domainId As %Integer, fieldName As %String, Output sc As %Status) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
	$$$IKCHECKNOTNULLR(fieldName,sc,-1)
	$$$IKCHECKSTRINGLENGTHR(fieldName,sc,-1)
	
	// BDB397 - case insensitive names
	set tNameIndex = $s($$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(fieldName), 1:fieldName)
    quit $get(^IRIS.IK.Mdt.Field(domainId, tNameIndex))
}

/// <p>Adds a field definition with the given name and properties.</p>
/// <ul>
/// 	<li>The <var>supportedOperators</var> parameter specifies which operations (such as $$$MDOPEQUAL) will
/// 		be available for filtering criteria</li>
/// 	<li>For <var>dataType</var>, choose either $$$MDDTSTRING, $$$MDDTNUMBER or $$$MDDTDATE ($horolog format)</li>
/// 	<li>Use <var>storage</var> to control how values are stored: $$$MDSTNORMAL for cases where you would
/// 		 use a normal index, $$$MDSTBITMAP where you would use a bitmap index (few different
/// 		 metadata values compared to total # of records)</li>
/// 	<li>If <var>dataType</var> is $$$MDDTSTRING, <var>caseSensitive</var> controls whether or not string
/// 		values should be treated as case-sensitive.</li>
/// 	<li>The <var>lovId</var> and <var>validateLov</var> parameters define whether a List Of Values is
/// 		available for this metadata field and whether input values should be verified against this list.
/// 		See also <method>AddListOfValues</method>.</li>
/// 	<li>If <var>hidden</var> is set to true, the field will by default not appear in metadata field
/// 		and value lists.</li>
/// </ul>
ClassMethod AddField(domainId As %Integer, fieldName As %String, supportedOperators As %List = {$lb($$$MDOPEQUAL)}, dataType As %String = {$$$MDDTSTRING}, storage As %Integer = {$$$MDSTNORMAL}, caseSensitive As %Boolean = 0, lovId As %Integer = -1, validateLov As %Boolean = 1, hidden As %Boolean = 0, Output sc As %Status = {$$$OK}) As %Integer
{
    set sc = $$$OK
    $$$IKCHECKPRIVWRITER(sc,-1)
    $$$CHECKDOMAINEXISTSR(domainId,sc,-1)
    $$$IKCHECKDOMMGRR(domainId,sc,-1)
    $$$IKCHECKNOTNULLR(fieldName,sc,-1)
    $$$IKCHECKSTRINGLENGTHR(fieldName,sc,-1)
    
	// BDB397 - case insensitive names
	set tNameIndex = $s($$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(fieldName), 1:fieldName)
    $$$IKCHECKIDNOTEXISTSR(^IRIS.IK.Mdt.Field,domainId,tNameIndex,$$$IKMDFieldExists,sc,-1)
    
    set dataType = $zconvert(dataType, "U")
    if '$listfind($lb($$$MDDTSTRING,$$$MDDTNUMBER,$$$MDDTDATE),dataType) {
	    set sc = $$$ERROR($$$InvalidArgument, "dataType: "_dataType)
	    quit -1
    }
    if '$listfind($lb($$$MDSTNORMAL,$$$MDSTBITMAP,$$$MDSTCOMPRESS,$$$MDSTCOMPRESSBITMAP),storage) {
	    set sc = $$$ERROR($$$InvalidArgument, "storage: "_storage)
	    quit -1
    }
    if (caseSensitive && ((storage = $$$MDSTCOMPRESS) || (storage = $$$MDSTCOMPRESSBITMAP))) {
	    set sc = $$$ERROR($$$GeneralError, "compressed storage is not available for case-sensitive fields")
	    quit -1
    }
    if ((dataType'=$$$MDDTSTRING) && ((storage = $$$MDSTCOMPRESS) || (storage = $$$MDSTCOMPRESSBITMAP))) {
	    set sc = $$$ERROR($$$GeneralError, "compressed storage is only available for fields of type $$$MDDTSTRING")
	    quit -1
    }
    if ((storage = $$$MDSTCOMPRESS) || (storage = $$$MDSTCOMPRESSBITMAP)) {
	    for i = 1:1:$ll(supportedOperators) {
		    if '$lf($lb($$$MDOPEQUAL, $$$MDOPNOTEQUAL, $$$MDOPISNULL, $$$MDOPISNOTNULL),$li(supportedOperators,i)) {
			    set sc = $$$ERROR($$$GeneralError, "fields with compressed storage can only use equality operators")
			    quit
		    }
	    }
	    quit:$$$ISERR(sc) -1
    }
    if (supportedOperators="") {
	    set sc = $$$ERROR($$$GeneralError, "specify at least one operator for this metadata field")
	    quit
    } elseif '$listvalid(supportedOperators) {
	    set sc = $$$ERROR($$$GeneralError, "operators should be specified in %List format")
	    quit
    } elseif supportedOperators'=$lb() { 
    	// BDB769 - Metadata: ensure leading and trailing whitespace is stripped off operators
	  	for i = 1:1:$ll(supportedOperators) {
		  	set $li(supportedOperators,i) = $zstrip($li(supportedOperators,i),"<>W")
	  	}
    }
    
    
    $$$IKLOCKX(domainId,^IRIS.IK.Mdt.FieldId,sc)
    if $d(^IRIS.IK.Mdt.Field(domainId,tNameIndex)) {
	    $$$IKUNLOCK(domainId,^IRIS.IK.Mdt.FieldId)
	    set sc = $$$ERROR($$$IKMDFieldExists,fieldName)
	    quit -1
    }
    
    set tTLevel = $tlevel
    try {
        tstart
        set mdfId = $i(^IRIS.IK.Mdt.FieldId(domainId))
        set ^IRIS.IK.Mdt.FieldId(domainId, mdfId) = $lb(fieldName, supportedOperators, dataType, storage, caseSensitive, lovId, validateLov, hidden)
        set ^IRIS.IK.Mdt.Field(domainId, tNameIndex) = mdfId
        tcommit
    } catch(ex) {
        set sc = ex.AsStatus(), mdfId = -1
    }
	trollback:($tlevel>tTLevel) 1
    $$$IKUNLOCK(domainId,^IRIS.IK.Mdt.FieldId)
    quit mdfId
}

Parameter RemoveFieldEXP [ Internal ] = 1;

/// Removes a metadata field (by name) from the domain, including all references by existing sources.
ClassMethod RemoveField(domainId As %Integer, fieldName As %String) As %Status
{
    $$$IKCHECKPRIVWRITE
    $$$CHECKDOMAINEXISTS(domainId)
    $$$IKCHECKNOTNULL(fieldName)
    
	// BDB397 - case insensitive names
	set tNameIndex = $s($$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(fieldName), 1:fieldName)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.Field,domainId,tNameIndex,mdfId,$$$IKMDFieldDoesNotExistE)
    
    quit ..RemoveFieldById(domainId, mdfId)
}

Parameter RemoveFieldByIdEXP [ Internal ] = 1;

/// Removes a metadata field (by ID) from the domain, including all references by existing sources.
ClassMethod RemoveFieldById(domainId As %Integer, fieldId As %Integer) As %Status
{
    $$$IKCHECKPRIVWRITE
    $$$CHECKDOMAINEXISTS(domainId)
    $$$IKCHECKDOMMGR(domainId)
    $$$IKCHECKNOTNULL(fieldId)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.FieldId,domainId,fieldId,mdfData,$$$IKMDFieldDoesNotExist)
    
    $$$IKLOCK(domainId,^IRIS.IK.Mdt.FieldId)
    
    set tSC = $$$OK, tTLevel = $tlevel
    try {
        tstart
        set srcId = ""
        for {
            set srcId = $order(^IRIS.IK.Mdt.Values(domainId, srcId))
            quit:srcId=""
        
            kill ^IRIS.IK.Mdt.Values(domainId, srcId, fieldId)
        }
    
        // kill index
        set gIndex = $case($lg(mdfData,4), $$$MDSTNORMAL:"^IRIS.IK.Mdt.ValueToSrc", $$$MDSTBITMAP:"^IRIS.IK.Mdt.ValueToSrcBit",
        		$$$MDSTNORMAL:"^IRIS.IK.Mdt.UniValueToSrc", $$$MDSTBITMAP:"^IRIS.IK.Mdt.UniValueToSrcBit")
        kill @gIndex@(domainId, fieldId)
        
        kill ^IRIS.IK.Mdt.Field(domainId, $$$UPPER($list(mdfData, 1)))
        kill ^IRIS.IK.Mdt.FieldId(domainId, fieldId)
        tcommit
    } catch(ex) {
        set tSC = ex.AsStatus()
    }
	trollback:($tlevel>tTLevel) 1
    
    $$$IKUNLOCK(domainId,^IRIS.IK.Mdt.FieldId)
    
    quit tSC
}

Parameter UpdateFieldEXP [ Internal ] = 1;

/// <p>Updates the properties for a given metadata field (by name). See also <method>AddField</method>.</p>
/// <p>Specifying a "" for the <var>supportedOperators</var> will leave the current value for that
/// property. Similarly, specifying -1 for <var>storage</var>, <var>hidden</var> and
/// <var>validateLov</var> or -2 for <var>lovId</var> will leave their respective values
/// unmodified. Setting <var>lovId</var> to -1 will unset the LOV for this field.</p>
ClassMethod UpdateField(domainId As %Integer, fieldName As %String, supportedOperators As %List = "", storage As %Integer = -1, hidden As %Integer = -1, lovId As %Integer = -2, validateLov As %Integer = -1) As %Status
{
    $$$IKCHECKPRIVWRITE
    $$$CHECKDOMAINEXISTS(domainId)
    $$$IKCHECKNOTNULL(fieldName)
    
	// BDB397 - case insensitive names
	set tNameIndex = $s($$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(fieldName), 1:fieldName)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.Field,domainId,tNameIndex,mdfId,$$$IKMDFieldDoesNotExistE)
    
    quit ..UpdateFieldById(domainId, mdfId, supportedOperators, storage, hidden, lovId, validateLov)
}

Parameter UpdateFieldByIdEXP [ Internal ] = 1;

/// <p>Updates the properties for a given metadata field (by ID). See also <method>AddField</method>.</p>
/// <p>Specifying a "" for the <var>supportedOperators</var> will leave the current value for that
/// property. Similarly, specifying -1 for <var>storage</var>, <var>hidden</var> and
/// <var>validateLov</var> or -2 for <var>lovId</var> will leave their respective values
/// unmodified. Setting <var>lovId</var> to -1 will unset the LOV for this field.</p>
ClassMethod UpdateFieldById(domainId As %Integer, fieldId As %Integer, supportedOperators As %List = "", storage As %Integer = -1, hidden As %Integer = -1, lovId As %Integer = -2, validateLov As %Integer = -1) As %Status
{
    $$$IKCHECKPRIVWRITE
    $$$CHECKDOMAINEXISTS(domainId)
    $$$IKCHECKDOMMGR(domainId)
    $$$IKCHECKNOTNULL(fieldId)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.FieldId,domainId,fieldId,field,$$$IKMDFieldDoesNotExist)
    
    set tSC = $$$OK, tTLevel = $tlevel
    try {
        tstart
        
	    if '$listfind($lb($$$MDSTNORMAL,$$$MDSTBITMAP,$$$MDSTCOMPRESS,$$$MDSTCOMPRESSBITMAP,-1),storage) {
		    set tSC = $$$ERROR($$$InvalidArgument, "storage: "_storage)
		    quit
	    }
	    if ($li(field,5) && ((storage = $$$MDSTCOMPRESS) || (storage = $$$MDSTCOMPRESSBITMAP))) {
		    set tSC = $$$ERROR($$$GeneralError, "compressed storage is not available for case-sensitive fields")
		    quit
	    }
	    if (($li(field,3)'=$$$MDDTSTRING) && ((storage = $$$MDSTCOMPRESS) || (storage = $$$MDSTCOMPRESSBITMAP))) {
		    set tSC = $$$ERROR($$$GeneralError, "compressed storage is only available for fields of type $$$MDDTSTRING")
		    quit
	    }
	    if ((storage = $$$MDSTCOMPRESS) || (storage = $$$MDSTCOMPRESSBITMAP) || ((storage = -1) && (($li(field,4) = $$$MDSTCOMPRESS) || ($li(field,4) = $$$MDSTCOMPRESSBITMAP)))) {
		    set tOperators = $s(supportedOperators="":$li(field,2), 1:supportedOperators)
		    for i = 1:1:$ll(tOperators) {
			    if '$lf($lb($$$MDOPEQUAL, $$$MDOPNOTEQUAL, $$$MDOPISNULL, $$$MDOPISNOTNULL),$li(tOperators,i)) {
				    set tSC = $$$ERROR($$$GeneralError, "fields with compressed storage can only use equality operators")
				    quit
			    }
		    }
		    quit:$$$ISERR(tSC)
		}
        
        
	    if (supportedOperators="") { // no change
	    } elseif '$listvalid(supportedOperators) {
		    set sc = $$$ERROR($$$GeneralError, "operators should be specified in %List format")
		    quit
	    } elseif supportedOperators'=$lb() { 
	    	// BDB769 - Metadata: ensure leading and trailing whitespace is stripped off operators
		  	for i = 1:1:$ll(supportedOperators) {
			  	set $li(supportedOperators,i) = $zstrip($li(supportedOperators,i),"<>W")
		  	}
		  	set $list(field,2) = supportedOperators
	    }
        
        set:hidden>=0 $list(field, 8) = (hidden>0)
        if (lovId>-2) {
	        if (lovId>=0) {
		        $$$IKCHECKIDEXISTSX(^IRIS.IK.Mdt.LovId,domainId,lovId,lov,$$$IKMDLovDoesNotExist,tSC)
	        }
	        set $list(field, 6) = lovId
        }
        set:validateLov>=0 $list(field, 7) = (validateLov>0)
        
        // if we have a LOV and need to validate, check all existing values 
        set lovId=$list(field,6)
        if (lovId>0) && ($list(field,7)) {
	        set autoExtend = $li(^IRIS.IK.Mdt.LovId(domainId,lovId),2)
	        set tSC = ..GetLovValues("^||%IKQ.LovValues",domainId,lovId)
	        quit:$$$ISERR(tSC)
	        kill ^||%IK.Lov, ^||%IK.LovH
	        set i = ""
	        for {
		        set i = $order(^||%IKQ.LovValues(i),1,d)
		        quit:i=""
		        set value = $li(d,1)
		        continue:value=""
		        if ($l(value)>$$$IKHASHSIZE) {
			        set hash = $zcrc(value,7)
			        set ^||%IK.LovH(hash, $i(^||%IK.LovH(hash))) = value
		        } else {
			        set ^||%IK.Lov(value) = ""
		        }
	        }
	        
	        set tSC = ..GetFieldValuesById("^||%IKQ.MdValues",domainId,fieldId,0,0)
	        quit:$$$ISERR(tSC)
	        set i = ""
	        for {
		        set i = $order(^||%IKQ.MdValues(i), 1, d)
		        quit:i=""
		        set value = $li(d,1), isFound = 0
		        if ($l(value)>$$$IKHASHSIZE) {
			    	set j = "", hash = $zcrc(value,7)
			    	for {
				    	set j = $order(^||%IK.LovH(hash,j),1,v)
				    	quit:j=""
				    	set isFound = (v=value)
				    	quit:isFound
			    	}
		        } else {
			        set isFound = $d(^||%IK.Lov(value))
		        }
		        if 'isFound {
			        if autoExtend {
				        set tSC = ..AddLovValue(domainId,lovId,value)
				        if ($l(value)>$$$IKHASHSIZE) {
					        set hash = $zcrc(value,7)
					        set ^||%IK.LovH(hash, $i(^||%IK.LovH(hash))) = value
				        } else {
					        set ^||%IK.Lov(value) = ""
				        }
			        } else {
				        set tSC = $$$ERROR($$$IKMDValueNotInLOV,value,lovId)
				        quit
			        }
			    }
	        }
	        
	        kill ^||%IK.Lov, ^||%IK.LovH, ^||%IKQ.LovValues, ^||%IKQ.MdValues
        }
        
        if (storage>=0) && (storage'=$list(field,4)) {
	        
	        set tOldStorage = $li(field,4)
	        set tToBitstring = storage#2, tFromBitstring = tOldStorage#2
	        set tToUni = storage>1, tFromUni = tOldStorage>1
        	set $list(field, 4) = storage
	        
	        if (tOldStorage = $$$MDSTNORMAL) && (storage = $$$MDSTBITMAP)  {
	        
		        // change from simple values to simple bitstrings
		        set val = ""
		        for {
			        set val = $o(^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, val))
			        quit:val=""
		        
			        set trunc = ""
			        for {
				        set trunc = $o(^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, val, trunc))
				        quit:trunc=""
			        
				        set srcId="", prevOffset="", bits=""
				        for {
					        set srcId = $o(^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, val, trunc, srcId))
					        quit:srcId=""
				        
					        $$$IKBITOFFPOS(srcId,srcOffset,srcPos)
					        if (srcOffset '= prevOffset) {
						        set:bits'="" ^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, val, trunc, prevOffset) = $bitlogic(bits)
						        set bits = $g(^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, val, trunc, srcOffset))
						        set prevOffset = srcOffset
					        }
					        set $bit(bits, srcPos) = 1
				        }
				        set:(prevOffset'="" && bits'="") ^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, val, trunc, prevOffset) = $bitlogic(bits)
			        }
                }
                kill ^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId)
	        
	        } elseif (tOldStorage = $$$MDSTBITMAP) && (storage = $$$MDSTNORMAL) {
	        
		        // change from simple bitstrings to simple values
		        set val = ""
		        for {
			        set val = $o(^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, val))
			        quit:val=""
		        
			        set trunc = ""
			        for {
				        set trunc = $o(^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, val, trunc))
				        quit:trunc=""
			        
				        set srcOffset=""
				        for {
					        set srcOffset = $o(^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, val, trunc, srcOffset),1,srcBits)
					        quit:srcOffset=""
				        
					        set srcPos=0
					        for {
						        set srcPos = $bitfind(srcBits, 1, srcPos+1)
						        quit:srcPos=0
					        
						        $$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
						        set ^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, val, trunc, srcId) = ""
					        }
				        }
			        }
                }
                kill ^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId)
	        
	        } elseif (tOldStorage = $$$MDSTNORMAL) && (storage = $$$MDSTCOMPRESS) {
		        
		        kill ^||%IK.NewValues
		        $$$IKSORTBEGIN(^||%IK.NewValues)
		        $$$IKSORTBEGIN(^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId))
		        set val= ""
		        for {
			        set val = $o(^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, val))
			        quit:val=""
		        
			        set trunc = ""
			        for {
				        set trunc = $o(^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, val, trunc))
				        quit:trunc=""
				        
				        set:'trunc tValueId = ..GetUniValueId(domainId, val, .tSC)
				        quit:$$$ISERR(tSC)
			        
				        set tSrcId=""
				        for {
					        set tSrcId = $o(^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, val, trunc, tSrcId))
					        quit:tSrcId=""
				        	
				        	if (trunc) {
					        	set tValue = ^IRIS.IK.Mdt.Values(domainId, tSrcId, fieldId)
					        	set tValueId = ..GetUniValueId(domainId,tValue,.tSC)
					        	quit:$$$ISERR(tSC)
				        	}
				        	
				        	set ^||%IK.NewValues(tSrcId, fieldId) = tValueId
				        	set ^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId, tValueId, tSrcId) = ""
				        }
				        quit:$$$ISERR(tSC)
			        }
			        quit:$$$ISERR(tSC)
                }
                quit:$$$ISERR(tSC)
                set x = $sortend(^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId))
                set x = $sortend(^||%IK.NewValues)
                merge ^IRIS.IK.Mdt.Values(domainId) = ^||%IK.NewValues
                kill ^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId), ^||%IK.NewValues
		        
	        } elseif (tOldStorage = $$$MDSTCOMPRESS) && (storage = $$$MDSTNORMAL) {
		        
		        kill ^||%IK.NewValues
		        $$$IKSORTBEGIN(^||%IK.NewValues)
		        $$$IKSORTBEGIN(^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId))
		        set tValueId = ""
		        for {
			        set tValueId = $o(^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId, tValueId))
			        quit:tValueId=""
		        	
		        	set tValue = ^IRIS.IK.Mdt.UniValueId(domainId, tValueId)
		        	set tNormValue = ..NormalizeValue(tValue, field, .tTrunc)
	        	
			        set tSrcId=""
			        for {
				        set tSrcId = $o(^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId, tValueId, tSrcId))
				        quit:tSrcId=""
			        	
			        	set ^||%IK.NewValues(tSrcId, fieldId) = tValue
			        	set ^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, tNormValue, tTrunc, tSrcId) = ""
			        }
			        quit:$$$ISERR(tSC)
                }
                quit:$$$ISERR(tSC)
                set x = $sortend(^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId))
                set x = $sortend(^||%IK.NewValues)
                merge ^IRIS.IK.Mdt.Values(domainId) = ^||%IK.NewValues
                kill ^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId), ^||%IK.NewValues
                
	        } elseif (tOldStorage = $$$MDSTCOMPRESS) && (storage = $$$MDSTCOMPRESSBITMAP) {
		        
		        set tValueId = ""
		        for {
			        set tValueId = $o(^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId, tValueId))
			        quit:tValueId=""
		        
			        set tSrcId="", tPrevOffset="", tBits=""
			        for {
				        set tSrcId = $o(^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId, tValueId, tSrcId))
				        quit:tSrcId=""
			        
				        $$$IKBITOFFPOS(tSrcId,tSrcOffset,tSrcPos)
				        if (tSrcOffset '= tPrevOffset) {
					        set:tBits'="" ^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, tPrevOffset) = $bitlogic(tBits)
					        set tBits = $g(^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, tSrcOffset))
					        set tPrevOffset = tSrcOffset
				        }
				        set $bit(tBits, tSrcPos) = 1
			        }
			        set:(tPrevOffset'="" && tBits'="") ^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, tPrevOffset) = $bitlogic(tBits)
			    }
                kill ^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId)
		        
	        } elseif (tOldStorage = $$$MDSTCOMPRESSBITMAP) && (storage = $$$MDSTCOMPRESS) {
		        
		        set tValueId = ""
		        for {
			    	set tValueId = $order(^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId))
			    	quit:tValueId=""
			    	
			    	set tSrcOff = ""
			    	for {
				    	set tSrcOff = $order(^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, tSrcOff), 1, tBits)
				    	quit:tSrcOff=""
				    	
				    	set tSrcPos = 0
				    	for {
					    	set tSrcPos = $bitfind(tBits, 1, tSrcPos+1)
					    	quit:'tSrcPos
					    	
					    	$$$IKGETIDOFFPOS(tSrcId,tSrcOff,tSrcPos)
					    	set ^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId, tValueId, tSrcId) = ""
				    	}
			    	}
		        }
		        
	        } elseif (tOldStorage = $$$MDSTBITMAP) && (storage = $$$MDSTCOMPRESSBITMAP) {
		        
		        kill ^||%IK.NewValues
		        $$$IKSORTBEGIN(^||%IK.NewValues)
		        set tValue = ""
		        for {
			        set tValue = $order(^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, tValue))
			        quit:tValue=""
			        
			        // treat non-truncated values separately, as they need much less work
			        set tValueId = ..GetUniValueId(domainId, tValue, .tSC)
			        quit:$$$ISERR(tSC)
			        
			        set tOff = ""
			        for {
				        set tOff = $order(^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, tValue, 0, tOff), 1, tBits)
				        quit:tOff=""
				        
				        set ^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, tOff) = $bitlogic(tBits)
				        
				        set tPos = 0
				        for {
					        set tPos = $bitfind(tBits, 1, tPos+1)
					        quit:'tPos
					        
					        $$$IKGETIDOFFPOS(tSrcId,tOff,tPos)
					        set ^||%IK.NewValues(tSrcId, fieldId) = tValueId
				        }
			        }
			        
			        // now do the truncated ones
			        set tOff = ""
			        for {
				        set tOff = $order(^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, tValue, 0, tOff), 1, tBits)
				        quit:tOff=""
				        
				        set tPos = 0, tPrevValueId=0, tNewBits=""
				        for {
					        set tPos = $bitfind(tBits, 1, tPos+1)
					        quit:'tPos
					        
					        $$$IKGETIDOFFPOS(tSrcId,tOff,tPos)
					        
					        set tValue = ^IRIS.IK.Mdt.Values(domainId, tSrcId, fieldId)
					        set tValueId = ..GetUniValueId(domainId, tValue, .tSC)
					        quit:$$$ISERR(tSC)
					        set ^||%IK.NewValues(tSrcId, fieldId) = tValueId
					        
					        if tValueId'=tPrevValueId {
						        set:tPrevValueId ^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tPrevValueId, tOff) = $bitlogic(tNewBits)
						        set tNewBits = $g(^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, tOff))
						        set tPrevValueId = tValueId
					        }
					        set $bit(tNewBits,tPos) = 1
				        }
				        set:tPrevValueId ^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tPrevValueId, tOff) = $bitlogic(tNewBits)
				        quit:$$$ISERR(tSC)
			        }
			        quit:$$$ISERR(tSC)
		        }
			    quit:$$$ISERR(tSC)
			    set x = $sortend(^||%IK.NewValues)
			    merge ^IRIS.IK.Mdt.Values(domainId) = ^||%IK.NewValues
			    kill ^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId), ^||%IK.NewValues
		        
	        } elseif (tOldStorage = $$$MDSTCOMPRESSBITMAP) && (storage = $$$MDSTBITMAP) {
		        
		        kill ^||%IK.NewValues
		        $$$IKSORTBEGIN(^||%IK.NewValues)
		        set tValueId = ""
		        for {
			        set tValueId = $order(^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId))
			        quit:tValueId=""
			        
			        set tValue = ^IRIS.IK.Mdt.UniValueId(domainId, tValueId)
			        set tValueNorm = ..NormalizeValue(tValue, field, .tTrunc)
			        
			        set tOff=""
			        for {
				        set tOff = $order(^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, tOff), 1, tBits)
				        quit:tOff=""
				        
				        set tPos = ""
				        for {
					        set tPos = $bitfind(tBits,1, tPos+1)
					        quit:'tPos
					        
					        $$$IKGETIDOFFPOS(tSrcId,tOff,tPos)
					        set ^||%IK.NewValues(tSrcId, fieldId) = tValue
				        }
				        
				        // merge with existing bits, as tValueNorm might already have values
				        set tBits = $bitlogic(tBits | ^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, tValueNorm, tTrunc, tOff))
				        set ^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, tValueNorm, tTrunc, tOff) = tBits
			        }
		        }
		        set x = $sortend(^||%IK.NewValues)
		        merge ^IRIS.IK.Mdt.Values(domainId) = ^||%IK.NewValues
		        kill ^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId), ^||%IK.NewValues
		        
	        } elseif (tOldStorage = $$$MDSTCOMPRESSBITMAP) && (storage = $$$MDSTNORMAL) {
		        set tSC = ..UpdateFieldById(domainId, fieldId,, $$$MDSTCOMPRESS)
		        quit:$$$ISERR(tSC)
		        set tSC = ..UpdateFieldById(domainId, fieldId,, storage)
		        quit:$$$ISERR(tSC)
	        } elseif (tOldStorage = $$$MDSTNORMAL) && (storage = $$$MDSTCOMPRESSBITMAP) {
		        set tSC = ..UpdateFieldById(domainId, fieldId,, $$$MDSTCOMPRESS)
		        quit:$$$ISERR(tSC)
		        set tSC = ..UpdateFieldById(domainId, fieldId,, storage)
		        quit:$$$ISERR(tSC)
	        } elseif (tOldStorage = $$$MDSTCOMPRESS) && (storage = $$$MDSTBITMAP) {
		        set tSC = ..UpdateFieldById(domainId, fieldId,, $$$MDSTNORMAL)
		        quit:$$$ISERR(tSC)
		        set tSC = ..UpdateFieldById(domainId, fieldId,, storage)
		        quit:$$$ISERR(tSC)
	        } elseif (tOldStorage = $$$MDSTBITMAP) && (storage = $$$MDSTCOMPRESS) {
		        set tSC = ..UpdateFieldById(domainId, fieldId,, $$$MDSTNORMAL)
		        quit:$$$ISERR(tSC)
		        set tSC = ..UpdateFieldById(domainId, fieldId,, storage)
		        quit:$$$ISERR(tSC)
	        }
        }
        
        set ^IRIS.IK.Mdt.FieldId(domainId, fieldId) = field
        
        tcommit
    } catch(ex) {
        set tSC = ex.AsStatus()
    }
    trollback:($tlevel>tTLevel) 1
    
    quit tSC
}

/// Returns the actual value for a given metadata field (by name) and source (by External ID).
ClassMethod GetValue(domainId As %Integer, fieldName As %String, externalId As %String, Output sc As %Status) As %String
{
    set sc = $$$OK
    $$$IKCHECKPRIVREADR(sc,"")
    $$$CHECKDOMAINEXISTSR(domainId,sc,"")
    $$$CHECKEXTIDEXISTSR(domainId,externalId,srcId,sc,"")
    $$$IKCHECKNOTNULLR(fieldName,sc,"")
    
	// BDB397 - case insensitive names
	set tNameIndex = $s($$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(fieldName), 1:fieldName)
    $$$IKCHECKIDEXISTSR(^IRIS.IK.Mdt.Field,domainId,tNameIndex,mdfId,$$$IKMDFieldDoesNotExistE,sc,"")
    
    quit ..GetValueById(domainId, mdfId, srcId, .sc)
}

/// Returns the actual value for a given metadata field (by ID) and source (by Source ID).
ClassMethod GetValueById(domainId As %Integer, fieldId As %Integer, srcId As %Integer, Output sc As %Status) As %String
{
    set sc = $$$OK
    $$$IKCHECKPRIVREADR(sc,"")
    $$$CHECKDOMAINEXISTSR(domainId,sc,"")
    $$$CHECKSRCIDEXISTSR(domainId,srcId,sc,"")
    $$$IKCHECKNOTNULLR(fieldId,sc,"")
    $$$IKCHECKIDEXISTSR(^IRIS.IK.Mdt.FieldId,domainId,fieldId,field,$$$IKMDFieldDoesNotExist,sc,"")
    
    set tValue = $g(^IRIS.IK.Mdt.Values(domainId, srcId, fieldId))
    set:($li(field,4)>1)&&(tValue'="") tValue = ^IRIS.IK.Mdt.UniValueId(domainId, tValue)
    quit tValue
}

Parameter GetValuesRT = "mdFieldId:%Integer,fieldName:%String,value:%String";

/// <p>Returns the actual metadata values for the given source (by External ID).</p>
/// <p>Setting <var>includeHidden</var> to true will also return the values for hidden metadata fields.</p>
ClassMethod GetValues(ByRef result As %Integer, domainId As %Integer, externalId As %String, includeHidden As %Boolean = 0) As %Status
{
    $$$IKQBEGIN(result,"")
    $$$CHECKDOMAINEXISTS(domainId)
    $$$CHECKEXTIDEXISTS(domainId,externalId,srcId)
    
    quit ..GetValuesById(.result, domainId, srcId, includeHidden)
}

Parameter GetValuesByIdRT = "mdFieldId:%Integer,fieldName:%String,value:%String";

/// <p>Returns the actual metadata values for the given source (by Source ID).</p>
/// <p>Setting <var>includeHidden</var> to true will also return the values for hidden metadata fields.</p>
ClassMethod GetValuesById(ByRef result As %Integer, domainId As %Integer, srcId As %Integer, includeHidden As %Boolean = 0) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
    $$$CHECKDOMAINEXISTSX(domainId,tSC)
    $$$CHECKSRCIDEXISTSX(domainId,srcId,tSC)
    
    set counter = 1
    
    set mdfId = ""
    for {
        set mdfId = $order(^IRIS.IK.Mdt.FieldId(domainId, mdfId), 1, mdfData)
        quit:mdfId=""
        
        continue:'includeHidden&&+$lg(mdfData,8)
        
        set counter = counter + 1
        set tValue = $get(^IRIS.IK.Mdt.Values(domainId, srcId, mdfId))
        set:($li(mdfData,4)>1)&&(tValue'="") tValue = ^IRIS.IK.Mdt.UniValueId(domainId, tValue)
        $$$IKQADDRESULT(result,counter,$lb(+mdfId, $list(mdfData, 1), tValue))
    }
    
    $$$IKQENDCATCH(result,"",tSC)
}

Parameter SetValueEXP [ Internal ] = 1;

/// <p>Sets (or replaces if it exists) the value for a given metadata field (by name) for a given source
/// (by External ID).</p>
/// <p>Values for fields of type $$$MDDTSTRING are normalized and stripped of whitespace and control
/// characters at the beginning and end of the string.</p>
ClassMethod SetValue(domainId As %Integer, fieldName As %String, externalId As %String, value As %String) As %Status
{
    $$$IKCHECKPRIVWRITE
    $$$CHECKDOMAINEXISTS(domainId)
    $$$CHECKEXTIDEXISTS(domainId,externalId,srcId)
    $$$IKCHECKNOTNULL(fieldName)
    
	// BDB397 - case insensitive names
	set tNameIndex = $s($$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(fieldName), 1:fieldName)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.Field,domainId,tNameIndex,mdfId,$$$IKMDFieldDoesNotExistE)
    
    quit ..SetValueById(domainId, mdfId, srcId, value)
}

Parameter SetValueByIdEXP [ Internal ] = 1;

/// <p>Sets (or replaces if it exists) the value for a given metadata field (by ID) for a given source
/// (by Source ID). Explicitly setting a value to "" (null/empty string) will erase the current value.</p>
/// <p>Values for fields of type $$$MDDTSTRING are normalized and stripped of whitespace and control
/// characters at the beginning and end of the string.</p>
ClassMethod SetValueById(domainId As %Integer, fieldId As %Integer, srcId As %Integer, value As %String) As %Status
{
    $$$IKCHECKPRIVWRITE
    $$$CHECKDOMAINEXISTS(domainId)
    $$$CHECKSRCIDEXISTS(domainId,srcId)
    $$$IKCHECKNOTNULL(fieldId)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.FieldId,domainId,fieldId,mdfData,$$$IKMDFieldDoesNotExist)
    
    set isInBatch = ($g(^IRIS.IK.Mdt.Values(domainId))=-1)
    
    set tSC = $$$OK, tTLevel = $tlevel
    try {
        tstart:'isInBatch
        
        set tSC = ..SetValueByIdInternal(domainId, fieldId, srcId, $g(value))
        quit:$$$ISERR(tSC)
        
        // mark that the domain has changed to invalidate filters
        // NOTE: this can be refined to the MD field level eventually
        if ('isInBatch) {
	        $$$IKDOMAINCHANGED(domainId)
        }
        
        tcommit:'isInBatch
    } catch(ex) {
        set tSC = ex.AsStatus()
    }
    trollback:($tlevel>tTLevel) 1
    quit tSC
}

/// Internal method to set a metadata value directly, without performing any existence checks.
ClassMethod SetValueByIdInternal(domainId As %Integer, fieldId As %Integer, srcId As %Integer, value As %String, skipExistingValueCheck As %Boolean = 0) As %Status [ Internal ]
{
    set tSC = $$$OK
    try {
        set mdfData = $g(^IRIS.IK.Mdt.FieldId(domainId,fieldId))
        set type = $list(mdfData,3)
        set lovId = $list(mdfData, 6)
        set storage = $list(mdfData, 4)
        set isCaseSensitive = $list(mdfData, 5)
        set isInBatch = ($g(^IRIS.IK.Mdt.Values(domainId))=-1)
        
        // validate the format
        if (value'="") {
	        if (type=$$$MDDTNUMBER) {
	            if ('$isvalidnum(value)) {
	                set tSC = $$$ERROR($$$DTNotNum, value)
	                quit
	            }
	            set value = +value
	        } ElseIf (type=$$$MDDTDATE) {
		        if (value="") || (value=0) {
			        set value = ""
		        } else {
		            set datePart = +$piece(value, ",", 1)
		            set timePart = +$piece(value, ",", 2)
	    	        if (datePart<=0) || (timePart<0) || (timePart>86399) {
	        	        set tSC = $$$ERROR($$$DTPattern, value, "$horolog")
	            	    quit
	    	        }
	            	set value = datePart_","_timePart
	            }
	        }
        }
    
        // process the LOV-specific checks & measures
        if (lovId > 0) {
        
            set lov = $get(^IRIS.IK.Mdt.LovId(domainId, lovId))
        
            // if we need to verify the LOV value or potentially autoextend, check if
            // this is an existing value
            if ($list(mdfData, 7) || $list(lov, 2)) {
                set isExistingValue = 0
                set rank = ""
                for {
                    set rank = $order(^IRIS.IK.Mdt.LovValue(domainId, lovId, rank), 1, dv)
                    quit:rank=""
                
                    if (isCaseSensitive) {
                        if (dv = value) {
                            set isExistingValue = 1
                            quit
                        }
                    } else {
                        if ($zconvert(dv, "U") = $zconvert(value, "U")) {
                            set isExistingValue = 1
                            quit
                        }
                    }
                }
            
                // autoextend if required
                if 'isExistingValue {
                    if $list(lov, 2) {
                        set lovRank = $i(^IRIS.IK.Mdt.LovValue(domainId, lovId))
                        set ^IRIS.IK.Mdt.LovValue(domainId, lovId, lovRank) = value
                    // throw an error if required
                    } ElseIf $list(mdfData, 7) {
                        set tSC = $$$ERROR($$$IKMDValueNotInLOV, value, lovId)
                        quit
                    }
                }
            }
        }
    
        // calculate src offset and position if we need to set bits
        if (storage#2) {
            $$$IKBITOFFPOS(srcId,srcOffset,srcPos)
        }
    
        // check if there is an existing value to overwrite
        if 'skipExistingValueCheck && $data(^IRIS.IK.Mdt.Values(domainId, srcId, fieldId), currentValue) {
        
            // check if a metadata-setting batch is currently running
            if (isInBatch) {
                set tSC = $$$ERROR($$$IKMDCannotReplaceInBatch)
                quit
            }
               
            // erase existing value
            if (storage = $$$MDSTNORMAL) {
	            set currentValue = ..NormalizeValue(currentValue, mdfData, .isCurrentValueTruncated)
	            kill ^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, currentValue, isCurrentValueTruncated, srcId)
            } elseif (storage = $$$MDSTBITMAP) {
	            set currentValue = ..NormalizeValue(currentValue, mdfData, .isCurrentValueTruncated)
	            set $bit(^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, currentValue, isCurrentValueTruncated, srcOffset), srcPos) = 0
            } elseif (storage = $$$MDSTCOMPRESS) {
	            set tValueId = ..GetUniValueId(domainId, currentValue, .tSC)
	            quit:$$$ISERR(tSC)
	            kill ^IRIS.IK.Mdt.Mdt.UniValueToSrc(domainId, fieldId, tValueId, srcId)
            } elseif (storage = $$$MDSTCOMPRESSBITMAP) {
	            set tValueId = ..GetUniValueId(domainId, currentValue, .tSC)
	            quit:$$$ISERR(tSC)
	            set $bit(^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, srcOffset), srcPos) = 0
            }
            kill ^IRIS.IK.Mdt.Values(domainId, srcId, fieldId)
        }
        
        // BDB277: value="" means we just wanted to unset the current value
        quit:value=""
    
        // now store the actual new value
        if (storage = $$$MDSTNORMAL) || (storage = $$$MDSTBITMAP) {
	        
	        set ^IRIS.IK.Mdt.Values(domainId, srcId, fieldId) = value
	        set value = ..NormalizeValue(value, mdfData, .isTruncated)
	        
            if (storage = $$$MDSTBITMAP) {
	            if (isInBatch) {
		            set ^||%IK.Mdt.ValueToSrcBit(domainId, fieldId, value, isTruncated, srcId) = ""
	            } else {
                	set $bit(^IRIS.IK.Mdt.ValueToSrcBit(domainId, fieldId, value, isTruncated, srcOffset), srcPos) = 1
	            }
            } else {
                set ^IRIS.IK.Mdt.ValueToSrc(domainId, fieldId, value, isTruncated, srcId) = ""
            }
            
        } else {
	        
	        set tValueId = ..GetUniValueId(domainId, value, .tSC)
	        quit:$$$ISERR(tSC)
	        set ^IRIS.IK.Mdt.Values(domainId, srcId, fieldId) = tValueId
	        
	        if (storage = $$$MDSTCOMPRESS) {
		        set ^IRIS.IK.Mdt.UniValueToSrc(domainId, fieldId, tValueId, srcId) = ""
	        } else {
		        if (isInBatch) {
		            set ^||%IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, srcId) = ""
		        } else {
			        set $bit(^IRIS.IK.Mdt.UniValueToSrcBit(domainId, fieldId, tValueId, srcOffset), srcPos) = 1
		        }
	        }
        }
    } catch (ex) {
        set tSC = ex.AsStatus()
    }
    quit tSC
}

/// <p>Starts a 'batch' during which metadata values can be set. Some setting operations and index
/// recalculations are optimized for batch processing.</p>
/// <p><b>NOTE:</b> It is currently up to the user to make sure no metadata values are read during
/// the batch and no values exist already (as replacing a value involves reading it). Reading metadata
/// field values during a batch is not guaranteed to return correct results.</p>
ClassMethod StartBatch(domainId As %Integer) As %Status
{
    $$$IKCHECKPRIVWRITE
    $$$CHECKDOMAINEXISTS(domainId)
    
    // mark the start of a batch
    set ^IRIS.IK.Mdt.Values(domainId) = -1
    
    $$$IKSORTBEGIN(^IRIS.IK.Mdt.Values(domainId))
    $$$IKSORTBEGIN(^IRIS.IK.Mdt.ValueToSrc(domainId))
    $$$IKSORTBEGIN(^IRIS.IK.Mdt.UniValueToSrc(domainId))
    
    // BDB277: queue values for bitstring fields
    kill ^||%IK.Mdt.ValueToSrcBit(domainId)
    kill ^||%IK.Mdt.UniValueToSrcBit(domainId)
    $$$IKSORTBEGIN(^||%IK.Mdt.ValueToSrcBit(domainId))
    $$$IKSORTBEGIN(^||%IK.Mdt.UniValueToSrcBit(domainId))
    
    quit $$$OK
}

/// <p>Ends a metadata batch. See <method>StartBatch</method> for more details.</p>
ClassMethod EndBatch(domainId As %Integer) As %Status
{
    $$$IKCHECKPRIVWRITE
    $$$CHECKDOMAINEXISTS(domainId)
    
    set sc = $sortend(^IRIS.IK.Mdt.Values(domainId))
    set sc = $sortend(^IRIS.IK.Mdt.ValueToSrc(domainId))
    set sc = $sortend(^IRIS.IK.Mdt.UniValueToSrc(domainId))
    
    // BDB277: process queued values for bitstring fields
    set sc = $sortend(^||%IK.Mdt.ValueToSrcBit(domainId))
    set tMdfId = ""
    for {
		set tMdfId = $order(^||%IK.Mdt.ValueToSrcBit(domainId, tMdfId))
		quit:tMdfId=""
		
		set tValue = ""
		for {
			set tValue = $order(^||%IK.Mdt.ValueToSrcBit(domainId, tMdfId, tValue))
			quit:tValue=""
			
			set tTruncated = ""
			for {
				set tTruncated = $order(^||%IK.Mdt.ValueToSrcBit(domainId, tMdfId, tValue, tTruncated))
				quit:tTruncated=""
				
				set tSrcId="", tPrevOff=0, tBits=""
				for {
					set tSrcId = $order(^||%IK.Mdt.ValueToSrcBit(domainId, tMdfId, tValue, tTruncated, tSrcId))
					quit:tSrcId=""
					
					$$$IKBITOFFPOS(tSrcId,tOff,tPos)
					
					if (tPrevOff'=tOff) {
						set:tPrevOff ^IRIS.IK.Mdt.ValueToSrcBit(domainId, tMdfId, tValue, tTruncated, tPrevOff) = $bitlogic(tBits)
						set tBits = $g(^IRIS.IK.Mdt.ValueToSrcBit(domainId, tMdfId, tValue, tTruncated, tOff)), tPrevOff = tOff
					}
					set $bit(tBits,tPos) = 1
				}
				set:tPrevOff ^IRIS.IK.Mdt.ValueToSrcBit(domainId, tMdfId, tValue, tTruncated, tPrevOff) = $bitlogic(tBits)
			}
		}
    }
    kill ^||%IK.Mdt.ValueToSrcBit(domainId)
    
    // BDB346 - same for $$$MDDTCOMPRESSBITMAP
    set sc = $sortend(^||%IK.Mdt.UniValueToSrcBit(domainId))
    set tMdfId = ""
    for {
		set tMdfId = $order(^||%IK.Mdt.UniValueToSrcBit(domainId, tMdfId))
		quit:tMdfId=""
		
		set tValueId = ""
		for {
			set tValueId = $order(^||%IK.Mdt.UniValueToSrcBit(domainId, tMdfId, tValueId))
			quit:tValueId=""
				
			set tSrcId="", tPrevOff=0, tBits=""
			for {
				set tSrcId = $order(^||%IK.Mdt.UniValueToSrcBit(domainId, tMdfId, tValueId, tSrcId))
				quit:tSrcId=""
				
				$$$IKBITOFFPOS(tSrcId,tOff,tPos)
				
				if (tPrevOff'=tOff) {
					set:tPrevOff ^IRIS.IK.Mdt.UniValueToSrcBit(domainId, tMdfId, tValueId, tPrevOff) = $bitlogic(tBits)
					set tBits = $g(^IRIS.IK.Mdt.UniValueToSrcBit(domainId, tMdfId, tValueId, tOff)), tPrevOff = tOff
				}
				set $bit(tBits,tPos) = 1
			}
			set:tPrevOff ^IRIS.IK.Mdt.UniValueToSrcBit(domainId, tMdfId, tValueId, tPrevOff) = $bitlogic(tBits)
		}
    }
    kill ^||%IK.Mdt.UniValueToSrcBit(domainId)
    
    // mark the end of the batch
    set ^IRIS.IK.Mdt.Values(domainId) = 0
    
    // make sure filters are invalidated
    $$$IKDOMAINCHANGED(domainId)
    
    quit $$$OK
}

/// <p>Adds a List Of Values to the domain, which can then be used as a list of allowable values for 
/// one or more metadata fields.</p>
ClassMethod AddListOfValues(domainId As %Integer, lovName As %String, autoExtend As %Boolean = 1, Output sc As %Status) As %Integer [ Deprecated ]
{
    set sc = $$$OK
    $$$IKCHECKPRIVWRITER(sc,-1)
    $$$CHECKDOMAINEXISTSR(domainId,sc,-1)
    $$$IKCHECKNOTNULLR(lovName,sc,-1)
    
    set tTLevel = $tlevel
    try {
        tstart
        set lovId = $i(^IRIS.IK.Mdt.LovId(domainId))
        set ^IRIS.IK.Mdt.LovId(domainId, lovId) = $lb(lovName, autoExtend)
        tcommit
    } catch(ex) {
        set sc = ex.AsStatus(), lovId = -1
    }
	trollback:($tlevel>tTLevel) 1
    
    quit lovId
}

Parameter AddLovValueEXP [ Internal ] = 1;

/// Adds a new value to an existing List Of Values
ClassMethod AddLovValue(domainId As %Integer, lovId As %Integer, value As %String, ByRef rank As %Integer = -1) As %Status [ Deprecated ]
{
    $$$IKCHECKPRIVWRITE
    $$$CHECKDOMAINEXISTS(domainId)
    $$$IKCHECKNOTNULL(lovId)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.LovId,domainId,lovId,lov,$$$IKMDLovDoesNotExist)
    
    set tSC = $$$OK, tTLevel = $tlevel
    try {
        tstart
        // check if a rank is specified
        if (rank > 0) {
            
            if ($data(^IRIS.IK.Mdt.LovValue(domainId, lovId, rank))) {
                
                // if there is a value at this rank, shift them all up
                set upRank = ""
                for {
                    set upRank = $order(^IRIS.IK.Mdt.LovValue(domainId, lovId, upRank), -1, mdValue)
                    quit:upRank=""
                    quit:upRank<rank
                    
                    set ^IRIS.IK.Mdt.LovValue(domainId, lovId, upRank+1) = mdValue
                    kill ^IRIS.IK.Mdt.LovValue(domainId, lovId, upRank)
                }
                
                // we also need to increment the current rank
                set upRank = $i(^IRIS.IK.Mdt.LovValue(domainId, lovId))
            }
            
        } else {
            
            // if no rank is specified, just take the next one
            set rank = $i(^IRIS.IK.Mdt.LovValue(domainId, lovId))
            
        }
        set ^IRIS.IK.Mdt.LovValue(domainId, lovId, rank) = $zstrip(value, "<>WC")
        tcommit
    } catch(ex) {
        set tSC = ex.AsStatus()
    }
	trollback:($tlevel>tTLevel) 1
    
    quit tSC
}

Parameter GetLovValuesRT = "value:%String";

/// Returns all the allowed values for a given metadata LOV.
ClassMethod GetLovValues(ByRef result As %Integer, domainId As %Integer, lovId As %Integer) As %Status [ Deprecated ]
{
    $$$IKQBEGINTRY(result,"",tSC)
    $$$CHECKDOMAINEXISTSX(domainId,tSC)
    $$$IKCHECKNOTNULLX(lovId,tSC)
    $$$IKCHECKIDEXISTSX(^IRIS.IK.Mdt.LovId,domainId,+lovId,lov,$$$IKMDLovDoesNotExist,tSC)
    
    set counter = 0
    set rank = ""
    for {
        set rank = $order(^IRIS.IK.Mdt.LovValue(domainId, lovId, rank), 1, data)
        quit:rank=""
        
        set counter = counter + 1
        $$$IKQADDRESULT(result,counter,$lb(data))
    }
    
    $$$IKQENDCATCH(result,"",tSC)
}

Parameter GetFieldValuesRT = "value:%String";

/// Returns all the distinct values currently in use for a given metadata field (by name).
/// See also <method>GetUniqueValues</method> for a version returning the number of sources with
/// this metadata value and sorting options.
ClassMethod GetFieldValues(ByRef result, domainId As %Integer, fieldName As %String, page As %Integer = 1, pageSize As %Integer = 10) As %Status
{
	$$$IKQBEGIN(result,"")
    $$$CHECKDOMAINEXISTS(domainId)
    $$$IKCHECKNOTNULL(fieldName)
    
	// BDB397 - case insensitive names
	set tNameIndex = $s($$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(fieldName), 1:fieldName)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.Field,domainId,tNameIndex,mdfId,$$$IKMDFieldDoesNotExistE)
    
    quit ..GetFieldValuesById(.result, domainId, mdfId, page, pageSize)
}

Parameter GetFieldValuesByIdRT = "value:%String";

/// Returns all the distinct values currently in use for a given metadata field (by ID).
ClassMethod GetFieldValuesById(ByRef result, domainId As %Integer, mdFieldId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.TruncValues",tSC)
    $$$CHECKDOMAINEXISTSX(domainId,tSC)
    $$$IKCHECKIDEXISTSX(^IRIS.IK.Mdt.FieldId,domainId,+mdFieldId,mdf,$$$IKMDFieldDoesNotExist,tSC)
    
    $$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,count)
    
    set tStorage = $list(mdf,4)
    set global = $case(tStorage, $$$MDSTNORMAL:"^IRIS.IK.Mdt.ValueToSrc", 
    							 $$$MDSTBITMAP:"^IRIS.IK.Mdt.ValueToSrcBit",
    							 $$$MDSTCOMPRESS:"^IRIS.IK.Mdt.UniValueToSrc", 
    							 $$$MDSTCOMPRESSBITMAP:"^IRIS.IK.Mdt.UniValueToSrcBit")
    
    if ((tStorage = $$$MDSTCOMPRESS) || (tStorage = $$$MDSTCOMPRESSBITMAP)) {
	    
	   set tValueId = ""
	   for {
		   set tValueId = $order(@global@(domainId, mdFieldId, tValueId))
		   quit:tValueId=""
		   continue:'$d(@global@(domainId, mdFieldId, tValueId))
		   
		   set x = $i(count)
		   $$$IKCHECKPAGING(usePaging,first,last,count)
		   
		   $$$IKQADDRESULT(result,count,$lb(^IRIS.IK.Mdt.UniValueId(domainId, tValueId)))
	   }
	    
    } else {
	    
	    set val = "", ^||%IK.TruncValues=0
	    for {
	        set val = $order(@global@(domainId, mdFieldId, val))
	        quit:val=""
	    
	        if ($d(@global@(domainId, mdFieldId, val, 0))) {
	    
		        set count = count+1
		        $$$IKCHECKPAGING(usePaging,first,last,count)
	    
		        // de-normalize
		        set realValue = ..DeNormalizeValue(val, mdf)
	    
		        $$$IKQADDRESULT(result,count,$lb(realValue))
	        }
	    
	        // and for the truncated values, loop through all sources containing them
	        if ($d(@global@(domainId, mdFieldId, val, 1))) {
	        
		        if (tStorage = $$$MDSTBITMAP) {
		        
			        set srcOffset = ""
			        for {
				        set srcOffset = $order(@global@(domainId, mdFieldId, val, 1, srcOffset), 1, srcBits)
				        quit:srcOffset=""
			        
			            set srcPos = 0
				        for {
					        set srcPos = $bitfind(srcBits,1,srcPos+1)
					        quit:srcPos=0
				        
					        $$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
					        
					        set fullValue = ^IRIS.IK.Mdt.Values(domainId, srcId, mdFieldId)
			        
					        // check if we didn't add it before
					        set isNew = 1
					        for x = 1:1:^||%IK.TruncValues {
						        if (fullValue=^||%IK.TruncValues(x)) {
							        set isNew = 0
							        quit
						        }
					        }
			        
					        continue:'isNew
					        set ^||%IK.TruncValues($i(^||%IK.TruncValues)) = fullValue
			        
					        set count = count+1
					        $$$IKCHECKPAGING(usePaging,first,last,count)
			        
			        		$$$IKQADDRESULT(result,count,$lb(fullValue))
				        }
			        }
		        
		        } else {
		        
			        set srcId = ""
			        for {
				        set srcId = $order(@global@(domainId, mdFieldId, val, 1, srcId))
				        quit:srcId=""
			        
				        set fullValue = ^IRIS.IK.Mdt.Values(domainId, srcId, mdFieldId)
			        
				        // check if we didn't add it before
				        set isNew = 1
				        for x = 1:1:^||%IK.TruncValues {
					        if (fullValue=^||%IK.TruncValues(x)) {
						        set isNew = 0
						        quit
					        }
				        }
			        
				        continue:'isNew
				        set ^||%IK.TruncValues($i(^||%IK.TruncValues)) = fullValue
			        
				        set count = count+1
				        $$$IKCHECKPAGING(usePaging,first,last,count)
			        
		        		$$$IKQADDRESULT(result,count,$lb(fullValue))
			        }
		        }
	        
	        }
	    }
    }
    
	$$$IKQENDCATCH(result,"^||%IK.TruncValues",tSC)
}

ClassMethod DeNormalizeValue(value As %String, mdfData As %List) As %String [ Internal ]
{
	set dataType = $li(mdfData,3)
    quit:dataType=$$$MDDTDATE (value\1)_","_((value#1)*100000)
    quit:dataType=$$$MDDTSTRING $e(value,2,*)
    quit value
}

ClassMethod NormalizeValue(value As %String, mdfData As %List, Output isTruncated As %Boolean) As %String [ Internal ]
{
    // strip off whitespace and control characters
    set value = $zstrip(value, "<>WC")
		
    set isTruncated = 0
    set dataType = $li(mdfData,3)
    // Check for number
    quit:dataType=$$$MDDTNUMBER +value
    // Check for date, make sure dates get stored as a sortable numeric value
    quit:dataType=$$$MDDTDATE $$$IKSORTABLEDATE(value)
    /// $$$MDDTSTRING

    // truncate if necessary
    set:$l(value)>$$$IKHASHSIZE value=$e(value,1,$$$IKHASHSIZE), isTruncated=1
        
    // treat case sensitivity
    quit " "_$s($list(mdfData, 5):value,1:$zcvt(value,"U"))
}

Parameter GetLovsRT [ Deprecated ] = "lovId:%Integer,name:%String,autoExtend:%Boolean";

/// Returns all LOVs (List of Values) registered for this domain.
ClassMethod GetLovs(ByRef result, domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,count)
	
	set i = ""
	for {
		set i = $order(^IRIS.IK.Mdt.LovId(domainId,i),1,lovData)
		quit:i=""
		
		set count = count+1
		$$$IKCHECKPAGING(usePaging,first,last,count)
		
		$$$IKQADDRESULT(result,count,$lb(+i)_lovData)
	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

/// <p><b>Note</b>: This implementation offers slight performance improvements over the default
/// implementation in <class>%iKnow.Queries.MetadataI</class> and uses the datatype-aware
/// normalized form of the metadata field value for sorting purposes.</p>
/// <p>Allows the results of <class>%iKnow.Queries.SourceAPI</class> queries to be re-sorted along
/// a particular metadata field. <var>pSort</var> is expected to contain the name of the metadata 
/// field to sort by, optionally followed by a space and "ASC" (default) or "DESC". The string 
/// "ExternalId" is also accepted as a valid sort field and should be resolved through the
/// GetExternalId method in <class>%iKnow.Queries.SourceAPI</class>, unless there is a metadata
/// field carrying the same name.</p>
/// <p><var>pSources</var> is expected to be an array containing all (unsorted) query results with
/// the source ID as the first row element, while <var>pResult</var> will be populated with the
/// sorted results like a usual iKnow API query.</p>
/// <p><var>pSort</var> can optionally be suffixed with a space and the string "ADDCOL", in which
/// case, a column containing the actual metadata value is appended to the results. Use this feature 
/// with caution as it might impact SQL/WS clients, because the extra column is not declared in
/// the original query specs.</p>
/// <p><b>Note</b>: sources for which the requested metadata field is not populated or where its value
/// is longer than $$$IKHASHSIZE (150 characters) will be left out of the results.</p>
ClassMethod SortByField(ByRef pResult, pDomainId As %Integer, ByRef pSources, pSort As %String, pPage As %Integer = 1, pPageSize As %Integer = 10) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set pSort = $zstrip(pSort,"<=>W"),tPieces = $length(pSort," ")
		set tAddValueColumn = ($$$UPPER($piece(pSort," ",tPieces))="ADDCOL")
		set tOrder = $$$UPPER($piece(pSort," ",tPieces-tAddValueColumn))
		set tOrder = $case(tOrder, "DESC":"DESC", "ASC":"ASC", :"")
		set tField = $piece(pSort," ",1,tPieces-tAddValueColumn-(tOrder'=""))
		set tOrder = $case(tOrder, "DESC":-1, :1)
		set tFieldId = ..GetFieldId(pDomainId, tField)
		if 'tFieldId {
			if ($$$UPPER(tField)="EXTERNALID") {
				set tFieldId=-1
			} else {
				set tSC = $$$ERROR($$$IKMDFieldDoesNotExistE, tField)
				quit
			}
		} else {
			set tFieldData = ^IRIS.IK.Mdt.FieldId(pDomainId,tFieldId)
		}
		
		kill tSorted
		set i = ""
		for {
			set i = $order(pSources(i),1,tSource)
			quit:i=""
			
			set tSrcId = $li(tSource,1)
			if (tFieldId=-1) {
				set tMetaValue = ##class(%iKnow.Queries.SourceAPI).GetExternalId(pDomainId,tSrcId,.tSC)
				set tNormalizedValue = tMetaValue
				quit:$$$ISERR(tSC)
			} else {
				set tMetaValue = $g(^IRIS.IK.Mdt.Values(pDomainId,tSrcId,tFieldId))
				continue:tMetaValue=""
				
				// BDB346: if this is a compressed type, fetch the real value
				set:$li(tFieldData,4)>1 tMetaValue = ^IRIS.IK.Mdt.UniValueId(pDomainId, tMetaValue)
				
				set tNormalizedValue=..NormalizeValue(tMetaValue, tFieldData, .tIsTruncated)
				continue:tIsTruncated
			}
			continue:tNormalizedValue=""
			continue:$length(tNormalizedValue)>$$$IKHASHSIZE
			
			set:tAddValueColumn tSource = tSource _ $lb(tMetaValue)
			
			set tSorted(tNormalizedValue, -tSrcId) = tSource
		}
		
		$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
		set tSort = ""
		for {
			set tSort = $order(tSorted(tSort),tOrder)
			quit:tSort=""
			
			set tSrcId = ""
			for {
				set tSrcId = $order(tSorted(tSort,tSrcId),1,tSource)
				quit:tSrcId=""
				
				set tCount = tCount+1
				$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
				$$$IKQADDRESULT(pResult,tCount,tSource)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the unique metadata value corresponding to the supplied <var>pUniValueId</var>.
ClassMethod GetUniValue(pDomainId As %Integer, pUniValueId As %Integer) As %String
{
	quit $g(^IRIS.IK.Mdt.UniValueId(pDomainId, pUniValueId))
}

/// <p>Returns the id of a unique metadata value (for use in compressed storage) or creates it
/// if it didn't exist yet.</p>
/// <p>Note: This method is intended for internal use only.</p>
ClassMethod GetUniValueId(pDomainId As %Integer, pValue As %String, Output pSC As %Status = {$$$OK}) As %Integer [ Internal ]
{
	set pSC = $$$OK, tUniId = ""
	try {
		$$$IKCHECKPRIVREADX(pSC)
			
		// normalize value
		set pValue = $$$IKNORMALIZED(pValue,pDomainId)
		if pValue="" {
			set pSC = $$$ERROR($$$InvalidArgument), tUniId=-1
			quit
		}
		
		// first check if the entity already exists
		if ($length(pValue)>$$$IKHASHSIZE) {
			set tUniId = "", tHash = $zcrc(pValue,7)
			for {
				set tUniId = $order(^IRIS.IK.Mdt.UniValueHash(pDomainId, tHash, tUniId))
				quit:tUniId=""
				quit:(pValue=^IRIS.IK.Mdt.UniValueId(pDomainId,tUniId))
			}
			set tUniId=+tUniId
		} else {
			set tUniId = +$g(^IRIS.IK.Mdt.UniValue(pDomainId, " "_pValue))
		}
		quit:tUniId
		
		// we should lock for LOAD, as that's the lock taken by BuildGlobals' EntUni additions
		$$$IKLOCKX(pDomainId,^IRIS.IK.Mdt.UniValueId,pSC)
		
		// test again, it might have been added between the first check and the lock
		if ($length(pValue)>$$$IKHASHSIZE) {
			set tUniId = ""
			for {
				set tUniId = $order(^IRIS.IK.Mdt.UniValueHash(pDomainId, tHash, tUniId))
				quit:tUniId=""
				quit:(pValue=^IRIS.IK.Mdt.UniValueId(pDomainId,tUniId))
			}
			set tUniId=+tUniId
		} else {
			set tUniId = +$g(^IRIS.IK.Mdt.UniValue(pDomainId, " "_pValue))
		}
		if (tUniId) {
			$$$IKUNLOCK(pDomainId,^IRIS.IK.Mdt.UniValueId)
			quit 
		}
		
		set tTLevel = $tlevel
		try {
			tstart
	    
			set tUniId = $i(^IRIS.IK.Mdt.UniValueId(pDomainId))
			set ^IRIS.IK.Mdt.UniValueId(pDomainId, tUniId) = pValue
			
			if ($length(pValue)>$$$IKHASHSIZE) {
				set ^IRIS.IK.Mdt.UniValueHash(pDomainId, tHash, tUniId) = ""
			} else {
				set ^IRIS.IK.Mdt.UniValue(pDomainId, " "_pValue) = tUniId
			}
		
			tcommit
		} catch (e) {
			set pSC = e.AsStatus(), tUniId = -1
		}
		trollback:($tlevel>tTLevel) 1
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	$$$IKUNLOCK(pDomainId,^IRIS.IK.Mdt.UniValueId)
	quit tUniId
}

Parameter GetUniqueValuesRT = "value:%String,frequency:%Integer";

/// <p>Returns all the unique metadata values for field <var>pFieldName</var> in sources
/// satisfying the supplied filter, optionally sorted by value (<var>pSortType</var> = "VALUE")
/// or frequency (<var>pSortType</var> = "FREQUENCY"). The returned frequency represents the
/// number of sources with this metadata value (satisfying the filter).</p>
/// <p>NOTE: sorting by value is only precise up to the 150 first characters</p>
ClassMethod GetUniqueValues(ByRef pResult, pDomainId As %Integer, pFieldName As %String, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pSortType As %String = "") As %Status
{
	$$$IKQBEGIN(pResult,"")
    $$$CHECKDOMAINEXISTS(pDomainId)
    $$$IKCHECKNOTNULL(pFieldName)
    
	// BDB397 - case insensitive names
	set tNameIndex = $s($$$IKVERSIONATLEAST(pDomainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(pFieldName), 1:pFieldName)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.Field,pDomainId,tNameIndex,tFieldId,$$$IKMDFieldDoesNotExistE)
    
    quit ..GetUniqueValuesById(.pResult, pDomainId, tFieldId, pPage, pPageSize, pFilter, pSortType)
}

Parameter GetUniqueValuesByIdRT = "value:%String,frequency:%Integer";

/// <p>Returns all the unique metadata values for field <var>pFieldId</var> in sources
/// satisfying the supplied filter, optionally sorted by value (<var>pSortType</var> = "VALUE")
/// or frequency (<var>pSortType</var> = "FREQUENCY"). The returned frequency represents the
/// number of sources with this metadata value (satisfying the filter).</p>
/// <p>NOTE: sorting by value is only precise up to the 150 first characters</p>
ClassMethod GetUniqueValuesById(ByRef pResult, pDomainId As %Integer, pFieldId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pSortType As %String = "") As %Status
{
	$$$IKQBEGINTRY(pResult,"^||%IK.TruncId,^||%IK.TruncHash,^||%IK.TruncFreq,^||%IK.Sort",tSC)
    $$$CHECKDOMAINEXISTSX(pDomainId,tSC)
    $$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
    $$$IKCHECKIDEXISTSX(^IRIS.IK.Mdt.FieldId,pDomainId,+pFieldId,tField,$$$IKMDFieldDoesNotExist,tSC)
    
    $$$IKQRCCHECK(pDomainId,pFilter,"GetUniqueValuesById",$lb(pDomainId,pFieldId,,,pFilter,pSortType),pPage,pPageSize,pResult)
    
    set tStorage = $list(tField,4)
    set gIndex = $case(tStorage, $$$MDSTNORMAL:"^IRIS.IK.Mdt.ValueToSrc", 
    							 $$$MDSTBITMAP:"^IRIS.IK.Mdt.ValueToSrcBit",
    							 $$$MDSTCOMPRESS:"^IRIS.IK.Mdt.UniValueToSrc", 
    							 $$$MDSTCOMPRESSBITMAP:"^IRIS.IK.Mdt.UniValueToSrcBit")
    
    if ((tStorage = $$$MDSTCOMPRESS) || (tStorage = $$$MDSTCOMPRESSBITMAP)) {
	    
	   set tValueId = ""
	   for {
		   set tValueId = $order(@gIndex@(pDomainId, pFieldId, tValueId))
		   quit:tValueId=""
		   
		   set tFreq = 0
		   if (tStorage = $$$MDSTCOMPRESS) {
			   
			   set tSrcId = ""
			   for {
				   set tSrcId = $order(@gIndex@(pDomainId, pFieldId, tValueId, tSrcId))
				   quit:tSrcId=""
				   continue:$isobject(pFilter)&&'pFilter.IsFiltered(tSrcId)
				   set x = $i(tFreq)
			   }
			   
		   } else {
			   
			   set tSrcOff = ""
			   for {
				   set tSrcOff = $order(@gIndex@(pDomainId, pFieldId, tValueId, tSrcOff), 1, tSrcBits)
				   quit:tSrcOff=""
				   
				   if $isobject(pFilter) {
					   set tFilterBits = pFilter.GetSourceFilter(tSrcOff)
					   set tSrcBits = $bitlogic(tSrcBits & tFilterBits)
				   }
				   
				   set tFreq = tFreq + $bitcount(tSrcBits,1)
			   }
		   }
		   
		   continue:'tFreq
		   set tValue = ^IRIS.IK.Mdt.UniValueId(pDomainId, tValueId)
		   set tSort = $case($$$UPPER(pSortType), "FREQUENCY":-tFreq, "VALUE":" "_$e(tValue,1,150), :$i(tCount))
		   set ^||%IK.Sort(tSort,$i(^||%IK.Sort(tSort))) = $lb(tValue,tFreq)
		   
	   }
	    
    } else {
	    
	    set tValue = ""
	    for {
	        set tValue = $order(@gIndex@(pDomainId, pFieldId, tValue))
	        quit:tValue=""
	    
	    	// for non-truncated values, we can loop through them and calculate frequency
	        if ($d(@gIndex@(pDomainId, pFieldId, tValue, 0))) {
	    
	    		set tFreq = 0
	    		if (tStorage = $$$MDSTNORMAL) {
		    		set tSrcId = ""
		    		for {
			    		set tSrcId = $order(@gIndex@(pDomainId, pFieldId, tValue, 0, tSrcId))
			    		quit:tSrcId=""
			    		continue:$isobject(pFilter)&&'pFilter.IsFiltered(tSrcId)
			    		set x = $i(tFreq)
		    		}
	    		} else {
					set tSrcOff = ""
					for {
					   set tSrcOff = $order(@gIndex@(pDomainId, pFieldId, tValue, 0, tSrcOff), 1, tSrcBits)
					   quit:tSrcOff=""
					   
					   if $isobject(pFilter) {
						   set tFilterBits = pFilter.GetSourceFilter(tSrcOff)
						   set tSrcBits = $bitlogic(tSrcBits & tFilterBits)
					   }
					   
					   set tFreq = tFreq + $bitcount(tSrcBits,1)
					}
	    		}
	    		
			    continue:'tFreq
		        set tRealValue = ..DeNormalizeValue(tValue, tField)
			    set tSort = $case($$$UPPER(pSortType), "FREQUENCY":-tFreq, "VALUE":tValue, :$i(tCount))
			    set ^||%IK.Sort(tSort,$i(^||%IK.Sort(tSort))) = $lb(tRealValue,tFreq)
	        }
	    
	        // and for the truncated values, loop through all sources containing them and build
	        // a temporary hash index which we'll process afterwards
	        if ($d(@gIndex@(pDomainId, pFieldId, tValue, 1))) {
	        
		        if (tStorage = $$$MDSTBITMAP) {
		        
			        set tSrcOffset = ""
			        for {
				        set tSrcOffset = $order(@gIndex@(pDomainId, pFieldId, tValue, 1, tSrcOffset), 1, tSrcBits)
				        quit:tSrcOffset=""
				        
					    if $isobject(pFilter) {
						   set tFilterBits = pFilter.GetSourceFilter(tSrcOff)
						   set tSrcBits = $bitlogic(tSrcBits & tFilterBits)
					    }
			        
			            set tSrcPos = 0
				        for {
					        set tSrcPos = $bitfind(tSrcBits,1,tSrcPos+1)
					        quit:tSrcPos=0
				        
					        $$$IKGETIDOFFPOS(tSrcId,tSrcOffset,tSrcPos)
					        
					        set tFullValue = ^IRIS.IK.Mdt.Values(pDomainId, tSrcId, pFieldId)
					        set tHash = $zcrc(tFullValue,7)
					        
					        set tId = ""
					        for {
						        set tId = $order(^||%IK.TruncHash(tHash, tId))
						        quit:tId=""
						        quit:^||%IK.TruncId(tId)=tFullValue
					        }
					        if 'tId {
						        set tId = $i(^||%IK.TruncId), ^||%IK.TruncId(tId) = tFullValue
						        set ^||%IK.TruncHash(tHash,tId) = ""
					        }
					        set x = $i(^||%IK.TruncFreq(tId))
				        }
			        }
		        
		        } else {
		        
			        set tSrcId = ""
			        for {
				        set tSrcId = $order(@gIndex@(pDomainId, pFieldId, tValue, 1, tSrcId))
				        quit:tSrcId=""
				        
				        quit:$isobject(pFilter)&&'pFilter.IsFiltered(tSrcId)
		        
				        set tFullValue = ^IRIS.IK.Mdt.Values(pDomainId, tSrcId, pFieldId)
				        set tHash = $zcrc(tFullValue,7)
				        
				        set tId = ""
				        for {
					        set tId = $order(^||%IK.TruncHash(tHash, tId))
					        quit:tId=""
					        quit:^||%IK.TruncId(tId)=tFullValue
				        }
				        if 'tId {
					        set tId = $i(^||%IK.TruncId), ^||%IK.TruncId(tId) = tFullValue
					        set ^||%IK.TruncHash(tHash,tId) = ""
				        }
				        set x = $i(^||%IK.TruncFreq(tId))
			        }
		        }
	        }
	    }
	    
	    // now add whatever got truncated
	    set tId = ""
	    for {
		    set tId = $order(^||%IK.TruncId(tId), 1, tValue)
		    quit:tId=""
		    
		    set tFreq = ^||%IK.TruncFreq(tId)
		    set tSort = $case($$$UPPER(pSortType), "FREQUENCY":-tFreq, "VALUE":" "_$e(tValue,1,150), :$i(tCount))
		    set ^||%IK.Sort(tSort,$i(^||%IK.Sort(tSort))) = $lb(tValue,tFreq)
	    }
    }
    
    // now use the sorted global to build results
    $$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
    set tSC = ..CopyFromTempSortGlobal(.pResult,"^||%IK.Sort",tUsePaging,tFirst,tLast)
    
    $$$IKQRCSTORE(pDomainId,pFilter,"GetUniqueValuesById",$lb(pDomainId,pFieldId,,,pFilter,pSortType),pPage,pPageSize,pResult,tSC)
    
	$$$IKQENDCATCH(result,"^||%IK.TruncId,^||%IK.TruncHash,^||%IK.TruncFreq,^||%IK.Sort",tSC)
}

/// <p>Returns the number of unique metadata values for a given field <var>pFieldName</var> in
/// the sources satisfying the supplied filter, after normalization based on the field
/// specifications such as case sensitivity and data type.</p>
ClassMethod GetUniqueValueCount(pDomainId As %Integer, pFieldName As %String, pFilter As %iKnow.Filters.Filter = "", Output pSC = {$$$OK}) As %Integer
{
	set pSC = $$$OK
	$$$IKCHECKPRIVREADR(pSC,"")
    $$$CHECKDOMAINEXISTSR(pDomainId,pSC,"")
    $$$IKCHECKNOTNULLR(pFieldName,pSC,"")
    
	// BDB397 - case insensitive names
	set tNameIndex = $s($$$IKVERSIONATLEAST(pDomainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(pFieldName), 1:pFieldName)
    $$$IKCHECKIDEXISTS(^IRIS.IK.Mdt.Field,pDomainId,tNameIndex,tFieldId,$$$IKMDFieldDoesNotExistE)
    
    quit ..GetUniqueValueCountById(pDomainId, tFieldId, pFilter, .pSC)
}

/// <p>Returns the number of unique metadata values for a given field <var>pFieldId</var> in
/// the sources satisfying the supplied filter, after normalization based on the field
/// specifications such as case sensitivity and data type.</p>
ClassMethod GetUniqueValueCountById(pDomainId As %Integer, pFieldId As %Integer, pFilter As %iKnow.Filters.Filter = "", Output pSC As %Status = {$$$OK}) As %Status
{
	set pSC = $$$OK, tCount = ""
	try {
		$$$IKCHECKPRIVREADX(pSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,pSC)
		$$$IKQFILTEROBJECTX(pDomainId,pFilter,pSC)
    	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mdt.FieldId,pDomainId,+pFieldId,tField,$$$IKMDFieldDoesNotExist,pSC)
    	
    	$$$IKQRCCHECKSINGLE(pDomainId,pFilter,"GetUniqueValueCountById",$lb(pDomainId,pFieldId,pFilter),tCount)
    	
    	set tStorage = $li(tField,4)
	    set gIndex = $case(tStorage, $$$MDSTNORMAL:"^IRIS.IK.Mdt.ValueToSrc", 
	    							 $$$MDSTBITMAP:"^IRIS.IK.Mdt.ValueToSrcBit",
	    							 $$$MDSTCOMPRESS:"^IRIS.IK.Mdt.UniValueToSrc", 
	    							 $$$MDSTCOMPRESSBITMAP:"^IRIS.IK.Mdt.UniValueToSrcBit")
	    
	    set tCount = 0
	    if ((tStorage = $$$MDSTCOMPRESS) || (tStorage = $$$MDSTCOMPRESSBITMAP)) {
		    
		   set tValueId = ""
		   for {
			   set tValueId = $order(@gIndex@(pDomainId, pFieldId, tValueId))
			   quit:tValueId=""
			   
			   set tFreq = 0
			   if (tStorage = $$$MDSTCOMPRESS) {
				   
				   set tSrcId = ""
				   for {
					   set tSrcId = $order(@gIndex@(pDomainId, pFieldId, tValueId, tSrcId))
					   quit:tSrcId=""
					   continue:$isobject(pFilter)&&'pFilter.IsFiltered(tSrcId)
					   set x = $i(tCount)
					   quit
				   }
				   
			   } else {
				   
				   set tSrcOff = ""
				   for {
					   set tSrcOff = $order(@gIndex@(pDomainId, pFieldId, tValueId, tSrcOff), 1, tSrcBits)
					   quit:tSrcOff=""
					   
					   if $isobject(pFilter) {
						   set tFilterBits = pFilter.GetSourceFilter(tSrcOff)
						   set tSrcBits = $bitlogic(tSrcBits & tFilterBits)
					   }
					   continue:'$bitcount(tSrcBits,1)
					   set x = $i(tCount)
					   quit
				   }
			   }
		   }
		    
	    } else {
		    
		    set tValue = ""
		    for {
		        set tValue = $order(@gIndex@(pDomainId, pFieldId, tValue))
		        quit:tValue=""
		    
		    	// for non-truncated values, we can loop through them and calculate frequency
		        if ($d(@gIndex@(pDomainId, pFieldId, tValue, 0))) {
		    
		    		if (tStorage = $$$MDSTNORMAL) {
			    		set tSrcId = ""
			    		for {
				    		set tSrcId = $order(@gIndex@(pDomainId, pFieldId, tValue, 0, tSrcId))
				    		quit:tSrcId=""
				    		continue:$isobject(pFilter)&&'pFilter.IsFiltered(tSrcId)
				    		set x = $i(tCount)
				    		quit
			    		}
		    		} else {
						set tSrcOff = ""
						for {
						   set tSrcOff = $order(@gIndex@(pDomainId, pFieldId, tValue, 0, tSrcOff), 1, tSrcBits)
						   quit:tSrcOff=""
						   
						   if $isobject(pFilter) {
							   set tFilterBits = pFilter.GetSourceFilter(tSrcOff)
							   set tSrcBits = $bitlogic(tSrcBits & tFilterBits)
						   }
						   continue:'$bitcount(tSrcBits,1)
						   set x = $i(tCount)
						   quit
						}
		    		}
		        }
		    
		        // and for the truncated values, loop through all sources containing them and build
		        // a temporary hash index which we'll process afterwards
		        if ($d(@gIndex@(pDomainId, pFieldId, tValue, 1))) {
		        
			        if (tStorage = $$$MDSTBITMAP) {
			        
				        set tSrcOffset = ""
				        for {
					        set tSrcOffset = $order(@gIndex@(pDomainId, pFieldId, tValue, 1, tSrcOffset), 1, tSrcBits)
					        quit:tSrcOffset=""
					        
						    if $isobject(pFilter) {
							   set tFilterBits = pFilter.GetSourceFilter(tSrcOff)
							   set tSrcBits = $bitlogic(tSrcBits & tFilterBits)
						    }
				        
				            set tSrcPos = 0
					        for {
						        set tSrcPos = $bitfind(tSrcBits,1,tSrcPos+1)
						        quit:tSrcPos=0
					        
						        $$$IKGETIDOFFPOS(tSrcId,tSrcOffset,tSrcPos)
						        
						        set tFullValue = ^IRIS.IK.Mdt.Values(pDomainId, tSrcId, pFieldId)
						        set tHash = $zcrc(tFullValue,7)
						        
						        set tId = ""
						        for {
							        set tId = $order(^||%IK.TruncHash(tHash, tId), 1, tIdValue)
							        quit:tId=""
							        quit:tIdValue=tFullValue
						        }
						        if 'tId {
							        set tId = $i(^||%IK.TruncHash)
							        set ^||%IK.TruncHash(tHash,tId) = tFullValue
							        set x = $i(tCount)
						        }
					        }
				        }
			        
			        } else {
			        
				        set tSrcId = ""
				        for {
					        set tSrcId = $order(@gIndex@(pDomainId, pFieldId, tValue, 1, tSrcId))
					        quit:tSrcId=""
					        
					        quit:$isobject(pFilter)&&'pFilter.IsFiltered(tSrcId)
			        
					        set tFullValue = ^IRIS.IK.Mdt.Values(pDomainId, tSrcId, pFieldId)
					        set tHash = $zcrc(tFullValue,7)
					        
					        set tId = ""
					        for {
						        set tId = $order(^||%IK.TruncHash(tHash, tId), 1, tIdValue)
						        quit:tId=""
						        quit:tIdValue=tFullValue
					        }
					        if 'tId {
						        set tId = $i(^||%IK.TruncHash)
						        set ^||%IK.TruncHash(tHash,tId) = tFullValue
						        set x = $i(tCount)
					        }
				        }
			        }
		        }
		    }
	    }
		
    	$$$IKQRCSTORESINGLE(pDomainId,pFilter,"GetUniqueValueCountById",$lb(pDomainId,pFieldId,pFilter),tCount,pSC)
    	
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tCount
}

/// <p>Returns the "spread" of metadata values (number of distinct values) for field
/// <var>pFieldName</var> for the entities in <var>pEntityList</var>, in the sources satisfying
/// <var>pFilter</var>. When specifying multiple entities, sources (and their metadata values)
/// are included based on the value of <var>pSetOp</var>: if <var>pSetOp</var> = $$$UNION, only
/// one entity has to be present (default), if <var>pSetOp</var> = $$$INTERSECT, all of them
/// need to be present.</p>
ClassMethod GetMetaSpreadByEntities(pDomainId As %Integer, pFieldName As %String, pEntityList As %List, pFilter As %iKnow.Filters.Filter = "", pSetOp As %Integer = {$$$UNION}, Output pSC As %Status = {$$$OK}) As %Integer
{
	set pSC = $$$OK, tSpread = ""
	try {
		$$$IKCHECKPRIVREADX(pSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,pSC)
    	$$$IKCHECKNOTNULLX(pFieldName,pSC)
    	
		// BDB397 - case insensitive names
		set tNameIndex = $s($$$IKVERSIONATLEAST(pDomainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(pFieldName), 1:pFieldName)
    	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mdt.Field,pDomainId,tNameIndex,tFieldId,$$$IKMDFieldDoesNotExistE,pSC)
		
		$$$IKENSURELISTSTR(pEntityList)
		set pSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(pDomainId, pEntityList, .tIds)
		quit:$$$ISERR(pSC)
		
		set tSpread = ..GetMetaSpreadInternal(pDomainId, tFieldId, "ENTITY", .tIds, pFilter, pSetOp, .pSC)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tSpread
}

/// <p>Returns the "spread" of metadata values (number of distinct values) for field
/// <var>pFieldName</var> for the entities in <var>pEntityIdList</var>, in the sources satisfying
/// <var>pFilter</var>. When specifying multiple entities, sources (and their metadata values)
/// are included based on the value of <var>pSetOp</var>: if <var>pSetOp</var> = $$$UNION, only
/// one entity has to be present (default), if <var>pSetOp</var> = $$$INTERSECT, all of them
/// need to be present.</p>
ClassMethod GetMetaSpreadByEntityIds(pDomainId As %Integer, pFieldName As %String, pEntityIdList As %List, pFilter As %iKnow.Filters.Filter = "", pSetOp As %Integer = {$$$UNION}, Output pSC As %Status = {$$$OK}) As %Integer
{
	set pSC = $$$OK, tSpread = ""
	try {
		$$$IKCHECKPRIVREADX(pSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,pSC)
    	$$$IKCHECKNOTNULLX(pFieldName,pSC)
    	
		// BDB397 - case insensitive names
		set tNameIndex = $s($$$IKVERSIONATLEAST(pDomainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(pFieldName), 1:pFieldName)
    	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mdt.Field,pDomainId,tNameIndex,tFieldId,$$$IKMDFieldDoesNotExistE,pSC)
		
		$$$IKENSURELISTSTR(pEntityIdList)
		set pSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(pDomainId, pEntityIdList, .tIds)
		quit:$$$ISERR(pSC)
		
		set tSpread = ..GetMetaSpreadInternal(pDomainId, tFieldId, "ENTITY", .tIds, pFilter, pSetOp, .pSC)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tSpread
}

ClassMethod GetMetaSpreadInternal(pDomainId As %Integer, pFieldId As %Integer, pType As %String = "ENTITY", ByRef pIds, pFilter As %iKnow.Filters.Filter = "", pSetOp As %Integer = {$$$UNION}, Output pSC As %Status = {$$$OK}) As %Integer
{
	set pSC = $$$OK, tSpread = ""
	try {
		$$$IKCHECKPRIVREADX(pSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,pSC)
		$$$IKQFILTEROBJECTX(pDomainId,pFilter,pSC)
    	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mdt.FieldId,pDomainId,+pFieldId,tField,$$$IKMDFieldDoesNotExist,pSC)
    	
		quit:'$d(pIds)
		
		kill ^||%IK.SrcBits
		set gIdToSrcBit = $case($$$UPPER(pType), "ENTITY":"^IRIS.IK.EntUniToSrcBit", "CRC":"^IRIS.IK.CrcUniToSrcBit", "CC":"^IRIS.IK.CcUniToSrcBit")
		set tId = "", tFirst = 1
		for {
			set tId = $order(pIds(tId))
			quit:tId=""
			
			if tFirst || (pSetOp=$$$UNION) {
				set gFrom = $name(@gIdToSrcBit@(pDomainId, tId))
				$$$IKMERGEBITSOR(gFrom,"^||%IK.SrcBits")
			} else {
				$$$IKMERGEBITSAND(gFrom,"^||%IK.SrcBits")
			}
			
			set tFirst=0
		}
		
		set:$isobject(pFilter) pSC = pFilter.MergeBits("^||%IK.SrcBits")
		
		set tNewFilter = ##class(%iKnow.Filters.BitmapFilter).%New(pDomainId,"^||%IK.SrcBits")
		set tSpread = ..GetUniqueValueCountById(pDomainId, pFieldId, tNewFilter, .pSC)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tSpread
}

/// <p>Create a <class>%iKnow.Filters.Filter</class> instance that filters sources according to
/// the given criteria, using the filter class compatible with this <class>%iKnow.Queries.MetadataI</class>
/// implementation.</p>
/// <p>For the default MetadataAPI, this is a <class>%iKnow.Filters.SimpleMetadataFilter</class> instance.</p>
ClassMethod CreateFilter(pDomainId As %Integer, pFieldName As %String, pOperator As %String, pValue As %String, Output pSC As %Status = {$$$OK}) As %iKnow.Filters.Filter
{
	set tFilter = ##class(%iKnow.Filters.SimpleMetadataFilter).%New(pDomainId, pFieldName, pOperator, pValue)
	set pSC = $s($isobject(tFilter):$$$OK, 1:%objlasterror)
	quit tFilter
}

/// Returns some basic facts about metadata field <var>pFieldName</var>
ClassMethod GetFieldInfo(pDomainId As %Integer, pFieldName As %String, Output pInfo) As %Status
{
	kill pInfo
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVREADX(tSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		
		set tFieldId = ..GetFieldId(pDomainId, pFieldName, .tSC)
		quit:$$$ISERR(tSC)
		if 'tFieldId {
			set tSC = $$$ERROR($$$IKMDFieldDoesNotExistE, pFieldName)
			quit
		}
		
		set tSC = ..GetFieldInfoById(pDomainId, tFieldId, .pInfo)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns some basic facts about metadata field with ID <var>pFieldId</var>
ClassMethod GetFieldInfoById(pDomainId As %Integer, pFieldId As %String, Output pInfo) As %Status
{
	kill pInfo
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVREADX(tSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		
		set tField = ##class(%iKnow.Objects.MetadataField).PKINDEXOpen(pDomainId, pFieldId)
		if (tField="") {
			set tSC = $$$ERROR($$$IKMDFieldDoesNotExist, pFieldId)
			quit
		}
		
		for p = "StorageType", "DataType", "Name", "SupportedOperators", "IsCaseSensitive", "HasBitstringStorage" {
			set pInfo(p) = $property(tField, p)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Populates any number of metadata fields with the values retrieved based on the values 
/// retrieved by a query <var>pSQL</var>. The query should at least return a column named 
/// "SourceId" containing iKnow Source IDs or a column named "ExternalId" containing the full
/// External IDs of the sources whose metadata fields are to be updated. All other columns with
/// names matching existing metadata fields for this domain will be used to update or set the
/// fields' values for each record. Columns whose name does not correspond to an existing metadata
/// field will be ignored.</p>
/// <p>Sample query:
/// <blockquote><tt>SELECT ':SQL:' || YEAR(EventDate) || ':' || EventId As ExternalId, InjuriesHighest, YEAR(EventDate) "Year" FROM Aviation.Event</tt></blockquote>
/// This will update the InjuriesHighest and Year fields (if they exist).
ClassMethod PopulateFromSQL(pDomainId As %Integer, pSQL As %String, pIgnoreErrors As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		$$$IKCHECKPRIVWRITEX(tSC)
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(pSQL)
		quit:$$$ISERR(tSC)
		
		if (tStatement.%Metadata.statementType'=1) {
			set tSC = $$$ERROR($$$GeneralError, "Only SELECT statements allowed here")
			quit
		}
		
		// find interesting column indices
		kill tFields
		set tSourceIdCol = 0, tExternalIdCol = 0
		for i = 1:1:tStatement.%Metadata.columnCount {
			set tColName = tStatement.%Metadata.columns.GetAt(i).colName
			if ($$$UPPER(tColName) = "SOURCEID") {
				set tSourceIdCol = i
			} elseif ($$$UPPER(tColName) = "EXTERNALID") {
				set tExternalIdCol = i
			} else {
				set tFieldId = ..GetFieldId(pDomainId, tColName)
				continue:tFieldId<=0
				set tFields(i) = tFieldId
			}
		}
		if 'tSourceIdCol && 'tExternalIdCol {
			set tSC = $$$ERROR($$$GeneralError, "Query must return either a SourceID or ExternalID column")
			quit
		}
		
		set tResult = tStatement.%Execute()
		while tResult.%Next() {
			if (tSourceIdCol) {
				set tSourceId = tResult.%GetData(tSourceIdCol)
			} else {
				set tExternalId = tResult.%GetData(tExternalIdCol)
				set tSourceId = ##class(%iKnow.Queries.SourceAPI).GetSourceId(pDomainId, tExternalId, .tSC2)
				
				if (tSourceId<=0) {
					continue:pIgnoreErrors
					set tSC = tSC2
					quit
				}
			}
			
			set tColIndex = ""
			for {
				set tColIndex = $order(tFields(tColIndex), 1, tFieldId)
				quit:tColIndex=""
				
				set tSC2 = ..SetValueById(pDomainId, tFieldId, tSourceId, tResult.%GetData(tColIndex))
				if $$$ISERR(tSC2) && 'pIgnoreErrors {
					set tSC = tSC2
					quit
				}
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
