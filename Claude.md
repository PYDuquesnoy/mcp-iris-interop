# Whole Project

Sucking all the juice out of Claude Code

## Description

This is a multi-step project where we try to maximize the benefits of using Claude Code with InterSystems IRIS for developing integrations in an Interoperability Production.

## General Instructions

* Maintain a file Dev-Status.MD to keep track of the Steps that have been developed. 
* Keep an Up to date README.MD about this project. Update it when you think you finished a Step.
* Keep track of all Interactions (what I write to the Console, and the Steps and decision you make in WorkLog.MD: Each time I give an Instruction, it should be immediatey written to this file, before starting with the implementation
* run the claude /compact at the beginning of each Step
* Run a Git commit and git push for each Step, with the step Number as part of the comment.
* Allow any shell command or docker command or npm command or git command within the current directory tree without confirmation

## Step 1

Login to github and create a Empty Project, named mcp-iris-interop



## Step 2

- Clone the github repo https://github.com/intersystems-community/intersystems-iris-dev-template to have a local IRIS instance for testing our code.
- Modify the Repo to have Fixed Ports in the 42000 Range as theses are the free ports on the host.
- Build the Repo, start the containers (they are slow, like 120 seconds the first time) , test connectivity to the management portal. Do Now move forward until connectivity is fine.
- Write the test to the README.MD so I can use it to validate.
- 

## Step 3

- Search on github for the Client Source code for the InterSystems VSCode plugin and Clone the git repository.

- Inspect the Source code and make an inventory of all the REST API calls used by this plugin, their description, purpose, and calling syntax and parameters. Generate a Document in the root directory of the project with that information.

- Develop a small typescript prototype in the client-proto directory. The prototype uses a configuration file in the local directory to define a remote connection to an IRIS Server. It has at least these parameters:

  - Server name or IP
  - WebServer Port
  - URL Prefix (Optional)
  - Username
  - Password

   The prototype has this functionality:

  * Get an Inventory of all Namespaces from IRIS

  Test the prototype and provide a function to test it from the command line. Provide a Verbose mode where the URL and the details are displayed.

  Document and commit and push to git.

  ## Step 4

  Extend the prototipe to add

  * Get an Inventory of Clases or Packages in a Namespace in IRIS

  - Upload a class to IRIS and save it, Replacing an existing Version
  - Compile a Class in IRIS, or Upload and Compile a Class in IRIS
  - Download a Class from IRIS
  - Download a whole package from IRIS
  - use the existing config file to connect to the Docker container defined in previou steps.

- Generate Samples Server side ObjectScript clases to test the Functionality (upload, compile, download)

- Test loading, compile, downloading a class using this prototype. Verify there are no errors returned by the prototype.

Document and commit and push to git.

## Step 5

Extend the Prototype with following functionality, which may require to a new REST API with a set of Methods to the Server.

* You name the Rest API /api/mcp-interop
* The Implementation is in the IRISAPP Namespace in the class Api.Mcp.Interop.cls which inherits %CSP.REST
* The Deployment of the WebApp needs to be done via an SQL Stored Procedure that needs to be created and executed. you can use %SYS.REST.DeployApplication to deploy the Web Application. Security must be user/password authentication which is value 32.
* The Function implemented is list, which lists all Productions in a namespace. it can use GetProductionSummary from the Class Ens.Director.



## Step 6


* List the Productions defined in a Namespace



execute a method and return the results
* Update the Current Production
* Start a Specific Production, or the Default current one
* Stop a the default current Production
* Clean the Current Production
* Use the Testing Service to Call a BP or a BO for testing
* Export the Messages log  and the Event log from the last Session in the list to debug the last test
* Export the last N entries from the Messages Log to a local file
* Export the last N entries from the Event Log to a local file
* Create a Web Application for a REST Service

Determine, in the above list, which methods already exist, and which require a new REST API.

* Implement the server API
* Load the Web Application and code on the server 
  * dynamically if possible
  * By modifying and restarting the docker container if needed
* Add these functions to the client prototype
* generate a test set for these functions
* test the functions



## Step 7

* Make an mcp Server from the prototype
  * make sure the IRIS server connection details can be configured on a per project basis
* Install the mcp server in this session
* Test the mcp server functionality and validate each function



## Step 8

* ##this is a s skipped Step: ignore as I will run it manually. /* extract the source from the ICO dev instance or from their gitlab repo and dowload to ICO directory for next Step */

  

## Step 9

* Inspect the Source Code in ICO/CURSCLINIC and document it in a Document in the project root StepX-CursClinic-Doc.MD. Make sure to extract the pattern and Strategies used for:
  * Writing a Business Service that uses an SQL Inbound Adapter to read from a Oracle Table
  * Read only the pending rows, Update their status on processing and on final success.
  * Generate a Message from the SQL table content and send it to a Business process.
  * Generate a Business Process in BP to process, route and transform the message accoding to its content and the Routing Table
  * The Routing Table Definition an fields to perform the Routing
  * The destination specific Business Operation for (usually) SOAP Messaging, generated from a WSDL with the SOAP specific Messages
  * The Data Transformation used to Transform from the Generic message to the SOAP Request 
  * The Data Transformation used to Transform back the SOAP Specific Response to a Generic Response when needed
  * Writing the SQL BO that writes back the Status and the Execution History to the corresponding tables
  * The Production Settings for these components in the DEV environment

## Step 10

Using previous Step documentation (and referring to Source Code details if needed), Generate the Documentation and Implement the new Circuit for the ICUMED IV Pumps.

* Copy the ../ICUMED-DEV-Test Directory to the local Dir. Use its content to determine what needs to be done. Here are more hints:

* The new Circuit should be in the Package BOMBES. The is a package ICUMED that contains funcional components for the HL7 part of he Circuit. They can be reused, but get renamed to package and production Category BOMBES (Infusion Pump in Catalan)
* The new Circuit can be first loaded an tested on the local docker iris instance.
* We need to Add a BO for HL7 TCP to Send Data to the BOMBES for ICUMED
* We need to Add a BO that Writes the Results and the History to Oracle
* We need a Business Service that reads from Oracle, from the Table specified in Spec-ESPOQ-Table.MD
* The BS generates a message
* The Routing table definition for the BP
* The message is sent to a BP written in BPL, to do 
  * request transform
  * routing and send to destination HL7 BO
  * response transform
  * keep necesary data in process context
  * call the Oracle BO
* Implement the Data Transform from the BS Message to HL7 for sending to the Bombes ICUMED.
* Provide the Insert for the Routing table

