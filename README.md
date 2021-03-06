[![Build Status](https://travis-ci.org/huntlabs/hunt-framework.svg?branch=master)](https://travis-ci.org/huntlabs/hunt-framework)

## Hunt framework
[Hunt](http://www.huntframework.com/) is a high-level [D Programming Language](http://dlang.org/) Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
![Framework](framework.png)

## Documents
- [Wiki](https://github.com/huntlabs/hunt-framework/wiki)
- [Tutorial](https://github.com/huntlabs/hunt-framework-docs)
- [Articles](https://github.com/huntlabs/hunt-framework-articles)


## Create a project
```bash
git clone https://github.com/huntlabs/hunt-skeleton.git myproject
cd myproject
dub run -v
```

Open the URL with the browser:
```bash
http://localhost:8080/
```

## Router config
config/routes
```conf
#
# [GET,POST,PUT...]    path    controller.action
#

GET     /               index.index
GET     /users          user.list
POST    /user/login     user.login
*       /images         staticDir:public/images

```

## Controller example
```D
module app.controller.index;

import hunt.framework;

class IndexController : Controller
{
    mixin MakeController;

    @Action
    string index()
    {
        return "Hello world!";
    }
}
```

For more, see [hunt-skeleton](https://github.com/huntlabs/hunt-skeleton) or [hunt-examples](https://github.com/huntlabs/hunt-examples).

## Components
1. [Routing](https://github.com/huntlabs/hunt-framework/wiki/Routing)
2. [Caching](https://github.com/huntlabs/hunt-framework/wiki/Cache)
3. [Middleware](https://github.com/huntlabs/hunt-framework/wiki/Middleware)
4. [Configuration](https://github.com/huntlabs/hunt-framework/wiki/Configuration)****
5. [Validation](https://github.com/huntlabs/hunt-framework/wiki/Validation)
6. [Entity & Repository](https://github.com/huntlabs/hunt-framework/wiki/Database)
7. [Form](https://github.com/huntlabs/hunt-framework/wiki/Form)
7. [Template Engine](https://github.com/huntlabs/hunt-framework/wiki/View)
8. Task Worker
9. Security
10. Queue

## Community
QQ Group: 184183224 

[Github](https://github.com/huntlabs/hunt-framework/issues)

## For Chinese users
[D语言中文社区](https://forums.dlangchina.com/)

