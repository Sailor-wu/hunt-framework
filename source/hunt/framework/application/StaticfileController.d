module hunt.framework.application.StaticfileController;

import core.time;
import std.array;
import std.conv;
import std.string;
import std.datetime;
import std.file;
import std.path;
import std.digest.md;
import std.stdio;
import std.algorithm.searching : canFind;

import hunt.logging;

import hunt.framework;
import hunt.framework.application.Controller;
import hunt.framework.util.String;

import hunt.http.codec.http.model.HttpHeader;
import hunt.http.codec.http.model.HttpStatus;

/**
 * TODO: This module can use FileResponse send file.
 */
class StaticfileController : Controller
{
    mixin MakeController;

    @Action
    Response doStaticFile()
    {
        string currentPath = request.route.staticFilePath;
        if (currentPath.empty)
            currentPath = config().http.path;
        version (HUNT_HTTP_DEBUG) logDebug("currentPath: ", currentPath);

        string staticFilename = mendPath(currentPath);
        version (HUNT_HTTP_DEBUG) {
            logDebug ("staticFilename: ", staticFilename);
        }
        staticFilename = buildPath(APP_PATH, staticFilename);
        version (HUNT_HTTP_DEBUG) {
            info("fullname: ", staticFilename);
        }

        if (staticFilename.empty)
        {
            response.do404();
            return response;
        }

        currentPath = staticFilename;
        string[] defaultIndexFiles = ["index.html", "index.htm", "default.html", "default.htm", "home.html"];
        bool isFileExisted = exists(currentPath);
        if(isFileExisted && isDir(currentPath))
        {
            isFileExisted = false;
            if(currentPath[$-1] != '/')
                currentPath ~= "/";
            foreach(string f; defaultIndexFiles)
            {
                staticFilename = currentPath ~ f;
                if(exists(staticFilename))
                {
                    isFileExisted = true;
                    break;
                }
            }
        }

        if (!isFileExisted)
        {
            logWarning("No default index files (like index.html) in: ", currentPath);
            response.do404();
            return response;
        }

        FileInfo fi;
        try
        {
            fi = makeFileInfo(staticFilename);
        }
        catch (Exception e)
        {
            response.doError(HttpStatus.INTERNAL_SERVER_ERROR_500);
            return response;
        }

        auto lastModified = toRFC822DateTimeString(fi.timeModified.toUTC());
        auto etag = "\"" ~ hexDigest!MD5(staticFilename ~ ":" ~ lastModified ~ ":" ~ to!string(fi.size)).idup ~ "\"";

        response.setHeader(HttpHeader.LAST_MODIFIED, lastModified);
        response.setHeader(HttpHeader.ETAG, etag);

        if (config().application.staticFileCacheMinutes > 0)
        {
            auto expireTime = Clock.currTime(UTC()) + dur!"minutes"(config().application.staticFileCacheMinutes);
            response.setHeader(HttpHeader.EXPIRES, toRFC822DateTimeString(expireTime));
            response.setHeader(HttpHeader.CACHE_CONTROL, "max-age=" ~ to!string(config().application.staticFileCacheMinutes * 60));
        }

        if ((request.headerExists(HttpHeader.IF_MODIFIED_SINCE) && (request.header(HttpHeader.IF_MODIFIED_SINCE) == lastModified)) ||
            (request.headerExists(HttpHeader.IF_NONE_MATCH) && (request.header(HttpHeader.IF_NONE_MATCH) == etag)))
        {
                response.setStatus(HttpStatus.NOT_MODIFIED_304);
                return response;
        }

        auto mimetype = getMimeTypeByFilename(staticFilename);
        response.setHeader(HttpHeader.CONTENT_TYPE, mimetype ~ ";charset=utf-8");

        response.setHeader(HttpHeader.ACCEPT_RANGES, "bytes");
        ulong rangeStart = 0;
        ulong rangeEnd = 0;

        if (request.headerExists(HttpHeader.RANGE))
        {
            // https://tools.ietf.org/html/rfc7233
            // Range can be in form "-\d", "\d-" or "\d-\d"
            auto range = request.header(HttpHeader.RANGE).chompPrefix("bytes=");
            if (range.canFind(','))
            {
                response.doError(HttpStatus.NOT_IMPLEMENTED_501);
                return response;
            }
            auto s = range.split("-");

            if (s.length != 2)
            {
                response.doError(HttpStatus.BAD_REQUEST_400);
                return response;
            }

            try
            {
                if (s[0].length)
                {
                    rangeStart = s[0].to!ulong;
                    rangeEnd = s[1].length ? s[1].to!ulong : fi.size;
                }
                else if (s[1].length)
                {
                    rangeEnd = fi.size;
                    auto len = s[1].to!ulong;

                    if (len >= rangeEnd)
                    {
                        rangeStart = 0;
                    }
                    else
                    {
                        rangeStart = rangeEnd - len;
                    }
                }
                else
                {
                    response.doError(HttpStatus.BAD_REQUEST_400);
                    return response;
                }
            }
            catch (ConvException e)
            {
                response.doError(HttpStatus.BAD_REQUEST_400, e.msg);
                return response;
            }

            if (rangeEnd > fi.size)
            {
                rangeEnd = fi.size;
            }

            if (rangeStart > rangeEnd)
            {
                rangeStart = rangeEnd;
            }

            if (rangeEnd)
            {
                rangeEnd--; // End is inclusive, so one less than length
            }
            // potential integer overflow with rangeEnd - rangeStart == size_t.max is intended. This only happens with empty files, the + 1 will then put it back to 0

            response.setHeader(HttpHeader.CONTENT_LENGTH, to!string(rangeEnd - rangeStart + 1));
            response.setHeader(HttpHeader.CONTENT_RANGE, "bytes %s-%s/%s".format(rangeStart < rangeEnd ? rangeStart : rangeEnd, rangeEnd, fi.size));
            response.setStatus(HttpStatus.PARTIAL_CONTENT_206);
        }
        else
        {
            rangeEnd = fi.size - 1;
            response.setHeader(HttpHeader.CONTENT_LENGTH, fi.size.to!string);
        }

        // write out the file contents
        auto f = std.stdio.File(staticFilename, "r");
        scope(exit) f.close();

        f.seek(rangeStart);
        int remainingSize = rangeEnd.to!uint - rangeStart.to!uint + 1;
        if(remainingSize <= 0) {
            warningf("actualSize:%d, remainingSize=%d", fi.size, remainingSize);
        } else {
            auto buf = f.rawRead(new ubyte[remainingSize]);
            response.setContent(buf);
        }

        return response;
    }

