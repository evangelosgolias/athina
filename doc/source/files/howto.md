# How-to

Here we are show some examples of how to analyze data or perform specific operations using athina.

## Drift correction

## Profiles along the third dimension

***Applies to XAS, XPEEM, LEEM-IV, LEED-IV or any three-dimensional dataset***

Extracting a profile along the third dimension (z-profile) is the most fundamental operation in an image stack. The third dimension can be the photon energy (XAS), electron kinetic energy (XPEEM, LEEM-IV, LEED-IV), time or any other quantity. 
In a stack of images, you need to define the area you'd like to integrate along the z dimension, so set your marquee, right-click in the marquee area and select to lauch the z-profiler using a rectangular or oval region as shown in the image below.


```{figure} media/rightClickLaunchZProfile.png
:alt: Launch z profile using marquee
:scale: 33%
:align: center
:name: rightClickLaunchZProfile

Right-click in the marquee area to see your options
```


```{tip} 
Launch image stack using **ATH NewImage**, set the marquee and press **z**, the z-profiler will be launched using the rectangular marked area.
```

```{figure} media/launchedZProfile.png
:alt: Z profiler in action
:scale: 33%
:align: center
:name: launchedZProfile

When you launch a profile a side-window pops. The red line in the plot marks the current image shown in the the stack that can be selected using the slider.
```

After launching the profiler a side window will appear. You can move the marked area using the red cursor and see the profile updating. There are two button and two checkboxes:
* "Save prof.": saves the currect profile
* "Set scale": set the scale of the x-axis (a prompt with instructions will pop)
* "Plot prof": when ticked the saved profile with be plotted
* "Mark areas": when a region is saved it is marked on the image.

When you save more than one profile, the line and region are marked with different color for clarity.

You can plot a second profile _on the same graph_ using a second image stack as source. To do so you need to provide the full path of the image stack you want to profile. The easiest way is to select the image stack in the data browser, right-click and select "Copy Full Path" as shown in the image below:

```{figure} media/copyFullPathInBrowser.png
:alt: copy full path in data browser
:scale: 33%
:align: center
:name: copyFullPathInBrowser

How to copy the full path in the data browser

```

Go to the profiler graph window and paste the copied path in the **TW** textbox and click the **Twin plot** checkbox to enable the second profile.

```{figure} media/twoZProfiles.png
:alt: plot two z profiles in one graph
:scale: 33%
:align: center
:name: twoZProfiles

Two z-profiles are shown in different colours. Blue is always the profiles of the displayed window. The two profiles can have different scales
```

```{caution} 
The operation is very usuful when you want to get information from the same region about two different measaurements. The twin plot comes from the region of the second stack as the one displayed in the active stack. Therefore, the two stacks have to be aligned and drift-corrected to ensure that you are not sampling signal from different regions.
```

## XPS

XPS datasets are saved as images of the dispersive plane. To extract the spectrum from the image you need to know the energy scale of the image, you need the conversion factor EPP (energy per pixel). This can be calculated if you have a know spin-orbit split core level (e.g. Au 4f)

## ARPES