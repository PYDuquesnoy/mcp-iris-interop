/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

Class %IO.FileStream Extends (%IO.DeviceStream, %IO.IParts.CharacterSeekableIO) [ Inheritance = right, System = 2 ]
{

Property LastModified As %TimeStamp [ Calculated ];

/// Flag to control whether this file is deleted automatically when the 
/// file object instance is killed or goes out of scope. The default is 0,
/// and the file is NOT automatically deleted.
Property IsTemp As %Boolean;

/// Flag to control whether the stream object should maintain the <property>charposmap</property>
/// map between character positions and external byte positions when the file is opened using a 
/// multibyte character encoding. This flag is ignored when the character set only contains single-bye characters.
/// The flag is initialized to 0 when a file is not opened with the READ flag, but can always be modified
/// by the user after <method>Open</method> has been called.
Property BuildCharPosMap As %Boolean [ InitialExpression = 1 ];

Parameter DEFTEMPFILEEXT As STRING = "iostream";

Method LastModifiedGet() As %TimeStamp
{
	Quit ""
}

Parameter READ = "R";

Parameter WRITE = "W";

Parameter WRITEAPPEND = "A";

Parameter WRITENEWOVER = "N";

Parameter WRITENEWIFABSENT = "E";

Property %Mode As %String(TRUNCATE = 1) [ ReadOnly ];

Property %ReadLineMode As %Boolean [ ReadOnly ];

Property %RWMode As %Boolean [ Private ];

Parameter RWREADNODATA [ Final ] = 0;

Parameter RWREADNOTCHANGED [ Final ] = 1;

Parameter RWREADCHANGED [ Final ] = 2;

Parameter RWWRITE [ Final ] = 3;

/// Map of byte positions to character positions
Property charposmap [ MultiDimensional, Private ];

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Do:""'=$G(initvalue) ..Open(initvalue,,,,.tSC)
	Set ..charposmap(1)=1
	Quit $$$OK
}

