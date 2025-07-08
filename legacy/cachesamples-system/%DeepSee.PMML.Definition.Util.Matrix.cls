/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.Matrix Extends %DeepSee.PMML.Definition.node [ System = 3 ]
{

Property kind As %DeepSee.PMML.Datatype.String(VALUELIST = ",diagnoal,symmetric,any", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "any" ];

Property nbRows As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE");

Property nbCols As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE");

Property Arrays As list Of Array(XMLNAME = "Array", XMLPROJECTION = "ELEMENT");

Property diagDefault As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property offDiagDefault As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property Cells As list Of MatCell(XMLNAME = "MatCell", XMLPROJECTION = "ELEMENT");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if ..kind = "any" {
			if ..Cells.Count() && ..Arrays.Count() {
				set tSC = $$$ERROR($$$GeneralError, "A Matrix should be represented through MatCell OR Array elements, not both")
				quit
			}
		} elseif ..Cells.Count() {
			set tSC = $$$ERROR($$$GeneralError, "A symmetric or diagonal matrix cannot be represented through MatCell elements")
			quit
		}
		
		if ..Arrays.Count() && (..diagDefault || ..offDiagDefault) {
			set tSC = $$$ERROR($$$GeneralError, "diagDefault and offDiagDefault can only be used when using MatCell representation")
			quit
		}
		
		set tSC = ..ValuesAsArray(.tArray)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the values of this matrix as a two-dimensional array, where pArray(i,j) contains
/// the value of the j'th column on the i'th row of the matrix. the top node of pArray contains
/// $lb(nbOfRows, nbOfColumns)
Method ValuesAsArray(Output pArray) As %Status
{
	kill pArray
	set tSC = $$$OK
	try {
		set tRows = ..nbRows, tCols = ..nbCols
		
		if ..Arrays.Count() {
			
			if ..kind = "any" {
				
				set pArray = ..Arrays.Count()
				if tRows && (pArray '= tRows) {
					set tSC = $$$ERROR($$$GeneralError, "Array count does not match nbRows")
					quit
				}
				set:'tRows tRows = pArray
				
				for i = 1:1:pArray {
					#dim tRow As AbstractArray = ..Arrays.GetAt(i)
					
					if tCols && (tRow.Length() '= tCols) {
						set tSC = $$$ERROR($$$GeneralError, "Array length at row "_i_" does not match column count")
						quit
					}
					set:'tCols tCols = tRow.Length()
					
					set tSC = tRow.ValuesAsArray(.tRowArray)
					quit:$$$ISERR(tSC)
					
					merge pArray(i) = tRowArray
				}
				quit:$$$ISERR(tSC)
				
			} elseif ..kind = "symmetric" {
				
				set pArray = ..Arrays.Count()
				if tRows && (pArray '= tRows) {
					set tSC = $$$ERROR($$$GeneralError, "Array count does not match nbRows")
					quit
				}
				set:'tRows tRows = pArray
				set:'tCols tCols = pArray
				
				for i = 1:1:pArray {
					set tRow = ..Arrays.GetAt(i)
					
					if (tRow.Length() '= i) {
						set tSC = $$$ERROR($$$GeneralError, "Array length at row "_i_" does not match column count for lower triangle")
						quit
					}
					
					set tSC = tRow.ValuesAsArray(.tRowArray)
					quit:$$$ISERR(tSC)
					
					for j = 1:1:i {
						set pArray(i,j) = $g(tRowArray(j))
						set pArray(j,i) = $g(tRowArray(j))
					}
				}
				quit:$$$ISERR(tSC)
				
			} elseif ..kind = "diagonal" {
				
				set tRow = ..Arrays.GetAt(1)
				
				if tRow="" {
					set tSC = $$$ERROR($$$GeneralError, "No array specified for Matrix diagonal values")
					quit
				}
				
				if tRows && (tRows '= tRow.Length()) {
					set tSC = $$$ERROR($$$GeneralError, "Diagonal values array length does not correspond to ..nbRows")
					quit
				}
				set:'tRows tRows = tRow.Length()
				
				set tSC = tRow.ValuesAsArray(.tRowArray)
				quit:$$$ISERR(tSC)
					
				for i = 1:1:tRows {
					set pArray(i,i) = tRowArray(i)
				}
			}
			
		} else { // MatCell representation
			
			// loop through cells first as row and column count may not be defined
			set tCellCount = ..Cells.Count(), tMaxRow = 0, tMaxCol = 0
			for i = 1:1:tCellCount {
				#dim tCell As MatCell = ..Cells.GetAt(i)
				
				if tCols && (tCell.col > tCols) {
					set tSC = $$$ERROR($$$GeneralError, "MatCell column index exceeds ..nbCols")
					quit
				}
				
				if tRows && (tCell.row > tRows) {
					set tSC = $$$ERROR($$$GeneralError, "MatCell row index exceeds ..nbRows")
					quit
				}
				
				set:tMaxRow<tCell.row tMaxRow = tCell.row
				set:tMaxCol<tCell.col tMaxCol = tCell.col
				
				set pArray(tCell.row, tCell.col) = tCell.value
				set:..kind="symmetric" pArray(tCell.col, tCell.row) = tCell.value
			}
			set:'tRows tRows = tMaxRow
			set:'tCols tCols = tMaxCol
			
			for i = 1:1:tRows {
				for j = 1:1:tCols {
					continue:$d(pArray(i,j))
					
					if (i=j) {
						set:..diagDefault'="" pArray(i,j) = ..diagDefault
					} else {
						set:..offDiagDefault'="" pArray(i,j) = ..offDiagDefault
					}
				}
			}
			
		}
		
		set pArray = $lb(tRows, tCols)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
