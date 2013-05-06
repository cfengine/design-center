# Utilities::OpenSSL::GenCert version 1

License: MIT
Tags: cfdc
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sketch for generating self-signed certificates

## Dependencies
CFEngine::stdlib

## API
### bundle: openssl_gencert
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *cert_path* (default: none, description: none)

* parameter _string_ *owner* (default: `"root"`, description: none)

* parameter _string_ *group* (default: `"root"`, description: none)

* parameter _string_ *valid_days* (default: `"365"`, description: none)

* parameter _string_ *country* (default: `"US"`, description: none)

* parameter _string_ *state* (default: `"CA"`, description: none)

* parameter _string_ *locality_name* (default: `"Los Angeles"`, description: none)

* parameter _string_ *organization* (default: `"Example Inc."`, description: none)

* parameter _string_ *org_unit_name* (default: `"IT Department"`, description: none)

* parameter _string_ *common_name* (default: `"$(sys.fqhost)"`, description: none)

* parameter _string_ *email* (default: `"example@example.org"`, description: none)

* returns _return_ *certificate_path* (default: none, description: none)

* returns _return_ *cn* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

