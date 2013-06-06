# Data::Stitch version 1

License: MIT
Tags: cfdc, data, stitch, template
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Build file from class-controlled pieces in format 'context::line_to_insert'.  Limitation: the pieces concatenated must not exceed MAXVARSIZE.

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## API
### bundle: cfdc_stitch
* parameter _string_ *filename* (default: none, description: File to edit (overwriting).)

* parameter _array_ *pieces* (default: none, description: key-value array of pieces in format CONTEXT::PIECE.  Keys should sort() sequentially.  Best use numbers like 000, 001, etc. for the keys or simply pass a JSON list.)

* returns _return_ *built* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

