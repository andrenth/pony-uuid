# Pony-UUID

## Introduction

This module provides a [Pony](https://www.ponylang.io/) package for parsing
and generating [UUIDs](https://tools.ietf.org/html/rfc4122).

This code is basically a direct port of [Google's `uuid` package for Go](https://github.com/google/uuid).

Pony-UUID does not support generating UUIDs of versions 1 and 2 at this point.

## Examples

The package is meant to be used with aliased `use` statements.

### Generating a random (version 4) UUID

```
use uuid = "uuid"

actor Main
  new create(env: Env) =>
    let id = uuid.UUID.v4()
    env.out.print(id.string())
```

### Parsing an UUID

```
use uuid = "uuid"

actor Main
  new create(env: Env) =>
    try
      let arg = env.args(1)?
      match uuid.Parse(arg)
      | let id: uuid.UUID =>
        env.out.print(id.string() + " version: " + id.version().string() + ", variant: " + id.variant().string())
      | uuid.InvalidPrefix =>
        env.out.print(arg + ": invalid prefix")
      | uuid.InvalidFormat =>
        env.out.print(arg + ": invalid format")
      | uuid.InvalidLength =>
        env.out.print(arg + ": invalid length")
    end
```
