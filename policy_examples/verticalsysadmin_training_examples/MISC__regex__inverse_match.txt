Let's say you want to write a regex that will match any string that does NOT contain the string "hello world". Use:

^((?!hello world).)*$

This is explained in http://stackoverflow.com/questions/406230/regular-expression-to-match-string-not-containing-a-word
