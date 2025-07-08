/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Filter implementation selecting sources based on their metadata values, as set through
/// <class>%iKnow.Queries.MetadataAPI</class>.</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>domainId</b> As <class>%Integer</class></li>
/// 	<li><b>fieldName</b> As <class>%String</class> - the name of the metadata field to filter by.</li>
/// 	<li><b>filterOperator</b> As <class>%String</class> - the operator to use for filtering (should be a supported one for this metadata field).</li>
/// 	<li><b>filterValue</b> - the value to compare the actual source metadata values against.</li>
/// </ol>
Class %iKnow.Filters.SimpleMetadataFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property FieldId As %Integer;

Property FilterOperator As %String;

Property FilterValue As %String;

Method %OnNew(domainId As %Integer, fieldName As %String, filterOperator As %String, filterValue As %String = "") As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(domainId)
	set fieldId = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(domainId, fieldName)
	quit:'+fieldId $$$ERROR($$$IKMDFieldDoesNotExistE, fieldName)
	
	set filterOperator = $zstrip(filterOperator,"<>W")
	quit:'$listfind($list(^IRIS.IK.Mdt.FieldId(domainId,fieldId),2),filterOperator) $$$ERROR($$$IKMDOperatorNotSupported, filterOperator, fieldName)
	
	set i%DomainId = domainId
	set i%FieldId = fieldId
	set i%FilterOperator = filterOperator
	set i%FilterValue = filterValue
	quit ..Initialize()
}

