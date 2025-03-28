@IsTest
public class MockApi {
	/**
	 * A simple, flexible API mocking layer that allows callers to test a variety of response types
	 * Use this class to simulate your HttpCallouts in apex tests, usually with just a couple of lines of test code!
	 **/
	public virtual class Response implements System.HttpCalloutMock {
		// Note: Inner class is necessary since @IsTest doesn't allow for virtual types
		protected String body;
		protected Exception calloutError;
		protected Map<String, String> headers;
		protected Integer statusCode;

		public Response() {
			this.headers = new Map<String, String>();
			this.statusCode = 200;
			this.setMock();
		}

		public virtual String generateResponseBody(HttpRequest request) {
			// Note: If not set, this class will return an empty JSON body
			return this.body ?? '{}';
		}

		public virtual HttpResponse respond(HttpRequest request) {
			if (this.calloutError != null) {
				throw this.calloutError;
			} else {
				HttpResponse response = new HttpResponse();
				response?.setBody(this.generateResponseBody(request));
				response?.setStatusCode(this.statusCode);
				this.setResponseHeaders(response);
				return response;
			}
		}

		public MockApi.Response setMock() {
			Test.setMock(System.HttpCalloutMock.class, this);
			return this;
		}

		public virtual MockApi.Response withBody(String body) {
			this.body = body;
			return this;
		}
		
		public MockApi.Response withBody(Object bodyObj) {
			return this.withBody(JSON.serialize(bodyObj));
		}

		public virtual MockApi.Response withError(Exception error) {
			this.calloutError = error;
			return this;
		}

		public MockApi.Response withError() {
			return this.withError(new System.CalloutException());
		}

		public MockApi.Response withHeaders(Map<String, String> headers) {
			this.headers?.putAll(headers);
			return this;
		}

		public MockApi.Response withHeader(String key, String value) {
			return this.withHeaders(new Map<String, String>{ key => value });
		}

		public virtual MockApi.Response withStatusCode(Integer statusCode) {
			this.statusCode = statusCode;
			return this;
		}

		protected void setResponseHeaders(HttpResponse response) {
			// Set the response headers
			for (String key : this.headers?.keySet()) {
				String value = this.headers?.get(key);
				response?.setHeader(key, value);
			}
		}
	}
}
