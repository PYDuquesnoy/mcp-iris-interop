Side Project Step 1:

Create a Separate Client and Server Prototype "exec-proto" that allows to execute Code on IRIS via SQL Stored Procedure". I can reuse the client-proto/06-queries.sh that executes SQL,

It can use a Stored Procedure writtten in Language Objectscript. The Stored procedure can call a classmethod defined in a separate class.

Once working. Check into GitHub. Document



Side Project Step 2:

in the same prototype, Create a Deployment class andMethod that allows to create a New Rest API with a set of Methods to the Server.

* You name the Rest API /side/mcp-interop
* The Implementation is in the IRISAPP Namespace in the class Side.Mcp.Interop.cls which inherits %CSP.REST
* The Deployment of the WebApp needs to be done via an SQL Stored Procedure that needs to be created and executed. you can use %SYS.REST.DeployApplication to deploy the Web Application. Security must be user/password authentication which is value 32.
* The Function implemented is list, which lists all Productions in a namespace. it can use GetProductionSummary from the Class Ens.Director.