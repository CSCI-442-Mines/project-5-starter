# Provided Tests

The files in this directory are named as follows:

```
input/<INPUT TYPE>/<INPUT TEST NUMBER>
output/<STRATEGY>/<MAX FRAME NUMBER>/<INPUT TEST NUMBER>_<OUTPUT MODE>.<OUTPUT TYPE>
```

- `<STRATEGY>` is one of:
    - `fifo`: first in, first out
    - `lru`: least recently used
- `<INPUT TEST NUMBER>` is the number of the input test file that the output is based on.
- `<INPUT TYPE>` is one of:
    - `process`: process image
    - `simulation`: simulation file
- `<MAX FRAME NUMBER>` is the maximum number of frames a process may be allocated.
- `<OUTPUT MODE>` is one of:
    - `verbose`: the output of the simulation with the `-v, --verbose` flag
- `<OUTPUT TYPE>` is one of:
    - `expected`: the expected output of the simulation (i.e., instructor's output)
    - `actual`: the actual output of the simulation (i.e., your output)

For example, if you run your simulation with these parameters,
```
./mem-sim --verbose --strategy fifo --max-frames 5 ./tests/input/simulation/1
```

Your standard output should look like the contents of the following file:
```
./tests/ouput/fifo/max_frame_5/1_verbose.expected
```
