Class ExecProto.Simple Extends %RegisteredObject
{

ClassMethod Test() As %String [ SqlProc ]
{
    Quit "Hello from ExecProto.Simple!"
}

ClassMethod Calculate(a As %Integer, b As %Integer) As %Integer [ SqlProc ]
{
    Quit a + b
}

}