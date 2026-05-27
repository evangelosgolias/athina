# ATH_Spaces

**Source file:** `Utilities/ATH_Spaces.ipf`

Module ATH_Spaces.

Igor Spaces organises windows (Graphs, Tables, Layouts, Notebooks or Panels) in separate Spaces.
When a Space is selected in the panel, only windows linked to it are shown.
How it works:
1. Launch Igor Spaces from "Windows/Packages" submenu.
2. Press the "New" button to create a new Space, name should be unique, otherwise you will be
prompted to change your input. When a new "Space" is created it becomes your active working Space.
New Spaces are created below the active row selection, and at the moment you cannot change their order.
3.Press "Delete" to delete the selected space. Windows associated with the space are released and not
linked to any space ("" tag)
4. Press "All" to show/hide all windows whether linked to a Space or not.
5. When the Igor Spaces Panel is open any window you create is associated with the active Space.
6. Double click on a row to rename the Space
7. Press Shift + Click on a row of the ListBox to move the top window to the selected space
8. Press Alt + Click anywhere in the ListBox of the panel (rows or empty space below) to pin the top
window to all spaces (visible everywhere)
9. To unpin press Shift + Alt + Click anywhere in the ListBox to unpin the window (becomes free floating).
You can also make a normal window free-floating using the same procedure. Alternatively, if you want to
unpin and link it to a space goto 7.
10. Use Ctlr + click to mark/unmark a space with an asterisk and link it to the selected data folder in the data browser.
When selecting a Space with an asterisk the current data folder changes to the linked data folder.
TL;DR:
SHIFT+Click: on a Space to associate with the top window.
Double-click: Rename the Space.
ALT+click (on an enpty row NOT a space): Pin top window to all Spaces.
SHIFT+ALT+click: unpin top window and make (now with no Space link, i.e. orphan).
CTRL+click (CMD+click on MacOS): link space to the selected data folder in Data Browser
(now marked with an asterisk). Current data folder changes when you select spaces with asterisk.

```{contents}
:local:
:depth: 2
```

## `MenuLaunch`

**Signature**

```igorpro
MenuLaunch()
```

Description of MenuLaunch.

Launch Spaces named ATH_Spaces#MenuLaunch().

### Returns

- **Variable**: 0


## `MakePanel`

**Signature**

```igorpro
MakePanel()
```

Create main window of ATH_Spaces.

Create main window of ATH_Spaces named ATH_SpacesPanel, launch from command line
as ATH_Spaces#MakePanel().

### Returns

- **Variable**: Returns 0 if all ok


## `ShowWindowsOfSpaceTag`

**Signature**

```igorpro
ShowWindowsOfSpaceTag(string spaceTagStr, variable show)
```

Show/hide windows tagged with @param spaceTagStr.

Show or hide windows that have a tag on them. Control show/hide using the parameter show.

### Parameters

- `spaceTagStr` *(String)*: Name of the tag
- `showSwitch` *(Variable)*: show = 0 or 1

### Returns

- **Variable**: 0


## `RenameSpaceTagOnWindows`

**Signature**

```igorpro
RenameSpaceTagOnWindows(string oldspaceTagStr, string newspaceTagStr)
```

Change the name of the space, all tag linked to the space are renamed.

Change the name of a space. All windows with tags linked to the space are renamed.
The function is used by Spaces when a space is renamed. Do not call the function directly.

### Parameters

- `oldspaceTagStr` *(String)*: Current space name
- `newspaceTagStr` *(Parameter)*: New space name

### Returns

- **Variable**: 0


## `ClearWindowsFromSpaceTag`

**Signature**

```igorpro
ClearWindowsFromSpaceTag(string spaceTagStr)
```

Clears all windows associated with a specific tag.

Clears all windows associated with a specific tag. This function is used by Spaces
to clear tags from windows associated to spaces that are being deleted. Do not call the
function directly.

### Parameters

- `spaceTagStr` *(String)*: spaceTagStr

### Returns

- **Variable**: 0


## `UniqueSpaceNameQ`

**Signature**

```igorpro
UniqueSpaceNameQ(WAVE/T textW, string spaceNameStr)
```

Is the Space name unique?

The function checks is the name of a space is not already in the list of existing spaces.

### Parameters

- `textW` *(Wave/T)*: textW.
- `spaceNameStr` *(String)*: spaceNameStr

### Returns

- **Variable**: True(1)/False(0)


## `SanitiseATHSpaceName`

**Signature**

```igorpro
SanitiseATHSpaceName(string spaceNameStr)
```

Sanitise a space name.

Returns a sanitized version of a space name by removing a trailing asterisk if present.
An asterisk is used to mark spaces linked to specific folders, therefore, they do not
consist valid space names in Spaces.

### Parameters

- `spaceNameStr` *(String)*: spaceNameStr

### Returns

- **String**: Sanitized spaceNameStr


## `ShowAllWindows`

**Signature**

```igorpro
ShowAllWindows(variable showSwitch)
```

Show all windows.

Show all windows in the current experiment.

### Parameters

- `showSwitch` *(Variable)*: show = 0 or 1

### Returns

- **Variable**: 0


## `ShowOrphanWindows`

**Signature**

```igorpro
ShowOrphanWindows(variable show)
```

Show orphan windows.

Show orphan windows, i.e. windows without any tag.

### Parameters

- `showSwitch` *(Variable)*: show = 0 or 1

### Returns

- **Variable**: 0
