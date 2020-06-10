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

module hunt.framework.middleware.MiddlewareInterface;

import hunt.framework.http.Request;
import hunt.framework.http.Response;


interface MiddlewareInterface
{
    ///get the middleware name
    string name();
    
    ///return null is continue, response is close the session
    Response onProcess(Request request, Response response = null);
}