Method Open(pName As %String = "", pMode As %String = "R", ByRef pTimeout As %Numeric = 0, pCharEncoding As %String = "Native", Output pSC As %Status) As %Boolean
{
	Set $ZT="Trap", tTimeout=pTimeout, pTimeout=0

	#; Must close before calling Open() again
	If ..IsOpen Set pSC = $$$ERROR($$$FileAlreadyOpen,..Name)  Quit 0

	If ""'=pName Kill ..charposmap Set ..Name=pName, ..charposmap(1)=1, ..IsTemp=0
	Set i%CharEncoding="x",..CharEncoding=pCharEncoding
	If ""=..TranslationTable Set pSC = $$$ERROR($$$ErrIONoCharTable,pCharEncoding) Quit 0

	#; Do not allow two objects to open the same file
	#;SML3019 ; Handle file name with ",".
	If $LISTFIND($LFS($translate($piece($View(-1,$job),"^",3),"*"),",",2),$ZU(12,..Name)) Set pSC=$$$ERROR($$$FileAlreadyOpen,..Name) Quit 0

	Set tMode=$ZCVT(pMode,"U")
	#; Add Write flag if it's implied
	Set:tMode'[..#WRITE&&(tMode[..#WRITENEWOVER||(tMode[..#WRITENEWIFABSENT)||(tMode[..#WRITEAPPEND)) tMode=tMode_..#WRITE
	#; force New if file doesn't exist and NewIfAbsent is asked for
	Set tExists=$S(""=..Name:0,1:##class(%File).Exists(..Name))
	Set:'tExists&&(tMode[..#WRITE)&&(tMode[..#WRITENEWIFABSENT)&&(tMode'[..#WRITENEWOVER) tMode=$TR(tMode,..#WRITENEWIFABSENT,..#WRITENEWOVER)
	#; fail if file doesn't exist and we're not going to try to create it
	If 'tExists&&(tMode'[..#WRITENEWOVER) Set pSC=$$$ERROR($$$FileDoesNotExist,..Name) Quit 0
	#; Add Read flag if it's implied
	Set:tMode'[..#WRITE&&(tMode'[..#READ) tMode=tMode_..#READ
	Set:""=..Name ..Name=..NewTempFilename(,1), ..IsTemp=1

	#; Open the file

	If tMode[..#WRITEAPPEND { Set tSize=##class(%File).GetFileSize(..Name), i%ExternalBytePosition=$S(tSize<0:1,1:tSize+1) }
	Else { Set i%ExternalBytePosition=1 }
	Set i%IsOpen=1, i%%Mode=tMode
	Set i%Position=i%ExternalBytePosition
	Set tOK=..reopen(1,1,..LineTerminator,.tTimeout) ; guess at default ReadLineMode
	Set pTimeout=tTimeout
	if 'tOK Set pSC=$$$ERROR($$$FileCanNotOpen,..Name), (i%IsOpen,i%ExternalBytePosition,i%Position)=0  Quit 0

	Set i%%Mode=$TR(i%%Mode,..#WRITENEWOVER) ; don't overwrite on reopen
	Set ..%RWMode=$S(tMode'[..#READ:..#RWWRITE,1:..#RWREADNOTCHANGED)
	If (tMode'[..#READ) Set ..BuildCharPosMap = 0
	Set pSC=$$$OK,i%AtEnd=0,i%%ReadLineMode=1  Quit 1
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Close ..Name
	Set i%IsOpen=0  Quit 0
}

Method reopen(pReadLineMode As %Boolean, pForce As %Boolean, pLineTerminator As %String, ByRef pTimeout As %Numeric = 0, ByRef pSize As %Integer = 0) As %Boolean [ Private ]
{
	Quit:'..IsOpen 0
	Quit:..%ReadLineMode=pReadLineMode&&'pForce&&('pReadLineMode||(..%CurrLineTerminator=pLineTerminator)) 1
	Close ..Name
	If (pSize) Set pSize = ##class(%File).GetFileSize(..Name)
	#; Go back to the beginning if file does not exist.  This can happen in Unix if a file is renamed and ..Name isn't changed. 
	If ('##class(%File).Exists(..Name)) {
		Set (i%ExternalBytePosition,i%Position) = 0
		Kill ..charposmap  Set ..charposmap(1)=1
	}
	Open ..Name:(..%Mode_$S(pReadLineMode:"S",1:"U")_"K\"_..TranslationTable_"\"::$S(pReadLineMode:pLineTerminator,1:"")):pTimeout  Set tOK=$Test
	Set i%%ReadLineMode=pReadLineMode, i%%CurrLineTerminator=pLineTerminator
	If tOK && (..ExternalBytePosition>1) {
		If '$$$isVMS { Set tIO=$IO  Use ..Name:(..ExternalBytePosition-1)  Set tOK=$Test Use tIO }
		Else { Set tOK=..Seek(..ExternalBytePosition) }
		#;Do:tOK ..initDeviceTranslationTable()
	}
	Quit tOK
}

/// Create a new, unused filename. By default, the returned filename will have no directory component
/// and will have the default file extension specified in <parameter>DEFTEMPFILEEXT</parameter>. 
/// If <var>tExt</var> is specified, this will be used as the file extension. If <var>pUseTempDir</var> is true, 
/// then the filename will include the current temporary directory for the namespace 
/// in which the method is called. If <var>pDirectory</var> is specified, the supplied directory name
/// will be used irrespective of the value of <var>pUseTempDir</var>.
ClassMethod NewTempFilename(tExt As %String = "", pUseTempDir As %Boolean = 0, pDirectory As %String = "") As %String
{
	Set tDir = ""
	If pDirectory '= "" {
		Set tDir = ##class(%File).NormalizeDirectory(pDirectory)
	}
	ElseIf pUseTempDir {
		Set tTempDir = $G(^%SYS("TempDir",$namespace), $$$SYSTempDir)
		Set tDir = ##class(%File).NormalizeDirectory(tTempDir)
	}
	Set tExtension = $S(tExt'="":tExt,1:..#DEFTEMPFILEEXT)
	#; create a reasonable short filename
	While 1 {
		Set tFilename=##class(%FileBinaryStream).NewFileName(tExtension)
		Set tFilename = tDir _ tFilename
		Quit:'##class(%File).Exists(tFilename)
	}
	#; Keep the extension of the stored file if we have one
	Quit tFilename
}

Method Close(Output pSC As %Status) As %Boolean
{
	Do:##super(.pSC)&&..IsTemp ##class(%File).Delete(..Name)
	Quit 1
}

Method Write(pData As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit
	If ..%Mode'[..#WRITE Set pSC=$$$ERROR($$$ErrIOFileNoWriteMode,..%Mode) Quit
	Set $ZT="Trap"
	If $$$isUNIX && ..%ReadLineMode && (pData [ $c(13)) {
		Do ..reopen(0,1,..LineTerminator)
	}
	Set tIO=$IO  Use ..Name  Write pData
	If '$$$isVMS { Set i%ExternalBytePosition=$ZSeek()+1 } Else { Set i%ExternalBytePosition=..Position+$L(pData) }
	Use tIO
	Set i%Position=..Position+$L(pData), pSC=$$$OK
	If ('..IsSingleByte)&&..BuildCharPosMap {
		Set ..charposmap(..ExternalBytePosition)=..Position
	}
	Set k=..ExternalBytePosition For  Set k=$O(..charposmap(k)) Quit:""=k  Kill ..charposmap(k) ; kill any map entries greater than write pos (??)
	Set:""'=pData ..%RWMode=..#RWWRITE
	Do:$G(pFlush,0) ..Flush() ; ..DefaultFlushOnWrite
	Quit
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Use tIO
	Quit
}

Method Read(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %String
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit ""
	If ..%Mode'[..#READ Set pSC=$$$ERROR($$$ErrIOFileNoReadMode,..%Mode) Quit ""
	Set pSC=$$$OK, tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	If 0=pMaxReadLen||..AtEnd Set pTimeout=0 Quit ""

	Do:..%ReadLineMode ..reopen(0,0,"")
	Set tEOFMode=$ZU(68,40) Do $ZU(68,40,1)
	Set tIO=$IO,tData=""
	Set $ZT="Trap"  Use ..Name
	If -1=pTimeout { Read tData#pMaxReadLen  Set tOK=1 }
	Else { Read tData#pMaxReadLen:pTimeout  Set tOK=$Test }
	Set:$ZEOF||(tOK&&($L(tData)<pMaxReadLen)) i%AtEnd=1
	Set:tOK||..AtEnd pTimeout=0
	Set:..%RWMode'=..#RWREADNOTCHANGED ..%RWMode=..#RWREADCHANGED
Exit
	Set i%Position=..Position+$L(tData)
	If '$$$isVMS { Set i%ExternalBytePosition=$ZSeek()+1 } Else { Set i%ExternalBytePosition=..Position }
	If ('..IsSingleByte)&&..BuildCharPosMap {
		Set ..charposmap(..ExternalBytePosition)=..Position
	}
	Use tIO
	Do $ZU(68,40,tEOFMode)
	Quit tData
Trap
	Set $ZT="",tZE=$ZE, tData=$G(tData) ; in case Read left it undefined
	If $E($G(tZE),1,11)="<ENDOFFILE>" Set i%AtEnd=1  Goto Exit
	Set pSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Set pTimeout=0
	Goto Exit
}

Method ReadLine(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status, ByRef pLineTerminator As %String = {..LineTerminator}) As %String
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit ""
	If ..%Mode'[..#READ Set pSC=$$$ERROR($$$ErrIOFileNoReadMode,..%Mode) Quit ""
	Set pSC=$$$OK, tZB=pLineTerminator, pLineTerminator=""
	Set tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	If 0=pMaxReadLen||..AtEnd Set pTimeout=0 Quit ""

	Do:'..%ReadLineMode||(tZB'=..%CurrLineTerminator) ..reopen(1,0,tZB)
	Set tEOFMode=$ZU(68,40) Do $ZU(68,40,1)
	Set tIO=$IO, tData=""
	Set $ZT="Trap"  Use ..Name
	If $$$isVMS {
		Set tMaxReadLen=pMaxReadLen
		Set tPrev="" For {
			If -1=pTimeout { Read tData#pMaxReadLen  Set tOK=1 }
			Else { Read tData#pMaxReadLen:pTimeout  Set tOK=$Test }
			Set pLineTerminator=$S($L(tData)=pMaxReadLen&&pMaxReadLen&&($ZB=$E(tData,*)):"", 1:$ZB)
			Set tData=tPrev_tData, tPrev=tData
			If ""'=pLineTerminator||'tOK||$ZEOF {
				Set:$L(tData)&&$ZEOF&&(""=pLineTerminator)&&(""=$TR(tData,$C(0))) tData=""
				Quit
			}
			Set pMaxReadLen=tMaxReadLen-$L(tData)
			Quit:pMaxReadLen<=0
		}
	} Else {
		If -1=pTimeout { Read tData#pMaxReadLen  Set tOK=1 }
		Else { Read tData#pMaxReadLen:pTimeout  Set tOK=$Test }
		Set pLineTerminator=$S($L(tData)=pMaxReadLen&&pMaxReadLen&&($ZB=$E(tData,*)):"", 1:$ZB)
	}
	Set:$ZEOF||(tOK&&(""=pLineTerminator)&&($L(tData)<pMaxReadLen)) i%AtEnd=1
	Set:tOK||..AtEnd pTimeout=0
	Set:..%RWMode'=..#RWREADNOTCHANGED ..%RWMode=..#RWREADCHANGED
Exit
	Set i%Position=..Position+$L(tData)+$L(pLineTerminator)
	If '$$$isVMS { Set i%ExternalBytePosition=$ZSeek()+1 } Else { Set i%ExternalBytePosition=..Position }
	If ('..IsSingleByte)&&..BuildCharPosMap {
		Set ..charposmap(..ExternalBytePosition)=..Position
	}
	Use tIO
	Do $ZU(68,40,tEOFMode)
	Quit tData
Trap
	Set $ZT="",tZE=$ZE, tData=$G(tData) ; in case Read left it undefined
	If $E($G(tZE),1,11)="<ENDOFFILE>" Set i%AtEnd=1  Goto Exit
	Set pSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Set pTimeout=0
	Goto Exit
}

/// Ensure that any data already written to the stream buffer is sent to the stream.
/// <P>In addition a reopen of the file takes place.
/// <P>Note: The Flush method does not ensure that data actually gets flushed to disk. Using the traditional COS "W *-3" to a device ensures that this occurs.
Method Flush(Output pSC As %Status)
{
	Set pSC=$$$OK
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit
	Quit:..%RWMode'=..#RWWRITE&&(..%RWMode'=..#RWREADCHANGED)
	Do ..reopen(..%ReadLineMode,1,$s(..%CurrLineTerminator'="": ..%CurrLineTerminator, 1: ..LineTerminator))
}

Method ExternalByteSizeGet() As %Integer [ CodeMode = expression ]
{
$S('..IsOpen:0,1:$S(..AtEnd:$S(..ExternalBytePosition>0:..ExternalBytePosition-1,1:0),1:##class(%File).GetFileSize(..Name)))
}

/// Return the current character size of the data stream. 
Method SizeGet() As %Integer
{
	Quit:..IsSingleByte ..ExternalByteSizeGet()
	Quit:'..IsOpen 0
	Quit:..%RWMode=..#RWWRITE ..Position-1
	Quit:..IsSingleByte ..ExternalByteSize
	Set tSize = -1+$G(..charposmap(..ExternalByteSize),0)  Quit:tSize>=0 tSize
	
	// Read the entire file in character mode to get char count
	Set tPos=..ExternalBytePosition
	Do ..Rewind()
	Set tSize=0 While 1 {
		Set tmp=..Read(,,.tSC),tSize=tSize+$L(tmp)
		Quit:""=tmp||$$$ISERR(tSC)
	}
	Do ..ExternalByteSeek(tPos)
	Quit $S($$$ISERR(tSC):-3,1:tSize)
}

Method ExternalByteSeek(pBytePos As %Integer, Output pSC As %Status) As %Boolean
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit 0
	Set tSize=##class(%File).GetFileSize(..Name)
	Set pSC=$S(pBytePos>0&&$S(..%RWMode=..#RWWRITE:1,1:pBytePos<=(tSize+1)):$$$OK, 1:$$$ERROR($$$ErrIOSeekPastEnd,pBytePos,..Name)) ; for some reason $Test after use dev:pos is always 0
	Quit:$$$ISERR(pSC) 0
	Quit:pBytePos=..ExternalBytePosition 1
	Quit:$$$isVMS ..Seek(pBytePos, .pSC) ; VMS does not support raw seeking or ExternalBytePosition
	Set tIO=$IO  Use ..Name:(pBytePos-1)  Set tOK=$Test Use tIO
	Set tOldPos=..ExternalBytePosition, i%ExternalBytePosition=pBytePos
	Set i%Position=$G(..charposmap(pBytePos))  Set:""=i%Position i%Position=$S(..IsSingleByte:pBytePos,1:-3+$$$ERROR($$$NotImplemented)) ; set %objlasterror
	Set i%AtEnd=(..ExternalBytePosition>=$S(..%RWMode=..#RWWRITE:tOldPos,1:tSize+1))
	Quit 1
}

Method Seek(pPosition As %Integer = 1, Output pSC As %Status) As %Boolean
{
	Set tOldPos = ..ExternalBytePosition
	Set tSize = -1
	If '$$$isVMS {
		Quit:(pPosition<=1||..IsSingleByte||'..IsOpen) ..ExternalByteSeek(pPosition,.pSC)
		Do:..Position'=1 ..Rewind(.pSC)
	} ElseIf ..Position'=1 {
		#; artificial rewind by reopen at pos 1
		Set i%ExternalBytePosition=1
		Set tLineTerm = $select(..%CurrLineTerminator'="": ..%CurrLineTerminator, 1: ..LineTerminator)
		Set tOK=..reopen(..%ReadLineMode,1,tLineTerm,,.tSize)
		If 'tOK Set i%ExternalBytePosition=tOldPos, pSC=$$$OK  Quit 0
		Set i%Position=1,i%AtEnd=0
	}
	Set pPosition=pPosition-1, tMaxLen=$$$MaxLocalLength
	While pPosition>0 {
		If '$$$isVMS || '..%ReadLineMode {
			Set tmp=..Read($S(pPosition>tMaxLen:tMaxLen,1:pPosition),,.pSC), pPosition=pPosition-$L(tmp)
		} Else { ; don't change line mode for VMS; it would force a rewind
			Set tLineTerm=$select(..%CurrLineTerminator'="": ..%CurrLineTerminator, 1: ..LineTerminator)
			Set tmp=..ReadLine($S(pPosition>tMaxLen:tMaxLen,1:pPosition),,.pSC,.tLineTerm), tmp=tmp_tLineTerm, pPosition=pPosition-$L(tmp)
			Set:pPosition<0 pPosition=0
		}
		If tmp=""||$$$ISERR(pSC) Quit
	}
	If 0=pPosition {
		If ('..IsSingleByte)&&..BuildCharPosMap {
			Set ..charposmap(..ExternalBytePosition)=..Position
		}
		If (tSize < 0) Set tSize = ##class(%File).GetFileSize(..Name)
		Set i%AtEnd = (..ExternalBytePosition>=$S(..%RWMode=..#RWWRITE:tOldPos,1:tSize+1))
		Set pSC=$$$OK
		Quit 1
	}
	Quit 0
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Quit 0
}

Method ExternalByteTruncateAt(pBytePos As %Integer, Output pSC As %Status) As %Boolean
{
	If ..%Mode'[..#WRITE Set pSC=$$$ERROR($$$ErrIOFileNoWriteMode,..%Mode) Quit 0
	Set pSC=$$$OK
	Set tMode=i%%Mode
	If pBytePos>1 {
		Set tEBS1=..ExternalByteSize+1  Quit:pBytePos>=tEBS1 (pBytePos=tEBS1)

		#; We don't have a system call for truncating, so we have to do it with a temp file
		Set i%%Mode=..#READ
		Set tOK=..reopen(0,1,..LineTerminator)
		Set tTemp=..%New()  Do tTemp.Open(,"RWN",,"binary",.pSC)  Quit:$$$ISERR(pSC) 0
		Do ..Rewind()  Set tCharset=..CharEncoding, ..CharEncoding="binary"
		#; Copy the pre-truncation data to the temp file
		Set tTotal=0, tLen=pBytePos-1
	    While tTotal<tLen,'..AtEnd,$$$ISOK(pSC) {
		    Set tChunk=$S(tLen-tTotal>32000:32000,1:tLen-tTotal)
		    Set tData=..Read(tChunk,0,.pSC)  Set tChunk=$L(tData)  Set tTotal=tTotal+tChunk  Quit:$$$ISERR(pSC)
			Do:tChunk tTemp.Write(tData,0,.pSC)  Quit:$$$ISERR(pSC)
	    }
	}
	#; overwrite on reopen
	Set i%%Mode=$TR(tMode,..#WRITENEWOVER)_..#WRITENEWOVER, i%ExternalBytePosition=1
	Set tOK=..reopen(..%ReadLineMode,1,..LineTerminator)
	Set i%ExternalBytePosition=1, i%Position=1, i%AtEnd=1
	Set i%%Mode=tMode
	If pBytePos<=1 {
		Kill ..charposmap  Set ..charposmap(1)=1
		Quit tOK
	}
	#; Copy back from the temp file
	Do tTemp.Rewind(), ..CopyFrom(tTemp,0,1,.pSC)
	Quit 1
}

Method TruncateAt(pPosition As %Integer, Output pSC As %Status) As %Boolean
{
	Quit:pPosition<=1||..IsSingleByte ..ExternalByteTruncateAt(pPosition,.pSC)
	If '..Seek(pPosition,.pSC)  Quit 0
	Set tOK=..ExternalByteTruncateAt(i%ExternalBytePosition,.pSC)
	Set ..charposmap(..ExternalBytePosition)=pPosition
	Quit tOK
}

}
