@IsTest
private class MockApiTest {
	@IsTest
	static void shouldReturnBasicSuccessResponse() {
		MockApi.Response responseBuilder = new MockApi.Response();
		HttpRequest request = MockApiTest.initRequest();

		Test.startTest();
		HttpResponse response = new Http()?.send(request);
		Test.stopTest();

		// A basic response with no customization should return a response w/these default values:
		Assert.areEqual('{}', response?.getBody(), 'Wrong body');
		Assert.areEqual(200, response?.getStatusCode(), 'Wrong status code');
		Assert.areEqual(0, response?.getHeaderKeys()?.size(), 'Wrong # of headers');
	}

	@IsTest
	static void shouldReturnResponseWithCustomStatusCode() {
		Integer statusCode = 400;
		MockApi.Response responseBuilder = new MockApi.Response()?.withStatusCode(statusCode);
		HttpRequest request = MockApiTest.initRequest();

		Test.startTest();
		HttpResponse response = new Http()?.send(request);
		Test.stopTest();

		Assert.areEqual(statusCode, response?.getStatusCode(), 'Wrong status code');
	}

	@IsTest
	static void shouldReturnResponseWithCustomResponseBody() {
		Map<String, Object> params = new Map<String, Object>{ 'foo' => 'bar' };
		MockApi.Response responseBuilder = new MockApi.Response()?.withBody(params);
		HttpRequest request = MockApiTest.initRequest();

		Test.startTest();
		HttpResponse response = new Http()?.send(request);
		Test.stopTest();

		// The body object passed to the MockApi.Response
		// will be serialized in the HttpResponse's body
		Object body = JSON.deserializeUntyped(response?.getBody());
		Assert.isInstanceOfType(body, Map<String, Object>.class, 'Wrong response body type');
		Map<String, Object> bodyMap = (Map<String, Object>) body;
		Assert.areEqual('bar', bodyMap?.get('foo'), 'Wrong value for "foo"');
	}

	@IsTest
	static void shouldReturnResponseWithCustomResponseHeaders() {
		MockApi.Response responseBuilder = new MockApi.Response()?.withHeader('Content-Type', 'application/json');
		HttpRequest request = MockApiTest.initRequest();

		Test.startTest();
		HttpResponse response = new Http()?.send(request);
		Test.stopTest();

		Assert.areEqual('application/json', response?.getHeader('Content-Type'), 'Wrong header value');
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	static void shouldThrowError() {
		MockApi.Response responseBuilder = new MockApi.Response()?.withError();
		HttpRequest request = MockApiTest.initRequest();

		Test.startTest();
		try {
			new Http()?.send(request);
			Assert.fail('A System.CalloutException was not thrown');
		} catch (System.CalloutException error) {
			// As expected...
		}
	}

	@IsTest
	static void shouldUseCustomResponseToSimulateAuthFailure() {
		MockApi.Response responseBuilder = new CustomResponse();
		HttpRequest request = MockApiTest.initRequest();

		Test.startTest();
		HttpResponse response = new Http()?.send(request);
		Test.stopTest();

		Assert.areEqual(404, response?.getStatusCode(), 'Authorization did not fail');
	}

	@IsTest
	static void shouldUseCustomResponseToSimulateAuthSuccess() {
		// Generate something that approximates a bearer token:
		String fakeToken = System.Uuid.randomUuid().toString()?.replaceAll('-', '');
		MockApi.Response responseBuilder = new CustomResponse();
		HttpRequest request = MockApiTest.initRequest();
		request?.setHeader('Authorization', 'Bearer ' + fakeToken);

		Test.startTest();
		HttpResponse response = new Http()?.send(request);
		Test.stopTest();

		Assert.areEqual(200, response?.getStatusCode(), 'Authorization failed');
	}

	// **** HELPER **** //
	private static HttpRequest initRequest() {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('https://fake-endpoint.com');
		request.setMethod('GET');
		return request;
	}

	// **** INNER **** //
	private class CustomResponse extends MockApi.Response {
		/**
		 * This custom implementation simulates custom api logic
		 * This example fails any requests w/out an Authorization header/Bearer token
		 * Something that a real API might actually do!
		 **/
		public override HttpResponse respond(HttpRequest request) {
			// Check if a Bearer token was passed in the authorization header
			String authHeader = request?.getHeader('Authorization');
			if (authHeader?.startsWith('Bearer ') != true) {
				// If none provided, simulate an failed authorization response
				this.withBody(new Map<String, Object>{ 'error' => 'Unauthorized' });
				this.withStatusCode(404);
			}
			// Resume processing the request as normal
			return super.respond(request);
		}
	}
}
