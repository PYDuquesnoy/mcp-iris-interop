/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occDynamicDispatch

Class %ASQ.Mutators
{

/// <p>
/// setPath() accepts a JPL Path expression (currently limited to simple dot delimited property names, no wild cards, arrays, or filters)
/// and a value. The path is traversed and the terminal property in the path will be set to the value. This can result in the
/// loss of data. If any non-terminal property is defined but is not an object then it will be set to a new object, replacing the current
/// value.
/// </p>
/// <p>
/// If <var>path</var> is null the current object is not modified.
/// </p>
/// <p>
/// If <var>path</var> is '$' and <var>value</var> is an instance of <class>%Library.AbstractObject</class> then <var>value</var> is
/// returned, otherwise, an array with a single element of <var>value</var> is returned.
/// </p>
/// <p>
/// In all other cases, the current object is modified and returned.
/// </p>
/// <p>
/// If a token in the path contains [*] and the current value of that property is an array then the array will be traversed and each
/// element will be set according to the setPath rules.
/// </p>
ClassMethod setPath(context As %AbstractSet, path As %String(MAXLEN="") = "", value As %Any = "") As %Library.AbstractSet [ Internal ]
{
	try {
			// first, parse the path
		do parseDelimitedString^%ocuParser(path,.tokens,".")
		if $get(tokens(1)) '= "$" {
			set startPtr = 1
		} elseif tokens = 1 {
			do context.clear()
			if $isObject(value) {
					// The base is $ and there is nothing more...the path is the entire document, what to do?
					// If the value is not an instance of the current object's class then it is an invalid value error
				if ($isObject(value))&&(value.%IsA($classname(context))) {
						// Attempt to retain $this as a modified object but that can only be if $this and value are the same type.
					if context."_isLabeled"() {
                        return context.putAll(value) // value.%Compose({"returnValue":($this)})
                    } else {
                        return context.addAll(value)
                    }
				} else {
						// this is an invalid value
					do $$$APPERROR1($$$ERINVARG)
				}
			} elseif value '= "" {
					// this is an invalid value
				do $$$APPERROR1($$$ERINVARG)
			}
			return context
		} else {
			set startPtr = 2
		}
		set pathElements = 0
		for tokenPtr = startPtr:1:tokens {
				// parse out the wildcard portion - it applies only when the current token's value is an array
			if $Extract(tokens(tokenPtr),*) '= "]" {
				set property = tokens(tokenPtr)
				set wildcard = ""
			} else {
					// Need to parse out the [] portion of the token
				do parseDelimitedString^%ocuParser(tokens(tokenPtr),.wildTokens,"[")
				set property = $get(wildTokens(1))
				if wildTokens > 1 {
					set wildcard = $Extract(wildTokens(2),1,*-1)
				} else {
					set wildcard = ""
				}
				kill wildTokens
			}
			set pathElements = pathElements + 1
			if $Extract(property) = """" {
				set property = $$$StripQuotes(property)
			}
			set pathElements(pathElements) = $listbuild(property,wildcard)
		}
		do ..setPathElement(context, .pathElements, 1, value)
	} catch exception {
		throw exception
	}
	return context
}

/// unsetPath() accepts a JPL Path expression (currently limited to simple dot delimited property names, no wild cards, arrays, or filters)
/// and a value. The path is traversed and the terminal property in the path will be removed. If any non-terminal property not defined or
/// is defined but is not an object then $unsetPath will return without doing any work.
/// 
/// If a token in the path contains [*] and the current value of that property is an array then the array will be traversed and each
/// element will be unset according to the unsetPath rules. </Description>
ClassMethod unsetPath(context As %AbstractSet, path As %String(MAXLEN="") = "", value As %String(MAXLEN="") = "") As %AbstractSet [ Internal ]
{
	try {
			// first, parse the path
		do parseDelimitedString^%ocuParser(path,.tokens,".")
		if $get(tokens(1)) '= "$" {
			set startPtr = 1
		} elseif tokens = 1 {
				// The base is $ and there is nothing more...the path is the entire document, what to do?
				// For now, just clear() and return $this
			do context.clear()
			return context
		} else {
			set startPtr = 2
		}
		set pathElements = 0
		for tokenPtr = startPtr:1:tokens {
				// parse out the wildcard portion - it applies only when the current token's value is an array
			if $Extract(tokens(tokenPtr),*) '= "]" {
				set property = tokens(tokenPtr)
				set wildcard = ""
			} else {
					// Need to parse out the [] portion of the token
				do parseDelimitedString^%ocuParser(tokens(tokenPtr),.wildTokens,"[")
				set property = $get(wildTokens(1))
				if wildTokens > 1 {
					set wildcard = $Extract(wildTokens(2),1,*-1)
				} else {
					set wildcard = ""
				}
				kill wildTokens
			}
			set pathElements = pathElements + 1
			if $Extract(property) = """" {
				set property = $$$StripQuotes(property)
			}
			set pathElements(pathElements) = $listbuild(property,wildcard)
		}
		do ..unsetPathElement(context, .pathElements,1)
	} catch exception {
		throw exception
	}
	return context
}

