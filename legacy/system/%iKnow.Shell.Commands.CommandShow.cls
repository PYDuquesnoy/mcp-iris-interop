/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Shell.Commands.CommandShow Extends %iKnow.Shell.Command [ Deprecated ]
{

Method GetCommandName() As %String
{
	quit "show"
}

Method Type(option As %String) As %String
{
	if (option="source") || (option="summary") {
		quit ..#QUERYSENTENCE
	} else {
		quit ..#COMMAND
	}
}

Method Describe(shell As %iKnow.Shell, ByRef description)
{
	set description("show") = "Show information about an option"
}

Method DescribeOptions(shell As %iKnow.Shell, ByRef description) [ Private ]
{
	set descStr = "Show information about an option"_$c(10)
	set descStr = descStr_"The following options are available:"_$c(10,10)
	set descStr = descStr_"device"_$c(10)
	set descStr = descStr_$c(9)_"Show the current selected device"_$c(10,10)
	set descStr = descStr_"domain"_$c(10)
	set descStr = descStr_$c(9)_"Show the current selected domain"_$c(10,10)
	set descStr = descStr_"filter"_$c(10)
	set descStr = descStr_$c(9)_"Show the current selected filter"_$c(10,10)
	set descStr = descStr_"metadata"_$c(9)_"[id|""external reference""] (id|""fieldname"")"_$c(10)
	set descStr = descStr_$c(9)_"Show the metadata values for the specified field"_$c(10)
	set descStr = descStr_$c(9)_"This is a query"_$c(10,10)
	set descStr = descStr_"page"_$c(10)
	set descStr = descStr_$c(9)_"Show the current page"_$c(10,10)
	set descStr = descStr_"pagesize"_$c(10)
	set descStr = descStr_$c(9)_"Show the current pagesize"_$c(10,10)
	set descStr = descStr_"source"_$c(9)_"[id|""external reference""]"_$c(10)
	set descStr = descStr_$c(9)_"Show the sentences of the source"_$c(10)
	set descStr = descStr_$c(9)_"This is a query and thus supports paging."_$c(10,10)
	set descStr = descStr_"summary"_$c(9)_"[id|""external reference""] [length]"_$c(10)
	set descStr = descStr_$c(9)_"Show the summary with the specified length of the source"_$c(10)
	set descStr = descStr_$c(9)_"This is a query"
	set description("show") = descStr
}

Method Run(shell As %iKnow.Shell, ByRef args, parentCommand As %iKnow.Shell.Command = "")
{
	set argCnt = $g(args,0)
	throw:argCnt=0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show: Invalid arguments"))
	
	if (argCnt=1) {
		set arg=args(1)
		if (arg = "?") {
			do ..DescribeOptions(shell, .description)
			do shell.OutputDescription(.description)
		} else {
			do ..RunOption(shell, arg, 0, parentCommand)
		}
	} else {
		set option=args(1)
		set optionArgs=argCnt-1
		for i=2:1:argCnt {
			set optionArgs(i-1)=args(i)
		}
		
		set outArgs=""
		do ..ParseArguments(shell, .optionArgs, .outArgs)
		
		do ..RunOption(shell, option, .outArgs, parentCommand)
	}
}

Method RunOption(shell As %iKnow.Shell, option As %String, ByRef arguments, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	if (option="device") {
		throw:arguments'=0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show device: No argument allowed"))
		do ..RunOptionDevice(shell, parentCommand)
	} elseif (option="domain") {
		throw:arguments'=0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show domain: No argument allowed"))
		do ..RunOptionDomain(shell, parentCommand)
	} elseif (option="filter") {
		throw:arguments'=0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show filter: No argument allowed"))
		do ..RunOptionFilter(shell, parentCommand)
	} elseif (option="metadata") {
		throw:$g(arguments(1))="" ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show metadata: No field supplied"))
		do ..RunOptionMetadata(shell, arguments(1), $g(arguments(2)), parentCommand)
	} elseif (option="page") {
		throw:arguments'=0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show page: No argument allowed"))
		do ..RunOptionPage(shell, parentCommand)
	} elseif (option="pagesize") {
		throw:arguments'=0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show pagesize: No argument allowed"))
		do ..RunOptionPagesize(shell, parentCommand)
	} elseif (option="source") {
		throw:$g(arguments(1))="" ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show source: No source supplied"))
		do ..RunOptionSource(shell, arguments(1), parentCommand)
	} elseif (option="summary") {
		throw:$g(arguments(1))="" ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show source: No source supplied"))
		throw:$g(arguments(2))="" ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show source: No summary length supplied"))
		do ..RunOptionSummary(shell, arguments(1), arguments(2), parentCommand)
	} else {
		throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"use: Invalid option: "_option))
	}
}

