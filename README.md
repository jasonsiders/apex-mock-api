# apex-mock-api

The `MockApi` class is a simple framework for mocking Http callouts in Salesforce Apex Tests.

The class uses the [`System.HttpCalloutMock`](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_restful_http_testing_httpcalloutmock.htm) interface, along with a simple builder object to easily construct responses to HttpCallouts.

## Getting Started

`apex-mock-api` is available for free, as an unlocked package. You can find the latest or past versions in the [Releases](https://github.com/jasonsiders/apex-mock-api/releases) tab.

Use the following command to install the package in your environment:

```sh
sf package install -p {{package_version_id}}
```

## Usage

Use the `MockApi.Response` class in your Apex unit tests to mock HttpCallouts. Simply creating a new `MockApi.Response` object will impliciltly call `Test.setMock` under the hood.

You can easily customize your responses, either by using the base `MockApi.Response` object, or you can implement your own custom API logic by extending this class.

### Simple Responses

Most simple responses can be implemented with just a couple of lines of code.

<details>
    <summary><b>Example: Simple Response</b></summary>

```java
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
```

</details>

You can add specific details, like a status code, headers, or return body using the `MockApi.Request`'s builder methods:

<details>
    <summary><b>Example: Simple Response w/Custom Return Values</b></summary>

```java
@IsTest
static void shouldReturnResponseWithCustomValues() {
    MockApi.Response responseBuilder = new MockApi.Response()
        ?.withBody(new Map<String, Object>{ 'foo' => 'bar' })
        ?.withHeader('Content-Type', 'application/json')
        ?.withStatusCode(400);
    HttpRequest request = MockApiTest.initRequest();

    Test.startTest();
    HttpResponse response = new Http()?.send(request);
    Test.stopTest();

    Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
        JSON.serialize(response?.getBody())
    );
    Assert.areEqual('bar', body?.get('foo'), 'Unexpected body');
    Assert.areEqual(400, response?.getStatusCode(), 'Wrong status code');
    Assert.areEqual('application/json', response?.getHeader('Content-Type'), 'Unexpected headers');
}
```

</details>

<details>
    <summary><b>Example: Simulate Callout Exceptions</b></summary>

```java
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
```

</details>

### Custom Response Logic

For more complex processing logic, you can extend the `MockApi.Response` class and its methods to accurately simulate a certain API's behavior:

<details>
    <summary><b>Example: Extending the <code>MockApi.Response</code></b></summary>

```java
@IsTest
static void shouldUseCustomResponseToSimulateAuthFailure() {
    MockApi.Response responseBuilder = new CustomResponse();
    HttpRequest request = MockApiTest.initRequest();

    Test.startTest();
    HttpResponse response = new Http()?.send(request);
    Test.stopTest();

    Assert.areEqual(404, response?.getStatusCode(), 'Authorization did not fail');
}

private class CustomResponse extends MockApi.Response {
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
```

</details>
