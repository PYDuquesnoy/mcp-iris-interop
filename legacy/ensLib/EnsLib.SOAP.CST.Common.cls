/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occLG, %occMGInfo)

/// Counted String Tree wire transport format implementation
/// Version 1 - original version
/// Version 1.1 - add support for: CR/LF in End-of-Object marker, null object properties, binary Streams, array collections
///               no collection count for 'collection=stream', client-optional structure signature-match header
Class EnsLib.SOAP.CST.Common Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod exportCST(pObj As %RegisteredObject, Output pLen As %Integer, pVersion As %String = "1.1") As %Status
{
	Set $ZT="Trap",pLen=0
	Quit:$Case(pVersion,1:0,1.1:0,:1) $$$ERROR($$$EnsErrGeneral,"Got CST version '"_pVersion_"'; only versions up to 1.1 supported")
    Set tClassname=$classname(pObj)
    Set tSC=..writeString(pVersion_"|"_..getSignature(tClassname),.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
    Set tSC=..writeString($S(tClassname="EnsLib.SOAP.CST.Fault":"SOAP.Fault",1:tClassname),.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
    Set tSC=..writeObj(pObj,tClassname,.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
    Set tSC=..writeString("EoO."_$C(13,10,13,10),.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
	$$$catTRACE("parse","Wrote EoO marker; exportCST complete ("_pLen_")")
    Write *-3 ; flush
Exit
	Quit tSC
Trap
	Set $ZT="",tZE=$ZE, tSC=$S($g(tZE)'["<WRITE>":$$$EnsSystemError,1:$$$SystemError)
	Goto Exit
}

ClassMethod writeObj(pObj As %RegisteredObject, pClassname As %String, pVersion As %String, ByRef pLen As %Integer) As %Status
{
	Set tSC=$$$OK
	If pVersion'=1 {
		If '$IsObject(pObj) {
			Set tSC=..writeString("0",.pVersion,.pLen) ; Null Oref marker
			Quit tSC
		} Else {
			Set tSC=..writeString("",.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC ; Object marker
		}
	}	
	Set tClass=##class(%Dictionary.CompiledClass).%OpenId(pClassname) $$$ASSERT($IsObject(tClass))
	For iProp=1:1:tClass.Properties.Count() {
		Set tProp=tClass.Properties.GetAt(iProp)
		If '("%"=$E(tProp.Name)||tProp.Calculated||tProp.Transient||tProp.Private) {
			Set tSC=..writeProp(pObj,tProp,.pVersion,.pLen) Quit:$$$ISERR(tSC)
		}
	}
	Quit tSC
}

ClassMethod writeProp(pObj As %RegisteredObject, pProp As %Dictionary.CompiledProperty, pVersion As %String, ByRef pLen As %Integer) As %Status
{
	$$$catTRACE("parse","Writing property "_pProp.Name_" "_pProp.Collection_"/"_pProp.Type_":"_$$$getClassType(pProp.Type)_"-"_$$$mginfoClassKeyGet(pProp.Type,$$$cCLASSclasstype)_"/"_pProp.RuntimeType_":"_$$$getClassType(pProp.RuntimeType)_"-"_$$$mginfoClassKeyGet(pProp.RuntimeType,$$$cCLASSclasstype))
	If pProp.MultiDimensional {
		Quit $$$ERROR($$$EnsErrGeneral,"Multidimensional export not supported")
	} ElseIf $$$getClassType(pProp.RuntimeType)=$$$cCLASSCLASSTYPEDATATYPE {
		Set tSC=..writeString($property(pObj,pProp.Name),.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
	}
	ElseIf ""'=pProp.Collection {
		Set tColl=$property(pObj,pProp.Name)
		If "stream"'=pProp.Collection||(pVersion=1) {
			#; Not sure if Collection='stream' will ever happen in 5.2+
			Set tNum=tColl.Count()
			Set tSC=..writeString(tNum,.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
			$$$catTRACE("parse","Collection count = "_tNum)
		}
		If "list"=pProp.Collection {
			If $$$getClassType(pProp.Type)=$$$cCLASSCLASSTYPEDATATYPE {
				For i=1:1:tNum {
					Set tVal=tColl.GetAt(i)
					Set tSC=..writeString(tVal,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					$$$catTRACE("parse","-> Wrote "_pProp.Name_" list element("_i_") val ("_$L(tVal)_")='"_tVal_"'")
				}
			} Else {
				For i=1:1:tNum {
					Set tSC=..writeObj(tColl.GetAt(i),pProp.Type,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					$$$catTRACE("parse","-> Wrote "_pProp.Name_" list element("_i_") type '"_pProp.Type_"'")
				}
			}
			Quit:$$$ISERR(tSC) tSC
		} ElseIf "array"=pProp.Collection {
			Set tKey=""
			If $$$getClassType(pProp.Type)=$$$cCLASSCLASSTYPEDATATYPE {
				For i=1:1:tNum {
					Set tVal=tColl.GetNext(tKey)
					Set tSC=..writeString(tKey,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					Set tSC=..writeString(tVal,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					$$$catTRACE("parse","-> Wrote "_pProp.Name_" array element("_tKey_") val ("_$L(tVal)_")='"_tVal_"'")
				}
			} Else {
				For i=1:1:tNum {
					Set tVal=tColl.GetNext(tKey)
					Set tSC=..writeString(tKey,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					Set tSC=..writeObj(tVal,pProp.Type,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					$$$catTRACE("parse","-> Wrote "_pProp.Name_" list element("_tKey_") type '"_pProp.Type_"'")
				}
			}
			Quit:$$$ISERR(tSC) tSC
		} ElseIf "stream"=pProp.Collection {
			#; Not sure if Collection='stream' will ever happen in 5.2+
			Set tSC=..writeStream($property(pObj,pProp.Name),.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
		} Else {
			Quit $$$ERROR($$$EnsErrGeneral,"CST export collection type not supported: "_pProp.Collection)
		}
	} ElseIf $classmethod(pProp.RuntimeType,"%Extends","%Stream.Object")||$classmethod(pProp.RuntimeType,"%Extends","%IO.I.Stream") {
		Set tSC=..writeStream($property(pObj,pProp.Name),.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tSC=..writeObj($property(pObj,pProp.Name),pProp.Type,.pVersion,.pLen) Quit:$$$ISERR(tSC) tSC
	}
	Quit tSC
}

ClassMethod writeString(pStr As %String, pVersion As %String, ByRef pLen As %Integer) As %Status
{
	If ""=pStr Write $C(0)  Set pLen=pLen+1  Quit $$$OK
	Set tUTF=$ZCVT(pStr,"O","UTF8")
	While $L(tUTF)>=255 {
		Write $C(255)_$E(tUTF,1,255)  Set tUTF=$E(tUTF,255+1,$L(tUTF)), pLen=pLen+1+255
	}
	Set tLen=$L(tUTF)
    If tLen { Write $C(tLen)_tUTF  Set pLen=pLen+1+tLen }
	Else { Write $C(0)  Set pLen=pLen+1 }
	Quit $$$OK
}

ClassMethod writeStream(pStream As %Stream.Object, pVersion As %String, ByRef pLen As %Integer) As %Status
{
	#; Not sure if stream prop = NULLOREF will ever happen in 5.2+
	If '$$$IsdefObject(pStream)||(0=pStream.Size) Write $C(0)  Set pLen=pLen+1  Quit $$$OK
	Set pLen0=pLen
	If pVersion=1 {
		Set tIsBinary=0
	} ElseIf pStream.%Extends("%IO.I.Stream") {
		Set tIsBinary=$S('pStream.%Extends("%IO.IParts.ByteIO"):1, 1:"RawBytes"=pStream.CharEncoding)
	} Else {
		Set tIsBinary=(pStream.%Extends("%Stream.Object")&&("BINARYSTREAM"=$$$comClassKeyGet($classname(pStream),$$$cCLASSclientdatatype)))
	}
	If tIsBinary {
		Write "b"  Set pLen=pLen+1
		Set tOut=""  While 'pStream.AtEnd {
			Set tOut=tOut_pStream.Read(32000)
			While $L(tOut)>=255 {
				Write $C(255)_$E(tOut,1,255)  Set tOut=$E(tOut,255+1,$L(tOut)), pLen=pLen+1+255
			}
		}
	} Else {
		If pVersion>1 Write "c"  Set pLen=pLen+1
		Set tOut=""  While 'pStream.AtEnd {
			Set tOut=tOut_$ZCVT(pStream.Read(8000),"O","UTF8")
			While $L(tOut)>=255 {
				Write $C(255)_$E(tOut,1,255)  Set tOut=$E(tOut,255+1,$L(tOut)), pLen=pLen+1+255
			}
		}
	}
	Set tLen=$L(tOut)
    If tLen { Write $C(tLen)_tOut  Set pLen=pLen+1+tLen }
	Else { Write $C(0)  Set pLen=pLen+1 }
	$$$catTRACE("parse","Wrote "_$S(tIsBinary:"binary ",1:"")_$classname(pStream)_" ("_(pLen-pLen0)_")")
	Do pStream.Rewind()
	Quit $$$OK
}

ClassMethod importCST(pClassname As %String, Output pObj As %RegisteredObject, pTimeout As %Numeric = -1, Output pVersion As %String, Output pLen As %Integer) As %Status
{
#define CountTimeout pTimeout
#define StringTimeout pTimeout
	Set $ZT="Trap",pLen=0
	Kill pObj set pObj=$$$NULLOREF

	#; Read version/signature
	Set tSC=..readString(.tVerSig,pTimeout,1,.pLen)  Quit:$$$ISERR(tSC) tSC
	Set pVersion=$P(tVerSig,"|"), tSignature=$E(tVerSig,$L(pVersion)+2,$L(tVerSig))
	Quit:$Case(pVersion,1:0,1.1:0,:1) $$$ERROR($$$EnsErrGeneral,"Got CST version '"_pVersion_"'; only versions up to 1.1 supported")

	#; Read classname
	Set tSC=..readString(.tDeclClassname,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
	If tDeclClassname'=pClassname {
		If tDeclClassname'="SOAP.Fault" {
			Quit $$$ERROR($$$EnsErrGeneral,"Got CST classname '"_tDeclClassname_"'; does not match expected classname "_pClassname)
		} Else {
			Set pClassname="EnsLib.SOAP.CST.Fault"
		}
	}
	Quit:""'=tSignature&&(tSignature'=..getSignature(pClassname)) $$$ERROR($$$EnsErrGeneral,"Received signature "_..getSignature(tSignature,"b>s")_" for class '"_pClassname_"' does not match expected signature "_..getSignature(pClassname,"s"))
	#; Read properties
	Set tSC=..readObj(.tObj,pClassname,pTimeout,.pVersion,.pLen) Quit:$$$ISERR(tSC) tSC
	
	#; Read end marker
	Set tSC=..readString(.tEoO,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
	Quit:"EoO."'=$E($G(tEoO),1,$L("EoO.")) $$$ERROR($$$EnsErrGeneral,"Found '"_tEoO_"'("_tCount_"), not End-of-Object marker for CST import of "_tDeclClassname)
	If pClassname="EnsLib.SOAP.CST.Fault" {
		Set tSC=$$$ERROR($$$SOAPFaultReceived,tObj.FaultAsString())
	} Else {
		Set pObj=tObj
	}
	$$$catTRACE("parse","Found EoO marker; importCST complete ("_pLen_")")
Exit
	Quit tSC
Trap
	Set $ZT="",tZE=$ZE,tSC=$S($g(tZE)'["<READ>":$$$EnsSystemError,1:$$$SystemError)
	Goto Exit
}

ClassMethod readObj(ByRef pObj As %RegisteredObject, pClassname As %String, pTimeout As %Numeric, pVersion As %String, ByRef pLen As %Integer) As %Status
{
	If pVersion'=1 {
		Set tSC=..readString(.tVal,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC ; Object marker
		If $L(tVal) {
			Set pObj=$$$NULLOREF
			Quit:tVal'="0" $$$ERROR($$$EnsErrGeneral,"Unrecognized (null-)Object marker found for class "_pClassname_" at position "_pLen)
			Quit $$$OK
		}
		If '$$$IsdefObject(pObj) { Set pObj=$zobjclassmethod(pClassname,"%New")  $$$ASSERT($IsObject(pObj)) }
		Else { $$$ASSERT($classname(pObj)=pClassname) }
	}	
	Set tSC=$$$OK
	Set tClass=##class(%Dictionary.CompiledClass).%OpenId(pClassname) $$$ASSERT($IsObject(tClass))
	For iProp=1:1:tClass.Properties.Count() {
		Set tProp=tClass.Properties.GetAt(iProp)
		If '("%"=$E(tProp.Name)||tProp.Calculated||tProp.Transient||tProp.Private) {
			Set tSC=..readProp(pObj,tProp,pTimeout,.pVersion,.pLen) Quit:$$$ISERR(tSC)
		}
	}
	Quit tSC
}

ClassMethod readProp(pObj As %RegisteredObject, pProp As %Dictionary.CompiledProperty, pTimeout As %Numeric, pVersion As %String, ByRef pLen As %Integer) As %Status
{
#define CountTimeout pTimeout
#define StringTimeout pTimeout
	Set tSC=$$$OK
	$$$catTRACE("parse","Reading property "_pProp.Name_" "_pProp.Collection_"/"_pProp.Type_":"_$$$getClassType(pProp.Type)_"-"_$$$mginfoClassKeyGet(pProp.Type,$$$cCLASSclasstype)_"/"_pProp.RuntimeType_":"_$$$getClassType(pProp.RuntimeType)_"-"_$$$mginfoClassKeyGet(pProp.RuntimeType,$$$cCLASSclasstype))
	If pProp.MultiDimensional {
		Quit $$$OK ; Multidimensional import not supported
	} ElseIf $$$getClassType(pProp.RuntimeType)=$$$cCLASSCLASSTYPEDATATYPE {
		Set tSC=..readString(.tVal,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
		$$$catTRACE("parse","-> Read property "_pProp.Name_" val ("_$L(tVal)_")='"_tVal_"'")
		Set $zobjproperty(pObj,pProp.Name)=tVal
	}
	ElseIf ""'=pProp.Collection {
		Set tColl=$zobjproperty(pObj,pProp.Name)
		If "stream"'=pProp.Collection||(pVersion=1) {
			#; Not sure if Collection='stream' will ever happen in 5.2+
			Set tSC=..readString(.tNum,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
			Quit:""=$G(tNum)||(tNum'=+tNum) $$$ERROR($$$EnsErrGeneral,"Unrecognized CST collection count: '"_$G(tNum)_"'")
			$$$catTRACE("parse","Collection count = "_tNum)
		}
		If "list"=pProp.Collection {
			If $$$getClassType(pProp.Type)=$$$cCLASSCLASSTYPEDATATYPE {
				For i=1:1:tNum {
					Set tSC=..readString(.tVal,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					Set tSC=tColl.Insert(tVal)  Quit:$$$ISERR(tSC)
					$$$catTRACE("parse","-> Read "_pProp.Name_" list element("_i_") val ("_$L(tVal)_")='"_tVal_"'")
				}
			} Else {
				For i=1:1:tNum {
					Set tSC=..readObj(.tVal,pProp.Type,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					Set tSC=tColl.Insert(tVal)  Quit:$$$ISERR(tSC)
					$$$catTRACE("parse","-> Read "_pProp.Name_" list element("_i_") type '"_pProp.Type_"'")
				}
			}
		} ElseIf "array"=pProp.Collection {
			If $$$getClassType(pProp.Type)=$$$cCLASSCLASSTYPEDATATYPE {
				For i=1:1:tNum {
					Set tSC=..readString(.tKey,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					Set tSC=..readString(.tVal,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					Set tSC=tColl.SetValueAt(tVal,tKey)  Quit:$$$ISERR(tSC)
				}
			} Else {
				For i=1:1:tNum {
					Set tSC=..readString(.tKey,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					Set tSC=..readObj(.tVal,pProp.Type,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
					Set tSC=tColl.SetValueAt(tVal,tKey)  Quit:$$$ISERR(tSC)
				}
			}
		} ElseIf "stream"=pProp.Collection {
			#; Not sure if Collection='stream' will ever happen in 5.2+
			#; Not sure if stream prop = NULLOREF will ever happen in 5.2+
			Set tStream=tColl  Set:'$IsObject(tStream) tStream=$zobjclassmethod(pProp.RuntimeType,"%New"), $zobjproperty(pObj,pProp.Name)=tStream
			Set tSC=..readStream(tStream,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
		} Else {
			Quit $$$ERROR($$$EnsErrGeneral,"Unrecognized CST collection type: "_pProp.Collection)
		}
	} ElseIf $zobjclassmethod(pProp.RuntimeType,"%Extends","%Stream.Object")||$zobjclassmethod(pProp.RuntimeType,"%Extends","%IO.I.Stream") {
		If pVersion=1 {
			Set tSC=..readString(.tNum,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC)
			Quit:""=$G(tNum)||(tNum'=+tNum) $$$ERROR($$$EnsErrGeneral,"Unrecognized CST collection count: '"_$G(tNum)_"'")
			$$$catTRACE("parse","Collection count = "_tNum)
		}
		#; Not sure if stream prop = NULLOREF will ever happen in 5.2+
		Set tStream=$zobjproperty(pObj,pProp.Name)  Set:'$IsObject(tStream) tStream=$zobjclassmethod(pProp.RuntimeType,"%New"), $zobjproperty(pObj,pProp.Name)=tStream
		Set tSC=..readStream(tStream,pTimeout,.pVersion,.pLen)  Quit:$$$ISERR(tSC) tSC
	} Else {
		Set (tOVal,tVal)=$zobjproperty(pObj,pProp.Name)
		Set tSC=..readObj(.tVal,pProp.Type,pTimeout,.pVersion,.pLen) Quit:$$$ISERR(tSC) tSC
		Set:tVal'=tOVal $zobjproperty(pObj,pProp.Name)=tVal
	}
	Quit tSC
}

ClassMethod readString(Output pStr As %String, pTimeout As %Numeric, pVersion As %String, ByRef pLen As %Integer) As %Status
{
#define CountTimeout pTimeout
#define StringTimeout pTimeout
	Set tSC=$$$OK,tUTF="" While 1 {
		Read tCount#1:$$$CountTimeout Set tTimedOut='$T  If 'tTimedOut { Set pLen=pLen+1, tCount=$A(tCount)  If tCount>0 { Read tBytes#tCount:$$$StringTimeout  Set tTimedOut='$T, pLen=pLen+$L(tBytes) }} If tTimedOut Set tSC=$$$ERROR($$$EnsErrGeneral,"CST String Read timed out after reading '"_tUTF_" | "_$G(tBytes)_"' ("_tCount_")")
		Quit:tCount'>0||$$$ISERR(tSC)
		Set tUTF=tUTF_tBytes
		Quit:tCount<255
	}
	Quit:$$$ISERR(tSC) tSC
	Set pStr=$ZCVT(tUTF,"I","UTF8")
	Quit $$$OK
}

ClassMethod readStream(pStream As %Stream.Object, pTimeout As %Numeric, pVersion As %String, ByRef pLen As %Integer) As %Status
{
#define CountTimeout pTimeout
#define StringTimeout pTimeout
	If pVersion=1 {
		Set tBin="c"
	} Else {
		Read tBin#1:$$$CountTimeout Set tTimedOut='$T
		If tTimedOut Set tSC=$$$ERROR($$$EnsErrGeneral,"CST Stream Read timed out after reading 0 bytes")  Quit tSC
		Set pLen=pLen+1
		Quit:0=tBin $$$OK ; empty stream
	}
	If tBin="b" {
		Set:pStream.%Extends("%IO.IParts.ByteIO") pStream.CharEncoding="RawBytes"
		Set tSC=$$$OK While 1 {
			Read tCount#1:$$$CountTimeout Set tTimedOut='$T  If 'tTimedOut { Set pLen=pLen+1, tCount=$A(tCount)  If tCount>0 { Read tBytes#tCount:$$$StringTimeout  Set tTimedOut='$T, pLen=pLen+$L(tBytes) }} If tTimedOut Set tSC=$$$ERROR($$$EnsErrGeneral,"CST binary Stream Read timed out after reading ' "_$G(tBytes)_"' ("_tCount_")")
			Quit:tCount<=0||$$$ISERR(tSC)
			Do pStream.Write(tBytes)
			Quit:tCount<255
		}
		$$$catTRACE("parse","Read binary "_$classname(pStream)_" ("_pStream.Size_")")
	} ElseIf tBin="c" {
		Set tSC=$$$OK,tFile=##class(%IO.FileStream).%New()  $$$ASSERT($IsObject(tFile))
		Do tFile.Open(,"EW",,"RawBytes",.tSC)  Quit:$$$ISERR(tSC) tSC
		Set tSC=$$$OK While 1 {
			Read tCount#1:$$$CountTimeout Set tTimedOut='$T  If 'tTimedOut { Set pLen=pLen+1, tCount=$A(tCount)  If tCount>0 { Read tBytes#tCount:$$$StringTimeout  Set tTimedOut='$T, pLen=pLen+$L(tBytes) }} If tTimedOut Set tSC=$$$ERROR($$$EnsErrGeneral,"CST Stream Read timed out after reading ' "_$G(tBytes)_"' ("_tCount_")")
			Quit:tCount'>0||$$$ISERR(tSC)
			Do tFile.Write(tBytes,,.tSC)  Quit:$$$ISERR(tSC)
			Quit:tCount<255
		} Quit:$$$ISERR(tSC) tSC
		#; Do tFile.Flush(),tFile.Rewind()
		Do tFile.Close(.tSC)  Quit:('tSC) tSC
		Do tFile.Open(tFile.Name,"ER",,"UTF-8",.tSC)  Quit:('tSC) tSC
		$$$catTRACE("parse","Read UTF8 "_$classname(pStream)_" ("_tFile.ExternalByteSize_")")
		#;set tFile.TranslationTable="UTF8"
		Set tSC=pStream.CopyFrom(tFile)
		Do tFile.Close(.tSC)  Do ##class(%Library.File).Delete(tFile.Name)
	} Else {
		Set tSC=$$$ERROR($$$EnsErrGeneral,"CST Stream Read found unrecognized bin/char marker '"_tBin_"'")
	}
	Quit tSC
}

ClassMethod getSignature(pClass As %String, pSigType As %String = "b") As %String
{
	Quit $Case(pSigType
			,"b":$S($D(^Ens.CSTsignature(pClass,$$$comClassKeyGet(pClass,$$$cCLASShash)),tBin):tBin, 1:^Ens.CSTsignature(pClass_$E($$classString(pClass),0),$$$comClassKeyGet(pClass,$$$cCLASShash))) ; compressed binary given classname
			,"s":$S($D(^Ens.CSTsignature(pClass,$$$comClassKeyGet(pClass,$$$cCLASShash),"str"),tStr):tStr, 1:$$classString(pClass)) ; plaintext string given classname
			,"b>s":$$binToString(pClass) ; convert from compressed binary to plaintext string
			,"s>b":$$stringToBin(pClass) ; convert from plaintext string to compressed binary
			,:"error"
			)
classString(cls)
	Kill ^Ens.CSTsignature(cls)
	Quit:'##class(%Dictionary.CompiledClass).%ExistsId(cls) "" ; class doesn't exist
	Set str=$$objString(cls)
	Set ^Ens.CSTsignature(cls,$$$comClassKeyGet(cls,$$$cCLASShash),"str") = str
	Set ^Ens.CSTsignature(cls,$$$comClassKeyGet(cls,$$$cCLASShash)) = $$stringToBin(str)
	Quit str
binToString(bin)
	Set bstr="" For i=1:1:$L(bin) { Set h=$ZHex(+$A($E(bin,i)))  Set:$L(h)=1 h="0"_h
		Set bstr=bstr_$Case($E(h,1)
						,"0":"0000"
						,"1":"0001"
						,"2":"0010"
						,"3":"0011"
						,"4":"0100"
						,"5":"0101"
						,"6":"0110"
						,"7":"0111"
						,"8":"1000"
						,"9":"1001"
						,"A":"1010"
						,"B":"1011"
						,"C":"1100"
						,"D":"1101"
						,"E":"1110"
						,"F":"1111"
						)_
						$Case($E(h,2)
						,"0":"0000"
						,"1":"0001"
						,"2":"0010"
						,"3":"0011"
						,"4":"0100"
						,"5":"0101"
						,"6":"0110"
						,"7":"0111"
						,"8":"1000"
						,"9":"1001"
						,"A":"1010"
						,"B":"1011"
						,"C":"1100"
						,"D":"1101"
						,"E":"1110"
						,"F":"1111"
						)
	}
	Set str="",i=1 For { 
		Set c=$S($E(bstr,i,i-1+1)="1":"s"
				,$E(bstr,i,i-1+3)="010":"S"
				,$E(bstr,i,i-1+3)="011":"l"
				,$E(bstr,i,i-1+4)="0010":"L"
				,$E(bstr,i,i-1+4)="0011":"("
				,$E(bstr,i,i-1+5)="00010":")"
				,$E(bstr,i,i-1+5)="00011":"b"
				,$E(bstr,i,i-1+6)="000010":"a"
				,$E(bstr,i,i-1+6)="000011":"A"
				,$E(bstr,i,i-1+5)="0000010":"X"
				,+$E(bstr,i,$L(bstr))=0:""
				,1:""
		)
		S i=i+$TR(c,"sSlL()baAX","1334455667")
		Quit:""=c
		Set str=str_c
	}
	Quit str
stringToBin(str)
	Quit:""'=$TR(str,"sSlL()baAX") "" ; wrong input
	Set bstr=""  For i=1:1:$L(str) { Set c=$E(str,i)
		Set bstr=bstr_$Case(c
						,"s":"1"
						,"S":"010"
						,"l":"011"
						,"L":"0010"
						,"(":"0011"
						,")":"00010"
						,"b":"00011"
						,"a":"000010"
						,"A":"000011"
						,:"0000010")
	}
	Quit $$binStr(bstr)
binStr(bstr)
	Set bstr=bstr_"00000000"
	Set b="" For i=1:8:$L(bstr)-8 { Set b1=$E(bstr,i,i+3), b0=$E(bstr,i+4,i+7)
		Set b=b_$C($ZHex($Case(b1
					,"0000":"0"
					,"0001":"1"
					,"0010":"2"
					,"0011":"3"
					,"0100":"4"
					,"0101":"5"
					,"0110":"6"
					,"0111":"7"
					,"1000":"8"
					,"1001":"9"
					,"1010":"A"
					,"1011":"B"
					,"1100":"C"
					,"1101":"D"
					,"1110":"E"
					,"1111":"F"
					)
					_$Case(b0
					,"0000":"0"
					,"0001":"1"
					,"0010":"2"
					,"0011":"3"
					,"0100":"4"
					,"0101":"5"
					,"0110":"6"
					,"0111":"7"
					,"1000":"8"
					,"1001":"9"
					,"1010":"A"
					,"1011":"B"
					,"1100":"C"
					,"1101":"D"
					,"1110":"E"
					,"1111":"F"
					)))
	}
	Quit b
objString(cls)
	Set tClass=##class(%Dictionary.CompiledClass).%OpenId(cls) $$$ASSERT($IsObject(tClass))
	Set str="" For iProp=1:1:tClass.Properties.Count() {
		Set tProp=tClass.Properties.GetAt(iProp)
		If '("%"=$E(tProp.Name)||tProp.Calculated||tProp.Transient||tProp.Private) {
			Set str=str_$$propString(tProp)
		}
	}
	Quit str
propString(pProp)
	If pProp.MultiDimensional {
		Quit "" ; Multidimensional import not supported
	} ElseIf $$$getClassType(pProp.RuntimeType)=$$$cCLASSCLASSTYPEDATATYPE {
		Quit "s"
	}
	ElseIf ""'=pProp.Collection {
		If "list"=pProp.Collection {
			If $$$getClassType(pProp.Type)=$$$cCLASSCLASSTYPEDATATYPE {
				Set str="l"
			} Else {
				Set str="L("_$$objString(pProp.Type)_")"
			}
		} ElseIf "array"=pProp.Collection {
			If $$$getClassType(pProp.Type)=$$$cCLASSCLASSTYPEDATATYPE {
				Set str="a"
			} Else {
				Set str="A("_$$objString(pProp.Type)_")"
			}
		} ElseIf "stream"=pProp.Collection {
			Set str="S"
		} Else {
			Set str="X"
		}
	} ElseIf $zobjclassmethod(pProp.RuntimeType,"%Extends","%Stream.Object")||$zobjclassmethod(pProp.RuntimeType,"%Extends","%IO.I.Stream") {
			Set str="S"
	} Else {
		Set str="("_$$objString(pProp.Type)_")"
	}
	Quit str
}

}
