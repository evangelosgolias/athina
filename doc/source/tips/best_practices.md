# Best practices

## Igor folders

When you import data using the menu **Athina>Import** or by drag-and-drop a .file in Igor Pro, a wave is created in the cwd.

A single (or muliply) image is imported as a wave named after the source filename (minus the file extention, i.e. .dat). When you import images in a stack, you can choose the name of the resulting wave or let the program find a unique name composed by the base name "ATH\_Stack" ended by a increasing numerical suffix.

```{note} 
All data import operations create a wave in the active Igor directory (cwd) 
```

Use Igor's data browser to organise your data in folders. In Igor if the data folder is not show press *CTRL + B*. In the image below you can see an example folder structure in an Igor experiment. Using "New Data Folder" you create a new directory with parent the current working directory (cwd). Cwd is marked with a red arrow and you can change directory either by right-click and  select "Set Current Data Folder"  or move the arrow using the mouse to the desired directory. You can rename or delete a data folder. You can drag and move a data folder to another parent directory. You can also move waves in folders by drag-and-drop.

```{Caution} 
When you delete a folder, you delete also the containing waves without warning. If at least one of the waves is displayed in a graph or table then delete is no op.
```

```{image} media/DataBrowserFolders.png
:alt: IgorDataBrowser
:scale: 33%
:align: center
:name: DataBrowserFolders
```

## Spaces

*Spaces* organises windows (Graphs, Tables, Layouts, Notebooks or Panels) in separate desktops (spaces). It is recommended to launch *Spaces* from the get-go to avoid screen overloading. Without spaces, and especially when you create windows for display-only data and you do not close them, your desktop will soon turn into a scramble of loose images/plots.

To launch *Spaces* select **Athina>Utilities>Spaces** and a panel titled ATH Spaces (winName: ATH_SpacesPanel). 

When a Space is click-selected, only windows with the same space tag are shown (space name is the space tag).

Guide to Spaces:

* Press the "New" button to create a new Space, name should be unique, otherwise you will be prompted to change your input. When a new "Space" is created it becomes your active working Space. New Spaces are created below the active row selection, and at the moment you cannot change their order.
* Press "Delete" to delete the selected space. Windows associated with the space are released and not linked to any space ("" tag).
* Press "All" to show/hide all windows whether linked to a Space or not.
* When the Igor Spaces Panel is open any window you create is associated with the active Space.
* Double click on a row to rename the Space
* Press Shift + Click on a row of the ListBox to move the top window to the selected space
* Press Alt + Click anywhere in the ListBox of the panel (rows or empty space below) to pin the top window to all spaces (visible everywhere)
* To unpin press Shift + Alt + Click anywhere in the ListBox to unpin the window (becomes free floating). You can also make a normal window free-floating using the same procedure. Alternatively, if you want to  unpin and link it to a space do Shift + Click on a row of the ListBox.
* Press CTRL + click (CMD on Mac) to mark a Space with an asterisk

```{tip} TL;DR

-  Use Shift + Click a row/*Space* to assign the top window.
-  Double click: Rename *Space*
-  Alt + Click (not a named row): Pin top window (appears in all *Spaces*)
-  Shift + Alt + Click: unpin top window
-  CTRL + click to mark a Space with an asterisk
```

Build time: {sub-ref}`today`
