/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (LDAPCli, %syLDAPFunc)

/// WARNING: This Class and its methods has been deprecated, please use the %SYS.LDAP class.
/// <br><br><br>
/// Attribute Value. Used by PropList, or Entry classes. 
/// See <class>%Net.LDAP.Client.PropList</class><b>.Insert()</b> or <class>%Net.LDAP.Client.Entry</class><b>.GetAttribValue()</b> methods.
Class %Net.LDAP.Client.ValueList Extends (%RegisteredObject, %Collection.AbstractIterator) [ Deprecated, Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// Parent Session
Property Parent As Session [ Internal ];

/// List of values
Property ValueList As %List [ Internal ];

/// List of types
Property TypeList As %String [ Internal ];

/// Big object ID
/// Note: PropList may inbed this value list and increment the the reference to this objID
Property BigObjectID As %Integer [ Internal ];

/// If Values is binary
Property Binary As %Boolean [ Internal ];

/// Destructor
Method %OnClose() As %Status [ Internal ]
{
 i $$$USELDAPCLI {

	d:((+..BigObjectID'=0)&&($IsObject(..Parent))&&($$$FNRelBigObj'=0)) $ZF(-5, $$$LDAPLibID, $$$FNRelBigObj, ..BigObjectID)
	q $$$OK
 } else {
 q $$$OK
 }
}

Method Init(ValueList As %List, TypeList As %List, ObjID As %Integer, binary As %Boolean) As %Boolean [ Internal ]
{
#;	w "ValueList",! zzdump ValueList
#;	w "TypeList",! zzdump TypeList
  	s ..ValueList=ValueList
  	s ..TypeList=TypeList
  	s ..BigObjectID=ObjID
  	s ..Binary=binary
  	q $$$OK
}

Method AllocBigObj() As %Integer [ Internal ]
{
 i $$$USELDAPCLI {
	s:($IsObject(..Parent) && (+..BigObjectID=0)) ..BigObjectID=$ZF(-5, $$$LDAPLibID, $$$FNNewBigObj)
	q ..BigObjectID
 } else {
 q 0
 }
}

/// Get the i-th value.
Method GetValue(index As %Integer) As %RawString
{
  	s tmp=$list(..ValueList,index)
  	s type=..GetType(index)
	if ($ZBOOLEAN(type,$$$LDAPLargeValMask,$$$booland)) {
		s id=$ZLA(tmp,1)
		s len=$ZLA(tmp,5)
		s offset=$ZLA(tmp,9)
		if (id '= $$$LDAPUseVLObjID) $$$LDAPRaiseException
		if ((len < 8000) || ((..Binary)&&(len < 32000))) {
			s tmp=$ZF(-5, $$$LDAPLibID, $$$FNGetSubObj, ..BigObjectID,offset,len)
			if (('..Binary)&&($a(tmp,$l(tmp))=0)) s tmp=$$$ConvertPlatValStr(tmp)
			q tmp
		} else {
			; *************************************************************
			; New a stream FILE obj, and return the value in the stream
			; *************************************************************
			s comp=$$$OK
			Set stream=##class(%FileCharacterStream).%New()
			s comp=stream.TranslateTableSet("RAW")
			q:(comp'=$$$OK) comp
			while (len > 0) {
				if (len > $$$LDAPBigObjTranLen) {
					s readlen=$$$LDAPBigObjTranLen
				} else {
					s readlen=len
				}
				s tmp=$ZF(-5, $$$LDAPLibID, $$$FNGetSubObj, ..BigObjectID,offset,readlen)
				q:(tmp="")
				s comp=stream.Write(tmp)
				q:(comp'=$$$OK)
				s len=len-$l(tmp)
				s offset=offset+$l(tmp)
			}
			s:(comp=$$$OK) comp=stream.Flush()
			s:(comp=$$$OK) comp=stream.Rewind()
			q:(comp'=$$$OK) comp
			if ('..Binary) s comp=stream.TranslateTableSet("UTF8")
			q stream
		}
	} elseif (type'=-1) {
  		; if not binary (string) convert from UTF8
  		q:(('..Binary)&&($a(tmp,$l(tmp))=0)) $$$ConvertPlatValStr(tmp)
  		q tmp
	}
 	q ""
}

/// Get partial value as %string. Use to extract large values.
/// Note start position is zero based!!
Method GetPartialValue(index As %Integer, StartPos As %Integer, NumBytes As %Integer = 32767) As %String
{
  	s tmp=$list(..ValueList,index)
  	s type=..GetType(index)
	if ($ZBOOLEAN(type,$$$LDAPLargeValMask,$$$booland) && ($l(tmp)=8)) {
		s id=$ZLA(tmp,1)
		s len=$ZLA(tmp,5)
		s offset=$ZLA(tmp,9)
		if (id '= $$$LDAPUseVLObjID) $$$LDAPRaiseException
		if ((StartPos >= len) || (NumBytes<1)) q ""
		s offset=offset+StartPos
		if ((len - StartPos) > NumBytes) s NumBytes=len-StartPos
		s tmp=$ZF(-5, $$$LDAPLibID, $$$FNGetSubObj, ..BigObjectID,offset,NumBytes)
		;; We cann't convert partila UTF8 string!!
		;; if ('..Binary) s tmp=$$$ConvertPlatValStr(tmp)
		#; If last chunk fetch, check and strip the nil terminator!!
		if ((len <= (NumBytes+StartPos)) && ($a(tmp,$l(tmp))=0)) s tmp=$e(tmp,1,$l(tmp)-1)
		q tmp
	} else {
		// Binary is not set and it's a valid nil terminating str then convert
  		if (('..Binary)&&($a(tmp,$l(tmp))=0)) s tmp=$$$ConvertPlatValStr(tmp)
  		if ((StartPos + NumBytes) > $l(tmp)) s NumBytes=$l(tmp)-StartPos
  		s:(NumBytes<0) NumBytes=0
  		q $e(tmp,StartPos+1,StartPos+NumBytes)
	}
}

/// Returns true if the entry is a large obj.
Method IsLargeObj(index As %Integer) As %Boolean [ Internal ]
{
   q $ZBOOLEAN(GetType(index),$$$LDAPLargeValMask,$$$booland)
}

/// Get the i-th entry len.
Method GetLen(index As %Integer) As %Boolean
{
  	s type=..GetType(index)
	q:(type=-1) 0
  	s tmp=$list(..ValueList,index)
	if ($ZBOOLEAN(type,$$$LDAPLargeValMask,$$$booland) && ($l(tmp)=12)) {
		q $ZLA(tmp,5)
	} else {
		q $l(tmp)
	}
 	q 0
}

/// Get the i-th type.
Method GetType(index As %Integer) As %Integer [ Internal ]
{
  q $a(..TypeList,index)
}

/// Get the i-th value into a stream. Returns $$$OK on success.
Method GetValueInStream(index As %Integer, stream As %Library.AbstractStream) As %Status
{
	set offset=0
	; It will fetch sub chunks from mem and write to the passed stream.
	f  {
		; use total len as starting position
		Set x=..GetPartialValue(index, offset)
		s slen=$l(x)
		q:(slen=0)
		Set sc=stream.Write(x) 
		If $$$ISERR(sc) { 
			;; Add err hnndling
			goto failed
		}
		Set offset=offset+slen
	}
 	q $$$OK
failed
	q sc
}

/// Get number of value entries.
Method GetNumItems() As %Integer
{
	q $l(..TypeList)
}

/// Append a String(s) value.
Method InsertBytes(v... As %String) As %Boolean [ Internal ]
{
 i $$$USELDAPCLI {
	s comp = $$$OK
	for i=1:1:v {
		if (($l(v(i)) > $$$LDAPMaxValLen) ||
 			(($l(v(i)) + $l(..ValueList) + $l(..TypeList)) > $$$LDAPStartConserving)) {
#;			W "Insert bytes as big obj value len=",$l(v(i)),!
			s comp=..InsertBigStr(v(i))
			q:(comp'=$$$OK)
		} else {
#;			W "Insert byte len=",$l(v(i)),!
			if (..Binary) {
				s ..ValueList=..ValueList_$listbuild(v(i))
				s ..TypeList=..TypeList_$char($$$LDAPBinVal)
			} else {
				s ..ValueList=..ValueList_$listbuild($$$ConvertValStrPlat(v(i)))
				s ..TypeList=..TypeList_$char($$$LDAPStrVal)
			}
		}
	}
	q comp
 } else {
 s comp = $$$OK
 for i=1:1:v {
	if (..Binary) {
			s ..ValueList=..ValueList_$listbuild(v(i))
			s ..TypeList=..TypeList_$char($$$LDAPBinVal)
		} else {
			s ..ValueList=..ValueList_$listbuild($$$ConvertValStrPlat(v(i)))
			s ..TypeList=..TypeList_$char($$$LDAPStrVal)
		}
 }
 q comp
 }
}

/// Append a Big String as large value.
Method InsertBigStr(Value As %String) As %Status [ Internal ]
{
	If (..AllocBigObj()=0) q $$$ERROR($$$LDAPOutOfHeap)
	set index=..InsertBigObjRef()
	s comp=..InsertBigObj(Value,index,1)
	q comp
}

/// Allocate and init a Big Object in the value list.
Method InsertBigObjRef() As %Integer [ Internal ]
{
	
	s ..ValueList=..ValueList_$ListBuild($ZLCHAR($$$LDAPUseVLObjID)_$ZLCHAR(0)_$ZLCHAR(0))
	; w "InsertBigObjRef: Value list:",!
	; zzdump ..ValueList
	if (..Binary) {
		s objtype = $$$LDAPLargeBinVal
	} else {
		s objtype = $$$LDAPLargeStrVal
	}
	s ..TypeList=..TypeList_$char(objtype)
	q $l(..TypeList) ;return the index
}

/// Append passed value to the end of last big obj; Return false on failure.
/// Under construction (Not tested!!)
Method InsertBigObj(Value As %RawString, index As %Integer, last As %Integer = 0) As %Status [ Internal ]
{
	if ('..Binary) {
		if ('last) {
			s Value=$$$ConvertValStrPlatNoTerm(Value)
		} else {
			s Value=$$$ConvertValStrPlat(Value)
		}
	}
	s vallen=$l(Value)
	s tmp=$list(..ValueList,index)
	if ($L(tmp)'=12) $$$LDAPRaiseException
	s curlen=$ZLA(tmp,5)
	s offset=$ZLA(tmp,9)
	s newoff=$ZF(-5, $$$LDAPLibID, $$$FNAppendObj, ..BigObjectID, Value)
	if (newoff = -1) q $$$ERROR($$$LDAPOutOfHeap)
	if ('offset) s offset=newoff
	s curlen=curlen+vallen
	s $list(..ValueList,index)=$ZLCHAR($$$LDAPUseVLObjID)_$ZLCHAR(curlen)_$ZLCHAR(offset)
	; w "InsertBigObj: Value list:",!
	; zzdump ..ValueList
	q $$$OK
}

/// Append the contents of stream. Return the number of bytes written or $$$ISERR. 
Method InsertStream(stream As %Library.AbstractStream, len As %Integer = -1) As %Integer [ Internal ]
{
	set st="errrtrap"
	set written=0
	If (..AllocBigObj()=0) q $$$ERRORCODE($$$LDAPOutOfHeap)
	set comp=$$$OK
	set index=..InsertBigObjRef()
	while (len '= 0) {
		;Read the file in chuncks then insert to in mem obj desc.
		s xlen=len
		s:(len < 0 || len >32000) xlen=32000
		s x=stream.Read(xlen)
		s xlen=$l(x)
		q:(xlen=0)
		s written=written+xlen,len=len-xlen
		;Insert the desc to the value list.
		s comp=..InsertBigObj(x,index)
		q:(comp'=$$$OK)
	}
errtrap	
	q:(comp'=$$$OK) comp
	if ('..Binary) d ..InsertBigObj("",index,1) ; insert nil terminator
	q written
}

/// Append a value to this value list object. Return $$$OK status,
/// otherwise related error.
/// <p>If the value is an abstract stream it will append the stream to the value list.
/// If the value is an abstract iterator it will iterate and store its contents.
/// Otherwise it will append/store the passed data as string or binary value. </p>
Method Insert(Value As %RawString) As %Status
{
	if ($IsObject(Value)) {
		if (Value.%IsA("%Library.AbstractStream")) {
			q ..InsertStream(Value)
		}
		elseif (Value.%IsA("%Collection.AbstractIterator")) {
			s key=""
			f  {
				s sv=Value.GetNext(.key)
				if (key="") q
				d ..Insert(sv)
			}
		} else {
			;; Unexpected obj!!
			q $$$ERROR(LDAPUnknownObj)
		}
	} else {
		q ..InsertBytes(Value)
	}
}

/// Delete the i-th entry.
Method Delete(Index As %Integer) As %Boolean
{
	if (Index <= 0) q 0
	// 	Property ValueList As %List;
	set ..TypeList=$e(..TypeList,1,index-1)_$e(..TypeList,index+1,$l(..TypeList))
	set ..ValueList=$list(..ValueList,1,Index-1)_$list(..ValueList,Index+1,$ll(..ValueList))
}

/// Finds and returns the value associated with key. 
/// Null string if no value is found. 
Method GetAt(Key As %String = "") As %RawString
{
	 q ..GetValue(Key)
}

/// Moves to the next key at the location in the iteration, 
/// and returns the associated value.
/// If the key is a null string (""), it starts from the beginning. 
/// The value of key, which is passed by reference, is updated to the 
/// key value of the index or null string ("") if key is at
/// the end of the list. 
Method GetNext(ByRef key As %RawString) As %RawString
{
	set key=+key
	if (key <= 0) set key=1
	if (key > ..GetNumItems()) s key="" q ""
	set v=..GetValue(key),key=key+1
	q v
}

/// Returns the next key at the location in the iteration. 
/// If key is a null string (""), then Next returns the first index (one).
/// Return "" string if key is out of bounds.
Method Next(key As %RawString = "") As %RawString
{
	if (key="") q 1
	if (..GetType(+key)=-1) q ""
	q key+1
}

}
