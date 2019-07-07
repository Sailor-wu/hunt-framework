/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.application.Controller;

import hunt.logging;

public import hunt.framework.http.Response;
public import hunt.framework.http.Request;
public import hunt.framework.routing;
public import hunt.framework.application.MiddlewareInterface;

import hunt.cache;
import hunt.framework.Simplify;
import hunt.framework.view;
import hunt.validation;
import hunt.framework.http.Form;

import std.exception;
import std.traits;

enum Action;

abstract class Controller
{

    protected
    {
        Request request;
        Response _response;
        View _view;
        ///called before all actions
        MiddlewareInterface[string] middlewares;
    }

    @property View view()
    {
        if (_view is null)
        {
            _view = GetViewObject();
            _view.setRouteGroup(this.request.route.getGroup());
            _view.setLocale(this.request.locale());
        }

        return _view;
    }

    final @property Response response()
    {
        if (_response is null)
            _response = new Response(request);
        return _response;
    }

    /// called before action  return true is continue false is finish
    bool before()
    {
        return true;
    }

    /// called after action  return true is continue false is finish
    bool after()
    {
        return true;
    }

    ///add middleware
    ///return true is ok, the named middleware is already exist return false
    bool addMiddleware(MiddlewareInterface m)
    {
        if(m is null || this.middlewares.get(m.name(), null) !is null)
        {
            return false;
        }

        this.middlewares[m.name()]= m;
        return true;
    }

    // get all middleware
    MiddlewareInterface[string] getMiddlewares()
    {
        return this.middlewares;
    }

    @property UCache cache()
    {
        return app().cache();
    }

    @property cacheManger()
    {
        return app().cacheManger();
    }

    protected final Response doMiddleware()
    {
        version (HUNT_DEBUG) logDebug("doMiddlware ..");

        foreach (m; middlewares)
        {
            version (HUNT_DEBUG) logDebugf("do %s onProcess ..", m.name());

            auto response = m.onProcess(this.request, this.response);
            if (response is null)
            {
                continue;
            }

            version (HUNT_DEBUG) logDebugf("Middleware %s is to retrun.", m.name);
            return response;
        }

        return null;
    }

    @property bool isAsync()
    {
        return true;
    }

    string processGetNumericString(string value)
    {
        import std.string;

        if (!isNumeric(value))
        {
            return "0";
        }

        return value;
    }

    Response processResponse(Response res)
    {
        // have ResponseHandler binding?
        // if (res.httpResponse() is null)
        // {
        //     res.setHttpResponse(request.responseHandler());
        // }

        return res;
    }

    void dispose() {

    }
}

mixin template MakeController(string moduleName = __MODULE__)
{
    mixin HuntDynamicCallFun!(typeof(this), moduleName);
}

mixin template HuntDynamicCallFun(T, string moduleName)
{
public:
    // version (HUNT_DEBUG) 
    // pragma(msg, __createCallActionMethod!(T, moduleName));

    mixin(__createCallActionMethod!(T, moduleName));
    shared static this()
    {
        // pragma(msg, __createRouteMap!(T, moduleName));
        mixin(__createRouteMap!(T, moduleName));
    }
}

private
{
    enum actionName = "Action";
    enum actionNameLength = actionName.length;

    bool isActionMember(string name)
    {
        return name.length > actionNameLength && name[$ - actionNameLength .. $] == actionName;
    }
}

