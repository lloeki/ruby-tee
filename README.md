# Tee

Allows Enumerables and IO objects to be teed via fibers.

# Examples

Teeing enumerables makes each proc receive its own enumerator. `#tee` returns
an array with each proc's return values.

```ruby
> require 'tee/core_ext'
> [1, 2, 3].tee -> (e) { e.reduce(&:+) },
                -> (e) { e.map { |i| i**2 } }
=> [6, [1, 4, 9]]
```

Teeing IOs makes each proc receive its own IO. Those IOs can read the incoming
data in chunks.

```ruby
> require 'tee/core_ext'
> StringIO.new("foo").tee -> (io) { io.chunks.each { |c| puts c } }
foo
=> [nil]
```

Data can currently only be read in whole, uniformly sized chunks. Concurrent
execution is achieved via fibers (no threads needed).

One can skip requiring `core_ext` and get `#tee` on a case by case basis by
including or extending `Enumerable::Tee` and `IO::Tee` modules.
