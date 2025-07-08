/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

Class %iKnow.Shell.Commands.CommandSimilar Extends %iKnow.Shell.Command [ Deprecated ]
{

Parameter TYPEENTITY = 1;

Parameter TYPESOURCE = 2;

Method GetCommandName() As %String
{
	quit "similar"
}

Method Type(option As %String) As %String
{
	if (option = "entity") {
		quit ..#QUERYENTITY
	} elseif (option = "source") {
		quit ..#QUERYSOURCE
	} else {
		throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"similar: Invalid option: "_option))
	}
}

Method Describe(shell As %iKnow.Shell, ByRef description)
{
	set description("similar") = "Show similar entities or sources depending on the option"
}

Method DescribeOptions(shell As %iKnow.Shell, ByRef description) [ Private ]
{
	set descStr = "Show similar entities or sources depending on the option"_$c(10)
	set descStr = descStr_"The following options are available:"_$c(10,10)
	set descStr = descStr_"entity"_$c(9)_"[id|""entity part""]"_$c(10)
	set descStr = descStr_$c(9)_"Show similar entites"_$c(10,10)
	set descStr = descStr_"source"_$c(9)_"[id|""external reference""]"_$c(10)
	set descStr = descStr_$c(9)_"Show similar sources"
	set description("similar") = descStr
}

Method Run(shell As %iKnow.Shell, ByRef args, parentCommand As %iKnow.Shell.Command = "")
{
	set argCnt = $g(args,0)
	throw:argCnt=0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"similar: Invalid arguments"))
	
	if (argCnt=1) {
		set arg=args(1)
		if (arg = "?") {
			do ..DescribeOptions(shell, .description)
			do shell.OutputDescription(.description)
		} else {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"similar: Invalid arguments"))
		}
	} else {
		set option=args(1)
		set optionArgs = argCnt-1
		for i=2:1:argCnt {
			set optionArgs(i-1)=args(i)
		}
		
		set outArgs=""
		if (option = "entity") {
			do ..ParseArguments(shell, .optionArgs, .outArgs, ..#TYPEENTITY)
			throw:outArgs'=1 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"similar entity: Invalid arguments"))
			do ..RunOptionEntity(shell, outArgs(1), parentCommand)
		} elseif (option = "source") {
			do ..ParseArguments(shell, .optionArgs, .outArgs, ..#TYPESOURCE)
			throw:outArgs'=1 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"similar source: Invalid arguments"))
			do ..RunOptionSource(shell, outArgs(1), parentCommand)
		} else {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"similar: Invalid option: "_option))
		}
	}
}

Method RunOptionEntity(shell As %iKnow.Shell, entity As %String, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	set sc=##class(%iKnow.Queries.EntityAPI).GetSimilar(.result, shell.RunState.Domain, entity, shell.RunState.Page, shell.RunState.PageSize, shell.RunState.Filter, $$$FILTERALLANDSORT)
	throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
	
	if (parentCommand'="") {
		do parentCommand.SetResult(.result)
	} else {
		// Set the header to the result
		set result(0)=..RTToHeader(##class(%iKnow.Queries.EntityAPI).#GetSimilarRT)
		do shell.OutputResult(.result)
	}
}

Method RunOptionSource(shell As %iKnow.Shell, source As %Integer, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	set sc=##class(%iKnow.Queries.SourceAPI).GetSimilar(.result, shell.RunState.Domain, source, shell.RunState.Page, shell.RunState.PageSize)
	throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
	
	if (parentCommand'="") {
		do parentCommand.SetResult(.result)
	} else {
		// Set the header to the result
		set result(0)=..RTToHeader(##class(%iKnow.Queries.SourceAPI).#GetSimilarRT)
		do shell.OutputResult(.result)
	}
}

Method ParseArguments(shell As %iKnow.Shell, ByRef inArgs, ByRef outArgs, type As %Integer) [ Private ]
{
	k outArgs
	set outArgs=0
	set inQuotes=0
	set groupArg=""
	
	for i=1:1:inArgs {
		set arg=inArgs(i)
		
		if (inQuotes=0) {
			if ($e(arg,1,1)="""") {
				
				if ($e(arg,*)="""") {
					if ($e(arg,*-1)'="\") {
						set value=$e(arg,2,*-1)
						set value=$replace(value,"\""","""")
						if (type=..#TYPESOURCE) {
							set sc=$$$OK
							set srcId=##class(%iKnow.Queries.SourceAPI).GetSourceId(shell.RunState.Domain, value, .sc)
							throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
							set outArgs($i(outArgs))=srcId
						} else {
							set outArgs($i(outArgs))=value
						}
						continue
					}
				}
				
				set inQuotes=1
				set groupArg = $e(arg,2,*)
			} else {
				if (type=..#TYPEENTITY) {
					set value=##class(%iKnow.Queries.EntityAPI).GetValue(shell.RunState.Domain, arg)
					throw:value="" ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError, "No entity found with id: "_arg))
					set outArgs($i(outArgs))=value
				} else {
					set outArgs($i(outArgs))=arg
				}
			}
		} else {
			if ($e(arg,*)="""") {
				if ($e(arg,*-1)'="\") {
					set groupArg = groupArg_" "_$e(arg,1,*-1)
					set groupArg = $replace(groupArg,"\""","""")
					if (type=..#TYPESOURCE) {
						set sc=$$$OK
						set srcId=##class(%iKnow.Queries.SourceAPI).GetSourceId(shell.RunState.Domain, groupArg, .sc)
						throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
						set outArgs($i(outArgs))=srcId
					} else {
						set outArgs($i(outArgs))=groupArg
					}
					set inQuotes=0
					continue
				}
			}
			
			set groupArg = groupArg_" "_arg
		}
	}
}

}