string __createCallActionMethod(T, string moduleName)()
{
    import std.traits;
    import std.format;
    import std.string;
    import hunt.logging;
    import std.conv;

    string str = `
        Response callActionMethod(string methodName, Request req) {
        this.request = req; 
        Response actionResult=null;
        version (HUNT_DEBUG) logDebug("methodName=", methodName);
        import std.conv;

        switch(methodName){
    `;

    foreach (memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember, T, memberName)) == function))
        {
            enum _isActionMember = isActionMember(memberName);
            foreach (t; __traits(getOverloads, T, memberName))
            {
                // version (HUNT_DEBUG) pragma(msg, "memberName: " ~ memberName);

                //alias pars = ParameterTypeTuple!(t);
                static if (hasUDA!(t, Action) || _isActionMember)
                {
                    str ~= "\tcase \"" ~ memberName ~ "\": {\n";

                    static if (hasUDA!(t, Action) || _isActionMember)
                    {
                        //before
                        str ~= q{
                            if(this.getMiddlewares().length)
                            {
                                auto response = this.doMiddleware();

                                if (response !is null)
                                {
                                    return response;
                                }
                            }

                            if (!this.before()) return response;
                        };
                    }

                    // Action parameters
                    auto params = ParameterIdentifierTuple!t;
                    string paramString = "";

                    static if (params.length > 0)
                    {
                        import std.conv : to;

                        string varName = "";
                        alias paramsType = Parameters!t;

                        static foreach (int i; 0..params.length)
                        {
                            varName = "var" ~ i.to!string;

                            static if (paramsType[i].stringof == "string")
                            {
                                str ~= "\t\tstring " ~ varName ~ " = request.get(\"" ~ params[i] ~ "\");\n";
                            }
                            else
                            {
                                static if (paramsType[i].stringof == "int" || paramsType[i].stringof == "long" || paramsType[i].stringof == "short" || paramsType[i].stringof == "float" || paramsType[i].stringof == "double"
                                || paramsType[i].stringof == "uint" || paramsType[i].stringof == "ulong" || paramsType[i].stringof == "ushort" || paramsType[i].stringof == "ifloat" || paramsType[i].stringof == "idouble"
                                 || paramsType[i].stringof == "cfloat" || paramsType[i].stringof == "cdouble")
                                    str ~= "\t\tauto " ~ varName ~ " = this.processGetNumericString(request.get(\"" ~ params[i] ~ "\")).to!" ~ paramsType[i].stringof ~ ";\n";
                                else static if(is(paramsType[i] : Form))
                                {
                                    str ~= "\t\tauto " ~ varName ~ " = request.bindForm!" ~ paramsType[i].stringof ~ "();\n";
                                }
                                else
                                    str ~= "\t\tauto " ~ varName ~ " = request.get(\"" ~ params[i] ~ "\").to!" ~ paramsType[i].stringof ~ ";\n";
                            }

                            paramString ~= i == 0 ? varName : ", " ~ varName;

                            varName = "";
                        }
                    }

                    // call Action
                    str ~= "\t\t" ~ ReturnType!t.stringof ~ " result = this." ~ memberName ~ "(" ~ paramString ~ ");\n";

                    static if (is(ReturnType!t : Response))
                    {
                        str ~= "\t\tactionResult = result;\n";
                    }
                    else
                    {
                        str ~= "\t\tactionResult = this.response;\n";

                        static if (!is(ReturnType!t == void))
                        {
                            str ~= "\t\tactionResult.setContent(to!string(result));\n";
                        }
                    }

                    str ~= "\t\tactionResult = this.processResponse(actionResult);\n";

                    static if(hasUDA!(t, Action) || _isActionMember)
                    {
                        str ~= "\t\tthis.after();\n";
                    }
                    str ~= "\n\t\tbreak;\n\t}\n";
                }
            }
        }
    }

    str ~= "\tdefault:\n\tbreak;\n\t}\n\n";
    str ~= "\timport hunt.framework.Simplify;\n";
    str ~= "\tcloseDefaultEntityManager();\n";
    str ~= "\treturn actionResult;\n";
    str ~= "}";

    return str;
}

string __createRouteMap(T, string moduleName)()
{
    string str = "";

    // pragma(msg, "moduleName: ", moduleName);

    str ~= q{
        import hunt.framework.application.StaticfileController;
        addRouteList("hunt.application.staticfile.StaticfileController.doStaticFile", 
            &callHandler!(StaticfileController, "doStaticFile"));
    };

    enum len = "Controller".length;
    string controllerName = moduleName[0..$-len];

    foreach (memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember, T, memberName)) == function))
        {
            foreach (t; __traits(getOverloads, T, memberName))
            {
                static if ( /*ParameterTypeTuple!(t).length == 0 && */ hasUDA!(t, Action))
                {
                    str ~= "\n\taddRouteList(\"" ~ controllerName ~ "." ~ T.stringof ~ "." ~ memberName
                        ~ "\",&callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
                }
                else static if (isActionMember(memberName))
                {
                    enum strippedMemberName = memberName[0 .. $ - actionNameLength];
                    str ~= "\n\taddRouteList(\"" ~ controllerName ~ "." ~ T.stringof ~ "." ~ strippedMemberName
                        ~ "\",&callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
                }
            }
        }
    }

    return str;
}

Response callHandler(T, string method)(Request req)
        if (is(T == class) || is(T == struct) && hasMember!(T, "__CALLACTION__"))
{
    T controller = new T();
    import core.memory;
    scope(exit) {
        controller.dispose();
        if(!controller.isAsync){controller.destroy(); GC.free(cast(void *)controller);}
    }

    req.action = method;
    return controller.callActionMethod(method, req);
}

RoutingHandler getRouteFromList(string str)
{
    if (!_init)
        _init = true;
    return __routerList.get(str, null);
}

void addRouteList(string str, RoutingHandler method)
{
    version (HUNT_DEBUG) logDebug("add router: ", str);
    if (!_init)
    {
        import std.string : toLower;
        __routerList[str.toLower] = method;
    }
}

private:
__gshared bool _init = false;
__gshared RoutingHandler[string] __routerList;
