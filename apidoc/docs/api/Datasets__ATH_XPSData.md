# ATH_XPSData

**Source file:** `Datasets/ATH_XPSData.ipf`

Module ATH_XPSData.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH XPSData functionality.

```{contents}
:local:
:depth: 2
```

## `XPSReferenceData`

**Signature**

```igorpro
XPSReferenceData()
```

Create and display the XPS reference-data selection panel.

New folder and display panel bring an existing panel forward.

### Returns

- **Variable**: Zero after completing the operation.


## `PTInitGlobals`

**Signature**

```igorpro
PTInitGlobals(ptpig)
```

Initialize global state for the periodic-table panel.

### Parameters

- `ptpig` *(Variable)*: Periodic-table panel state structure.

### Returns

- **Variable**: Zero after completing the operation.


## `PTInitPanel`

**Signature**

```igorpro
PTInitPanel()
```

Create the periodic-table element-selection panel.

### Returns

- **Variable**: The Igor panel-creation status.


## `PTDisplayPanel`

**Signature**

```igorpro
PTDisplayPanel()
```

Display and populate the periodic-table panel.

### Returns

- **Variable**: Zero after completing the operation.


## `SetVariableFunction`

**Signature**

```igorpro
SetVariableFunction(STRUCT WMSetVariableAction& sv)
```

