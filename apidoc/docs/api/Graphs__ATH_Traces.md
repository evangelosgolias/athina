# ATH_Traces

**Source file:** `Graphs/ATH_Traces.ipf`

Module ATH_Traces.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Traces functionality.

```{contents}
:local:
:depth: 2
```

## `TopTraceToWaveRef`

**Signature**

```igorpro
TopTraceToWaveRef([string grfName])
```

Return a reference to the top trace in a graph.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `MarqueeToTraceOperation`

**Signature**

```igorpro
MarqueeToTraceOperation(variable op)
```

Marquee to trace operation.

Op: 0: PullToZero 1: Normalise to one 2: Maximun to one.

### Parameters

- `op` *(Variable)*: Operation selector.

### Returns

- **Variable**: Zero after completing the operation.


## `OperationsOnGraphTracesWithMarquee`

**Signature**

```igorpro
OperationsOnGraphTracesWithMarquee(variable left, variable right, variable operationSelection)
```

Apply an arithmetic operation to graph traces inside the active marquee range.

Trace calculations using graph marquee.

### Parameters

- `left` *(Variable)*: Left ROI or marquee bound.
- `right` *(Variable)*: Right ROI or marquee bound.
- `operationSelection` *(Variable)*: Index selecting the arithmetic operation to perform.

### Returns

- **Variable**: Zero after completing the operation.


## `AlignTracesDB`

**Signature**

```igorpro
AlignTracesDB()
```

Align traces selected in the Data Browser.

Fix: For stitching to have sense as done here there should be an overlap between regions, i.e. region
width should be larger than the step between traces.

### Returns

- **Variable**: Zero after completing the operation.
