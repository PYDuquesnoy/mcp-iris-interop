/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Stream.TmpBinary">Working with Streams</a>.</p>
Class %Stream.TmpBinary Extends TmpCharacter [ ClientDataType = BINARYSTREAM, OdbcType = LONGVARBINARY, System = 2 ]
{

/// Copies the contents of <i>source</i> from the beginning up to the
/// the <i>insert offset</i>, adds the <i>new data</i>, moves to the
/// <i>delete size</i> + <i>insert offset</i> position and copies the remainder
/// of the <i>source</i> stream into this Stream.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// 
/// This method is used internally to implement the TSQL UPDATETEXT SQL statement
ClassMethod CopyFromAndUpdate(pSource As %Stream.Object = "", pInsertOffset As %Integer, pDeleteSize As %Integer, pText As %Binary, pTextObject As %Binary, ByRef pStatus As %Library.Status) As %Stream.TmpBinary [ Internal ]
{
	try {
		set tReturn = ..%New()
		if $isobject(pSource) {
			if pInsertOffset = "" { set pInsertOffset = pSource.Size }
			do pSource.Rewind()
			set sc1=$$$OK,sc2=$$$OK
				#; if pInsertOffset is true, then copy from the beginning to tInsertOffset
			if pInsertOffset {
				set tChunks = pInsertOffset \ 32000, tLastChunk = pInsertOffset # 32000
				for tChunk=1:1:tChunks quit:(pSource.AtEnd)||($$$ISERR(sc1)||($$$ISERR(sc2)))  set len=32000,sc1=tReturn.Write(pSource.Read(len,.sc2))
				if '(pSource.AtEnd)&&(tLastChunk)&&($$$ISOK(sc1))&&($$$ISOK(sc2)) { set len=tLastChunk,sc1=tReturn.Write(pSource.Read(len,.sc2)) }
				if $$$ISERR(sc1) { throw ##class(%Exception.StatusException).CreateFromStatus(sc1) }
				elseif $$$ISERR(sc2) { throw ##class(%Exception.StatusException).CreateFromStatus(sc2) }
			}
		}
		if pText '= "" {
			if '$isobject(pText) { set sc1=tReturn.Write(pText) }
			else {
					#; copy the update stream
				do pText.Rewind()
				set sc1=$$$OK,sc2=$$$OK
				for  quit:(pText.AtEnd)||($$$ISERR(sc1)||($$$ISERR(sc2)))  set len=32000,sc1=tReturn.Write(pText.Read(len,.sc2))
				if $$$ISERR(sc1) { throw ##class(%Exception.StatusException).CreateFromStatus(sc1) }
				elseif $$$ISERR(sc2) { throw ##class(%Exception.StatusException).CreateFromStatus(sc2) }
			}
		}
		elseif $isobject(pTextObject) {
			do pTextObject.Rewind()
			set sc1=$$$OK,sc2=$$$OK
			for  quit:(pTextObject.AtEnd)||($$$ISERR(sc1)||($$$ISERR(sc2)))  set len=32000,sc1=tReturn.Write(pTextObject.Read(len,.sc2))
			if $$$ISERR(sc1) { throw ##class(%Exception.StatusException).CreateFromStatus(sc1) }
			elseif $$$ISERR(sc2) { throw ##class(%Exception.StatusException).CreateFromStatus(sc2) }
		}
		if $isobject(pSource) {
			if pDeleteSize { do pSource.MoveTo(pInsertOffset + pDeleteSize + 1) }
			set sc1=$$$OK,sc2=$$$OK
			for  quit:(pSource.AtEnd)||($$$ISERR(sc1)||($$$ISERR(sc2)))  set len=32000,sc1=tReturn.Write(pSource.Read(len,.sc2))
			if $$$ISERR(sc1) { throw ##class(%Exception.StatusException).CreateFromStatus(sc1) }
			elseif $$$ISERR(sc2) { throw ##class(%Exception.StatusException).CreateFromStatus(sc2) }
		}
		set pStatus = $$$OK
	}
	catch tException {
		#dim tException as %Exception.AbstractException
		set pStatus = tException.AsStatus()
		set tReturn = ""
	}
	quit tReturn
}

}
