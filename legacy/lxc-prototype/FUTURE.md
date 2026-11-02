# Future LXC work

## Optional default parameter values

Planned for methods and constructors; not implemented. This note does not authorize
parser, compiler or runtime changes.

Potential syntax:

```text
public Creature(sName = "Unnamed", nMaximumHitPoints = 100)
{
    -- Constructor body.
}
```

- Use the default when an argument is omitted or explicitly nil.
- Preserve supplied false, 0 and empty-string values.
- Apply constructor defaults before evaluating parent-constructor arguments.

Support for arbitrary default expressions, their evaluation ordering, and override
compatibility rules remain undecided.
