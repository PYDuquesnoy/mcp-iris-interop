/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Task to run Incremental Backup of database list
Class %SYS.Task.BackupIncrementDatabaseList Extends (%SYS.Task.Definition, %SYS.Task.BackupSuper) [ Inheritance = right, System = 4 ]
{

Parameter TaskName = "IncrementalDBList";

}