Handle changes to the panel set-variable control.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sv` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `PTResizePanel`

**Signature**

```igorpro
PTResizePanel(pa)
```

Resize and reposition the periodic-table selection panel.

Wait for mouse up event store current states redraw panel at new scale factor.

### Parameters

- `pa` *(Variable)*: Igor control-action structure.

### Returns

- **Variable**: Zero after completing the operation.


## `GetAtNr`

**Signature**

```igorpro
GetAtNr(Estr)
```

Return the atomic number for an element symbol.

### Parameters

- `Estr` *(Variable)*: Text containing the estr.

### Returns

- **Variable**: The the atomic number for an element symbol.


## `ShowButtonProc`

**Signature**

```igorpro
ShowButtonProc(STRUCT WMButtonAction &ba)
```

Handle the continue button for show.

CAUTION: Tiling hard-coded, change /A=(x, y) if you like.

### Parameters

- `ba` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `ClearButtonProc`

**Signature**

```igorpro
ClearButtonProc(STRUCT WMButtonAction &ba)
```

Handle the continue button for clear.

Kill graphs. Clear selected button in the panel and reset ElemSelect wave.

### Parameters

- `ba` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `KEButtonProc`

**Signature**

```igorpro
KEButtonProc(STRUCT WMButtonAction &ba)
```

Handle the continue button for kinetic energy.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `ba` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `PTGetState`

**Signature**

```igorpro
PTGetState(STRUCT WMButtonAction &bs)
```

Read the current element selections from the periodic-table panel.

DimLabels for the dataset.

### Parameters

- `bs` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `GetSelectedElementsStr`

**Signature**

```igorpro
GetSelectedElementsStr(WAVE/T symbolsW, WAVE selw)
```

Return the chemical symbols selected in the periodic-table panel.

### Parameters

- `symbolsW` *(Wave/T)*: Text wave containing chemical-element symbols.
- `selw` *(Wave)*: Selection-state wave for periodic-table elements.

### Returns

- **String**: A semicolon-separated list of selected element symbols.


## `GetColumnOrderFromSelectedElement`

**Signature**

```igorpro
GetColumnOrderFromSelectedElement(string elementStr)
```

Return the table-column ordering for a selected element.

### Parameters

- `elementStr` *(String)*: Chemical-element symbol.

### Returns

- **String**: The column-order specification associated with the element.


## `PlotPhCrossSectionOfElement`

**Signature**

```igorpro
PlotPhCrossSectionOfElement(string elementStr)
```

Plot ph cross section of element.

Change colors for traces. Add legends.

### Parameters

- `elementStr` *(String)*: Text containing the element str.

### Returns

- **Variable**: Zero after completing the operation.


## `SetTraceColor`

**Signature**

```igorpro
SetTraceColor(variable colorIndex)
```

Return the RGB values assigned to a trace color index.

### Parameters

- `colorIndex` *(Variable)*: Zero-based index into the standard trace-color palette.

### Returns

- **Multiple values**: The red, green, and blue values for the selected trace-color index.


## `CreateElemSelectCoreLevels`

**Signature**

```igorpro
CreateElemSelectCoreLevels([int KE, variable hv, variable wf])
```

Create elem select core levels.

Not the most effective fuction having to call GetCrossSectionAtPhotonEnergy.

### Parameters

- `KE` *(Integer, optional)*: Kinetic energy in electronvolts.
- `hv` *(Variable, optional)*: Photon energy in electronvolts.
- `wf` *(Variable, optional)*: Work function in electronvolts.

### Returns

- **Variable**: Zero after completing the operation.


## `CreateElemSelectCSAtPhotonEnergy`

**Signature**

```igorpro
CreateElemSelectCSAtPhotonEnergy(WAVE wRef, variable hv, [int normalise, int maskExc])
```

Create elem select csat photon energy.

WRef here is root:Packages:ATH_DataFolder:XPSReferenceData:CoreLevelsSelect RSF p3/2 = RSFp * 2/3 RSF
p1/2 = RSFp * 1/3.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `hv` *(Variable)*: Photon energy in electronvolts.
- `normalise` *(Integer, optional)*: If nonzero, normalize the calculated values.
- `maskExc` *(Integer, optional)*: If nonzero, mask excluded energy values.

### Returns

- **Variable**: Zero after completing the operation.


## `GetCrossSectionAtPhotonEnergy`

**Signature**

```igorpro
GetCrossSectionAtPhotonEnergy(string elem, string orb, variable hv)
```

Return cross section at photon energy.

Get the ionisation cross-section, use DimLavels. Orb might be given as 2p1/2 but PhCS is given for the
subshell, 2p.

### Parameters

- `elem` *(String)*: Chemical-element symbol.
- `orb` *(String)*: Atomic orbital label.
- `hv` *(Variable)*: Photon energy in electronvolts.

### Returns

- **Variable**: The returned value is cross section at photon energy.


## `soRSF`

**Signature**

```igorpro
soRSF(string orbital)
```

Return the spin-orbit relative sensitivity factor for an orbital.

Return relative sensitivity factor orbital is a string of the for 2p, 2p3/2 N.B No checks for valid
inputs!!!!.

### Parameters

- `orbital` *(String)*: Atomic orbital label, including spin-orbit component when applicable.

### Returns

- **Variable**: The the spin-orbit relative sensitivity factor for an orbital.


## `CoreLevelsInEnergyRange`

**Signature**

```igorpro
CoreLevelsInEnergyRange(variable Elow, variable Ehigh, [int KE, variable hv, variable wf, string elements, variable core, variable auger])
```

List core levels and Auger transitions inside an energy range.

The range can be interpreted as binding or kinetic energy and can include photoelectron core levels, Auger
transitions, or both.

### Parameters

- `Elow` *(Variable)*: Lower energy bound in electronvolts.
- `Ehigh` *(Variable)*: Upper energy bound in electronvolts.
- `KE` *(Integer, optional)*: If nonzero, interpret the range as kinetic energy.
- `hv` *(Variable, optional)*: Photon energy in electronvolts.
- `wf` *(Variable, optional)*: Work function in electronvolts.
- `elements` *(String, optional)*: element-symbol filter.
- `core` *(Variable, optional)*: If nonzero, include photoelectron core levels.
- `auger` *(Variable, optional)*: If nonzero, include Auger transitions.

### Returns

- **String**: A formatted list of matching transitions and energies.


## `ShowNotebookCoreLevelsInEnergyRange`

**Signature**

```igorpro
ShowNotebookCoreLevelsInEnergyRange(variable Elow, variable Ehigh, [int KE, variable hv, variable wf, string elements, variable core, variable auger])
```

Show matching core levels and Auger transitions in a notebook.

### Parameters

- `Elow` *(Variable)*: Lower energy bound in electronvolts.
- `Ehigh` *(Variable)*: Upper energy bound in electronvolts.
- `KE` *(Integer, optional)*: If nonzero, interpret the range as kinetic energy.
- `hv` *(Variable, optional)*: Photon energy in electronvolts.
- `wf` *(Variable, optional)*: Work function in electronvolts.
- `elements` *(String, optional)*: element-symbol filter.
- `core` *(Variable, optional)*: If nonzero, include photoelectron core levels.
- `auger` *(Variable, optional)*: If nonzero, include Auger transitions.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.
