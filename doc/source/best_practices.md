# Beamtime best practices

Recommendations that will make your beamtime smooth and productive.

## Igor folders

When you import data using the menu **Athina>Import** or by drag-and-drop a .file in Igor Pro, a wave is created in the cwd.

```{Note}
A red arrow marks the current working directoty cwd in the data browser
```

Use Igor's data browser to organise your data in folders. In the image below you can see an example folder structure in an Igor experiment. Using "New Data Folder" you create a new directory with parent the current working directory (cwd). Cwd is marked with a red arrow and you can change directory either by right-click and  select "Set Current Data Folder"  or move the arrow using the mouse to the desired directory. You can rename or delete a data folder. You can drag and move a data folder to another parent directory. You can also move waves in folders by drag-and-drop.

```{Caution}
When you delete a folder, you delete also the containing waves without warning. If at least one of the waves is displayed in a graph or table then delete is no op.
```

```{image} media/best_practices/DataBrowserFolders.png
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
## Cleanup and delete big waves

We assume that you save your Igor files as packed experiments (.pxp), which is the default for most Igor Pro users. Analysing datasets with large image stacks creates .pxp files of tens of GBs! It is recommended to cleanup and delete large 3d waves that you do not anymore need after processing/extracting the infomation you need. The original data are still there for you to import again in case you want to come back to them. Please use the "Free Space" operation under Utilities in the **Athina** menu. Select the threshold in MB above which Igor Pro marks a file for deleting. The program will show you a list with files that are larger that your threshold. This is your last change to delete an entry (or invalidate it be adding gibberish in the textbox) and keep the file.
Press continue and **Athina** will cleanup your .pxp experiment. Now you can save your file (Ctlr+s) and save disk space, as a bonus Igor will save your changes faster. 

Build time: {sub-ref}`today`
