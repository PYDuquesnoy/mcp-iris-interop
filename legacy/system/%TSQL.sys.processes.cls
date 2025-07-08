/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySite, %syPidtab, %sySystem)

Class %TSQL.sys.processes [ ClassType = view, System = 4, ViewQuery = {
		select	JobNumber as spid, 
			1 as kpid,
			null as blocked,
			ClientNodeName as clienthostname,
			ClientExecutableName as clientapplname, 
			PidExternal as hostprocess,	
			Routine As program_name, 
			GlobalReferences as physical_io,
			MemoryUsed As memusage, 
			CURRENT_TIMESTAMP as login_time,
			Priority as priority, 
			ClientNodeName as clientname, 
			State as status, 
			$TSQL_HOST_NAME() as hostname,
			CurrentLineAndRoutine as cmd,
			OSUserName as nt_username, 	
			UserName as loginame,
			ClientIPAddress, 
			CurrentDevice, 
			CurrentSrcLine, 
			InTransaction, 
			JobType, 
			LastGlobalReference, 
			LinesExecuted, 
			Location,
			MemoryAllocated,
			NameSpace,
			OpenDevices, 
			Pid, 
			StartupClientIPAddress, 
			StartupClientNodeName, 
			UserInfo
			from %SYS.ProcessQuery} ]
{

}
