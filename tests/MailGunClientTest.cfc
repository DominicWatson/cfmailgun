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

		} );
	}


// helper to test private methods
	function privateMethodRunner( method, args ) output=false {
		return this[method]( argumentCollection=args );
	}
}