ClassMethod setPathElement(context As %AbstractSet, ByRef pathElements As %RawString, elementPtr As %Integer = 0, value As %Library.Any) As %Library.AbstractSet [ Internal ]
{
    if context."_isLabeled"() {
        return ..setPathMember(context, .pathElements, .elementPtr, .value)
    }
    try {
		set wildcard = $List(pathElements(elementPtr),2)
			// imply wildcard of "*" since we aren't fully supporting JPL at this time.
		if (wildcard = "*") || (wildcard = "") {
			set arrayStart = 0
			set arrayEnd = context.size() - 1
			if elementPtr = pathElements {
				for arrayPtr = arrayStart:1:arrayEnd {
					do applyTerminalPathElement
				}
			} else {
				for arrayPtr = arrayStart:1:arrayEnd {
					do applyPathElement
				}
			}
		} else {
				// We need to handle an array of subscript expressions here, for later on
			set arrayMax = context.size()
			do parseDelimitedString^%ocuParser(wildcard,.subExpressions,",")
			if (subExpressions = 1) && ($isValidNum(subExpressions(1))) {
					// Optimize for the single subscript case
				set arrayPtr = subExpressions(1)
				if elementPtr = pathElements {
					do applyTerminalPathElement
				} else {
					do applyPathElement
				}
				return context
			} else {
				for ptr = 1:1:subExpressions {
					if $isValidNum(subExpressions(ptr)) {
						set $bit(visit,subExpressions(ptr)+1) = 1
					} else {
						set subscriptExpression = $$$ucase(subExpressions(ptr))
						if subscriptExpression [ "TO" {
							set arrayStart = $zstrip($piece(subscriptExpression,"TO",1),"<>W")
							set arrayEnd = $zstrip($piece(subscriptExpression,"TO",2),"<>W")
						} else {
							throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"%DynamicArray - illegal array subscript expression: '"_wildcard_"'"))
						}
						if $$$ucase(arrayEnd) = "LAST" {
							set arrayEnd = arrayMax - 1
						}
						for arrayPtr = arrayStart:1:arrayEnd {
							set $bit(visit,arrayPtr+1) = 1
						}
					}
				}
				set bitPtr = 0
				for {
					set bitPtr = $bitfind(visit,1,bitPtr+1)
					quit:'bitPtr
					set arrayPtr = bitPtr - 1
					if elementPtr = pathElements {
						do applyTerminalPathElement
					} else {
						do applyPathElement
					}
				}
			}
		}
	} catch exception {
		throw exception
	}
	return context

applyTerminalPathElement
		// terminal - set the value, we are only here if wildcard is not null so apply the wildcard
	do context.put(arrayPtr,value)
	quit

applyPathElement
	set elementValue = context.get(arrayPtr)
	if ('$Isobject(elementValue)) || ('elementValue.%IsA("%Library.DynamicAbstractObject")) {
		set elementValue = {}
		do context.put(arrayPtr,elementValue)
	}
	do ..setPathElement(elementValue, .pathElements,$Select((elementValue.%IsA("%Library.DynamicObject")):elementPtr + 1,1:elementPtr),.value)
	quit
}

ClassMethod unsetPathElement(context As %AbstractSet, ByRef pathElements As %RawString, elementPtr As %Integer = 0) As %AbstractSet [ Internal ]
{
    if context."_isLabeled"() {
        return ..unsetPathMember(context, .pathElements, .elementPtr)
    }
	try {
		set wildcard = $List(pathElements(elementPtr),2)
			// imply wildcard of "*" since we aren't fully supporting JPL at this time.
		if (wildcard = "*") || (wildcard = "") {
			if elementPtr = pathElements {
					// terminal - set the value, we are only here if wildcard is not null so apply the wildcard
		// TODO: $remove is shifting positions on us so we can't use it to process an array accessor other than a wildcard = *. For now
		// 		we only support * wildcards so it isn't a problem. When we do support additional array accessors then
		// 		this will have to change.
		//		for arrayPtr = arrayStart:1:arrayEnd {
		//			do ..$remove(arrayPtr)
		//		}
                do context.clear()
			} else {
				set arrayStart = 0
				set arrayEnd = context.size() - 1
				for arrayPtr = arrayStart:1:arrayEnd {
					do applyPathElement
				}
			}
		} else {
				// We need to handle an array of subscript expressions here, for later on
			set arrayMax = context.size()
			do parseDelimitedString^%ocuParser(wildcard,.subExpressions,",")
			if (subExpressions = 1) && ($isValidNum(subExpressions(1))) {
					// Optimize for the single subscript case
				set arrayPtr = subExpressions(1)
				if arrayPtr < arrayMax {
					if elementPtr = pathElements {
						do context.put(arrayPtr,"","null")
					} else {
						do applyPathElement
					}
				}
				return context
			} else {
				for ptr = 1:1:subExpressions {
					if $isValidNum(subExpressions(ptr)) {
						set:subExpressions(ptr)<arrayMax $bit(visit,subExpressions(ptr)+1) = 1
					} else {
						set wildtr = $Translate(subExpressions(ptr),"to "_$c(9),"TO"_$c(1,1))
						if wildtr [ "TO" {
							set arrayStart = $Piece(wildtr,$Char(1),1)
							set arrayEnd = $p(wildtr,$Char(1),*)
						} else {
							throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"%DynamicArray - illegal array subscript expression: '"_wildcard_"'"))
						}
						if arrayEnd '< arrayMax {
							set arrayEnd = arrayMax - 1
						}
						for arrayPtr = arrayStart:1:arrayEnd {
							set $bit(visit,arrayPtr+1) = 1
						}
					}
				}
				set bitPtr = 0
				for {
					set bitPtr = $bitfind(visit,1,bitPtr+1)
					quit:'bitPtr
					set arrayPtr = bitPtr - 1
					if elementPtr = pathElements {
						do context.put(arrayPtr,"","null")
					} else {
						do applyPathElement
					}
				}
			}
		}
	} catch exception {
		throw exception
	}
	return context

