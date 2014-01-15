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
			it( "should send a POST request to: /(domain)/messages", function(){
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

			it( "should send attachments and inline attachments as files to MailGun", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some new id" } );

				mailGunClient.sendMessage(
					  from              = "another test from"
					, to                = "another test to"
					, subject           = "another test subject"
					, text              = "another test text"
					, html              = "another test html"
					, domain            = "another.domain.com"
					, attachments       = [ "C:\somefile.txt", "Z:\files\yetanother.zip" ]
					, inlineAttachments = [ "C:\pics\me.jpg", "D:\animated-log.gif", "C:\another.jpg" ]
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].files ?: {} ).toBe( {
					  attachment = [ "C:\somefile.txt", "Z:\files\yetanother.zip" ]
					, inline     = [ "C:\pics\me.jpg", "D:\animated-log.gif", "C:\another.jpg" ]
				} );

			} );

			it( "should send 'o:testing' post var when test mode specified", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some new id" } );

				mailGunClient.sendMessage(
					  from      = "some test from"
					, to        = "some test to"
					, subject   = "some test subject"
					, text      = "some test text"
					, html      = "some test html"
					, testMode  = true
					, domain    = "some.domain.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: {} ).toBe( {
					  from         = "some test from"
					, to           = "some test to"
					, subject      = "some test subject"
					, text         = "some test text"
					, html         = "some test html"
					, "o:testmode" = "yes"
				} );
			} );

			it( "should send all optional post vars when specified as arguments", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some new id" } );

				mailGunClient.sendMessage(
					  from            = "some test from"
					, to              = "some test to"
					, cc              = "test cc"
					, bcc             = "test bcc"
					, subject         = "some test subject"
					, text            = "some test text"
					, html            = "some test html"
					, domain          = "some.domain.com"
					, tags            = ["tag1","another tag"]
					, campaign        = "campaign id"
					, dkim            = true
					, deliveryTime    = "2014-01-10 09:00"
					, tracking        = false
					, clickTracking   = "htmlonly"
					, openTracking    = true
					, customHeaders   = { Custom = "testing custom", AnotherCustom = "testing custom again" }
					, customVariables = { someVariable = "a test variable", fubar="test" }
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: {} ).toBe( {
					  from                = "some test from"
					, to                  = "some test to"
					, cc                  = "test cc"
					, bcc                 = "test bcc"
					, subject             = "some test subject"
					, text                = "some test text"
					, html                = "some test html"
					, "o:tag"             = ["tag1","another tag"]
					, "o:campaign"        = "campaign id"
					, "o:dkim"            = "yes"
					, "o:deliverytime"    = httpDateFormat( "2014-01-10 09:00" )
					, "o:tracking"        = "no"
					, "o:tracking-clicks" = "htmlonly"
					, "o:tracking-opens"  = "yes"
					, "h:X-Custom"        = "testing custom"
					, "h:X-AnotherCustom" = "testing custom again"
					, "v:someVariable"    = "a test variable"
					, "v:fubar"           = "test"
				} );
			} );
		} );

		describe( "The listCampaigns() method", function(){

			it( "should send a GET request to: /(domain)/campaigns", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { total_count=0, items=[] } );

				mailGunClient.listCampaigns( domain = "some.domain.com" );

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "GET" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/campaigns" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "some.domain.com" );
			} );

			it( "should return total count and array of items from API call", function(){
				var result     = "";
				var mockResult = {
					"total_count": 1,
					"items": [{
						"delivered_count": 924,
						"name": "Sample",
						"created_at": "Wed, 15 Feb 2012 11:31:17 GMT",
						"clicked_count": 135,
						"opened_count": 301,
						"submitted_count": 998,
						"unsubscribed_count": 44,
						"bounced_count": 20,
						"complained_count": 3,
						"id": "1",
						"dropped_count": 13
					}
				]}

				mailGunClient.$( "_restCall", mockResult );

				result = mailGunClient.listCampaigns( domain="some.domain.com" );

				expect( result ).toBe( mockResult );
			} );

			it( "should send optional 'limit' and 'skip' get vars when passed", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { total_count : 0, items : [] } );

				mailGunClient.listCampaigns( domain = "some.domain.com", limit=50, skip=3 );

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].getVars.limit ?: "" ).toBe( 50 );
				expect( callLog._restCall[1].getVars.skip  ?: "" ).toBe( 3  );
			} );

			it( "should throw suitable error when API return response is not in expected format", function(){
				mailGunClient.$( "_restCall", { total_count : 5 } );

				expect( function(){
					mailGunClient.listCampaigns();
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "Expected response to contain \[total_count\] and \[items\] keys\. Instead, receieved: \["
				);

			} );

		} );

		describe( "The getCampaign() method", function(){

			it( "should send a GET request to: /(domain)/campaigns/(campaignId)", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { id="someId", name="Some name" } );

				mailGunClient.getCampaign( domain = "some.domain.com", id="myCampaign"  );

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "GET" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/campaigns/myCampaign" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "some.domain.com" );
			} );

			it( "should return the response from the API call", function(){
				var result     = "";
				var mockresult = { id = "result", name = "here" };

				mailGunClient.$( "_restCall", mockResult );

				result = mailGunClient.getCampaign( domain = "test.domain.com", id="someCampaign"  );

				expect( result ).toBe( mockResult );
			} );

			it( "should throw a sensible error when the result is not in the expected format", function(){
					mailGunClient.$( "_restCall", { bad = "result", format = "wrong" } );

					expect( function(){
						mailGunClient.getCampaign( "idOfACampaign" );

					} ).toThrow(
						  type  = "cfmailgun.unexpected"
						, regex = "Unexpected mailgun response\. Expected a campaign object \(structure\) but received: \["
					);
			} );

		} );

		describe( "The createCampaign() method", function(){

			it( "should send a post request to /(domain)/campaigns", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "Campaign created", campaign = {} } );

				mailGunClient.createCampaign(
					  domain = "my.domain.net"
					, name   = "This is my campaign"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "POST" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/campaigns" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "my.domain.net" );
			} );

			it( "should send required [name] argument as a post variable", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "Campaign created", campaign = {} } );

				mailGunClient.createCampaign(
					  domain = "my.domain.net"
					, name   = "This is my campaign"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: "" ).toBe( { name="This is my campaign" } );
			} );

			it( "should send optional [id] argument as a post variable when passed in and not empty", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "Campaign created", campaign = {} } );

				mailGunClient.createCampaign(
					  domain = "my.domain.net"
					, name   = "I like testing campaigns, really"
					, id     = "someId"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: "" ).toBe( { name = "I like testing campaigns, really", id = "someId" } );
			} );

			it( "should throw a suitable error when response in the wrong format", function(){
				mailGunClient.$( "_restCall", { bade = "response", format = {} } );

				expect( function(){
					mailGunClient.createCampaign( "Some new campaign" );
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "CreateCampaign\(\) response was an in an unexpected format\. Expected success message and campaign detail\. Instead, recieved\: \["
				);
			} );

		} );

		describe( "The updateCampaign() method", function(){
			it( "should send a a PUT request to /(domain)/campaigns/(id)", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "Campaign updated", campaign = {} } );

				mailGunClient.updateCampaign(
					  domain = "my.domain.net"
					, id     = "someCampaign"
					, name   = "This is my campaign"
					, newId  = "ANewId"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "PUT" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/campaigns/someCampaign" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "my.domain.net" );
			} );

			it( "should send the optional [name] url variable when supplied", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "Campaign updated", campaign = {} } );

				mailGunClient.updateCampaign(
					  domain = "my.domain.net"
					, id     = "someCampaign"
					, name   = "This is my campaign"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].getVars ?: "" ).toBe( { name = "This is my campaign" } );
			} );

			it( "should send the optional [id] url variable when [newId] argument supplied", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "Campaign updated", campaign = {} } );

				mailGunClient.updateCampaign(
					  domain = "my.domain.net"
					, id     = "someCampaign"
					, newId  = "aNewId"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].getVars ?: "" ).toBe( { id = "aNewId" } );
			} );

			it( "should send the optional [id] and [name] url variable when both arguments supplied", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "Campaign updated", campaign = {} } );

				mailGunClient.updateCampaign(
					  domain = "my.domain.net"
					, id     = "someCampaign"
					, name   = "my name"
					, newId  = "myId"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].getVars ?: "" ).toBe( { id = "myId", name = "my name" } );
			} );

			it( "should throw a suitable error when response is not in the expected format.", function(){
				mailGunClient.$( "_restCall", { bad = "response", format = {} } );

				expect( function(){
					mailGunClient.updateCampaign( id="blah", name="Some new campaign" );
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "UpdateCampaign\(\) response was an in an unexpected format\. Expected success message and campaign detail\. Instead, recieved\: \["

				);
			} );
		} );

		describe( "The deleteCampaign() method", function(){

			it( "should send an HTTP DELETE request to /(domain)/campaigns/(id)", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "Campaign delete", id="someId" } );

				mailGunClient.deleteCampaign(
					  domain = "my.domain.net"
					, id     = "someCampaign"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "DELETE" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/campaigns/someCampaign" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "my.domain.net" );
			});

			it( "should throw an informative error when response is not in the expected format", function(){
				mailGunClient.$( "_restCall", { bad = "response", format = {} } );

				expect( function(){
					mailGunClient.deleteCampaign( id="blah" );
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "DeleteCampaign\(\) response was an in an unexpected format\. Expected success message and campaign id\. Instead, recieved\: \["

				);
			});

		});

		describe( "The listMailingLists() method", function(){

			it( "should send a GET request to: /lists", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { total_count=0, items=[] } );

				mailGunClient.listMailingLists();

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "GET" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/lists" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "" );
			} );

			it( "should return total count and array of items from API call", function(){
				var result     = "";
				var mockResult = {
					"total_count": 1,
					"items": [{
						  access_level  = "readonly"
						, address       = "test@test.com"
						, created_at    = "Wed, 15 Jan 2014 11:59:02 -0000"
						, description   = "test description"
						, members_count = 2525
						, name          = "Test mailing list"
					}]
				};

				mailGunClient.$( "_restCall", mockResult );

				result = mailGunClient.listMailingLists();

				expect( result ).toBe( mockResult );
			} );

			it( "should send optional 'limit' and 'skip' get vars when passed", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { total_count : 0, items : [] } );

				mailGunClient.listMailingLists( limit=50, skip=3 );

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].getVars.limit ?: "" ).toBe( 50 );
				expect( callLog._restCall[1].getVars.skip  ?: "" ).toBe( 3  );
			} );

			it( "should throw suitable error when API return response is not in expected format", function(){
				mailGunClient.$( "_restCall", { total_count : 5 } );

				expect( function(){
					mailGunClient.listMailingLists();
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "Expected response to contain \[total_count\] and \[items\] keys\. Instead, receieved: \["
				);

			} );

		} );

		describe( "The createMailingList() method", function(){

			it( "should send a post request to /lists", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "List created", list = {} } );

				mailGunClient.createMailingList(
					address = "test@test.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "POST" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/lists" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "" );
			} );

			it( "should send required [address] argument as a post variable", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "List created", list = {} } );

				mailGunClient.createMailingList(
					address = "test@test.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: "" ).toBe( { address="test@test.com" } );
			} );

			it( "should send optional [name], [access_level] and [description] arguments as post variables when passed in and not empty", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "List created", list = {} } );

				mailGunClient.createMailingList(
					  domain       = "my.domain.net"
					, address      = "test@test.com"
					, name         = "I like testing lists, really"
					, description  = "this is a description"
					, accessLevel  = "test"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: "" ).toBe( {
					  address      = "test@test.com"
					, name         = "I like testing lists, really"
					, description  = "this is a description"
					, access_level = "test"
				 } );
			} );

			it( "should throw a suitable error when response in the wrong format", function(){
				mailGunClient.$( "_restCall", { bade = "response", format = {} } );

				expect( function(){
					mailGunClient.createMailingList( "list@test.com" );
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "createMailingList\(\) response was an in an unexpected format\. Expected success message and list detail\. Instead, recieved\: \["
				);
			} );

		} );

		describe( "The getMailingList() method", function(){

			it( "should send a GET request to: /lists/(list_address)", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { list={ address="test234@somedomain.com" } } );

				mailGunClient.getMailingList( address="test234@somedomain.com"  );

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "GET" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/lists/test234@somedomain.com" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "" );
			} );

			it( "should return the response from the API call", function(){
				var result     = "";
				var mockresult = { list={ address="test234@somedomain.com" } };

				mailGunClient.$( "_restCall", mockResult );

				result = mailGunClient.getMailingList( address="test234@somedomain.com"  );

				expect( result ).toBe( mockResult.list );
			} );

			it( "should throw a sensible error when the result is not in the expected format", function(){
					mailGunClient.$( "_restCall", { bad = "result", format = "wrong" } );

					expect( function(){
						mailGunClient.getMailingList( "test234@somedomain.com" );

					} ).toThrow(
						  type  = "cfmailgun.unexpected"
						, regex = "Unexpected mailgun response\. Expected a mailing list object \(structure\) but received: \["
					);
			} );

		} );

		describe( "The updateMailingList() method", function(){
			it( "should send a a PUT request to /lists/(list_address)", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "List updated", list = {} } );

				mailGunClient.updateMailingList(
					  address    = "test@test.com"
					, newAddress = "new@test.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "PUT" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/lists/test@test.com" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "" );
			} );

			it( "should send optional URL variables when supplied", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "List updated", list = {} } );

				mailGunClient.updateMailingList(
					  address     = "some@address.com"
					, newAddress  = "new@address.com"
					, name        = "This is my list"
					, description = "Description here"
					, accessLevel = "newAccessLevel"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].getVars ?: "" ).toBe( {
					  address      = "new@address.com"
					, name         = "This is my list"
					, description  = "Description here"
					, access_level = "newAccessLevel"
				} );
			} );


			it( "should throw a suitable error when response is not in the expected format.", function(){
				mailGunClient.$( "_restCall", { bad = "response", format = {} } );

				expect( function(){
					mailGunClient.updateMailingList(
						  address    = "test@test.com"
						, newAddress = "new@test.com"
					);
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "UpdateMailingList\(\) response was an in an unexpected format\. Expected success message and list detail\. Instead, recieved\: \["

				);
			} );

		} );

		describe( "The deleteMailingList() method", function(){

			it( "should send an HTTP DELETE request to /lists/(list_address)", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message = "List deleted", address="someId" } );

				mailGunClient.deleteMailingList(
					address = "test@address.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "DELETE" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/lists/test@address.com" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "" );
			});

			it( "should throw an informative error when response is not in the expected format", function(){
				mailGunClient.$( "_restCall", { bad = "response", format = {} } );

				expect( function(){
					mailGunClient.deleteMailingList( address="test@address.com" );
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "DeleteMailingList\(\) response was an in an unexpected format\. Expected success message and list address\. Instead, recieved\: \["

				);
			});

		});

		describe( "The listMailingListMembers method", function(){

			it( "should send a get request to /lists/(list_address)/members", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { total_count=1, items=[{address="test@test.com", name="Bob", subscribed=true, vars={} } ] } );

				mailGunClient.listMailingListMembers( address = "some@address.com" );

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "GET" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/lists/some@address.com/members" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "" );
			});

			it( "should return total count and array of items from API call", function(){
				var result     = "";
				var mockResult = {
					"total_count": 6256,
					"items": [{
						  address="test@test.com"
						, name="Bob"
						, subscribed=true
						, vars={}
					}]
				}

				mailGunClient.$( "_restCall", mockResult );

				result = mailGunClient.listMailingListMembers( address = "some@address.com" );

				expect( result ).toBe( mockResult );
			} );

			it( "should send optional [limit], [skip] and [subscribed] get vars when arguments passed", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", {
					"total_count": 6256,
					"items": [{
						  address="test@test.com"
						, name="Bob"
						, subscribed=true
						, vars={}
					}]
				} );

				mailGunClient.listMailingListMembers( address="test@list.net", limit=50, skip=3, subscribed=true );

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].getVars.limit ?: "" ).toBe( 50 );
				expect( callLog._restCall[1].getVars.skip  ?: "" ).toBe( 3  );
				expect( callLog._restCall[1].getVars.subscribed  ?: "" ).toBe( "yes" );
			} );

			it( "should throw an informative error when response is not in the expected format", function(){
				mailGunClient.$( "_restCall", { bad = "response", format = {} } );

				expect( function(){
					mailGunClient.listMailingListMembers( address="test@list.net", limit=50, skip=3, subscribed=true );
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "ListMailingListMembers\(\) response was an in an unexpected format\. Expected list of addresses\. Instead, recieved\: \["

				);
			});
		});
	}

// helper to test private methods
	function privateMethodRunner( method, args ) output=false {
		return this[method]( argumentCollection=args );
	}

	private function httpDateFormat( required date theDate ) output=false {
		var dtGMT = DateAdd( "s", GetTimeZoneInfo().UTCTotalOffset, theDate );

		return DateFormat( dtGMT, "ddd, dd mmm yyyy" ) & " " & TimeFormat( dtGMT, "HH:mm:ss")  & " GMT";
	}

}