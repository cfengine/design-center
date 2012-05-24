# File-based package installation through custom execution

##AUTHOR
Eystein Måløy Stenberg <eystein@cfengine.com>

##PLATFORM
Windows

##DESCRIPTION
Scans a directory for any new or changed files. Any found .msi files are
installed with msiexec, while any .bat and .exe files are executed in a shell
environment. Does nothing with files not having any of these suffixes.
Note that interactive installations/error dialogue boxes will cause problems 
for automation (as always).

##REQUIREMENTS
 * A directory or share with package files, currently .msi, .bat and .exe are supported types
 * cfengine_stdlib.cf

##SAMPLE USAGE
    body common control
    {
    bundlesequence => { "packages" };
    inputs => { "cfengine_stdlib.cf", "filebased_execution.cf" };
    }

    bundle agent packages
    {
    methods:
      "any" usebundle => filebased_execution( "\\\\myhost\repo" );
    }

##TODO
 * Support Unix packages: take accepted file-types and respective managers as parameters
 * Test with interactive installations, handle (abort and report) - with expireafter?
 * Introduce native support in packages: promises to make this sketch obsolete
