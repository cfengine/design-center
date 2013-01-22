# Negative Knowledge In CFEngine

## Design Center HOWTO series

### Author: Ted Zlatanov <tzz@lifelogs.com>

### Version: 3.4.1-0

This is an explanation of negative knowledge and how it matters in CFEngine.

Important terms:

* _knowledge_: the agent's fluid and evolving idea of what's true, e.g. "I am on a _Linux_ machine."
* _convergence_: the process by which CFEngine evaluates and resolves promises (variables and classes are types of promises, too)
* _context_ or _class_: a unit of knowledge, like a boolean in programming languages, which can be either present or absent.  The two terms are used interchangeably.

Most of CFEngine (documentation, tools, and community) recognize
_class_ as the more common name for a unit of knowledge, but _context_
is also used.

CFEngine classes represent knowledge.  For instance, the _hard
classes_ are irrevocable units of knowledge about the system:

`solaris.Monday`: "I am running on _Solaris_.  It's a _Monday_."

You can't force-define a hard class.  Try `cf-agent -Dsolaris` and it
will not let you.

_Soft classes_ are units of knowledge that can come from the policy.

`compliance.boston`: "I belong to group _Compliance_.  My location is _Boston_."

Well, often you want to know that some knowledge is _not_ present.

`!boston`: "If I'm not in _Boston_, I should not peer with network X."

The tricky thing here is that just because you don't have the
knowledge now, doesn't mean you won't have it later in the convergence
process.  You can even *cancel* a class!

In other words, *knowing not* and *not knowing* are different things
(as Mark Burgess put it).

So, how do we distinguish between "I am not in _Boston_" and "I have
not been in _Boston_ yet during the CFEngine agent execution"?

We have to create a class to represent the negative.  In this case:

`not_boston`: "I am definitely not in _Boston_.  Really."

To use this technique just do this:

``
classes:
  "not_boston" expression => "!boston";
``

But more importantly, any time you see the negation of a class in your
CFEngine policies, think about it.  Can the absence of the class ever
change?  If yes, you may want to use an explicit "no_class".
