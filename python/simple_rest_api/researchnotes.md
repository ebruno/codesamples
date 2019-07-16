## Problem Statement ##

Software Engineer Assessment Test: 
You will receive a string as input, potentially a mixture of upper and lower case, numbers, special characters etc.

The task is to determine if the string contains at least one of each letter of the alphabet.

    Return: true if all are found
            false if not.
	    
Write it as a RESTful web service (no authentication necessary) in any language/framework you choose and document the service.
Please bring your laptop on the day of your interview to present your information.

## Use Python ##
The easiest way to this is a using python sets
refset = set('abcdefghijklmnopqrstuvwxyz')
result_set = refset - indata
result = False

if len(result__set) == 0:
  result = True

## Testing Tools ##

http://webtest.pythonpaste.org/en/latest/testapp.html#making-requests

key	Value	Comments
	 REQUEST_METHOD	"GET"	
	 SCRIPT_NAME	""	server setup dependent
	 PATH_INFO	"/auth"	
	 QUERY_STRING	"token=123"	
	 CONTENT_TYPE	""	
	 CONTENT_LENGTH	""
         SERVER_NAME	"127.0.0.1"	server setup dependent
         SERVER_PORT	"8000"	
         SERVER_PROTOCOL	"HTTP/1.1"	
         HTTP_(...)		Client supplied HTTP headers
         wsgi.version	(1, 0)	tuple with WSGI version
         wsgi.url_scheme	"http"	
         wsgi.input		File-like object
         wsgi.errors		File-like object
         wsgi.multithread	False	True if server is multithreaded
         wsgi.multiprocess	False	True if server runs multiple processes
         wsgi.run_once	False	True if the server expects this script to run only once (e.g.: in a CGI environment)


