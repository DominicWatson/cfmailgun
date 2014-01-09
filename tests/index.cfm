<cfscript>
	runner = new testbox.system.testing.TestBox( bundles=[ "tests.MailGunClientTest" ] );

	WriteOutput( runner.run() );
</cfscript>