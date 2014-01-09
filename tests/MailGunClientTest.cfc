component output=false {

	function beforeAll() output=false {
		mailGunClient = new cfmailgun.MailGunClient(
			  apiKey        = "ITDOESNOTMATTER_WE_WILL_MOCK_ANY_REAL_CALLS"
			, forceTestMode = true
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
	}


// helper to test private methods
	function privateMethodRunner( method, args ) output=false {
		return this[method]( argumentCollection=args );
	}
}