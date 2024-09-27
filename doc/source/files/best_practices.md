# Best practices

## Igor folders

When you import data using the menu entry **athina > Import** or by drag-and-drop a file (.dat only) in Igor Pro, a wave is created in the current working folder.

Images are imported as waves named after the source filename (minus the file extention, i.e. .dat). When you import images in a stack, athina sets a unique name composed by "ATH\_Stack" plus a numerical suffix.

Use Igor's data browser to organise your data in folders. In Igor if the data folder is not show press *CTRL+B*. In the image below you can see an example folder structure in an Igor experiment. Using "New Data Folder" you create a new directory with parent the current working directory (cwd). Cwd is marked with a red arrow and you can change directory either by right-click and  select "Set Current Data Folder"  or move the arrow using the mouse to the desired directory. You can rename or delete a data folder. You can drag and move a data folder to another parent directory. You can also move waves in folders by drag-and-drop.

```{Caution} 
When you delete a folder, you delete also the containing waves without warning. If at least one of the waves is displayed in a graph or table then delete does nothing.
```

```{image} media/DataBrowserFolders.png
:alt: IgorDataBrowser
:scale: 33%
:align: center
:name: DataBrowserFolders
```

## Spaces

*Spaces* organise windows (Graphs, Tables, Layouts, Notebooks or Panels) in separate desktops (Spaces!). It is recommended to launch *Spaces* from the get-go to avoid screen overloading. Without Spaces, and especially when you create windows for display-only data and you do not kill them, your desktop will soon turn into a scramble of loose images/plots.

To launch *Spaces* select **athina > Utilities > Spaces** and a panel titled ATH Spaces (winName: ATH_SpacesPanel) will pop. Move it at the right end of your desktop. 

When a Space is click-selected, only windows that belong to the selected Space are shown, all others are hidden. All graphs, notebooks, layouts created are automatically assigned to the active (selected) Space. You can move windows between spaces, pin them to all spaces, make them orphans (they do not belong to Space), create, delete and rename a Space as well as link a Space to a specific data folder. 

A short guide of Spaces buttons mouse actions and key-bindings:

* __When the Spaces Panel is open any window you create is associated with the active Space__
* __Buttons__ 
    - Press the "New" button to create a new Space, name should be unique, otherwise you will be prompted to change your input. When a new "Space" is created it becomes your active working Space. New Spaces are created below the active row selection.
    - Press "Delete" to delete the selected space. Windows associated with the space are released and not linked to any space (orphans).
    - ress "All" to show/hide all windows whether linked to a Space or not.
    - Press "Orphans" to show windows that do not belong to any Space
* __Mouse__
    - Double click on a row to rename the Space
* __Key-bindings__
    - Press SHIFT+click on a row of the ListBox to move the top window to the selected space
    - Press ALT+Cclick anywhere in the ListBox of the panel (rows or empty space below) to pin the top window to all spaces (visible everywhere)
    - To unpin press SHIFT+ALT+click anywhere in the ListBox to unpin the window (becomes free floating). You can also make a normal window free-floating using the same procedure. Alternatively, if you want to  unpin and link it to a space do SHIFT+click on a row of the ListBox.
    - Press CTRL+click (CMD on Mac) to mark/unmark a space with an asterisk and link it to the selected data folder in the data browser. When selecting a Space with an asterisk the current data folder changes to the linked data folder.

```{figure} media/SpacesPanel.png
:alt: Spaces Panel
:scale: 33%
:align: center
:name: SpacesPanel

Spaces panel. **Hover over over the red question mark (?) for quick help**.
```

```{tip} Quick-help

-  SHIFT+Click: on a Space to associate with the top window.
-  Double-click: Rename the Space.
-  ALT+click (on an enpty row NOT a Space): Pin top window to all Spaces.
-  SHIFT+ALT+click: unpin top window and make (now with no Space link, i.e. orphan).
-  CTRL+click (CMD+click on Mac): link space to the selected data folder in Data Browser (now marked with an asterisk). Current data folder changes when you select spaces with asterisk.
```

## Data cleanup

It is common to load and process big image stacks with hunders of MB or a few GB in size. If you do not bin your images and acquire in 4K resolution, then an 100 image stack takes about 3.3 GB of space!
Large Igor experiment (.pxp) files slow down your computer's response (RAM overload) and it takes some time when you save your analysis.

A good habit is to clean up your experiment from time to time. Processed image stacks that are not needed anymore is better to be removed from your experiment (if you need the raw data you can reload them). To do this easily run **athina > Utilities > Free Space**. The following prompt will appear:

```{figure} media/FreeSpacePrompt.png
:alt: Free Spacem operation prompt window
:scale: 33%
:align: center
:name: FreeSpacePrompt

Free space operation prompt. Enter threshold size in MB and press continue.
```
Select the threshold size in MB above which a file should be deleted and press continue. A list of files will pop, as seen in the screenshot below, and that's your last chance to cancel or proceed. 

```{figure} media/FreeSpaceFileList.png
:alt: Free Spacem operation prompt window
:scale: 33%
:align: center
:name: FreeSpaceFileList

List of files above the selected threshold to be deleted.
```

```{tip}
To keep one or more files just delete the corresponding entry in "WaveNamesW" list
```

```{caution}
If a wave is displayed, even if it's hidden in a Space, it will not be deleted.
```

Build time: {sub-ref}`today`
