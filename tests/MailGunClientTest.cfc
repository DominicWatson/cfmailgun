component output=false {

	function beforeAll() output=false {
		mailGunClient = new cfmailgun.MailGunClient(
			  apiKey        = "ITDOESNOTMATTER_WE_WILL_MOCK_ANY_REAL_CALLS"
			, forceTestMode = true
		);

		mailGunClient.privateMethodRunner = privateMethodRunner;
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
		} );
	}

	function privateMethodRunner( method, args ) output=false {
		return this[method]( argumentCollection=args );
	}
}