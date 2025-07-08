/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

Class %iKnow.Shell.Commands.CommandRelated Extends %iKnow.Shell.Command [ Deprecated ]
{

Parameter TYPEENTITY = 1;

Method GetCommandName() As %String
{
	quit "related"
}

Method Type(option As %String) As %String
{
	if (option = "entity") {
		quit ..#QUERYENTITY
	} else {
		throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"related Invalid option: "_option))
	}
}

Method Describe(shell As %iKnow.Shell, ByRef description)
{
	set description("related") = "Show related entities"
}

Method DescribeOptions(shell As %iKnow.Shell, ByRef description) [ Private ]
{
	set descStr = "Show related entities"_$c(10)
	set descStr = descStr_"The following options are available:"_$c(10,10)
	set descStr = descStr_"entity"_$c(9)_"[id|""entity part""]"_$c(10)
	set descStr = descStr_$c(9)_"Show related entites"
	set description("related") = descStr
}

Method Run(shell As %iKnow.Shell, ByRef args, parentCommand As %iKnow.Shell.Command = "")
{
	set argCnt = $g(args,0)
	throw:argCnt=0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"related: Invalid arguments"))
	
	if (argCnt=1) {
		set arg=args(1)
		if (arg = "?") {
			do ..DescribeOptions(shell, .description)
			do shell.OutputDescription(.description)
		} else {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"related: Invalid arguments"))
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
			throw:outArgs'=1 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"related entity: Invalid arguments"))
			do ..RunOptionEntity(shell, outArgs(1), parentCommand)
		} else {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"related: Invalid option: "_option))
		}
	}
}

Method RunOptionEntity(shell As %iKnow.Shell, entity As %Integer, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	set sc=##class(%iKnow.Queries.EntityAPI).GetRelatedById(.result, shell.RunState.Domain, $lb(entity), shell.RunState.Page, shell.RunState.PageSize, shell.RunState.Filter, $$$FILTERALLANDSORT)
	throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
	
	if (parentCommand'="") {
		do parentCommand.SetResult(.result)
	} else {
		// Set the header to the result
		set result(0)=..RTToHeader(##class(%iKnow.Queries.EntityAPI).#GetRelatedByIdRT)
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
						if (type=..#TYPEENTITY) {
							set entId=##class(%iKnow.Queries.EntityAPI).GetId(shell.RunState.Domain, value)
							throw:entId="" ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError, "No entity found with value: "_value))
							set outArgs($i(outArgs))=entId
						} else {
							set outArgs($i(outArgs))=value
						}
						continue
					}
				}
				
				set inQuotes=1
				set groupArg = $e(arg,2,*)
			} else {
				set outArgs($i(outArgs))=arg
			}
		} else {
			if ($e(arg,*)="""") {
				if ($e(arg,*-1)'="\") {
					set groupArg = groupArg_" "_$e(arg,1,*-1)
					set groupArg = $replace(groupArg,"\""","""")
					if (type=..#TYPEENTITY) {
						set entId=##class(%iKnow.Queries.EntityAPI).GetId(shell.RunState.Domain, groupArg)
						throw:entId="" ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError, "No entity found with value: "_groupArg))
						set outArgs($i(outArgs))=entId
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