applyPathElement
	set elementValue = context.get(arrayPtr)
	if ($Isobject(elementValue)) && (elementValue.%IsA("%Library.DynamicAbstractObject")) {
		do ..unsetPathElement(elementValue, .pathElements,$Select((elementValue.%IsA("%Library.DynamicObject")):elementPtr + 1,1:elementPtr))
	}
}

/// INTERNAL - recursive method to set the element in the current context object using a parsed path expression.
ClassMethod unsetPathMember(context As %AbstractSet, ByRef pathElements As %RawString, elementPtr As %Integer = 0) As %AbstractSet [ Internal ]
{
    if 'context."_isLabeled"() {
        return ..unsetPathElement(context, .pathElements, .elementPtr, .value)
    }
	try {
		set property = $List(pathElements(elementPtr),1)
		set wildcard = $List(pathElements(elementPtr),2)
		set elementValue = context.get(property)
		set isArray = (($Isobject(elementValue)) && (elementValue.%IsA("%Library.DynamicArray")))
		if elementPtr = pathElements {
				// This is the terminal, if not an array elementValue then just set it, otherwise, dispatch to %Library.DynamicArray
			if ('isArray) || (wildcard = "") {
				do context.remove(property)
			} else {
				do ..unsetPathElement(elementValue,.pathElements,$Select('isArray:elementPtr + 1,1:elementPtr))
			}
		} elseif $Isobject(elementValue) && (elementValue.%IsA("%Library.DynamicAbstractObject")) {
			do ..unsetPathElement(elementValue,.pathElements,$Select('isArray:elementPtr + 1,1:elementPtr))
		} else {
			return context
		}
	} catch exception {
		throw exception
	}
	return context
}

/// INTERNAL - recursive method to set the element in the current context object using a parsed path expression. </Description>
ClassMethod setPathMember(context As %AbstractSet, ByRef pathElements As %RawString, elementPtr As %Integer = 0, value As %Library.Any) As %AbstractSet [ Internal ]
{
    if 'context."_isLabeled"() {
        return ..setPathElement(context, .pathElements, .elementPtr, .value)
    }
	try {
		set property = $List(pathElements(elementPtr),1)
		set arrayAccessorExpr = $List(pathElements(elementPtr),2)
		set elementValue = context.get(property)
		set isArray = (($Isobject(elementValue)) && (elementValue.%IsA("%Library.DynamicArray")))
			// what does it mean for an arrayAccessorExpr to be specified and the value is not an array?
			// The SQL Standard supports lax and strict modes. In lax mode, our default mode and we don't support strict now,
			// the specification of an array accessor on a non-array value triggers an implicit wrap(), meaning the non-array
			// value becomes the zero-th element in an array.
		if ('isArray) && (arrayAccessorExpr '= "") {
			set elementValue = [(elementValue)]
			set isArray = 1
			do context.put(property,elementValue)
		}
		if elementPtr = pathElements {
				// This is the terminal, if not an array elementValue then just set it, otherwise, dispatch to %Library.DynamicArray
			if ('isArray) || (arrayAccessorExpr = "") || (arrayAccessorExpr = "*") {
				do context.put(property,value)
			} else {
				do ..setPathElement(elementValue, .pathElements,elementPtr, .value)
			}
		} elseif ($Isobject(elementValue)) && (elementValue.%IsA("%Library.DynamicAbstractObject")) {
			do ..setPathElement(elementValue, .pathElements,$Select('isArray:elementPtr + 1,1:elementPtr),.value)
		} else {
			set elementValue = {}
			do context.put(property,elementValue)
			do ..setPathElement(elementValue, .pathElements,$Select('isArray:elementPtr + 1,1:elementPtr),.value)
		}
	} catch exception {
		throw exception
	}
	return context
}

}
