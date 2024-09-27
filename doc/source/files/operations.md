# Operations

Let's the the fundamental operations we use to extract information from spectro-microscopy/microspectroscopy data.

## Z profile

***Can be used with any three-dimensional dataset to extract a profile along the third dimension.***

In a stack of images, you need to define the area you'd like to integrate along the z dimension, so set your marquee, right-click in the marquee area and select:

- ATH Z-profiler: Set rectangular ROI (3D)
- ATH Z-profiler: Set oval ROI (3D)

to launch an integrated rectangular or oval z profile. 

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
After launching the profiler a side window will appear. You can move the marked area using the red cursor and see the live profile.

```{figure} media/launchedZProfile.png
:alt: Z profiler in action
:scale: 33%
:align: center
:name: launchedZProfile

Z profle window. The vertical red line in the graph marks the displayed image of the stack selected using the slider.
```

There are two button and two checkboxes:
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

The operation is very useful when you want to get information from the same region about two different measaurements. The twin plot comes from the region of the second stack as the one displayed in the active stack. Therefore, the two stacks have to be aligned and drift-corrected to ensure that you are not sampling signal from different regions.
```

```{tip} 

You can save a region of interest (ROI) and use it in image stacks when you want to launch the same profiler. Set a marquee, right-click inside and select "ATH Save Rect ROI" or "ATH Save Oval ROI". A dashed line will highlight your selection. Afterwards, in any image stack you can **right-click** anywhere in the graph and select "ATH Z-profiler: Use Saved ROI" and the z-profiler will launch
```

```{Note} 
Right-click and select "ATH Clear UserFront layer" to clear all markings.
```
## Line profile

To launch the line profiler select "athina > Profiles > Line profiles" or if you displayed the image using "ATH NewImage" just press "l".

The buttons, tickboxes on the line profile plot do the following:

- Save Profile: Saves the current profile
- Save Settings: Save all settings to restore.
- Restore settings: Restore saved settings
- Show width: Show set line profile integration width while pressed.
- Plot Profile: Display the saved profile.
- Mark lines: Mark with a traced line the line of the saved profile (line and graph trace colors are the same)
- Stack layer: Update displayed profile when displayed plane changes in a 3D wave.
- Width: integration with of the extraction profile in pixels.

```{figure} media/Launch_line_profile.png
:alt: Line profiler
:scale: 33%
:align: center
:name: Line profiler

Line profile plot (interactive), use cursors.
```
## Plane profile

The operation extracts a profile of a plane that intersects a 3D volume. The points that define the plane are two cursors on the the surface of the volume and one projection of one of them on the bottom. The cut is always along the z direction. To launch this operation you can select from the menu "athina > Profiles > Plane profile " or press "p" if the *image stack* has been launched using "ATH New Image" in the data browser. The window below will appear:

```{figure} media/planeZprofile.png
:alt: Plane profile
:scale: 33%
:align: center
:name: Plane profile

Plane profile using a PED dataset. Use cursors to define the plane (interactive).
```

The image size (pixels) that the profiler extracts has Nx: number of pixels between cursors G and H (x-axis zero is at pointer G)and Ny: number of layers in the stack. 

You can override the default size by ticking the corresponding tickboxes and the entering the values of your choice and you will get an *interpolated* image with the dimensions you've set. 

You can change the width of the plane profile to the number of pixels you'd to integrate along the z direction (Width (px)). 

You can scale the extracted profile by pressing "Set Scale" and the following dialog will appear:

```{figure} media/scalePlaneZProfile.png
:alt: Scale plane profile
:scale: 33%
:align: center
:name: Scale plane profile

Scale the extracted plane profile.
```

The first input sets the x-scale: the distance between cursor G and H is set to this value. That's now your x-scale

The Y top and bottom values set your Y axis. Use higher top value to keep the order of planes as is, otherwise the profile will be reversed, i.e  bottom to the top.

Set scale(s) to zero to reset the scales.

## Drift correction

During data acquisition images can drift because of temperature or electronic instabilities, space-charge effects or external vibrations. Frequently, the effect is not visible as the drifts are below the spatial resolution of the instrument but sometimes there are so prominent that the analysis of image stacks is pointless without drift correction. athina can correct drifted images using different approaches and the current paragraph is not a complete guide of athina's capabilities, built-in algorithms and methodologies. If you want to know more about the implementation you have to read Igor's manual about ImageRegistration, ImageInterpolation, FFT and others and also browse and inspect the source code along witn having an understanding of image processing. 

There is no silver bullet for dfift correction, trial-and-error is your guide but later on we will give some tips and tricks.

### Backup/restore image stack

When you apply drift correction to a stack of images a backup is always created in case you want to revert the operation. The name of the backup wave is the name of your original wave with an "_undo" suffix (NameOfWave\_undo). *To restore the original image press SHIFT+b (if plotted using ATH NewImage) or right-click on the image and select "ATH Restore Image" or right-click on the source wave in the data browser and select "ATH Restore Image". If you are happy with the drift correction it is advised to delete the backup wave either manually in the data browser or using the "athina > Utilities > Free Space" function.

### Automatic

athina uses two main methods to drift-correct images: Image Registatration and (cross) correlation. Image Registration can do sub-pixel drift-correction, while at the moment (it can change in future releases) correlation drift-corrects by an integer number of pixels. 

athina can correct the drift using the whole image or a selected part of it. The first is computational intensive, most of the times less accurate(!) and it should be used only for a handful of images in the stack, if at all.
_Most of the times it is advised to use the latter, i.e select a characteristic feature of an image to correct the drift_. You can launch drift correction using a feature on the top graph (TG) from the main menu as seen in the image below:

```{figure} media/lauchDriftCorrectionFromMenu.png
:alt: Launch z profile using marquee
:scale: 33%
:align: center
:name: lauchDriftCorrectionFromMenu