## References ##
Hands on RESTFul API Desing Patterns Best Practices (https://learning.oreilly.com/library/view/hands-on-restful-api/9781788992664/)
by Pethuru Raj; Harihara Subramanian
Published by Packt Publishing, 2019

## Naming Conventions ##
  - Use singular nouns for document names
      /users/memberstatus
  - Use plual nouns for collections and Stores
     /users

  - Controller names repsetn an action, use verb  or verb phase for controller resources
     profiles/users/memberstatus/reset


## HTTP Headers ##

The following points suggest a few sets of rules conforming to the HTTP standard headers:

 - Should use content-type: Client and servers rely on this header to indicate how to process the message's body, as the value of the content-type
specifies the form of the data contained in the request or response message body called media types.

 - Should use content-length: The client should know the size of the message body that it is about to read. The other benefit is that the client
gets to know how large the response body is that it needs to download, without needing to download the whole response by making a HEAD request.

 - Should use last-modified in responses: The response should specify the timestamp when the representational state of the required resource
was modified or updated so that the client and cache intermediaries can rely on this header to determine the freshness of their local
copies of a resource's state representation. The last-modified header should be part of their requests.

 - Should use ETag in responses: Entity tag (ETag) is an HTTP header that helps the client to identify a specific version of the
   resources they asked for. The server should always respond with the ETag as a header for the client GET requests. The value
   of the ETag is commonly a digest (hash value, for instance, MD5 hash) of the resource contents so that the server can identify
   whether the cached contents of the resources are different from the latest version of the resources. ETag differs from the
   last-modified header by the value (resource content as digest versus timestamp). This header value enables the client to
   choose whether or not to send the representation again by using If-Non-Match conditionals in the future GET requests.
   If the ETag value hasn't changed, then the client can decide to save time and bandwidth by not sending the representation
   again in their subsequent GET requests.

- Stores must support conditional PUT requests: REST API can support conditional PUT requests by relying on client requests with If-Unmodified-Since, and/or If-Match request headers. As the store resources use the PUT method for both inserts and updates, the REST API should know the client's intent of the PUT requests. PUT is the same as POST except PUT is *idempotent. Please note that HTTP supports conditional requests with the GET, POST , and DELETE methods; this is an essential pattern for allowing writable REST APIs to help collaboration among API clients.

From a RESTful service standpoint, the idempotent of a service call means the calls that the client makes produce the same results for all calls; that is, multiple requests from the clients produce the same effect as a single request. Please note that the same result or behavior is on the server. However, the response that the client receives may not be the same as the resource state may change between the requests.

- Should use the location to specify the URI of newly created resources (through PUT): In response to the successful creation of resources through collections or stores, the API should provide the location (URI) of the newly created resource as a response header. The location header can be part of the status code 202 response to direct the clients about the status of their asynchronous call.

 - Should leverage HTTP cache headers: This is to encourage caching, provide cache-control, Expires, and date-response headers to leverage caching at various levels, such as the API server side, content delivery networks (CDN), or even at the client's network. Some examples are as follows:
   
    Cache-Control: max-age=90, must-revalidate (max-age is in seconds)
    For HTTP 1.0 based caches,Date: Tue, 29 Apr 2018 08:12:31 GMTExpires: Fri, 04 May 2018 16:00:00 GMT
    To discourage caching, add cache-control headers with no-cache and no-store, with the following:

For HTTP 1.0 legacy caches
Add the Pragma—no-cache and Expires—0 header values
However, unless necessary, REST API should always provoke caching of responses, maybe by shorter
duration instead of using a no-cache directive. So the clients get faster responses for frequent access requests by fetching the short-lived response copies.

   - Should use expiration headers with 200 ("OK") responses: Setting expiration caching headers in response to the
     successful GET and HEAD requests encourages caching at the client side. Please note that the POST method is
     also cacheable, and so don't treat this method as non-cacheable.
  - May use expiration caching headers with 3xx and 4xx responses: In addition to status code 200 ("OK": successful responses),
    the APIs can include caching headers for 3xx and 4xx responses, also known as negative caching.
    It helps the REST API server with a reduction in loads due to some redirection and error triggers.
    Mustn't use custom HTTP headers: The primary purpose of custom HTTP headers is to provide additional information and
   troubleshooting tips for app developers; however, for some distinctive cases at the server side, it comes in handy
   unless those cases do not change the behavior of the HTTP methods. An example could be an API that makes use of
   the X-cache header to let app developers know whether the resource is delivered by the origin server or by the
   edge server. If the information that should go through a custom HTTP header is critical in that it needs an
   accurate interpretation of the request or response, then it is better for it to be included in the body of
   the request or response or in the URI used for that request.

Uses application-specific media types: REST APIs treat the body of an HTTP request or response as part of an application-specific interaction. While the request or response body is built with languages such as JSON or XML, it typically has semantics that requires special processing beyond merely parsing the language's syntax. An example representation of such a REST API URI is https://swapi.co/api/planets/1 that responds to the GET requests with a representation of the Star Wars planet resource that's formatted using JSON.
Supports media type negotiations in case of multiple representations: The client may require different formats and schema by submitting the desired media type as part of the Accept header, so the API should allow the clients to get the response in the desired format.Following is an example representation of the media type negotiations from developer.atlassian.com for the following Accept header:


## HTTP Response codes ##

     1×× Informational
     100 Continue
     101 Switching Protocols
     102 Processing
     2×× Success
     200 OK
     201 Created
     202 Accepted
     203 Non-authoritative Information
     204 No Content
     205 Reset Content
     206 Partial Content
     207 Multi-Status
     208 Already Reported
     226 IM Used
     3×× Redirection
     300 Multiple Choices
     301 Moved Permanently
     302 Found
     303 See Other
     304 Not Modified
     305 Use Proxy
     307 Temporary Redirect
     308 Permanent Redirect
     4×× Client Error
     400 Bad Request
     401 Unauthorized
     402 Payment Required
     403 Forbidden
     404 Not Found
     405 Method Not Allowed
     406 Not Acceptable
     407 Proxy Authentication Required
     408 Request Timeout
     409 Conflict
     410 Gone
     411 Length Required
     412 Precondition Failed
     413 Payload Too Large
     414 Request-URI Too Long
     415 Unsupported Media Type
     416 Requested Range Not Satisfiable
     417 Expectation Failed
     418 I'm a teapot
     421 Misdirected Request
     422 Unprocessable Entity
     423 Locked
     424 Failed Dependency
     426 Upgrade Required
     428 Precondition Required
     429 Too Many Requests
     431 Request Header Fields Too Large
     444 Connection Closed Without Response
     451 Unavailable For Legal Reasons
     499 Client Closed Request
     5×× Server Error
     500 Internal Server Error
     501 Not Implemented
     502 Bad Gateway
     503 Service Unavailable
     504 Gateway Timeout
     505 HTTP Version Not Supported
     506 Variant Also Negotiates
     507 Insufficient Storage
     508 Loop Detected
     510 Not Extended
     511 Network Authentication Required
     599 Network Connect Timeout Error