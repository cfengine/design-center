# The Design Center API

## Design Center HOWTO series

### Author: Ted Zlatanov <tzz@lifelogs.com>

### Version: 1.0.0

### API General Information

The Design Center API (DC API or just API henceforth) is a simple JSON-based
protocol for communicating with the Design Center backend.  The backend may be
running locally or remotely; the API makes no assumptions about the transport
channel and is entirely a line-based text protocol consisting of *one* JSON line
each way.

The API client makes a request and gets a response over the same channel.
Again, the request and the response can only be a single line of text, ended by
the transport channel's standard line-ending sequence, e.g. CRLF for HTTP.  JSON
escapes such sequences so they should not happen anywhere in the payloads.

API requests have the following general structure:

    { dc_api_version: "0.0.1", request: { ...commands... } }

The version is strictly semantically versioned as *major.minor.patch*.  It must
match exactly, so you can't have a _0.0.1_ client talking to a _0.0.2_ server
for instance (the client has to say "0.0.2" to be usable).  We expect backwards
compatibility, this is just a way to avoid misunderstandings.

#### NOTE: Generally, only *one* command may be specified per request.

API responses look like this:

    {"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{ ...response data... }}}

The top key can be one of the following:

* `api_ok`: the command was processed correctly and the response is enclosed as
  valid JSON (note that this doesn't mean the response indicates success!!!)
  
* `api_error`: the command was not processed correctly and the response may not
  be valid JSON at all.  It may be good JSON and even contain keys like `api_ok`
  promises, e.g. `warnings` or `success`, but you can't rely on that.

The API client may wish to replace unparseable data with
`{api_error: "BAD JSON (escaped data here)"}` or something similar to make the
response handler simpler.

Inside the API response, under the `api_ok` key, you can expect to find the following:

* `success`: indicates, generally speaking, that the command succeeded or
  failed.  Any complex commands can fail in subtle ways, but the API will do its
  best to make this a good indicator.
  
* `errors` and `warnings`: lists of strings that log errors and warnings for the
  command.
  
* `error_tags`: key-value array of tag strings assigned to the error messages.
  This lets the client tell what stages or areas of the command triggered the
  errors.
  
* `log`: list of general message strings.  This is optional and purely informational.
  
* `tags`: key-value array of tag strings assigned to the response, not
  associated with errors.  This lets the client tell what stages or areas of the
  command triggered messages or warnings, or more generally what stages or areas
  of the command were executed.  This is optional and purely informational.

* `data`: the meat of the response plate, if you will.  This key contains all
  the response data that the API command generated.  Each command has different
  return data so the specifics are listed per command.
  
### API Commands

The API commands and their data responses are listed below.  Generally they are
exclusive of each other, and the order below is the order in which they are
answered.  Thus, for instance, a request that issues both `list` and `search`
will get just the `list` results.

#### list

##### option: describe

#### search

##### option: describe

#### describe

#### install

#### uninstall

#### compositions

#### compose

#### decompose

#### activations

#### activate

##### option: compose

#### deactivate

#### definitions

#### define

#### undefine

#### environments

#### define_environment

#### undefine_environment

#### validations

#### define_validation

#### undefine_validation

#### regenerate
