# Normal Ordering And Promise Convergence In CFEngine 3.4.x

## Design Center HOWTO series

### Author: Ted Zlatanov <tzz@lifelogs.com>

### Version: 3.4.0-0

This is an introduction to normal ordering, meaning the standard order in which CFEngine processes promises.

Important terms:

* _promise_: the basic computation unit of promise theory
* _promise type_: a functional classification of promises (what they *do*, their *function*)
* _bundle_: a logical grouping of promises (what they are *for*, relating them by *purpose*)
* _convergence_: the process by which CFEngine evaluates and resolves promises (variables and classes are types of promises, too)

It's important to remember that the following is the current state of affairs as of CFEngine 3.4.0.  The convergence algorithms and number of passes may change in the future.

CFEngine is not a programming language.  The less you think of it as a programming language, the easier it will be to work within the framework it offers.  If you know Makefiles, CFEngine has similar traits in being declarative and establishing dynamic relationships and dependencies between promises.

When CFEngine converges a bundle, it needs to do it in some order.  The normal ordering is the order in which promises are converged by promise type.  In addition you can force ordering with `ifvarclass` and contexts.  In addition, new in 3.4.0, the `depends_on` promise attribute also lets you explicitly say that one promise handle depends on others to be converged first.

The global convergence logic converges a bundle a limited number of times before moving on.  The number is set during compilation and is 3 by default.  This means that if you have promise _X_ use promise _Y_ which uses promise _Z_ that's usually OK.  But if you have a chain of 4 or more promises, they may not converge in 3 convergence cycles.

If you find yourself ordering promises explicitly, generally you're approaching the problem incorrectly.  There are rare exceptions when you have to require a specific order of promises, but it's a sure sign of inexperience using CFEngine to try to order all the promises you write.  Trust CFEngine to do the right thing.

Variables and classes are converged 3 times each within the wider 3-cycle iteration, as indicated by the `1 2 3` in the table.  This is done to allow for deeper dependencies between variables and between classes, and to make life easier for the promise author so they don't have to micro-manage their variables and classes.  So if you have variable or class _a_ depending on variable or class _b_ which depends on variable or class _c_, that dependency will be resolved in the *first* cycle before you get to the outputs promise types and beyond.  Again, please remember the convergence algorithms and number of passes may change in the future.  You should not be thinking in terms of iterations and cycles when you work with CFEngine.

|Promise Type       |agent/common|server|monitor|edit_line|Purpose|Reference URL|
|-------------------|------------|------|-------|---------|-------|-------------|
|meta               |Y           |Y     |Y      |Y        |Bundle metadata|https://cfengine.com/manuals/cf3-Reference#meta-in-common-promises|
|vars               |1 2 3       |Y     |Y      |Y        |Declare variables|https://cfengine.com/manuals/cf3-Reference#vars-in-common-promises|
|defaults           |Y           |Y     |Y      |Y        |Variable default values|https://cfengine.com/manuals/cf3-Reference#defaults-in-common-promises|
|classes            |1 2 3       |Y     |Y      |Y        |Determine classes|https://cfengine.com/manuals/cf3-Reference#classes-in-common-promises|
|outputs            |Y           |      |       |         |Verbosity control|https://cfengine.com/manuals/cf3-Reference#outputs-in-agent-promises|
|interfaces         |Y           |      |       |         |Net interfaces|https://cfengine.com/manuals/cf3-Reference#interfaces-in-agent-promises|
|files              |Y           |      |       |         |File control+edit|https://cfengine.com/manuals/cf3-Reference#files-in-agent-promises|
|packages           |Y           |      |       |         |Package control|https://cfengine.com/manuals/cf3-Reference#packages-in-agent-promises|
|guest_environments |Y           |      |       |         |libvirt control|https://cfengine.com/manuals/cf3-Reference#guest_005fenvironments-in-agent-promises|
|methods            |Y           |      |       |         |Call bundles|https://cfengine.com/manuals/cf3-Reference#method-in-agent-promises|
|processes          |Y           |      |       |         |Process control|https://cfengine.com/manuals/cf3-Reference#processes-in-agent-promises|
|services           |Y           |      |       |         |Service control|https://cfengine.com/manuals/cf3-Reference#services-in-agent-promises|
|commands           |Y           |      |       |         |Call commands and modules|https://cfengine.com/manuals/cf3-Reference#commands-in-agent-promises|
|storage            |Y           |      |       |         |Mounts and volumes|https://cfengine.com/manuals/cf3-Reference#storage-in-agent-promises|
|databases          |Y           |      |       |         |Database control|https://cfengine.com/manuals/cf3-Reference#databases-in-agent-promises|
|access             |            |Y     |       |         |Access control rules|https://cfengine.com/manuals/cf3-Reference#access-in-server-promises|
|roles              |            |Y     |       |         |Server-side class write control|https://cfengine.com/manuals/cf3-Reference#roles-in-server-promises|
|measurements       |            |      |Y      |         |Measurement probes|https://cfengine.com/manuals/cf3-Reference#measurements-in-monitor-promises|
|delete_lines       |            |      |       |Y        |Delete lines|https://cfengine.com/manuals/cf3-Reference#delete_005flines-in-edit_005fline-promises|
|field_edits        |            |      |       |Y        |Edit lines by field|https://cfengine.com/manuals/cf3-Reference#field_005fedits-in-edit_005fline-promises|
|insert_lines       |            |      |       |Y        |Insert lines|https://cfengine.com/manuals/cf3-Reference#insert_005flines-in-edit_005fline-promises|
|replace_patterns   |            |      |       |Y        |Search and replace regular expressions|https://cfengine.com/manuals/cf3-Reference#replace_005fpatterns-in-edit_005fline-promises|
|reports            |Y           |Y     |Y      |Y        |Write reports and return values|https://cfengine.com/manuals/cf3-Reference#reports-in-common-promises|

The above table omits the agent `edit_xml` bundles (new in 3.4.0) for brevity, but they are similar to `edit_line` ordering.

The above table omits the knolwedge bundles `inferences`, `things`, `topics`, and `occurrences` for brevity.
