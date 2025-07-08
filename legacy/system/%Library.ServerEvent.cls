/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <CLASS>%ServerEvent</CLASS> class implements the interface for Server
/// callbacks. Server connections can specify the name of a class derived from
/// %ServerEvent. The server will then dispatch calls to methods implemented in
/// that class when certain events occur in the server.
/// 
/// Only three events dispatch calls to methods in the event class at this time.
/// %OnConnect is called after the server has processed a new connection;
/// %OnTranCommit is called after the server has processed a transaction commit;
/// %OnTranRollback is called after the server has processed a transaction rollback.
Class %Library.ServerEvent [ Abstract, Not ProcedureBlock, System = 2 ]
{

ClassMethod %OnConnect()
{
 Quit
}

ClassMethod %OnTranCommit()
{
 Quit
}

ClassMethod %OnTranRollback()
{
 Quit
}

}
