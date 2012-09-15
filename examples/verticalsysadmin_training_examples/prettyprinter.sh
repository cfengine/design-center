#!/bin/sh

# Based on Diego Zamboni's shell script.

if [[ $# -eq 0 ]]; then
  FILES=src/*.cf
else
  FILES="$@"
fi

for i in $FILES; do
  echo "Processing $i ..."
  emacs --batch $i --eval '(progn  (push '"'"'("\\.cf\\'"'"'" . cfengine3-mode) auto-mode-alist) (setq-default cfengine-parameters-indent (quote (promise arrow 16))) (setq-default indent-tabs-mode nil)   (defvar cfengine-indent 2)  (cfengine3-mode)  (indent-region (point-min) (point-max) nil) (untabify (point-min) (point-max)))' --eval '(write-region (point-min) (point-max) "'`basename $i.new`'")' && mv $i.new $i 
done
