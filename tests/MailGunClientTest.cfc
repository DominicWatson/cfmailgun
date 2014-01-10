component output=false {

	function beforeAll() output=false {
		mailGunClient = new cfmailgun.MailGunClient(
			  apiKey        = "ITDOESNOTMATTER_WE_WILL_MOCK_ANY_REAL_CALLS"
			, defaultDomain = "test.domain.com"
		);

		mailGunClient.privateMethodRunner = privateMethodRunner;

		mailGunClient = prepareMock( mailGunClient );
	}

	function run() output=false {

		describe( "API Response processing", function(){

			it( "should return deserialized json from MailGun response", function(){
				var response = { some="simple", object="here" };
				var processed = mailGunClient.privateMethodRunner(
					  method = "_processApiResponse"
					, args   = { status_code = 200, filecontent = SerializeJson( response ) }
				);

				expect( processed ).toBe( response );
			} );

			it( "should throw error when response is not json", function(){
				expect( function(){
					mailGunClient.privateMethodRunner(
						  method = "_processApiResponse"
						, args   = { status_code = 200, filecontent = "some non-json response" }
					);
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "^Unexpected error processing MailGun API response\. MailGun response body: \[some non-json response\]"
				);
			} );

			it( "should throw error when response code is not 200", function(){
				expect( function(){
					mailGunClient.privateMethodRunner(
						  method = "_processApiResponse"
						, args   = { status_code = 3495, filecontent = SerializeJson( { message="hello" } ) }
					);
				} ).toThrow();
			} );

			it( "should show MailGun provided message in thrown errors", function(){
				expect( function(){
					mailGunClient.privateMethodRunner(
						  method = "_processApiResponse"
						, args   = { status_code = 400, filecontent = SerializeJson( { message="something went wrong here" } ) }
					);
				} ).toThrow( regex="something went wrong here" );
			} );

			it( "should show response body itself in thrown errors when response does not contain error message", function(){
				expect( function(){
					mailGunClient.privateMethodRunner(
						  method = "_processApiResponse"
						, args   = { status_code = 401, filecontent = "this is a test" }
					);
				} ).toThrow( regex="this is a test" );
			} );

		} );

		describe( "The SendMessage() method", function(){
			it( "should send a POST request to: /messages", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some id" } );

				mailGunClient.sendMessage(
					  from    = "test from"
					, to      = "test to"
					, subject = "test subject"
					, text    = "test text"
					, html    = "test html"
					, domain  = "some.domain.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "POST" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/messages" );
			} );

			it ( "should send all required post vars to MailGun", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some id" } );

				mailGunClient.sendMessage(
					  from    = "test from"
					, to      = "test to"
					, subject = "test subject"
					, text    = "test text"
					, html    = "test html"
					, domain  = "some.domain.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: {} ).toBe( {
					  from    = "test from"
					, to      = "test to"
					, subject = "test subject"
					, text    = "test text"
					, html    = "test html"
				} );
			} );

			it( "should return newly created message ID from MailGun response", function(){
				mailGunClient.$( "_restCall", { message="nice one, ta", id="a test" } );

				var result = mailGunClient.sendMessage(
					  from    = "test from"
					, to      = "test to"
					, subject = "test subject"
					, text    = "test text"
					, html    = "test html"
					, domain  = "some.domain.com"
				);

				expect( result ).toBe( "a test" );
			} );

			it ( "should throw a suitable error when no ID is returned in the MailGun response", function(){
				mailGunClient.$( "_restCall", { message="nice one, ta - message queued" } );

				expect( function(){

					mailGunClient.sendMessage(
						  from    = "test from"
						, to      = "test to"
						, subject = "test subject"
						, text    = "test text"
						, html    = "test html"
						, domain  = "some.domain.com"
					);

				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "Unexpected error processing mail send\. Expected an ID of successfully sent mail but instead received \["
				);
			} );
		} );
	}


// helper to test private methods
	function privateMethodRunner( method, args ) output=false {
		return this[method]( argumentCollection=args );
	}
}