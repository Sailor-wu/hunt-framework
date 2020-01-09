﻿/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.routing.Define;

// import hunt.logging;

// import hunt.framework.http.Request;
// import hunt.framework.http.Response;

// import hunt.http.routing.RoutingContext;

// import std.exception;

// // default route group name
// enum DEFAULT_ROUTE_GROUP = "default";

// // alias RoutingHandler = Response function(Request);

// // alias RoutingHandler = void delegate(RoutingContext context);

// // support methods
// enum HTTP_METHODS {
//     GET = 1,
//     POST,
//     PUT,
//     DELETE,
//     HEAD,
//     OPTIONS,
//     PATCH,
//     ALL
// }

// HTTP_METHODS getMethod(string method) {
//     with (HTTP_METHODS) {
//         if (method == "POST")
//             return POST;
//         else if (method == "GET")
//             return GET;
//         else if (method == "PUT")
//             return PUT;
//         else if (method == "DELETE")
//             return DELETE;
//         else if (method == "HEAD")
//             return HEAD;
//         else if (method == "OPTIONS")
//             return OPTIONS;
//         else if (method == "PATCH")
//             return PATCH;
//         else if (method == "*")
//             return ALL;
//         else
//             throw new Exception("unkonw method: (" ~ method ~ ")");
//     }
// }

// HTTP_METHODS[] stringToHTTPMethods(string method) {
//     with (HTTP_METHODS) {
//         if (method == "POST")
//             return [POST];
//         else if (method == "GET")
//             return [GET];
//         else if (method == "PUT")
//             return [PUT];
//         else if (method == "DELETE")
//             return [DELETE];
//         else if (method == "HEAD")
//             return [HEAD];
//         else if (method == "OPTIONS")
//             return [OPTIONS];
//         else if (method == "PATCH")
//             return [PATCH];
//         else if (method == "*")
//             return [GET, POST, PUT, DELETE, HEAD, OPTIONS, PATCH];
//         else
//             throw new Exception("unkonw method");
//     }
// }