Method RunOptionDevice(shell As %iKnow.Shell, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	if (shell.RunState.Device=0) {
		do shell.OutputInfo("Current device: Shell")
	} else {
		do shell.OutputInfo("Current device: "_shell.RunState.Device)
	}
}

Method RunOptionDomain(shell As %iKnow.Shell, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	if (shell.RunState.Domain=0) {
		do shell.OutputInfo("No domain selected")
	} else {
		set dom=##class(%iKnow.Domain).OpenId(shell.RunState.Domain)
		throw:dom="" ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"show domain: No domain with id: "_shell.RunState.Domain))
		do shell.OutputInfo("Current domain: "_dom.Name_" ("_dom.Id_")")
	}
}

Method RunOptionFilter(shell As %iKnow.Shell, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	if (shell.RunState.FilterName="") {
		do shell.OutputInfo("No filter selected")
	} else {
		do shell.OutputInfo("Current filter: "_shell.RunState.FilterName)
	}
}

Method RunOptionMetadata(shell As %iKnow.Shell, source As %String, field As %String = "", parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	if ('(source?1.N)) {
		set sc=$$$OK
		set source=##class(%iKnow.Queries.SourceAPI).GetSourceId(shell.RunState.Domain, source, .sc)
		throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	
	if (field="") {
		set sc=##class(%iKnow.Queries.MetadataAPI).GetValuesById(.result,shell.RunState.Domain,source)
		throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
		if (parentCommand'="") {
			set result(0) = ..RTToHeader(##class(%iKnow.Queries.MetadataAPI).#GetValuesByIdRT)
		}
	} else {
		if ('(field?1.N)) {
			set sc=$$$OK
			set field=##class(%iKnow.Queries.MetadataAPI).GetFieldId(shell.RunState.Domain,field,.sc)
			throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
		}
		set sc=$$$OK
		set value=##class(%iKnow.Queries.MetadataAPI).GetValueById(shell.RunState.Domain,field,source,.sc)
		throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
		set result=1
		set result(1)=$lb(value)
		if (parentCommand'="") {
			set result(0)=$lb("Value")
		}
	}
	
	if (parentCommand'="") {
		do parentCommand.SetResult(.result)
	} else {
		do shell.OutputResult(.result)
	}
}

Method RunOptionPage(shell As %iKnow.Shell, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	do shell.OutputInfo("Current page: "_shell.RunState.Page)
}

Method RunOptionPagesize(shell As %iKnow.Shell, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	do shell.OutputInfo("Current pagesize: "_shell.RunState.PageSize)
}

Method RunOptionSource(shell As %iKnow.Shell, source As %String, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	if ('(source?1.N)) {
		set sc=$$$OK
		set source=##class(%iKnow.Queries.SourceAPI).GetSourceId(shell.RunState.Domain, source, .sc)
		throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	
	set sc=##class(%iKnow.Queries.SentenceAPI).GetBySource(.result,shell.RunState.Domain, source, shell.RunState.Page, shell.RunState.PageSize)
	throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
	
	if (parentCommand'="") {
		do parentCommand.SetResult(.result)
	} else {
		set result(0) = ..RTToHeader(##class(%iKnow.Queries.SentenceAPI).#GetBySourceRT)
		do shell.OutputResult(.result)
	}
}

Method RunOptionSummary(shell As %iKnow.Shell, source As %String, length As %Integer, parentCommand As %iKnow.Shell.Command = "") [ Private ]
{
	if ('(source?1.N)) {
		set sc=$$$OK
		set source=##class(%iKnow.Queries.SourceAPI).GetSourceId(shell.RunState.Domain, source, .sc)
		throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	
	set sc=##class(%iKnow.Queries.SourceAPI).GetSummary(.result,shell.RunState.Domain,source,length)
	throw:$$$ISERR(sc) ##class(%Exception.StatusException).CreateFromStatus(sc)
	
	if (parentCommand'="") {
		do parentCommand.SetResult(.result)
	} else {
		set result(0) = ..RTToHeader(##class(%iKnow.Queries.SourceAPI).#GetSummaryRT)
		do shell.OutputResult(.result)
	}
}

Method ParseArguments(shell As %iKnow.Shell, ByRef inArgs, ByRef outArgs) [ Private ]
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
						set outArgs($i(outArgs))=value
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
					set outArgs($i(outArgs))=groupArg
					set inQuotes=0
					continue
				}
			}
			
			set groupArg = groupArg_" "_arg
		}
	}
}

}