Launch drift correction from the main menu targeting the top graph.
```

**or better if you have created the stack plot using right-click "ATH Newimage" the just place a marquee on the graph and press z**.

The following panel will appear:

```{figure} media/automaticDriftCorrection.png
:alt: Automatic drift correction panel
:scale: 33%
:align: center
:name: automaticDriftCorrection

Launch drift correction from the main menu targeting the top graph.
```

There you have the following options:

* "Method": Registration or Correlation
* "Reference layer": Reference layer for drift calculation
* "Apply filter": Apply one filter: gauss, avg, median, max or min
* "Filter N = 3 ..": when a region is saved it is marked on the image.
* "Apply filter 1..5 times": How many times to apply the filter
* "Normalise range [0, 1]": Normalise image between [0, 1]
* "Apply histogram equalization": yes/no
* "Edge detection method": shen, kirsch, sobel, prewitt, canny, roberts, marr or frei
* "Cutoff drift (pixels)": threshold above which no drift correction applies
* "Print drift layer": Yes/No to show the drifts applies per layer.

Place the marquee around a characteristic feature of your sample, as seen in the image below. Select the minimum area that covers all the positions of your selected feature across all layers - you can check this using the slider. Make sure that the characteristic feature is not very close to the marquee boundaries. Then press continue and cross fingers. The time needed to complete the operation scales with the selected area.

```{figure} media/setMarqueeForDriftCorrection.png
:alt: Set marquee to use a feature for drift correction.
:scale: 33%
:align: center
:name: setMarqueeForDriftCorrection

Select a characteristic feature using the marquee and press continue to procced.
```

```{tip} 

When you try to aling XAS or XPEEM images where the contrast reverses between layers the **correlation method** gives better results. When you acquire a stack of images under the same conditions the Registration is the best method.
```

### Interactive

For difficult drift correction cases there is an interactive drift correction panel. To launch it you can either select "athina > Interactive Operations > Drift Correction" or **press z with no marquee** ("ATH NewImage") in top graph to launch the interactive panel.

```{figure} media/interactiveDriftCorrection.png
:alt: Interactive drift correction panel.
:scale: 33%
:align: center
:name: interactiveDriftCorrection

The interactive drift correction panel
```

Using the green cursor you can set a reference point or indicate the position to move a feature. If you want to be more precise you can zoom in in a part of the image using the marquee and right-click and select "Expand" (to go back presse CTLR + A (CMD + A on a Mac)) as seen below.

```{figure} media/expandWithMarquee.png
:alt: Zoom in using the marquee
:scale: 33%
:align: center
:name: expandWithMarquee

Use the marquee to zoom in to a region of an image
```

First you have to move the cursor to the reference point you want to use and press " (Re)Set anchor". Dashed red lines will indicate the reference point you've (re)set - it's the crossing point. 
Move the slider and then cursor and press "Drift Image" to manually drift an image (mouse wheel works also).
Press "Drift N images" and select a range of images you want to move.
Press "Cascade drift" to move all images from the current image to the end of the stack.

Using the **Linear Drift Corr** part you can drift correct a series of images by linear interpolating between the start and end layers. Move the slider to the start layer and press "Start" while having the cursor on the feature you use as fiducial. Move the slider to the end layer and set the cursor to the new position of your previous fiducial point. Press "Drift" and you're done. 

```{tip} 

Linear drift correction is useful in linear drifts between layes that usually happen when there are monotonous temperature changes in the microscope
```

Press "Checkpoint" to save the state of the stack (N.B you cannot restore the original stack afterwards)
Press "Restore stack" to revert all changes.

Last, there a fast drift correction that can be enables by ticking the "SHIFT+Click & drift". **You cannot enable this mode unless you have set a reference point** When the mode is enabled the fiducial point is not a red dot, it is small as we assume that most of the time you'd like to work in a small part of the image to be more precise. Use:

* SHIFT + left mouse click on a point to drift the image. The reference point will be moved to the point you clicked, so try to follow your fiducial point with your mouse. After clicking the next layer will be displayed.
* Use arrow keys or mousewheel to skip layers or go back to previous ones. 
* Press Delete or BackSpace to revern the current layer to it's starting position (no drift correction).

```{caution} 

If you have drift correct your stack the changes are automatically applies if you close the iDriftCorrection side-window. There is no backup left to restore your stack to its original state. **If you want to discard any changes with you to press "Restore stack" before exiting.**

```