    private string mendPath(string path)
    {
        if (!path.startsWith(".") && !isAbsolute(path))
        {
            path = "./" ~ path;
        }

        if (!path.endsWith("/"))
        {
            path ~= "/";
        }

        return path ~ chompPrefix(request.path, request.route.getPattern());
    }

    private struct FileInfo {
        string name;
        ulong size;
        SysTime timeModified;
        SysTime timeCreated;
        bool isSymlink;
        bool isDirectory;
    }

    private FileInfo makeFileInfo(string fileName)
    {
        FileInfo fi;
        fi.name = baseName(fileName);
        auto ent = DirEntry(fileName);
        fi.size = ent.size;
        fi.timeModified = ent.timeLastModified;
        version(Windows) fi.timeCreated = ent.timeCreated;
        else fi.timeCreated = ent.timeLastModified;
        fi.isSymlink = ent.isSymlink;
        fi.isDirectory = ent.isDir;

        return fi;
    }

    private bool isCompressedFormat(string mimetype)
    {
        switch (mimetype)
        {
            case "application/gzip", "application/x-compress", "application/png", "application/zip",
                    "audio/x-mpeg", "image/png", "image/jpeg",
                    "video/mpeg", "video/quicktime", "video/x-msvideo",
                    "application/font-woff", "application/x-font-woff", "font/woff":
                return true;
            default: return false;
        }
    }
}