Method ToString() As %String
{
	quit $classname()_"|"_..DomainId_"|"""_$list(^IRIS.IK.Mdt.FieldId(..DomainId,..FieldId),1)_"""|"""_..FilterOperator_"""|"""_..FilterValue_""""
}

Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set mdf = $get(^IRIS.IK.Mdt.FieldId(..DomainId, ..FieldId))
		set tStorage = $list(mdf, 4), tIsBitmap = (tStorage#2), tCompressed = (tStorage>1)
		set dataType = $list(mdf, 3)
	
		for offset = 1:1:maxOffset {
			set bitstring = ""
			
			// now build the Bits based on the operator
			if ((..FilterOperator = $$$MDOPEQUAL) || (..FilterOperator = $$$MDOPNOTEQUAL)) {
		
				set isTruncated = 0
				set:'tCompressed normalizedValue = ##class(%iKnow.Queries.MetadataAPI).NormalizeValue(..FilterValue, mdf, .isTruncated)
				set:tCompressed tValueId = ##class(%iKnow.Queries.MetadataAPI).GetUniValueId(..DomainId, ..FilterValue, .tSC)
				quit:$$$ISERR(tSC)
		
				if (tIsBitmap) {
			
					// if this is a date but we didn't receive a time part, take all times for that day
					if (dataType=$$$MDDTDATE) && '+$p(..FilterValue,",",2) {
				
						set bitstring = "", dateTime = $order(^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, normalizedValue), -1)
						for {
							set dateTime = $order(^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, dateTime))
							quit:dateTime=""
							quit:(dateTime>=(normalizedValue+1))
							set bitstring = $bitlogic(bitstring | ^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, dateTime, 0, offset))
						}
				
					} else {
				
						// otherwise, simply copy the bitmaps from ^IRIS.IK.Mdt.ValueToSrcBit
						if (tStorage = $$$MDSTBITMAP) {
							set bitstring = $g(^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, normalizedValue, isTruncated, offset))
						} else {
							set bitstring = $g(^IRIS.IK.Mdt.UniValueToSrcBit(..DomainId, ..FieldId, tValueId, offset))
						}
				
					}
			
					// if the value is truncated, we need to double-check each actual value
					if ('tCompressed && isTruncated) {
						set srcPos = 0
						for {
							set srcPos = $bitfind(bitstring, 1, srcPos+1)
							quit:srcPos=0
					
							$$$IKGETIDOFFPOS(srcId,offset,srcPos)
					
							if ($get(^IRIS.IK.Mdt.Values(..DomainId, srcId, ..FieldId)) '= ..FilterValue) {
								set $bit(bitstring, srcPos) = 0
							}
						}
					}
			
				} else { 
			
					// otherwise, we'll have to build them from ^IRIS.IK.Mdt.ValueToSrc
					set bitstring = ""
			
					// if this is a date but we didn't receive a time part, take all times for that day
					if (dataType=$$$MDDTDATE) && '+$p(..FilterValue,",",2) {
				
						set dateTime = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, normalizedValue),-1)
						for {
							set dateTime = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, dateTime))
							quit:dateTime=""
							quit:(dateTime>=(normalizedValue+1))
					
							set maxSrcId = offset*64000
							set srcId = (offset-1)*64000
							for {
								set srcId = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, dateTime, 0, srcId))
								quit:srcId=""
								quit:srcId>=maxSrcId
						
								set $bit(bitstring, srcId#64000 + 1) = 1
							}
						}
				
					} else {
				
						set gValueToSrc = $s(tCompressed:$name(^IRIS.IK.Mdt.UniValueToSrc(..DomainId, ..FieldId, tValueId)),
												1:$name(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, normalizedValue, isTruncated)))
						set maxSrcId = offset*64000
						set srcId = (offset-1)*64000
						for {
							set srcId = $order(@gValueToSrc@(srcId))
							quit:srcId=""
							quit:srcId>=maxSrcId
				
							// if the normalized value was truncated, we need to doublecheck
							if (isTruncated && 'tCompressed) {
								if ($get(^IRIS.IK.Mdt.Values(..DomainId, srcId, ..FieldId)) = ..FilterValue) {
									set $bit(bitstring, srcId#64000 + 1) = 1
								}
							} else {
								set $bit(bitstring, srcId#64000 + 1) = 1
							}
						}
						
					}
				}
		
				// this implementation for NOTEQUAL will include all entries with a NULL value
				// as well !
				if (..FilterOperator = $$$MDOPNOTEQUAL) {
					set bitstring = $bitlogic(^IRIS.IK.SrcExistsBit(..DomainId, offset) & ~bitstring)
				}
				
				set tSC = ..SetSourceBits(offset, $bitlogic(bitstring))
				quit:$$$ISERR(tSC)
		
			} elseif ((..FilterOperator = $$$MDOPSMALLER) || (..FilterOperator = $$$MDOPSMALLEROREQUAL) || 
					(..FilterOperator = $$$MDOPLARGER) || (..FilterOperator = $$$MDOPLARGEROREQUAL) || 
					(..FilterOperator = $$$MDOPSMALLEROREQUAL2) || (..FilterOperator = $$$MDOPLARGEROREQUAL2) || 
					(..FilterOperator = $$$MDOPBETWEEN)) {
				
				// first define the min and max values
				set minIsSet = 0
				set maxIsSet = 0
				set minIncluded = 0
				set maxIncluded = 0
				set minIsTruncated = 0
				set maxIsTruncated = 0
				if (..FilterOperator = $$$MDOPSMALLER) {
					set maxIsSet = 1
					set rawMax = ..FilterValue
					set max = ##class(%iKnow.Queries.MetadataAPI).NormalizeValue(rawMax, mdf, .maxIsTruncated)
				} elseif (..FilterOperator = $$$MDOPSMALLEROREQUAL) || (..FilterOperator = $$$MDOPSMALLEROREQUAL2) {
					set maxIsSet = 1
					set maxIncluded = 1
					set rawMax = ..FilterValue
					set max = ##class(%iKnow.Queries.MetadataAPI).NormalizeValue(..FilterValue, mdf, .maxIsTruncated)
			
					// if there is a max date without a time part, make sure all times of that day are included
					if (dataType=$$$MDDTDATE) && '+$p(rawMax,",",2) {
						set max = max + 0.99999
					}
				} elseif (..FilterOperator = $$$MDOPLARGER) {
					set minIsSet = 1
					set rawMin = ..FilterValue
					set min = ##class(%iKnow.Queries.MetadataAPI).NormalizeValue(rawMin, mdf, .minIsTruncated)
			
					// if there is a min date without a time part, make sure all times of that day are excluded
					if (dataType=$$$MDDTDATE) && '+$p(rawMin,",",2) {
						set min = min + 0.99999
					}
				} elseif (..FilterOperator = $$$MDOPLARGEROREQUAL) || (..FilterOperator = $$$MDOPLARGEROREQUAL2) {
					set minIsSet = 1
					set minIncluded = 1
					set rawMin = ..FilterValue
					set min = ##class(%iKnow.Queries.MetadataAPI).NormalizeValue(rawMin, mdf, .minIsTruncated)
				} elseif (..FilterOperator = $$$MDOPBETWEEN) {
					set minIsSet = 1
					set maxIsSet = 1
					set minIncluded = 1
					set maxIncluded = 1
					set rawMin = $piece(..FilterValue, $$$MDVALSEPARATOR, 1)
					set rawMax = $piece(..FilterValue, $$$MDVALSEPARATOR, 2)
					set min = ##class(%iKnow.Queries.MetadataAPI).NormalizeValue(rawMin, mdf, .minIsTruncated)
					set max = ##class(%iKnow.Queries.MetadataAPI).NormalizeValue(rawMax, mdf, .maxIsTruncated)
			
					// if there is a max date without a time part, make sure all times of that day are included
					if (dataType=$$$MDDTDATE) && '+$p(rawMax,",",2) {
						set max = max + 0.99999
					}
				}
		
				// define the starting value
				set mdValue = ""
				if (minIsSet) {
					if (tIsBitmap) {
						set mdValue = $order(^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, min), -1)
					} else {
						set mdValue = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, min), -1)
					}
				}
		
				if (tIsBitmap) {
			
					for {
						set mdValue = $order(^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, mdValue))
						quit:mdValue=""
				
						// check if we've passed the max value
						if (maxIsSet) {
							if (mdValue ]] max) {
								quit
							} elseif ('maxIncluded && (mdValue = max) && 'maxIsTruncated) {
								quit
							}
						}
				
						// now use the bitmaps from ^IRIS.IK.Mdt.ValueToSrcBit
				
						// first treat the untruncated entries for this mdValue, unless we're at the
						// normalized minimum value and the actual minimum value was truncated (which
						// means the non-truncated definitely precedes the actual and should be skipped),
						// or when the minimum wasn't truncated but should not be included
						if (minIsSet && (min = mdValue) && (minIsTruncated || ('minIsTruncated && 'minIncluded))) {
							// skip
						} else {
							set bitstring = $bitlogic(bitstring | ^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, mdValue, 0, offset))
						}
				
						// now treat the truncated entries (if any)
						if ($data(^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, mdValue, 1, offset), truncBits)) {
					
							// if we are at the normalized min or max value, and it was truncated, 
							// it means we should doublecheck each entry as its actual value might
							// be less or more
							if ((minIsSet && minIsTruncated && (min = mdValue)) ||
								(maxIsSet && maxIsTruncated && (max = mdValue))) {
								set srcPos = 0
								for {
									set srcPos = $bitfind(truncBits, 1, srcPos+1)
									quit:srcPos=0
							
									$$$IKGETIDOFFPOS(srcId,offset,srcPos)
									set actualValue = $get(^IRIS.IK.Mdt.Values(..DomainId, srcId, ..FieldId))
							
									if (minIsSet && (min = mdValue)) {
										if (minIncluded) {
											if (rawMin ]] actualValue) {
												set $bit(truncBits, srcPos) = 0
											}
										} else {
											if (actualValue ']] rawMin) {
												set $bit(truncBits, srcPos) = 0
											}
										}
									}
							
									if (maxIsSet && (max = mdValue)) {
										if (maxIncluded) {
											if (actualValue ]] rawMax) {
												set $bit(truncBits, srcPos) = 0
											}
										} else {
											if (rawMax ']] actualValue) {
												set $bit(truncBits, srcPos) = 0
											}
										}
									}
								}
							}
					
							set bitstring = $bitlogic(bitstring | truncBits)
						}
					}
			
				} else { 
			
					// otherwise, we'll have to build them from ^IRIS.IK.Mdt.ValueToSrc
					set bitstring = ""
					set maxSrcId = offset*64000
					set minSrcId = (offset-1)*64000
					for {
						set mdValue = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, mdValue))
						quit:mdValue=""
				
						// check if we've passed the max value
						if (maxIsSet) {
							if (mdValue ]] max) {
								quit
							} elseif ('maxIncluded && (mdValue = max) && 'maxIsTruncated) {
								quit
							}
						}
				
						// first treat the untruncated entries for this mdValue, unless we're at the
						// normalized minimum value and the actual minimum value was truncated (which
						// means the non-truncated definitely precedes the actual and should be skipped),
						// or when the minimum wasn't truncated but should not be included
						if (minIsSet && (min = mdValue) && (minIsTruncated || ('minIsTruncated && 'minIncluded))) {
							// skip
						} else {
						
							set srcId = minSrcId
							for {
								set srcId = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, mdValue, 0, srcId))
								quit:srcId=""
								quit:srcId>=maxSrcId
						
								set $bit(bitstring, srcId#64000 + 1) = 1
							}
						}
				
						// and now treat the truncated ones
						set srcId = minSrcId
						for {
							set srcId = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, mdValue, 1, srcId))
							quit:srcId=""
							quit:srcId>maxSrcId
						
							// if we are at the normalized min or max value, and it was truncated, 
							// it means we should doublecheck each entry as its actual value might
							// be less or more
							if ((minIsSet && minIsTruncated && (min = mdValue)) ||
								(maxIsSet && maxIsTruncated && (max = mdValue))) {
						
								set actualValue = $get(^IRIS.IK.Mdt.Values(..DomainId, srcId, ..FieldId))
						
								if (minIsSet && (min = mdValue)) {
									if (minIncluded) {
										if (rawMin ]] actualValue) {
											continue
										}
									} else {
										if (actualValue ']] rawMin) {
											continue
										}
									}
								}
						
								if (maxIsSet && (max = mdValue)) {
									if (maxIncluded) {
										if (actualValue ]] rawMax) {
											continue
										}
									} else {
										if (rawMax ']] actualValue) {
											continue
										}
									}
								}
							}
					
							set $bit(bitstring, srcId#64000 + 1) = 1
						}
					}
				}	
		
				set tSC = ..SetSourceBits(offset, $bitlogic(bitstring))
				quit:$$$ISERR(tSC)
			
			} elseif (..FilterOperator = $$$MDOPISNULL) || (..FilterOperator = $$$MDOPISNOTNULL) {
				
				// only do this once
				continue:offset'=1
				
				kill ^||%IK.SrcBits
				
				if (tCompressed) {
					
					if (tIsBitmap) {
						
						set tValueId = ""
						for {
							set tValueId = $order(^IRIS.IK.Mdt.UniValueToSrcBit(..DomainId, ..FieldId, tValueId))
							quit:tValueId=""
							
							set gFrom = $name(^IRIS.IK.Mdt.UniValueToSrcBit(..DomainId, ..FieldId, tValueId))
							$$$IKMERGEBITSOR(gFrom,"^||%IK.SrcBits")
						}
						
					} else {
						
						kill ^||%IK.Srcs
						$$$IKSORTBEGIN(^||%IK.Srcs)
						set tValueId = ""
						for {
							set tValueId = $order(^IRIS.IK.Mdt.UniValueToSrc(..DomainId, ..FieldId, tValueId))
							quit:tValueId=""
							
							merge ^||%IK.Srcs = ^IRIS.IK.Mdt.UniValueToSrc(..DomainId, ..FieldId, tValueId)
						}
						set x = $sortend(^||%IK.Srcs)
						
						set tSrcId="", tPrevOff=0, tBits=""
						for {
							set tSrcId = $order(^||%IK.Srcs(tSrcId))
							quit:tSrcId=""
							
							$$$IKBITOFFPOS(tSrcId,tOff,tPos)
							
							if (tOff'=tPrevOff) {
								set:tPrevOff ^||%IK.SrcBits(tPrevOff) = $bitlogic(tBits)
								set tBits = "", tPrevOff = tOff
							}
							set $bit(tBits, tPos) = 1
						}
						set:tPrevOff ^||%IK.SrcBits(tPrevOff) = $bitlogic(tBits)
						kill ^||%IK.Srcs
					}
					
				} elseif (tIsBitmap) {
					
					set tValue = ""
					for {
						set tValue = $order(^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, tValue))
						quit:tValue=""
						
						set tTruncated=""
						for {
							set tTruncated = $order(^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, tValue, tTruncated))
							quit:tTruncated=""
							
							set gFrom = $name(^IRIS.IK.Mdt.ValueToSrcBit(..DomainId, ..FieldId, tValue, tTruncated))
							$$$IKMERGEBITSOR(gFrom,"^||%IK.SrcBits")
						}
					}
					
				} else {
					
					kill ^||%IK.Srcs
					$$$IKSORTBEGIN(^||%IK.Srcs)
					set tValue = ""
					for {
						set tValue = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, tValue))
						quit:tValue=""
						
						set tTruncated=""
						for {
							set tTruncated = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, tValue, tTruncated))
							quit:tTruncated=""
							
							set tSrcId=""
							for {
								set tSrcId = $order(^IRIS.IK.Mdt.ValueToSrc(..DomainId, ..FieldId, tValue, tTruncated, tSrcId))
								quit:tSrcId=""
								set ^||%IK.Srcs(tSrcId) = ""
							}
						}
					}
					set x = $sortend(^||%IK.Srcs)
					
					set tSrcId="", tPrevOff=0, tBits=""
					for {
						set tSrcId = $order(^||%IK.Srcs(tSrcId))
						quit:tSrcId=""
						
						$$$IKBITOFFPOS(tSrcId,tOff,tPos)
						
						if (tOff'=tPrevOff) {
							set:tPrevOff ^||%IK.SrcBits(tPrevOff) = $bitlogic(tBits)
							set tBits = "", tPrevOff = tOff
						}
						set $bit(tBits, tPos) = 1
					}
					set:tPrevOff ^||%IK.SrcBits(tPrevOff) = $bitlogic(tBits)
					kill ^||%IK.Srcs
				}
				
				set tOffset=""
				for {
					set tOffset = $order(^||%IK.SrcBits(tOffset), 1, tBits)
					quit:tOffset=""
					
					if (..FilterOperator=$$$MDOPISNULL) {
						set tBits = $bitlogic(^IRIS.IK.SrcExistsBit(..DomainId, tOffset) & ~tBits)
					} else {
						set tBits = $bitlogic(^IRIS.IK.SrcExistsBit(..DomainId, tOffset) & tBits)
					}
					
					set tSC = ..SetSourceBits(tOffset, tBits)
					quit:$$$ISERR(tSC)
				}
				
			} else {
				set tSC = $$$ERROR($$$IKMDOperatorNotSupported, ..FilterOperator, ..FieldId)
				quit
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method FieldIdSet(fieldId As %Integer) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:fieldId=i%FieldId $$$OK
	set i%FieldId = fieldId
	quit ..ChangeParams()
}

Method FilterOperator(operator As %String) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:operator=i%FilterOperator $$$OK
	set i%FilterOperator = operator
	quit ..ChangeParams()
}

Method FilterValue(value As %String) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:value=i%FilterValue $$$OK
	set i%FilterValue = value
	quit ..ChangeParams()
}

}
